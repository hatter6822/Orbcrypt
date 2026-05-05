<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Audit 2026-04-18 — Workstream Resolution Plan

**Source audit:** `docs/audits/LEAN_MODULE_AUDIT_2026-04-18.md` (22 findings, 1,374 lines)
**Branch:** `claude/audit-workstream-planning-d1kg3`
**Created:** 2026-04-18
**Author:** Claude (planning agent)

## 0. How to read this document

- Every audit finding (F-01 … F-22) is resolved by one or more **Work Units** (WUs).
- Work Units are grouped into seven **Workstreams** (A–G) by theme, dependency, and risk.
- Each WU is atomic: one well-scoped change, one acceptance gate, ≤ 1 commit target.
- Effort sizes: **XS** (< 30 min), **S** (< 2 h), **M** (2–8 h), **L** (1–3 d), **XL** (> 3 d).
- Every WU carries a `lake build` verification command. No WU is complete until
  the specific module(s) it touches build green *and* the workstream-level
  regression suite still passes.
- Appendix A gives the inverse mapping (Finding → WU) in a single table for
  audit traceability.

## 1. Executive Summary

The 2026-04-18 audit raised 22 findings. **None are exploitable security
vulnerabilities.** They split into five qualitative buckets:

| Bucket | Count | Findings | Disposition |
|--------|-------|----------|-------------|
| CI / style / cosmetic | 7 | F-03, F-04, F-12, F-16, F-18, F-19, F-22 | Ship immediately (Workstream A) |
| Security-definition refinement | 3 | F-02, F-13, F-15 | Ship in parallel (Workstreams A, B) |
| Composition gap (provable in Lean) | 2 | F-07, F-08 | Short-term (Workstreams C, D) |
| Probabilistic refinement (the big lift) | 5 | F-01, F-10, F-11, F-17, F-20 | Medium-term (Workstream E) |
| Research / implementation | 5 | F-05, F-06, F-09, F-14, F-21 | Long-term (Workstream F) |
| Documentation hygiene | — | none standalone | Each workstream has a doc WU (G) |

**Bucket total: 7 + 3 + 2 + 5 + 5 = 22 findings** (matches audit §7).

**The single highest-value item** — flagged by the audit itself (§5.1) — is
Workstream **E**: propagate Phase 8's `ConcreteOIA` / `CompOIA` framework
through the KEMOIA layer, the Phase 12 hardness chain, and the Phase 13
combiner impossibility theorem. Until that work lands, `oia_implies_1cpa`,
`kemoia_implies_secure`, `hardness_chain_implies_security`, and
`equivariant_combiner_breaks_oia` are all **vacuously true on any scheme with
≥ 2 orbit representatives** — a fact the project already self-documents but
has not yet remediated.

**Decomposition discipline.** The original plan named 38 parent work units;
the present revision decomposes every M/L/XL parent into atomic sub-WUs
(B1 → B1a/b/c, C2 → C2a/b/c, D1 → D1a/b/c, D2 → D2a/b/c, E1 → E1a–d,
E2 → E2a/b/c, E3 → E3-prep + E3a–d, E4 → E4a–c, E6 → E6a–c, E7 → E7a–c,
E8 → E8a–d, F1 → F1a–d, F3 → F3a–d, F4 → F4a–d, F5 → F5a–c (tiered),
F6 → F6a–c). The resulting **77 atomic units** are each: independently
buildable, ≤ 16 h apiece, individually revertible. No remaining sub-WU
is a multi-day monolith.

## 2. Finding Verification (non-erroneous)

Every finding was spot-checked against the current source. Representative
evidence:

| Finding | Evidence |
|---------|----------|
| F-03 | `.github/workflows/lean4-build.yml:34` — `grep -rn "sorry"` (no `\b` anchor) |
| F-04 | `Orbcrypt/Construction/Permutation.lean:92` — literal `push Not at h` |
| F-12 | `grep GIReducesToCE/GIReducesToTI` shows only 2 defs + 2 docstring refs, zero consumers |
| F-16 | `Hardness/CodeEquivalence.lean:220–227` — conclusion is `ArePermEquivalent`, not a set identity |
| F-18 | `Probability/Negligible.lean:90,101` — two `have hn_pos` bindings |
| F-19 | `PublicKey/KEMAgreement.lean:132–141` — proof is `rw [kem_correctness, kem_correctness]` leaving `rfl` |
| F-22 | `.github/workflows/lean4-build.yml:13–15` — `curl | bash` with no SHA-256 |
| F-05 | `KeyMgmt/SeedKey.lean:140–161` — structure exists, no `HGOEKeyExpansion → SeedKey` bridge |
| F-06 | `KeyMgmt/SeedKey.lean:222–228` — `sampleG : ℕ → G` plain function, no secrecy obligation |
| F-08 | `Hardness/CodeEquivalence.lean` has only `arePermEquivalent_refl`; no `_symm` / `_trans` |
| F-11 | `Crypto/CompSecurity.lean:211–218` — `single_query_bound` body is `hOIA D m₀ m₁` — a rename |

All 22 findings are substantiated by the current tree at commit `HEAD`.
**None are erroneous.** Findings F-01, F-10, F-17, F-20 overlap
thematically — they are distinct symptoms of the same root cause
(deterministic OIA unsatisfiability), but each raises a specific theorem
affected by it and each is correctly filed.

## 3. Workstream Overview

### Workstream-level dependencies

```
A (quick fixes) ──┐
                  ├── independent, can land immediately
B (defs)       ──┘

C (MAC/INT_CTXT) ── independent, unblocks future CCA work
D (CE API)       ── independent, enables F-09 research later

E (prob chain) ── depends on A2 (F-04 fix unblocks the Construction module),
                  builds on existing Phase 8 infrastructure
F (research)   ── long-term; F3/F4 strengthen E4; F5 strengthens Phase 13
G (docs)       ── continuous; each workstream has a doc WU
```

### Atomic sub-WU dependencies (key sequencing edges)

```
Workstream B intra:
  B1a → B1b → B1c   (sequential: define → prove → docstring)
  B2 (independent)
  B3 (independent; required by E8)

Workstream C intra:
  C1 → C2a            (verify_inj field unblocks the false-branch lemma)
  C1 → C2b → C2c      (key-uniqueness needs the field; assembly needs both)
  C2c → C3            (headline listing follows landing the theorem)
  C1 → C4             (witness MAC needs the field)

Workstream D intra:
  D1a → D1b           (helper unlocks _symm)
  D1a → D2b           (helper also unlocks inv_mem')
  D1c (independent)
  D2a + D2b           (must commit together — structure-field sorry rule)
  D2a/b → D2c         (carrier identity follows the structure)
  D1+D2 → D3          (set identity needs both)
  D1 → D4             (Setoid instance needs symm/trans)

Workstream E intra (the critical path):
  E1a → E1b → E1c → E1d                   (KEM probabilistic)
  E2a, E2b, E2c                           (independent leaves)
  E3-prep → {E3a, E3b, E3c} → E3d         (encoding interface gates the three)
  E2c → E3c                               (GIOIA used by GIOIAImpliesOIA)
  E3a–d → E4a → E4b                        (chain assembly)
  E4a → E4c                               (tight constructor, parallel to E4b)
  E4 → E5                                 (final theorem)
  E1 → E6a → E6b → E6c                    (combiner, after E1's PMF infra)
  E7a → E7b → E7c                         (product PMF foundations)
  E7 + B3 → E8a → E8b → E8c → E8d         (multi-query)
  All E* → E9                             (transparency report final)

Workstream F intra:
  F1a → F1b → F1c → F1d
  F3a → {F3b, F3c} → F3d
  F4a → {F4b, F4c} → F4d
  F5a (Tier 1, standalone) → F5b → F5c
  F6a, F6b, F6c (independent leaves)
  F3, F4 (when complete) supply concrete witnesses for E4's Prop fields
```

The longest sequential chain (the *critical path*) is in Workstream E:
**E7a → E7b → E7c → E8a → E8b → E8c** (≈ 12 h end to end, gated by
B3). Workstream E sub-tracks E1 (KEM), E2 (OIA family), and E7 (PMF)
can run in parallel.

### 3.1 Workstream summary

After complex-WU decomposition (see §4–§10 for sub-units), the inventory is:

| WS | Title | Parent WUs | Atomic sub-WUs | Findings covered | Horizon | Total effort |
|----|-------|------------|----------------|------------------|---------|--------------|
| A | Immediate CI & Style Fixes | 8 | 8 | F-03, F-04, F-12, F-13, F-16, F-18, F-19, F-22 | Hours | ~5 h |
| B | Adversary & Family Type Refinements | 3 | 5 (B1×3 + B2 + B3) | F-02, F-15 | Hours–days | ~7 h |
| C | MAC Integrity & INT_CTXT | 4 | 6 (C1 + C2×3 + C3 + C4) | F-07 | Days | ~10 h |
| D | Code Equivalence API | 4 | 8 (D1×3 + D2×3 + D3 + D4) | F-08, F-16 (extension) | Days | ~12 h |
| E | Probabilistic Refinement Chain | 9 | 27 (decomposed; see below) | F-01, F-10, F-11, F-17, F-20 | Weeks | ~62 h |
| F | Implementation Gaps (research) | 6 | 19 (decomposed; see below) | F-05, F-06, F-09, F-14, F-21 | Months | ~165 h |
| G | Documentation & Transparency | 4 | 4 | cross-cutting, all | Continuous | ~8 h |
| — | **Total** | **38** | **77 atomic** | **22** | — | **~269 h** |

#### Workstream E sub-WU count breakdown

| Parent | Sub-WUs | Total |
|--------|---------|-------|
| E1 (ConcreteKEMOIA) | E1a, E1b, E1c, E1d | 4 |
| E2 (Concrete{Tensor,CE,GI}OIA) | E2a, E2b, E2c | 3 |
| E3 (probabilistic reductions) | E3-prep, E3a, E3b, E3c, E3d | 5 |
| E4 (ConcreteHardnessChain) | E4a, E4b, E4c | 3 |
| E5 (chain → IND-1-CPA) | (atomic) | 1 |
| E6 (probabilistic combiner) | E6a, E6b, E6c | 3 |
| E7 (product PMF) | E7a, E7b, E7c | 3 |
| E8 (multi-query) | E8a, E8b, E8c, E8d | 4 |
| E9 (axiom transparency) | (atomic) | 1 |
| Total | | **27** |

(`E3-prep` is included in the E3 row above as the first of its five
sub-WUs.)

#### Workstream F sub-WU count breakdown

| Parent | Sub-WUs | Total |
|--------|---------|-------|
| F1 (HGOEKeyExpansion bridge) | F1a, F1b, F1c, F1d | 4 |
| F2 (SampleGroupSpec) | (atomic) | 1 |
| F3 (GI ≤_p CE) | F3a, F3b, F3c, F3d | 4 |
| F4 (GI ≤ TI) | F4a, F4b, F4c, F4d | 4 |
| F5 (CommGroupAction) | F5a, F5b, F5c | 3 |
| F6 (separating invariants) | F6a, F6b, F6c | 3 |
| Total | | **19** |

**Why decompose:** every sub-WU is independently buildable, independently
reviewable, and independently revertible. The largest (F3c, F4c, F1b)
are still ~12–16 h each — research-grade — but are no longer
single 30–40 h monoliths.

### 3.2 Sequencing principles

1. **Land Workstream A first.** It dispatches seven tiny fixes with near-zero
   risk, improves CI health, and removes noise from diffs when Workstream E
   begins.
2. **Workstreams B, C, D, G can run in parallel** with Workstream A, since
   they touch disjoint modules.
3. **Workstream E is gated by `lake build` green on the current tree.** It
   touches the most files and is most sensitive to the deterministic-OIA
   → probabilistic-OIA shift. It should begin only once Workstreams A–D
   land, to avoid rebase noise on the same files.
4. **Workstream F is research-grade** and must not block any other
   workstream. F3 / F4 (concrete reductions) land *as improvements* on
   Workstream E's `ConcreteHardnessChain`, not as prerequisites.
5. **Workstream G (docs)** closes out each other workstream: a workstream
   is not "done" until `CLAUDE.md`, `docs/DEVELOPMENT.md`, and the root
   `Orbcrypt.lean` axiom transparency report reflect the new state.

### 3.3 Per-unit acceptance gate (applies to every WU)

A WU is complete iff:

1. **Module builds:** `source ~/.elan/env && lake build <Module.Path>` exits 0
   for every module the WU edits (per `CLAUDE.md` — the default `lake build`
   is insufficient; per-module builds are mandatory).
2. **No `sorry`, no custom axiom:** `grep -rn "^axiom\s\|sorry" Orbcrypt/`
   stays empty in the touched files.
3. **Docstring preserved:** every public `def` / `theorem` / `structure` /
   `instance` the WU adds or touches retains a `/-- ... -/` docstring.
4. **Axiom report updated** (Orbcrypt.lean) if the WU changes or adds a
   headline theorem.
5. **Documentation updated** (CLAUDE.md + relevant phase doc) per the
   ownership rules in `CLAUDE.md § Documentation rules`.
6. **Commit message** carries the WU id (e.g. `A1: harden sorry CI regex
   (F-03)`) and references the audit id.

---

## 4. Workstream A — Immediate CI & Style Fixes

**Status:** **LANDED** (2026-04-18, branch `claude/workstream-a-fixes-6XlEP`).
All eight atomic sub-units A1–A8 shipped in a single cluster of edits with
zero `sorry`, zero new axioms, and zero regressions. See the
"Workstream A" section of `CLAUDE.md` for the per-finding landing
summary; see the per-sub-unit notes below for the as-landed resolution.

**Goal:** dispatch the seven lowest-risk findings in a single afternoon.
Every WU here is independent and can be landed in its own commit.

### A1 — Harden the CI `sorry` regex (F-03) · XS · 10 min · **LANDED**

**Files:** `.github/workflows/lean4-build.yml`

**Problem:** L34 uses `grep -rn "sorry"`. Any `.lean` docstring containing
the word "sorry" (e.g. a proof-strategy comment) would turn CI red. Today
no such prose exists, but the regex is fragile.

**Approach:** switch to the same disciplined pattern already used for the
axiom check at L44:

```yaml
- name: Verify no sorry
  run: |
    # Match only the tactic `sorry` (word boundary) in proof bodies,
    # not docstrings. Use Perl regex + -w for word-boundary.
    if grep -Prn "(^|[^A-Za-z_])sorry([^A-Za-z_]|$)" \
        Orbcrypt/ --include="*.lean" \
        | grep -v '^\s*--' | grep -v '/-.*sorry.*-/'; then
      echo "ERROR: sorry found in source files"
      exit 1
    fi
```

**Acceptance:** CI stays green on HEAD; add a red-team test locally by
temporarily inserting `-- this comment mentions sorry` and confirming it is
*not* flagged, then `sorry` in a proof *is* flagged.

**Risk:** regex typos turn CI red. Mitigate by running the exact regex
locally against HEAD before pushing.

### A2 — Fix `push Not at h` (F-04) · XS · 5 min · **LANDED** (wontfix — recommendation reversed by upstream deprecation)

**As-landed note:** The audit's recommendation was based on an older
Mathlib API where `push_neg` was the preferred spelling. The pinned
Mathlib (commit `fa6418a8`, `Mathlib/Tactic/Push.lean:276–282`) has since
**deprecated `push_neg`** in favour of `push Not`: the legacy elaborator
emits a `logWarning` when invoked. Applying the audit's original fix
would therefore turn `lake build Orbcrypt.Construction.Permutation`
warning-dirty, which violates the workstream's zero-warning gate
(§ 3.3 per-unit acceptance criterion 2 generalised to warnings).

**Disposition:** the `push Not at h` spelling on line 92 is preserved.
The finding is logged as a historical observation, and
`CLAUDE.md`'s Workstream A summary records the reversal so future
auditors do not regress. If Mathlib ever re-introduces `push_neg` as
the canonical form, this line should be re-checked.

**Verification:** `lake build Orbcrypt.Construction.Permutation` exits 0
with zero warnings.

**Files:** `Orbcrypt/Construction/Permutation.lean:92`

**Problem:** non-idiomatic tactic spelling. `push_neg at h` is the standard
Mathlib form used everywhere else.

**Approach:**
```
-    push Not at h
+    push_neg at h
```

**Acceptance:**
- `lake build Orbcrypt.Construction.Permutation` exits 0.
- `lake build Orbcrypt.Construction.HGOE` also exits 0 (downstream check).
- `perm_action_faithful` still has `#print axioms` = propext only.

**Risk:** none — `push_neg` is stable Mathlib surface.

### A3 — Remove shadowed `have hn_pos` (F-18) · XS · 10 min · **LANDED**

**Files:** `Orbcrypt/Probability/Negligible.lean:90,101`

**Problem:** the outer `hn_pos` at L90 is only used inside the `C = 0`
branch; the `C ≠ 0` branch redefines it at L101. Rename one for clarity.

**Approach:** rename outer binding to `hn_pos_from_one` and keep the
inner-branch `hn_pos` (which is arithmetically tighter). Alternatively,
restructure with a single `hn_pos` before the `by_cases` — but the tighter
lower bound from `hn_ge_C` is only available in one branch, so rename is
the simpler fix.

**Acceptance:**
- `lake build Orbcrypt.Probability.Negligible` exits 0.
- Each branch uses its own locally-scoped `hn_pos*` without ambiguity.

**Risk:** none.

### A4 — Pin elan SHA-256 in CI workflow (F-22) · S · 30 min · **LANDED**

**Files:** `.github/workflows/lean4-build.yml`

**Problem:** CI fetches `elan-init.sh` from `raw.githubusercontent.com/leanprover/elan/master`
without integrity verification. The corresponding `scripts/setup_lean_env.sh`
*does* verify a SHA-256 — CI must match.

**Approach:**
1. Read the SHA-256 constant from `scripts/setup_lean_env.sh` (the canonical
   source).
2. In the workflow, download to `/tmp/elan-init.sh`, run `sha256sum -c`, then
   `bash /tmp/elan-init.sh -y --default-toolchain none`.
3. If `scripts/setup_lean_env.sh` encodes the SHA as a shell variable, the
   workflow can simply invoke the script itself rather than re-encoding the
   constant — preferred (DRY).

**Acceptance:**
- CI still installs elan successfully.
- `sha256sum --check` runs and exits 0 on the expected blob.
- If the upstream blob ever rotates, CI fails fast with a clear error
  rather than silently running new code.

**Risk:** upstream churn. Mitigate by leaving a comment linking to the
upstream release where the SHA was captured.

### A5 — Retire or strengthen `kem_agreement_correctness` (F-19) · S · 45 min · **LANDED** (strengthen)

**Files:** `Orbcrypt/PublicKey/KEMAgreement.lean`

**Problem:** after the two `rw [kem_correctness ...]` rewrites, both sides
reduce to `combiner k_A k_B` — the theorem is a literal tautology. Its
intended content ("both parties agree") is already *precisely* captured by
`kem_agreement_alice_view` and `kem_agreement_bob_view`.

**Approach (preferred — strengthen):**
Replace the theorem statement with a direct identity that ties both views
to `sessionKey`:

```lean
theorem kem_agreement_correctness
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K)
    (a : G_A) (b : G_B) :
    agr.combiner (decaps agr.kem_A (encaps agr.kem_A a).1)
                 (encaps agr.kem_B b).2 =
      agr.sessionKey a b ∧
    agr.combiner (encaps agr.kem_A a).2
                 (decaps agr.kem_B (encaps agr.kem_B b).1) =
      agr.sessionKey a b :=
  ⟨kem_agreement_bob_view agr a b, kem_agreement_alice_view agr a b⟩
```

This keeps the name `kem_agreement_correctness` (referenced in
`CLAUDE.md` headline theorem #16) while giving it genuine content: both
views reduce to `sessionKey a b`, not to each other.

**Approach (alternative — retire):** delete the theorem and update
`CLAUDE.md` theorem #16 to point at `kem_agreement_alice_view` /
`kem_agreement_bob_view`. Simpler but forces a doc churn.

**Recommendation:** strengthen. Preserves the headline-theorem surface
documented in `CLAUDE.md` and elevates a tautology to a real bi-view
identity.

**Acceptance:**
- `lake build Orbcrypt.PublicKey.KEMAgreement` exits 0.
- `CLAUDE.md` theorem #16 cell unchanged; docstring updated to note the
  conjunction.
- `Orbcrypt.lean` axiom transparency entry for `kem_agreement_correctness`
  updated if axiom dependency changes (it should not — `And.intro` adds
  nothing).

**Risk:** a downstream consumer might pattern-match on the old form. No
such consumer exists in the tree (grep-verified).

### A6 — Rename / strengthen `paut_coset_is_equivalence_set` (F-16) · S · 1 h · **LANDED** (rename; set-identity strengthening deferred to D3)

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean:220–227`

**Problem:** the name promises a set identity
`{ρ | ∀ c ∈ C₁, ρ(c) ∈ C₂} = σ · PAut(C₁)` but the body proves only
`ArePermEquivalent C₁ C₂` — a much weaker claim.

**Approach (phase 1 — rename, XS):** rename to
`paut_compose_yields_equivalence` (matches what it actually proves). Keep
the existing proof. Update the docstring to drop the set-identity claim.

**Approach (phase 2 — prove the identity, S):** add a new theorem:

```lean
theorem paut_equivalence_set_eq_coset
    [Fintype (Equiv.Perm (Fin n))] [DecidableEq (Fin n → F)]
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂) :
    { ρ : Equiv.Perm (Fin n) | ∀ c ∈ C₁, permuteCodeword ρ c ∈ C₂ }
      = (fun τ => σ * τ) '' PAut C₁ := by
  ext ρ
  constructor
  · intro hρ
    refine ⟨σ⁻¹ * ρ, ?_, ?_⟩
    · -- show σ⁻¹ * ρ ∈ PAut C₁
      sorry  -- actual content: compose hρ with σ⁻¹ acting
    · simp [mul_assoc, mul_inv_cancel_left]
  · rintro ⟨τ, hτ, rfl⟩
    exact paut_compose_preserves_equivalence _ _ _ hσ _ hτ
```

The `sorry` above is a placeholder: the actual proof requires showing that
`σ⁻¹ ∘ ρ` maps `C₁ → C₁`, which is straightforward from `hρ` mapping
`C₁ → C₂` and `hσ⁻¹` mapping `C₂ → C₁`. **Must land with zero sorry**.

**Recommendation:** land phase 1 immediately (A6a), add phase 2 as a
follow-up WU A6b if audit reviewers want the full set identity.

**Acceptance (A6a):**
- `lake build Orbcrypt.Hardness.CodeEquivalence` exits 0.
- Renamed theorem has an accurate docstring.
- `Orbcrypt.lean` root-file references updated.

**Acceptance (A6b, optional):**
- New theorem `paut_equivalence_set_eq_coset` landed with full proof.
- No `sorry` in the file.
- A one-line usage example in the docstring.

**Risk (A6a):** name change may break external cites. No external consumer
exists in this repo.
**Risk (A6b):** the `σ⁻¹` direction requires `Finset`-preserving
permutation action (`σ⁻¹ ∘ σ = id` lifted to the code). Mathlib's
`Equiv.Perm` supplies this; low risk.

### A7 — Extract helper `def`s in Comp* modules (F-13) · S · 1 h · **LANDED**

**Files:** `Orbcrypt/Crypto/CompOIA.lean`, `Orbcrypt/Crypto/CompSecurity.lean`

**Problem:** `CompOIA` and `CompIsSecure` embed ~10-token `@`-qualified
expressions inline (`@advantage`, `@orbitDist`, `@OrbitEncScheme.reps`,
each with 6+ explicit arguments). Hard to read, fragile under Mathlib
renames.

**Approach:** add two small helper definitions in `Crypto/CompOIA.lean`:

```lean
/-- Per-level orbit distribution under a scheme family. -/
noncomputable def SchemeFamily.orbitDistAt (sf : SchemeFamily) (n : ℕ)
    (m : sf.M n) : PMF (sf.X n) :=
  @orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
    (sf.instNonempty n) (sf.instAction n)
    (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
      (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m)

/-- Per-level advantage under a scheme family. -/
noncomputable def SchemeFamily.advantageAt (sf : SchemeFamily)
    (D : ∀ n, sf.X n → Bool) (m₀ m₁ : ∀ n, sf.M n) (n : ℕ) : ℝ :=
  @advantage (sf.X n) (D n)
    (sf.orbitDistAt n (m₀ n)) (sf.orbitDistAt n (m₁ n))
```

Then `CompOIA` simplifies to:

```lean
def CompOIA (sf : SchemeFamily) : Prop :=
  ∀ (D : ∀ n, sf.X n → Bool) (m₀ m₁ : ∀ n, sf.M n),
    IsNegligible (sf.advantageAt D m₀ m₁)
```

**Acceptance:**
- `lake build Orbcrypt.Crypto.CompOIA` and `Orbcrypt.Crypto.CompSecurity` exit 0.
- `det_oia_implies_concrete_zero`, `concrete_oia_implies_1cpa`,
  `comp_oia_implies_1cpa` all still compile with no proof body changes
  beyond trivial `show`/`simp only [SchemeFamily.orbitDistAt]` adjustments.
- `#print axioms comp_oia_implies_1cpa` unchanged (standard Lean only).

**Risk:** if the helpers trigger universe inference issues, fall back to
keeping the inline expressions but wrap them in a single `let` in each
definition to halve the repetition. The `@`-qualification itself is fine
for Lean — the concern is readability, not correctness.

### A8 — Delete or consume `GIReducesTo*` (F-12) · XS · 20 min · **LANDED** (document; deletion deferred — E4 will consume)

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean:153–158`,
`Orbcrypt/Hardness/TensorAction.lean:297–302`

**Problem:** both `Prop`-level definitions are declared but no theorem in
the codebase ever takes them as a hypothesis. They look like
axiomatisations-in-waiting. Either they should be consumed (by existing
or new theorems) or deleted.

**Approach:** defer the delete decision to Workstream E (where E4 *will*
consume them as inputs to `ConcreteHardnessChain`). For the immediate
cleanup: add a one-line comment to each definition pointing at the
consumer's eventual location, and add each name to the axiom-transparency
report in `Orbcrypt.lean` under a new "Hardness parameter Props" section
noting that these are *reduction claims*, not proofs.

**Acceptance:**
- No code change to the two definitions (preserved for Workstream E).
- `Orbcrypt.lean` gains a § noting hardness-parameter Props and pointing
  at `docs/HARDNESS_ANALYSIS.md` for literature context.

**Risk:** none — purely additive documentation.

---

## 5. Workstream B — Adversary & Family Type Refinements

**Status:** **LANDED** (2026-04-19, branch
`claude/review-workstream-plan-Hxljy`). All five atomic sub-units
(B1a–B1c, B2, B3) shipped with zero `sorry`, zero new axioms, zero
warnings, and no regressions on any downstream module. See the
"Workstream B" section of `CLAUDE.md` for the per-finding landing
summary; see the per-sub-unit notes below for the as-landed resolution.

**Goal:** tighten the adversary and scheme-family definitions in
`Crypto/Security.lean` and `Crypto/CompOIA.lean` so downstream probabilistic
theorems (Workstream E) can consume them cleanly.

### B1 — Introduce `IsSecureDistinct` predicate (F-02) · M · 3 h · **LANDED**

**Parent goal:** surface the `Adversary.choose` asymmetry (unconstrained,
may return `(m, m)`) by adding a distinct-challenge variant that matches
the classical IND-1-CPA game.

**As-landed summary:** B1a–B1c were all shipped as a single coherent
edit to `Orbcrypt/Crypto/Security.lean`. The distinctness conjunct uses
the component-access form
`(A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2` (rather than the
plan's `let`-sketch) so that `hasAdvantageDistinct.2` is definitionally
equal to a `hasAdvantage` witness — this lets
`isSecure_implies_isSecureDistinct` discharge the implication with
`exact hSec A hAdv.2` (no existential re-packing needed). Both the
module docstring and the `IsSecure` docstring gained a "Game asymmetry
(audit F-02)" note.

**Comprehensive-audit addition:** an explicit `Iff.rfl`-trivial
decomposition lemma `hasAdvantageDistinct_iff` was added so downstream
proofs can rewrite `hasAdvantageDistinct ↔ distinct ∧ hasAdvantage`
without reaching for definitional unfolding. Both this lemma and
`isSecure_implies_isSecureDistinct` are *strictly axiom-free* (verified
by `#print axioms` returning "does not depend on any axioms"); they
appear under that label in `Orbcrypt.lean`'s axiom transparency
report.

**Decomposition** into three sub-units:

#### B1a — Define `hasAdvantageDistinct` and `IsSecureDistinct` · XS · 45 min · **LANDED**

**File:** `Orbcrypt/Crypto/Security.lean`

**Approach:**
```lean
def hasAdvantageDistinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  let (m₀, m₁) := A.choose scheme.reps
  m₀ ≠ m₁ ∧ ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps m₀) ≠
    A.guess scheme.reps (g₁ • scheme.reps m₁)

def IsSecureDistinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ A, ¬ hasAdvantageDistinct scheme A
```

**Acceptance:**
- `lake build Orbcrypt.Crypto.Security` exits 0.
- Both definitions carry `/-- ... -/` docstrings citing IND-1-CPA literature.
- No existing theorem is modified.

#### B1b — Prove `IsSecure → IsSecureDistinct` · XS · 30 min · **LANDED**

**File:** same module (adjacent).

**Approach:** one-liner — the weaker distinct-challenge game is implied
by the stronger uniform game.
```lean
theorem isSecure_implies_isSecureDistinct [...] (scheme : ...) :
    IsSecure scheme → IsSecureDistinct scheme := by
  intro hSec A hAdv
  exact hSec A ⟨_, _, hAdv.2.choose_spec.choose_spec⟩
```

**Acceptance:**
- Theorem compiles.
- `#print axioms isSecure_implies_isSecureDistinct` = standard Lean only.

#### B1c — Update `IsSecure` docstring noting the asymmetry · XS · 30 min · **LANDED**

**Files:** `Orbcrypt/Crypto/Security.lean`, `docs/DEVELOPMENT.md` (Security §).

**Approach:** add a paragraph to `IsSecure`'s docstring:
> *Note on game asymmetry (F-02):* `Adversary.choose` is unconstrained,
> so `IsSecure` is strictly stronger than the classical IND-1-CPA game.
> `IsSecureDistinct` (in this file) matches the classical game.
> `isSecure_implies_isSecureDistinct` proves the weaker form follows from
> the stronger.

**Acceptance:**
- Module still builds.
- docs/DEVELOPMENT.md references the three definitions.

**Dependency:** none; B1a → B1b → B1c is strictly sequential.

### B2 — Explicit universes on `SchemeFamily` (F-15) · S · 1 h · **LANDED**

**As-landed summary:** added a module-level `universe u v w` declaration
at the top of `Orbcrypt/Crypto/CompOIA.lean` and changed the three type
fields from `ℕ → Type*` to `ℕ → Type u|v|w`. Lean 4's auto-bind promotes
these declared universes to explicit parameters of the `SchemeFamily`
structure (call sites can write `@SchemeFamily.{u, v, w} ...`).
Downstream helpers (`repsAt`, `orbitDistAt`, `advantageAt`, `CompOIA`,
`CompIsSecure`, `comp_oia_implies_1cpa`) and the `scripts/audit_a7_defeq.lean`
`rfl` checks required no signature changes — Lean inherits the universes
from the `sf : SchemeFamily` binder. No temporary
`examples/SchemeFamilyUniverseCheck.lean` was committed; the universe
parameters are already exercised by the existing audit script and the
downstream definitions that consume `sf : SchemeFamily`.

**Files:** `Orbcrypt/Crypto/CompOIA.lean:44–49, 128–150`

**Problem:** `SchemeFamily` uses `G, X, M : ℕ → Type*` with implicit
universe polymorphism. `@`-qualified call sites do currently work, but any
downstream code that tries to instantiate in a specific universe meets
inference pain.

**Approach (as applied):**
1. Add an explicit universe declaration at module scope:
   ```lean
   universe u v w
   ```
2. Change `SchemeFamily`'s field types to
   `G : ℕ → Type u`, `X : ℕ → Type v`, `M : ℕ → Type w`.
3. Lean auto-binds the declared universes as structure parameters —
   `structure SchemeFamily.{u, v, w} where ...` is the effective
   signature. No further plumbing is needed at downstream consumer
   sites because they only touch `sf.X n`, `sf.G n`, `sf.M n` which
   inherit the universes through the `sf : SchemeFamily` binder.

**Acceptance (all met):**
- `lake build Orbcrypt.Crypto.CompOIA` exits 0.
- `lake build Orbcrypt.Crypto.CompSecurity` exits 0.
- `scripts/audit_a7_defeq.lean` continues to elaborate (the `rfl`
  definitional-equality checks for `repsAt` / `orbitDistAt` /
  `advantageAt` still pass, confirming no definitional drift).
- No new files added to the repo.

**Risk (mitigated):** universe polymorphism regressions are
Mathlib-sensitive. Mitigation: no external Mathlib-facing signature
changed; the universes live entirely on the internal `SchemeFamily`
structure.

### B3 — Add a per-query choose structure for multi-query groundwork (prereq for E8) · M · 4 h · **LANDED**

**As-landed summary:** implemented as a single extension to
`Orbcrypt/Crypto/CompSecurity.lean` (no new file needed). Chose the
wrapper option: `DistinctMultiQueryAdversary extends MultiQueryAdversary`
with a `choose_distinct : ∀ reps i, (choose reps i).1 ≠ (choose reps i).2`
field, leaving the base `MultiQueryAdversary` unchanged so existing
consumers and the `single_query_bound` theorem are untouched.
`perQueryAdvantage` takes an explicit single-query Boolean distinguisher
`D : X → Bool` and the query index `i : Fin Q`, returning the advantage
between the two orbit distributions at query `i`. Four new public
declarations:
`DistinctMultiQueryAdversary`, `perQueryAdvantage`,
`perQueryAdvantage_nonneg`, `perQueryAdvantage_le_one`, plus a bonus
`perQueryAdvantage_bound_of_concreteOIA` that specialises
`single_query_bound` to the multi-query setting — all with docstrings
and each proof a one-liner.

**Files:** `Orbcrypt/Crypto/CompSecurity.lean` (lines added in the
"Workstream B3" section)

**Problem:** the current `MultiQueryAdversary` structure
(`CompSecurity.lean:195`) has a `choose : (M → X) → Fin Q → M × M` field,
but there is no `IsDistinct` obligation and no notion of per-query advantage.
Workstream E8 needs both.

**Approach (as applied):**
1. Added `DistinctMultiQueryAdversary` as a separate wrapper extending
   `MultiQueryAdversary`, carrying the per-query distinctness obligation
   `∀ reps i, (choose reps i).1 ≠ (choose reps i).2`.
2. Added `perQueryAdvantage scheme A D i`: the distinguishing advantage
   of `D : X → Bool` between the two orbit distributions at query `i`,
   treating each query as an independent single-query game.
3. Proved `perQueryAdvantage_nonneg` and `perQueryAdvantage_le_one` as
   one-liners from `advantage_nonneg` / `advantage_le_one`.
4. Proved the bonus `perQueryAdvantage_bound_of_concreteOIA` specialising
   the single-query `ConcreteOIA` bound to each query of a multi-query
   adversary — the atom that Workstream E8's hybrid argument will chain
   Q times.

**Acceptance (all met):**
- `lake build Orbcrypt.Crypto.CompSecurity` exits 0.
- All four new declarations carry docstrings citing the audit finding.
- No new axioms introduced; the per-query lemmas inherit `propext` +
  `Classical.choice` from `advantage`'s existing axiom dependencies.

**Risk (mitigated):** the `extends` syntax for
`DistinctMultiQueryAdversary` keeps the base structure untouched, so
existing consumers of `MultiQueryAdversary` see no change.

---

## 6. Workstream C — MAC Integrity & INT_CTXT (F-07)

**Status (2026-04-19): COMPLETE.** All four work units (C1, C2a/b/c, C3,
C4) have landed. Headline deliverables:

- `Orbcrypt/AEAD/MAC.lean` — `MAC` gains a `verify_inj` field (C1).
- `Orbcrypt/AEAD/AEAD.lean` — `authDecaps_none_of_verify_false` (C2a,
  private), `keyDerive_canon_eq_of_mem_orbit` (C2b, private),
  `authEncrypt_is_int_ctxt` (C2c, main theorem).
- `Orbcrypt/AEAD/CarterWegmanMAC.lean` — `deterministicTagMAC`,
  `carterWegmanHash`, `carterWegmanMAC`, `carterWegman_authKEM`,
  `carterWegmanMAC_int_ctxt` (C4). Concrete witness showing `verify_inj`
  is satisfiable.
- `Orbcrypt.lean`, `CLAUDE.md`, `docs/DEVELOPMENT.md` — new headline theorems
  (#19, #20), axiom-transparency report entries, §8.5 AEAD + INT-CTXT
  section (C3).

**As-landed implementation notes.**

- **C2b — chose hypothesis-threaded form (Option B).** The plan preferred
  Option A (add a proven field to `AuthOrbitKEM`), but in the landed
  implementation C2b is a *private lemma* (`keyDerive_canon_eq_of_mem_orbit`)
  rather than a structure field. Rationale: keeping `AuthOrbitKEM` free
  of derived data makes the structure easier to re-use and leaves the
  decision of *when* to invoke the lemma in the theorem writer's hands.
  The lemma itself is unconditional and discharges via
  `canon_eq_of_mem_orbit` (which in turn uses `canonical_isGInvariant`),
  matching Option A's proven-not-assumed character.
- **C2c — orbit-cover carried as explicit hypothesis.** Per the risk
  note, ciphertext space `X` may be larger than `orbit G basePoint` for
  general `AuthOrbitKEM` instances (e.g. `X = Bitstring n` with a strict
  subgroup of `S_n`). Adding `basepoint_orbit_univ` as a structural field
  would break realistic instances, so the theorem carries
  `hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint` as
  an explicit hypothesis. Concrete witnesses discharge it when their
  action is transitive (regular action on `G`, quotient actions, etc.).
- **C4 — generalised via `deterministicTagMAC` template.** The plan
  proposed a single Carter–Wegman instance. The landed file factors the
  boilerplate into a `deterministicTagMAC` combinator: any MAC whose
  verification is definitionally `decide (t = f k m)` inherits `correct`
  (by `decide` reflexivity) and `verify_inj` (by `of_decide_eq_true`).
  `carterWegmanMAC` is then a one-line instance over `ZMod p × ZMod p`.
  This makes future witnesses (different hash families, HMAC-style once
  probabilistic refinement lands) cheaper to add.

**Goal (original spec):** discharge F-07 — INT_CTXT is currently defined
but unprovable from the existing `MAC` abstraction. Add the missing
uniqueness requirement and prove INT_CTXT for an honestly-composed
AuthOrbitKEM.

### C1 — Augment the `MAC` structure with `verify_inj` (F-07 step 1) · S · 2 h

**Files:** `Orbcrypt/AEAD/MAC.lean`

**Problem:** `MAC` has only `correct : verify k m (tag k m) = true`. This
allows MACs that accept many tags for the same message (information-theoretically
wrong). INT_CTXT cannot be proved against this abstraction.

**Approach:** add a uniqueness field gated behind an optional flag so
existing consumers don't break:

```lean
structure MAC (K : Type*) (Msg : Type*) (Tag : Type*) where
  tag : K → Msg → Tag
  verify : K → Msg → Tag → Bool
  correct : ∀ k m, verify k m (tag k m) = true
  /-- Tag uniqueness: only the honestly-computed tag verifies.
      This is the algebraic analogue of strong unforgeability (SUF-CMA).
      A MAC without this property cannot discharge INT_CTXT. -/
  verify_inj : ∀ k m t, verify k m t = true → t = tag k m
```

Note: adding a field to a Lean `structure` is a *breaking change* for
positional constructors. Every existing `MAC` instance in the codebase
(audit scan: none in `Orbcrypt/`, only a DEM stub in `AEAD/Modes.lean`
which uses a different structure) must be updated — verify via
`grep -n "MAC\.mk\|MAC {" Orbcrypt/ --include="*.lean"` before proceeding.

**Acceptance:**
- `lake build Orbcrypt.AEAD.MAC` exits 0.
- `lake build Orbcrypt.AEAD.AEAD` exits 0 (downstream check).
- `lake build Orbcrypt.AEAD.Modes` exits 0.
- New field has a docstring explaining the SUF-CMA-like semantics.
- `docs/DEVELOPMENT.md` (AEAD section) references `verify_inj` as a MAC
  assumption.

**Risk:** downstream `authEncaps` / `authDecaps` should not change; they
only use `correct`. Spot-check required. If any construction MAC instances
exist outside `Orbcrypt/`, they must be extended too (audit scan shows
none).

### C2 — Prove `INT_CTXT` from `verify_inj` (F-07 step 2) · M · 3 h

**Parent goal:** give `INT_CTXT` its first proof. The argument has two
branches (`verify` succeeds vs. fails) and a subtle key-uniqueness
requirement on the KEM side. Decompose into three sub-units so each
branch is built and tested independently.

#### C2a — Prove the `verify k c t = false` branch · S · 45 min

**File:** `Orbcrypt/AEAD/AEAD.lean`

**Approach:** extract the easy branch as its own lemma.
```lean
private lemma authDecaps_none_of_verify_false
    (akem : AuthOrbitKEM G X K Tag) (c : X) (t : Tag)
    (hVerify : akem.mac.verify (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t = false) :
    authDecaps akem c t = none := by
  simp [authDecaps, hVerify]
```

**Acceptance:** lemma compiles; unfold-only proof; no new hypothesis.

#### C2b — Identify + prove the key-uniqueness hypothesis · M · 1 h 15 min

**File:** same module; extend `AuthOrbitKEM` or thread as a hypothesis.

**Approach:** the `verify k c t = true` branch needs that the key `k`
computed via `keyDerive (canon c)` matches the MAC key that would have
signed `c`. Choose ONE of:

- **Option A (preferred):** add an `AuthOrbitKEM.key_unique` field
  stating `∀ c, keyDerive (canon c)` depends only on the orbit of `c`.
  This holds unconditionally by `canonical_isGInvariant` — so the field
  is provable, not assumed. Add as a *proven* field, not a parameter.
- **Option B:** thread `key_unique` as an explicit hypothesis to
  `authEncrypt_is_int_ctxt`. Cleaner on the structure but forces every
  caller to re-derive the obvious fact.

Pick Option A. Add a `have : akem.kem.keyDerive (akem.kem.canonForm.canon c) = ...`
rewriting lemma for use in C2c.

**Acceptance:**
- New field / lemma has a `/-- ... -/` docstring.
- It is discharged via `canonical_isGInvariant`, zero sorry.
- `lake build Orbcrypt.AEAD.AEAD` exits 0.

#### C2c — Assemble the main theorem · M · 1 h

**File:** same module.

**Approach:** stitch C2a and C2b.

```lean
theorem authEncrypt_is_int_ctxt (akem : AuthOrbitKEM G X K Tag) :
    INT_CTXT akem := by
  intro c t hFresh
  by_cases hVerify :
      akem.mac.verify (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t = true
  · -- true branch: derive a collision with hFresh via verify_inj + C2b
    exfalso
    have htag := akem.mac.verify_inj _ c t hVerify
    -- htag : t = tag k c, where k = keyDerive (canon c)
    -- Need to exhibit a g ∈ G with c = (authEncaps akem g).1 and
    -- t = (authEncaps akem g).2.2, contradicting hFresh g.
    sorry  -- filled using C2b's key_unique rewriting
  · -- false branch: use C2a
    exact authDecaps_none_of_verify_false akem c t
      (by simpa using hVerify)
```

**The `sorry` in the sketch is a planning artifact; the landed commit has zero sorry.**
The true-branch proof closes by choosing any `g : G` (existence of a
ciphertext generator is given by `Nonempty G`, which `AuthOrbitKEM`
already requires for KEM operation) and using C2b to pin down the tag.

**Acceptance:**
- `lake build Orbcrypt.AEAD.AEAD` exits 0.
- `#print axioms authEncrypt_is_int_ctxt` = standard Lean only.
- No new custom axiom.
- Depends on: C1 (verify_inj field), C2a, C2b.

**Risk:** the true-branch case depends on whether an honest generator `g`
exists for *every* `c` — i.e., whether every ciphertext in `X` is in
`orbit G basePoint`. The intended model says yes (the ciphertext space
equals a single orbit). If the formalization doesn't yet enforce this,
add `c_in_orbit : c ∈ orbit G akem.kem.basePoint` as a hypothesis or
add `basepoint_orbit_univ` as a field. Decide at implementation time.

### C3 — Wire `authEncrypt_is_int_ctxt` into the headline theorem list · XS · 20 min

**Files:** `CLAUDE.md`, `Orbcrypt.lean`

**Approach:** add `authEncrypt_is_int_ctxt` as theorem #19 in the
"Three core theorems" table (expanded). Add it to the axiom-transparency
report in `Orbcrypt.lean`. Cross-reference F-07 in the docstring.

**Acceptance:**
- `CLAUDE.md` table compiles and renders.
- `Orbcrypt.lean` axiom report lists the new theorem's axiom dependencies
  (should be `propext`, `Classical.choice`, `Quot.sound` via MAC unfolds).

**Risk:** none — documentation only.

### C4 — Sample concrete MAC instantiation (F-07 step 3) · M · 3 h

**Files:** new `Orbcrypt/AEAD/CarterWegmanMAC.lean` (or similar)

**Problem:** to demonstrate that `verify_inj` is satisfiable, provide at
least one concrete `MAC` witness.

**Approach:** build a trivial MAC over `ZMod p` (universal hash style) for
which `verify k m t = decide (t = tag k m)`. This has `verify_inj` by
construction (`verify k m t = true ↔ t = tag k m` → discharged by
`decide_eq_true`).

**Acceptance:**
- The new file builds.
- A theorem `carterWegmanMAC_is_MAC : MAC ZMod.p Msg ZMod.p` is exhibited
  with all four fields proved.
- A theorem `carterWegmanMAC_int_ctxt : INT_CTXT (buildAuthKEM kem carterWegmanMAC)`
  follows from C2.
- Docstring cites this as "simplest-possible witness; not production-grade".

**Risk:** the witness is information-theoretically weak, but that's
acceptable — this WU is about Lean-level satisfiability, not production
crypto.

---

## 7. Workstream D — Code Equivalence API Strengthening (F-08)

**Status (2026-04-20): COMPLETE.** All eight atomic work units (D1a, D1b,
D1c, D2a, D2b, D2c, D3, D4) have landed. Headline deliverables, all in
`Orbcrypt/Hardness/CodeEquivalence.lean`:

- **D1 helpers.** Two-sided inverse (`permuteCodeword_inv_apply`,
  `permuteCodeword_apply_inv`, both `@[simp]`) and global injectivity
  (`permuteCodeword_injective`) of the codeword-permutation action.
- **D1a.** `permuteCodeword_self_bij_of_self_preserving` —
  finite-bijection lemma: if a permutation maps `C` into itself, so does
  its inverse. Proof via `Function.Injective.bijective_of_finite` on the
  Fintype subtype `↥C`.
- **D1 helper (extracted from D1b for reuse in D3):**
  `permuteCodeword_inv_mem_of_card_eq` — cross-code inverse-mapping
  lemma, the equal-cardinality analogue of D1a.
- **D1b.** `arePermEquivalent_symm` — one-line consequence of the
  helper. Carries the `C₁.card = C₂.card` side condition.
- **D1c.** `arePermEquivalent_trans` — unconditional, by composition.
- **D2.** `paut_inv_closed` (free-standing inverse-closure corollary of
  D1a applied to `C` itself); `PAutSubgroup` (full
  `Subgroup (Equiv.Perm (Fin n))` instance composing
  `paut_contains_id` / `paut_mul_closed` / `paut_inv_closed`);
  `mem_PAutSubgroup` (`@[simp]` membership-coercion lemma).
- **D2c.** `PAut_eq_PAutSubgroup_carrier` — `rfl` bridge between the
  `Set`-valued and `Subgroup`-valued formulations.
- **D3.** `paut_equivalence_set_eq_coset` — full set identity
  `{ρ | ρ : C₁ → C₂} = σ · PAut C₁`. Forward inclusion uses the D1
  helper to inhabit the coset; reverse inclusion delegates to
  `paut_compose_preserves_equivalence`.
- **D4.** `arePermEquivalent_setoid` — `Setoid` instance on the
  card-indexed subtype `{C : Finset (Fin n → F) // C.card = k}`,
  bundling D1a/b/c into a Mathlib `Equivalence`.

Verification: `scripts/audit_d_workstream.lean` exercises every Workstream D
headline declaration with `#print axioms`, instantiates a concrete
singleton code over `Fin 1 → Bool`, and exhibits non-vacuous witnesses
for the `Setoid`, `Subgroup`, and coset identity. Running
`lake env lean scripts/audit_d_workstream.lean` should produce only
standard-Lean-axiom or "does not depend on any axioms" outputs — never
`sorryAx` or a custom axiom.

**As-landed implementation notes.**

- **D1b card hypothesis kept on signature.** The plan considered making
  the `C₁.card = C₂.card` hypothesis optional. The landed signature
  keeps it because (a) it is exactly what the cross-code helper
  (`permuteCodeword_inv_mem_of_card_eq`) needs internally and
  (b) it lets D4's `Setoid` instance factor through the
  card-indexed subtype without any further bookkeeping.
- **D1 helper extracted.** Rather than inlining the bijection argument
  twice, the landed implementation factors it into
  `permuteCodeword_inv_mem_of_card_eq`. D1b becomes a one-liner and
  D3's forward direction uses the same lemma — eliminating proof
  duplication.
- **D2 single commit.** The plan called for D2a + D2b to be committed
  *together* because a structure-field `sorry` in D2a alone would
  poison `lake build`. The landed implementation skips the intermediate
  D2a checkpoint entirely: `paut_inv_closed` is proved first, then
  `PAutSubgroup` is defined with all four fields fully discharged in a
  single declaration.
- **D3 forward direction simplified.** The plan sketched a path through
  `arePermEquivalent_symm` to recover σ⁻¹'s C₂ → C₁ action; the landed
  proof goes one step shorter by calling
  `permuteCodeword_inv_mem_of_card_eq` directly, sidestepping the
  symm/destructure dance.
- **Post-landing audit (2026-04-20).** A second-pass audit verified
  every proof independently (traced `permuteCodeword_mul`-based
  rewrites, verified `Fintype.bijective_iff_injective_and_card` flow,
  checked `Subgroup` field bindings against `Mathlib.Algebra.Group.Subgroup.Defs`,
  destructured the D3 coset proof manually). Two refinements landed:
  * **D4 parameter style (audit refinement).** `arePermEquivalent_setoid`
    originally declared `(n : ℕ) (F : Type*) (k : ℕ)` as *explicit*
    parameters, shadowing the file-level `variable {n} {F}` implicits.
    Explicit-on-instance is non-idiomatic: Mathlib convention uses
    implicit braces because typeclass synthesis unifies index
    parameters from the subtype in `Setoid Y` calls anyway.
    Switched to `{n} {F} {k}`; `inferInstance` at concrete
    `{C : Finset (Fin 3 → Bool) // C.card = 2}` resolves cleanly.
  * **Test coverage expansion.** The committed
    `scripts/audit_d_workstream.lean` gained five post-audit pressure
    tests (sections 6–10): a negative-cardinality test proving that
    D1b's `hcard` is mathematically necessary (a concrete
    `smallCode ⊊ bigCode` witness); `inferInstance` synthesis across
    three concrete subtypes; `mem_PAutSubgroup` bidirectional simp
    firing; `paut_inv_closed` idempotence via `inv_inv`; and a D3
    reverse-direction witness (σ ∈ σ · PAut C₁ via τ = 1).

The post-audit verification found *no* correctness regressions and
*no* shortcuts compromising security or formal soundness. Every
`#print axioms` output remains `[propext, Classical.choice, Quot.sound]`;
`lake build` succeeds end-to-end with 3362/3362 jobs green.

Patch version: `lakefile.lean` bumped from `0.1.2` to `0.1.3` for this
workstream.

**Goal (original spec):** turn `ArePermEquivalent` and `PAut` into
first-class Mathlib-style API with `symm`, `trans`, and `Subgroup`
structure. Eliminates the gap at F-08 and unblocks Workstream E's
probabilistic CE refinements.

### D1 — `ArePermEquivalent.symm` and `_trans` (F-08 step 1) · M · 4 h

**Parent goal:** prove symmetry and transitivity of `ArePermEquivalent`.
Symmetry requires a finite-bijection helper that is also reused by D2;
decompose so D1a lands first as a standalone lemma.

#### D1a — Helper: `permuteCodeword_self_bij_of_self_preserving` · M · 1 h 30 min

**File:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Purpose:** the shared inversion lemma used by both `_symm` and D2's
`inv_mem'`.

**Approach:**
```lean
lemma permuteCodeword_self_bij_of_self_preserving
    [DecidableEq (Fin n → F)]
    (C : Finset (Fin n → F)) (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C, permuteCodeword σ c ∈ C) :
    ∀ c ∈ C, permuteCodeword σ⁻¹ c ∈ C := by
  -- `permuteCodeword σ` is injective on the finite set C and maps C → C.
  -- Injective self-map of a finite set is a bijection, so σ⁻¹ also
  -- preserves C by the bijection's inverse.
  intro c hc
  have hInjOnC : Function.Injective (fun x : C => ⟨permuteCodeword σ x.1,
      hσ x.1 x.2⟩ : C → C) := by
    rintro ⟨x, hx⟩ ⟨y, hy⟩ heq
    simp [permuteCodeword] at heq
    -- Equal images under a permutation → equal preimages.
    ext i
    exact congr_fun heq i  -- abbreviated; may need funext massaging
  have hBij : Function.Bijective _ := hInjOnC.bijective_of_finite
  obtain ⟨⟨pre, hpre⟩, hmap⟩ := hBij.2 ⟨c, hc⟩
  -- pre is the σ-preimage of c inside C; therefore permuteCodeword σ⁻¹ c = pre ∈ C.
  sorry  -- final rewriting step; zero sorry in landed commit
```

**Acceptance:**
- Lemma compiles with zero sorry.
- Re-usable by D1b and D2b.
- Docstring explains the finite-bijection argument.

**Risk:** Mathlib's `Function.Injective.bijective_of_finite` exists but
has specific signature requirements. If the precise lemma is missing,
compose via `Finset.card_image_of_injOn` + `Finset.eq_of_subset_of_card_le`.

#### D1b — Prove `arePermEquivalent_symm` · S · 1 h

**File:** same module.

**Approach:** use D1a.
```lean
theorem arePermEquivalent_symm
    [DecidableEq (Fin n → F)]
    (C₁ C₂ : Finset (Fin n → F))
    (hcard : C₁.card = C₂.card) :
    ArePermEquivalent C₁ C₂ → ArePermEquivalent C₂ C₁ := by
  rintro ⟨σ, hσ⟩
  refine ⟨σ⁻¹, ?_⟩
  intro c hc
  -- c ∈ C₂. Need σ⁻¹ · c ∈ C₁.
  -- hcard + hσ injective makes hσ a bijection C₁ → C₂, so σ⁻¹ maps C₂ → C₁.
  -- Apply D1a reasoning with C = C₁ ∪ C₂, or directly via bijection.
  sorry  -- full proof using D1a's bijection
```

**Acceptance:**
- Theorem compiles; zero sorry.
- Docstring cites `hcard` requirement.

#### D1c — Prove `arePermEquivalent_trans` · XS · 30 min

**File:** same module.

**Approach:** unconditional composition.
```lean
theorem arePermEquivalent_trans
    (C₁ C₂ C₃ : Finset (Fin n → F)) :
    ArePermEquivalent C₁ C₂ → ArePermEquivalent C₂ C₃ →
    ArePermEquivalent C₁ C₃ := by
  rintro ⟨σ, hσ⟩ ⟨τ, hτ⟩
  refine ⟨τ * σ, ?_⟩
  intro c hc
  rw [show permuteCodeword (τ * σ) c = permuteCodeword τ (permuteCodeword σ c)
      from by simp [permuteCodeword_mul]]
  exact hτ _ (hσ c hc)
```

**Acceptance:**
- Theorem compiles; zero sorry.
- No side condition.

**Dependencies:** D1a must land before D1b. D1c is independent of D1a/D1b.

### D2 — Promote `PAut` to `Subgroup (Equiv.Perm (Fin n))` (F-08 step 2) · M · 3 h

**Parent goal:** expose PAut with the full `Subgroup` API so Mathlib's
cosets/Lagrange/quotient tools become available for free.

**Dependency:** D1a (shared bijection helper).

#### D2a — `PAutSubgroup` with `carrier`, `mul_mem'`, `one_mem'` · S · 1 h

**File:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Approach:** build the three easy fields.
```lean
def PAutSubgroup (C : Finset (Fin n → F)) :
    Subgroup (Equiv.Perm (Fin n)) where
  carrier := PAut C
  mul_mem' := fun hσ hτ => paut_mul_closed C _ _ hσ hτ
  one_mem' := paut_contains_id C
  inv_mem' := by intro σ hσ; sorry  -- filled by D2b
```

**Acceptance:** all three fields discharged from existing lemmas; the
`inv_mem'` `sorry` is a *build-incomplete* placeholder and the module
does NOT build at the end of D2a — D2a lands *together with* D2b in a
single commit. Mark D2a as a planning checkpoint, not a standalone
commit.

**Rationale for non-independent commit:** Lean `structure`-field `sorry`
poisons `lake build`. D2a + D2b must ship together; D2a is exposed here
for effort accounting only.

#### D2b — Discharge `inv_mem'` using D1a · S · 1 h

**File:** same module.

**Approach:** instantiate D1a at `C = C` (self-preserving permutations).
```lean
  inv_mem' := by
    intro σ hσ
    exact permuteCodeword_self_bij_of_self_preserving C σ hσ
```

**Acceptance:**
- `PAutSubgroup` fully defined, zero sorry.
- `lake build Orbcrypt.Hardness.CodeEquivalence` exits 0.
- Commit D2a + D2b together.

#### D2c — Prove `PAut_eq_PAutSubgroup_carrier` · XS · 30 min

**File:** same module.

**Approach:**
```lean
theorem PAut_eq_PAutSubgroup_carrier (C : Finset (Fin n → F)) :
    PAut C = (PAutSubgroup C : Set (Equiv.Perm (Fin n))) := rfl
```

**Acceptance:**
- Theorem compiles (likely `rfl`).
- Docstring notes the definitional match so downstream `simp` stays idiomatic.

**Risk:** `PAut` is `Set`-valued; `PAutSubgroup.carrier` is also `Set`-valued
via `SetLike.coe`. If `rfl` fails due to unfolds, use
`Subgroup.ext fun _ => Iff.rfl` or `by rfl` with `simp [PAutSubgroup]`.

### D3 — Prove the actual coset set identity (F-16 step 2 — optional A6b) · M · 4 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Problem:** A6a renames `paut_coset_is_equivalence_set`. A6b's
optional strengthening proves the *set identity*
`{ρ | ρ maps C₁ → C₂} = σ · PAut C₁`. With D1+D2 available, this proof is
tractable and adds real structural content.

**Approach:** use the helper lemma from D2, plus D1's symmetry, to
establish both inclusions. Proof sketch:
1. Forward: any `ρ` with `ρ(C₁) ⊆ C₂` can be written as `σ * (σ⁻¹ * ρ)`,
   and `σ⁻¹ * ρ` maps `C₁ → C₁` by composition.
2. Reverse: `paut_compose_preserves_equivalence` (already exists).

**Acceptance:**
- `lake build Orbcrypt.Hardness.CodeEquivalence` exits 0.
- New theorem `paut_equivalence_set_eq_coset` with full proof, zero sorry.
- Docstring includes a 2-line cryptographic interpretation: "the set of
  all CE-witnessing permutations is a PAut-coset — this is the algebraic
  reason that LESS-style signatures can shrink the effective search
  space by |PAut|."

**Risk:** low, given D1+D2 landed.

### D4 — Connect reductions to Mathlib's `Setoid` (F-08 step 3) · S · 1 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Approach:** expose `ArePermEquivalent` as a `Setoid` instance (given D1):

```lean
instance arePermEquivalent_setoid_of_card
    (k : ℕ) : Setoid { C : Finset (Fin n → F) // C.card = k } where
  r := fun C₁ C₂ => ArePermEquivalent C₁.val C₂.val
  iseqv := ⟨
    fun C => arePermEquivalent_refl _,
    fun h => arePermEquivalent_symm _ _ (by rw [C.property, C'.property]) h,
    fun h₁₂ h₂₃ => arePermEquivalent_trans _ _ _ h₁₂ h₂₃⟩
```

**Acceptance:**
- Module builds.
- Instance synthesizes at call sites.
- Docstring explains the card-index subtype.

**Risk:** the subtype-indexed `Setoid` may produce synthesis noise. If so,
leave it as an unbundled `Equivalence` rather than a `Setoid` instance.

---

## 8. Workstream E — Probabilistic Refinement Chain (F-01, F-10, F-11, F-17, F-20)

**Status:** **LANDED** (all nine sub-workstreams E1–E9 complete).

**Goal:** thread Phase 8's `ConcreteOIA` / `CompOIA` framework through the
KEMOIA layer (F-10), the Phase 12 hardness chain (F-20), and the Phase 13
combiner no-go theorem (F-17). **After this workstream lands, no headline
security theorem will be vacuously true on any scheme with ≥ 2 orbit
representatives.**

**Delivery summary.** New modules `Orbcrypt/KEM/CompSecurity.lean` (E1)
and `Orbcrypt/Hardness/Encoding.lean` (E3-prep). Extensions to
`Orbcrypt/Hardness/CodeEquivalence.lean` (E2a, +`Orbcrypt.Probability`
imports + `Mathlib.Data.Fintype.Perm`), `Orbcrypt/Hardness/TensorAction.lean`
(E2b), `Orbcrypt/Hardness/Reductions.lean` (E2c + E3 + E4 + E5),
`Orbcrypt/PublicKey/CombineImpossibility.lean` (E6),
`Orbcrypt/Probability/Monad.lean` (E7a), `Orbcrypt/Probability/Advantage.lean`
(E8 prereq `hybrid_argument_uniform`), and `Orbcrypt/Crypto/CompSecurity.lean`
(E8). Root file `Orbcrypt.lean` + `CLAUDE.md` + this planning doc updated
with traceability notes (E9).

**Non-goal (deferred).** Concrete witnesses for the three ε-preserving
reduction Props (`ConcreteTensorOIAImpliesConcreteCEOIA`, etc.) and the
per-step marginal proof `h_step` inside `indQCPA_bound_via_hybrid` require
external mathematical work (CFI graph gadget, Grochow–Qiao structure
tensor, PMF marginalisation over `uniformPMFTuple`). They remain as
hypotheses of the top-level theorems; the chain composes cleanly once
any concrete instance is supplied. See Workstreams F3 / F4 in § 9 and
the audit plan E8b note for the research-grade next steps.

**Post-landing audit (2026-04-20 follow-up).** A targeted review of
the landed Workstream E content surfaced six correctness / documentation
issues addressed in an in-place revision. The highlights:

1. **E3 Props were decoupled.** `∀ T₀ T₁ C₀ C₁, TensorOIA T εT →
   CEOIA C εC` collapsed to `∀ C, CEOIA C εC` because `T₀ = T₁`
   trivially satisfies the hypothesis. The chain never consumed tensor
   hardness. **Fix:** reshaped to
   `UniversalConcreteTensorOIA εT → UniversalConcreteCEOIA εC` (and
   analogously for CE → GI, GI → scheme-OIA). Now the chain genuinely
   threads TI-hardness through every link. See
   `Orbcrypt/Hardness/Reductions.lean` `UniversalConcreteTensorOIA`,
   `UniversalConcreteCEOIA`, `UniversalConcreteGIOIA`.
2. **E4 `ConcreteHardnessChain` carried a per-pair tensor witness.**
   The landed structure had `(n, G_TI, T₀, T₁)` fields and a per-pair
   `tensor_hard`. Composition passed through empty codes / trivial
   graphs — the tensor content was never consumed. **Fix:** chain now
   carries `tensor_hard : UniversalConcreteTensorOIA εT` and the
   composition is a three-line `hc.gi_to_oia (hc.ce_to_gi
   (hc.tensor_to_ce hc.tensor_hard))`, using every link. A new
   `ConcreteHardnessChain.tight_one_exists` lemma witnesses non-vacuity
   at ε = 1.
3. **E1 `ConcreteKEMOIA` collapsed on `ε ∈ [0, 1)`.** Under `PMF.pure`
   point masses, advantage is binary (0 or 1), so bounding by ε < 1
   forces the 0-advantage case. `ConcreteKEMOIA kem ε` for `ε ∈ [0, 1)`
   is equivalent to `ConcreteKEMOIA kem 0`. **Fix:** honest docstring
   disclosing the collapse + new `ConcreteKEMOIA_uniform` over the
   `kemEncapsDist` push-forward whose advantage can take any real value
   in `[0, 1]`.
4. **E6 `combinerOrbitDist_mass_bounds` was over-claimed.** Mass bounds
   on one orbit don't imply cross-orbit advantage bounds. **Fix:**
   revised docstrings state the bound is intra-orbit only.
5. **`OrbitPreservingEncoding` was dead code.** Defined in
   `Hardness/Encoding.lean` but not consumed. **Fix:** module docstring
   now clarifies it is the reference interface that a future
   per-encoding refactor (Workstream F3/F4) will plug into.
6. **`audit_e_workstream.lean` was only axiom dumps.** **Fix:** added
   a Part 2 of ~15 concrete `example` bindings exercising each headline
   result on a well-typed instance.

See `CLAUDE.md`'s "Workstream E follow-up" subsection for the detailed
fix log and line-by-line references.

### E-overview: what "vacuous" means and what replaces it

Today:
- `oia_implies_1cpa` takes `hOIA : OIA scheme` — unsatisfiable when
  `reps_distinct` holds on a ≥ 2-element `M` (because the `decide (x ∈ orbit G (reps m₀))`
  Boolean distinguisher refutes it).
- `kemoia_implies_secure`, `hardness_chain_implies_security`, and
  `equivariant_combiner_breaks_oia` all inherit this vacuity via the
  same deterministic OIA ⊥ hypothesis.

After Workstream E:
- Each theorem has a probabilistic counterpart parameterised by an explicit
  advantage bound `ε : ℝ`.
- Each counterpart **preserves** the original theorem (the deterministic
  form becomes a corollary of `ε = 0`, which is the ConcreteOIA(0) case).
- Each counterpart is **non-vacuous**: ConcreteOIA(1) is trivially
  satisfiable (`advantage ≤ 1` always), giving a meaningful if weak
  statement. Interesting ε values parameterise realistic security.

### E1 — `ConcreteKEMOIA` + probabilistic `kemoia_implies_secure` (F-10 step 1) · L · 6 h

**Parent goal:** lift KEMOIA from a deterministic (vacuous) Prop to a
probabilistic ε-bounded Prop. Decompose into four sub-units so the PMF
push-forward, the deterministic bridge, and the security implication
can each be tested in isolation.

#### E1a — `kemEncapsDist` PMF push-forward · M · 1 h 30 min

**File:** new `Orbcrypt/KEM/CompSecurity.lean`

**Approach:** define the joint distribution of (ciphertext, key) under
the uniform group distribution.
```lean
noncomputable def kemEncapsDist [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] (kem : OrbitKEM G X K) : PMF (X × K) :=
  PMF.map (fun g => encaps kem g) (uniformPMF G)
```

Plus three sanity lemmas mirroring `orbitDist_support` /
`orbitDist_pos_of_mem`:
- `kemEncapsDist_support` — support equals the image of `encaps kem`
- `kemEncapsDist_pos_of_mem` — every reachable pair has positive measure

**Acceptance:**
- Module builds.
- Three sanity lemmas, all with docstrings.

#### E1b — Define `ConcreteKEMOIA` and prove `_one` satisfiability · S · 1 h

**File:** same.

**Approach:**
```lean
def ConcreteKEMOIA [...] (kem : OrbitKEM G X K) (ε : ℝ) : Prop :=
  ∀ (D : X × K → Bool) (g₀ g₁ : G),
    advantage D (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁)) ≤ ε

theorem concreteKEMOIA_one (kem : OrbitKEM G X K) :
    ConcreteKEMOIA kem 1 :=
  fun D _ _ => advantage_le_one _ _ _
```

**Acceptance:**
- Both compile.
- `_one` lemma proves satisfiability (mirrors `concreteOIA_one`).

#### E1c — Bridge: `det_kemoia_implies_concreteKEMOIA_zero` · M · 1 h 30 min

**File:** same.

**Approach:** mirror `det_oia_implies_concrete_zero` from `Crypto/CompOIA.lean`.
Take `KEMOIA.1` (deterministic indistinguishability), specialise at the
diagonal `g, g`, derive that `D` is constant on encapsulation outputs,
hence advantage = 0 ≤ 0.

**Acceptance:**
- Theorem compiles, zero sorry.
- `#print axioms det_kemoia_implies_concreteKEMOIA_zero` = standard Lean.

#### E1d — Probabilistic `concrete_kemoia_implies_secure` · M · 2 h

**File:** same.

**Approach:** define `kemIndCPAAdvantage` and prove it is bounded by ε.
```lean
noncomputable def kemIndCPAAdvantage
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) : ℝ :=
  -- Per-distinguisher advantage of A on encapsulation pairs
  ⨆ g₀ g₁, advantage (fun p => A.guess kem.basePoint p.1 p.2)
    (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁))

theorem concrete_kemoia_implies_secure
    (kem : OrbitKEM G X K) (ε : ℝ)
    (hOIA : ConcreteKEMOIA kem ε) (A : KEMAdversary X K) :
    kemIndCPAAdvantage kem A ≤ ε := by
  unfold kemIndCPAAdvantage
  exact ciSup_le (fun g₀ => ciSup_le fun g₁ => hOIA _ g₀ g₁)
```

**Acceptance:**
- Theorem compiles, zero sorry.
- `#print axioms concrete_kemoia_implies_secure` = standard Lean only
  (uses `Classical.choice` indirectly via `⨆` — acceptable; it is
  already in the project's standard axiom set).

**Dependencies:** E1a → E1b → E1c → E1d (strict). Each lands as its own
commit; the file builds after every one.

**Risk:** `⨆` over `G × G` requires a `BoundedAbove` instance on the set
`{advantage ... | g₀ g₁}`. Bound by 1 (via `advantage_le_one`); supply
explicitly if Mathlib's `ciSup_le` complains.

### E2 — `ConcreteTensorOIA`, `ConcreteCEOIA`, `ConcreteGIOIA` (F-10 step 2) · L · 8 h

**Parent goal:** add the three probabilistic OIA variants for the
hardness-chain layer. They are independent — each can land in parallel.

#### E2a — `ConcreteCEOIA` and `codeOrbitDist` · M · 2 h 30 min

**File:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Approach:**
```lean
noncomputable def codeOrbitDist [Fintype (Equiv.Perm (Fin n))]
    (C : Finset (Fin n → F)) : PMF (Finset (Fin n → F)) :=
  PMF.map (fun σ => C.image (permuteCodeword σ))
    (uniformPMF (Equiv.Perm (Fin n)))

def ConcreteCEOIA [Fintype (Equiv.Perm (Fin n))]
    (C₀ C₁ : Finset (Fin n → F)) (ε : ℝ) : Prop :=
  ∀ (D : Finset (Fin n → F) → Bool),
    advantage D (codeOrbitDist C₀) (codeOrbitDist C₁) ≤ ε

theorem concreteCEOIA_one (C₀ C₁ : Finset (Fin n → F)) :
    ConcreteCEOIA C₀ C₁ 1 :=
  fun D => advantage_le_one _ _ _
```

**Acceptance:**
- Module builds.
- Three declarations (helper + Prop + `_one`), all docstrings.

#### E2b — `ConcreteTensorOIA` and `tensorOrbitDist` · M · 3 h

**File:** `Orbcrypt/Hardness/TensorAction.lean`

**Approach:** GL³ is large; the orbit distribution is over the action
of `(GL n)³` on `Tensor3 n F`. PMF push-forward needs `Fintype (GL n F)`,
which requires a finite field `F`. Add `[Fintype F] [DecidableEq F]`
hypothesis throughout.

```lean
noncomputable def tensorOrbitDist [Fintype F] [DecidableEq F]
    (T : Tensor3 n F) : PMF (Tensor3 n F) :=
  PMF.map (fun (gh : (Matrix (Fin n) (Fin n) F)ˣ ×
                     (Matrix (Fin n) (Fin n) F)ˣ ×
                     (Matrix (Fin n) (Fin n) F)ˣ) =>
              gh • T)
    (uniformPMF _)  -- uniform over the GL³ product

def ConcreteTensorOIA (T₀ T₁ : Tensor3 n F) (ε : ℝ) : Prop :=
  ∀ (D : Tensor3 n F → Bool),
    advantage D (tensorOrbitDist T₀) (tensorOrbitDist T₁) ≤ ε

theorem concreteTensorOIA_one (T₀ T₁ : Tensor3 n F) :
    ConcreteTensorOIA T₀ T₁ 1 :=
  fun D => advantage_le_one _ _ _
```

**Acceptance:**
- Module builds.
- Same three-declaration shape as E2a.

**Risk:** `Fintype (GL n F)` requires manual instance discovery. If
absent, restate as parameterised over a `[Fintype G_TI]` where `G_TI` is
an abstract Fintype group acting on `Tensor3` — defer the GL³ binding
to Workstream F4.

#### E2c — `ConcreteGIOIA` and `graphOrbitDist` · M · 2 h 30 min

**File:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:**
```lean
noncomputable def graphOrbitDist (adj : Matrix (Fin n) (Fin n) Bool) :
    PMF (Matrix (Fin n) (Fin n) Bool) :=
  PMF.map (fun σ => permuteAdj σ adj) (uniformPMF (Equiv.Perm (Fin n)))

def ConcreteGIOIA (adj₀ adj₁ : Matrix (Fin n) (Fin n) Bool) (ε : ℝ) : Prop :=
  ∀ (D : Matrix (Fin n) (Fin n) Bool → Bool),
    advantage D (graphOrbitDist adj₀) (graphOrbitDist adj₁) ≤ ε

theorem concreteGIOIA_one (adj₀ adj₁ : Matrix (Fin n) (Fin n) Bool) :
    ConcreteGIOIA adj₀ adj₁ 1 :=
  fun D => advantage_le_one _ _ _
```

**Acceptance:** module builds, three declarations, all docstrings.

**E2 dependencies:** none across sub-units; E2a/E2b/E2c are independent.

### E3 — Probabilistic reduction steps (F-09 at the Prop level, F-20 step 1) · L · 10 h

**Parent goal:** the three ε-preserving reductions, each as its own Prop.
Independent leaves; can be parallelised.

**Encoding interface (shared across E3a–E3c):** before the three
reductions, land a small `EncodingInterface` predicate file
(see E3-prep) that captures "object X is encoded as object Y, with the
encoding preserving the relevant orbit structure." Without this, each
reduction reinvents the encoding signature.

#### E3-prep — `EncodingInterface` predicate · S · 1 h

**File:** new `Orbcrypt/Hardness/Encoding.lean`

**Approach:**
```lean
/-- An encoding from objects of type α (under group A action) to objects
    of type β (under group B action) is *orbit-preserving* if it sends
    A-orbits to B-orbits. Used to formalise reductions between hardness
    problems. -/
structure OrbitPreservingEncoding
    (α β : Type*) [Group A] [Group B] [MulAction A α] [MulAction B β] where
  encode : α → β
  /-- Orbit preservation: A-equivalent inputs map to B-equivalent outputs. -/
  preserves : ∀ x y, (∃ a : A, a • x = y) → (∃ b : B, b • encode x = encode y)
  /-- Reflectivity: B-equivalent encodings come from A-equivalent inputs. -/
  reflects : ∀ x y, (∃ b : B, b • encode x = encode y) → (∃ a : A, a • x = y)
```

**Acceptance:** module builds; structure has docstring; one trivial
instance (`identityEncoding`) demonstrates satisfiability.

#### E3a — `ConcreteTensorOIAImpliesConcreteCEOIA` Prop · M · 2 h 30 min

**File:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:**
```lean
def ConcreteTensorOIAImpliesConcreteCEOIA
    [Fintype F] [DecidableEq F] (εT εC : ℝ) : Prop :=
  ∀ (T₀ T₁ : Tensor3 n F) (C₀ C₁ : Finset (Fin m → F))
    (_enc : OrbitPreservingEncoding (Tensor3 n F) (Finset (Fin m → F))),
    ConcreteTensorOIA T₀ T₁ εT → ConcreteCEOIA C₀ C₁ εC
```

**Acceptance:** module builds; docstring cites Beullens–Persichetti;
`_one_one` trivial witness lemma.

#### E3b — `ConcreteCEOIAImpliesConcreteGIOIA` Prop · M · 2 h 30 min

**File:** same.

**Approach:** symmetric to E3a using `OrbitPreservingEncoding` from
codes to adjacency matrices.

**Acceptance:** as E3a.

#### E3c — `ConcreteGIOIAImpliesConcreteOIA` Prop · M · 2 h 30 min

**File:** same.

**Approach:** symmetric, but the target is `ConcreteOIA scheme` rather
than `Concrete*OIA obj`. Carry an extra `OrbitEncSchemeFromGraph`
encoding parameter.

**Acceptance:** as E3a.

#### E3d — Trivial composition lemma `_zero_zero_zero_zero` · S · 1 h

**File:** same.

**Approach:** prove that if all three reductions hold at ε = 0 and
ConcreteTensorOIA holds at ε = 0, then ConcreteOIA holds at ε = 0.
This is the algebraic sanity check for E4 and demonstrates that the
ε-parameter machinery composes.

```lean
theorem concrete_chain_zero_compose
    (h₁ : ConcreteTensorOIAImpliesConcreteCEOIA 0 0)
    (h₂ : ConcreteCEOIAImpliesConcreteGIOIA 0 0)
    (h₃ : ConcreteGIOIAImpliesConcreteOIA 0 0)
    {scheme : OrbitEncScheme G X M} : ... := by
  ...
```

**Acceptance:** theorem compiles; serves as a sanity sentry for E4.

**Dependencies:** E3-prep before E3a/b/c. E3a/b/c are independent leaves
and can ship in parallel. E3d depends on all of E3a/b/c.

### E4 — `ConcreteHardnessChain` (F-20 step 2) · L · 4 h

**Parent goal:** assemble the four-link chain into a single composable
structure + proof.

#### E4a — Define the `ConcreteHardnessChain` structure · S · 1 h

**File:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:**
```lean
structure ConcreteHardnessChain
    [...] (scheme : OrbitEncScheme G X M) (ε : ℝ) where
  εT : ℝ
  εC : ℝ
  εG : ℝ
  /-- Bound on the per-pair tensor advantage (assumed hard). -/
  tensor_hard : ∀ T₀ T₁, ConcreteTensorOIA T₀ T₁ εT
  /-- Tensor → CE reduction Prop. -/
  tensor_to_ce : ConcreteTensorOIAImpliesConcreteCEOIA εT εC
  /-- CE → GI reduction Prop. -/
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA εC εG
  /-- GI → OIA reduction Prop. -/
  gi_to_oia : ConcreteGIOIAImpliesConcreteOIA εG ε
```

**Acceptance:** structure compiles; every field has a docstring.

#### E4b — Prove `concreteOIA_from_chain` · M · 2 h 30 min

**File:** same.

**Approach:** sequential application.
```lean
theorem concreteOIA_from_chain
    (hc : ConcreteHardnessChain scheme ε) : ConcreteOIA scheme ε := by
  intro D m₀ m₁
  -- 1. Pick tensors T₀ T₁ encoded from scheme.reps m₀, m₁ via E3-prep.
  -- 2. Apply hc.tensor_hard at εT.
  -- 3. Apply hc.tensor_to_ce to lift to ConcreteCEOIA at εC.
  -- 4. Apply hc.ce_to_gi to lift to ConcreteGIOIA at εG.
  -- 5. Apply hc.gi_to_oia to lift to ConcreteOIA at ε.
  -- 6. Specialize at D, m₀, m₁.
  sorry  -- planning placeholder; landed commit has zero sorry
```

**Acceptance:**
- Theorem compiles, zero sorry.
- `#print axioms concreteOIA_from_chain` = standard Lean only.

#### E4c — Add an additive ε-loss helper lemma · S · 30 min

**File:** same.

**Approach:** when reductions are tight (`εT = εC = εG = ε`), the chain
collapses. Provide a convenience constructor.
```lean
def ConcreteHardnessChain.tight
    (h_tensor : ∀ T₀ T₁, ConcreteTensorOIA T₀ T₁ ε)
    (h_tc : ConcreteTensorOIAImpliesConcreteCEOIA ε ε)
    (h_cg : ConcreteCEOIAImpliesConcreteGIOIA ε ε)
    (h_go : ConcreteGIOIAImpliesConcreteOIA ε ε) :
    ConcreteHardnessChain scheme ε :=
  { εT := ε, εC := ε, εG := ε,
    tensor_hard := h_tensor, tensor_to_ce := h_tc,
    ce_to_gi := h_cg, gi_to_oia := h_go }
```

**Acceptance:** definition compiles; docstring explains the tight case.

**Dependencies:** E3a/b/c/d before E4. E4a → E4b strict. E4c independent
of E4b.

### E5 — Probabilistic `hardness_chain_implies_security` (F-20 step 3) · M · 3 h

**Files:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:** compose E4 with `concrete_oia_implies_1cpa`:

```lean
theorem concrete_hardness_chain_implies_1cpa_advantage_bound
    [...] (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (hc : ConcreteHardnessChain scheme ε)
    (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) ≤ ε :=
  concrete_oia_implies_1cpa scheme ε (concreteOIA_from_chain hc) D m₀ m₁
```

Also retain the original `hardness_chain_implies_security` but mark its
docstring "vacuous under deterministic OIA; see `concrete_hardness_chain_implies_1cpa_advantage_bound`
for the non-vacuous formulation."

**Acceptance:**
- Module builds.
- New theorem compiles with zero sorry.
- Docstring of the original `hardness_chain_implies_security` carries the
  vacuity disclaimer and a `@[deprecated "use concrete_hardness_chain_implies_1cpa_advantage_bound"]`
  attribute (optional — may break Lean attribute surface; assess at
  implementation time).

**Risk:** none beyond E4's landing.

### E6 — Probabilistic `equivariant_combiner_breaks_oia` (F-17) · L · 6 h

**Parent goal:** turn the vacuous `false`-derivation into a quantitative
advantage lower bound. Decompose into three sub-units: define the
distinguisher distribution, derive the lower bound, then combine.

#### E6a — Define `combinerOrbitDist` and `combinerDistinguisherAdvantage` · M · 2 h

**File:** `Orbcrypt/PublicKey/CombineImpossibility.lean`

**Approach:**
```lean
noncomputable def combinerOrbitDist [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (comb : GEquivariantCombiner G X)
    (m : M) : PMF Bool :=
  PMF.map (fun g => combinerDistinguisher comb (g • scheme.reps m))
    (uniformPMF G)

noncomputable def combinerDistinguisherAdvantage
    (scheme : OrbitEncScheme G X M) (comb : GEquivariantCombiner G X)
    (m₀ m₁ : M) : ℝ :=
  advantage id (combinerOrbitDist scheme comb m₀)
              (combinerOrbitDist scheme comb m₁)
```

**Acceptance:** both compile; docstrings explain what they distinguish.

#### E6b — Lower bound from non-degeneracy · M · 2 h

**File:** same.

**Approach:** the non-degeneracy witness exhibits a single `g` with
`combinerDistinguisher (g • bp) = false`. Combined with
`combinerDistinguisher_basePoint = true`, the empirical distribution under
the uniform group law has support on both Booleans. Lower bound:
`advantage ≥ 1/|G|` (one tick of probability mass differs).

```lean
theorem combinerDistinguisherAdvantage_lower_bound_of_nonDeg
    (scheme : OrbitEncScheme G X M) (comb : GEquivariantCombiner G X)
    (hND : NonDegenerateCombiner comb) (m₀ m₁ : M)
    (hDistinct : scheme.reps m₀ ≠ scheme.reps m₁) :
    combinerDistinguisherAdvantage scheme comb m₀ m₁ ≥ (1 : ℝ) / Fintype.card G := by
  sorry  -- planning placeholder; landed commit has zero sorry
```

**Acceptance:** theorem compiles, zero sorry; bound is concrete (`1/|G|`).

#### E6c — Combine into `nondegenerate_equivariant_combiner_advantage_lower_bound` · S · 1 h 30 min

**File:** same.

**Approach:**
```lean
theorem nondegenerate_equivariant_combiner_advantage_lower_bound
    (scheme : OrbitEncScheme G X M) (comb : GEquivariantCombiner G X)
    (hND : NonDegenerateCombiner comb)
    (m₀ m₁ : M) (hDistinct : scheme.reps m₀ ≠ scheme.reps m₁)
    (ε : ℝ) (hOIA : ConcreteOIA scheme ε) :
    ε ≥ (1 : ℝ) / Fintype.card G := by
  calc (1 : ℝ) / Fintype.card G
      ≤ combinerDistinguisherAdvantage scheme comb m₀ m₁ :=
        combinerDistinguisherAdvantage_lower_bound_of_nonDeg ..
    _ ≤ ε := hOIA _ m₀ m₁
```

**Acceptance:**
- Theorem compiles, zero sorry.
- Original `equivariant_combiner_breaks_oia` retained; its docstring
  cross-references this new theorem.

**Dependencies:** E1d's PMF infrastructure; otherwise self-contained.

**Risk:** `1/|G|` may be too weak for the headline reading. If
non-degeneracy can be strengthened to "many `g` distinguish", lift the
bound to `Ω(1)`. Defer that strengthening to a follow-up; the present
WU is "any positive lower bound suffices to refute the vacuity".

### E7 — Product PMF infrastructure (F-11 prereq) · M · 6 h

**Parent goal:** lift `uniformPMF` from single elements to Q-tuples so
the hybrid argument can interpolate over Q queries.

#### E7a — `uniformPMFTuple` definition · M · 2 h

**File:** `Orbcrypt/Probability/Monad.lean`

**Approach:** spike Mathlib first — does `PMF.pi` exist?
```bash
# Mathlib spike
grep -r "PMF.pi\|PMF.prod\|PMF.fintype.*pi" path/to/mathlib
```

If `PMF.pi` exists: thin wrapper.
If absent: build by `Fin.foldr` of `PMF.bind`.
```lean
noncomputable def uniformPMFTuple (α : Type*) [Fintype α] [Nonempty α]
    (Q : ℕ) : PMF (Fin Q → α) :=
  Fin.foldr Q (fun _ acc =>
    PMF.bind (uniformPMF α) (fun a =>
      PMF.bind acc (fun f =>
        PMF.pure (fun i => if i.val = 0 then a else f i.castSucc))))
    (PMF.pure (Fin.elim0 ·))
  -- or simpler: noncomputable def via Fintype.fintypeOfPi
```

**Acceptance:**
- Module builds.
- One sanity lemma `uniformPMFTuple_apply` showing pointwise mass = 1/|α|^Q.

#### E7b — `probEventTuple`, `advantageTuple`, marginals · M · 2 h 30 min

**File:** same.

**Approach:**
```lean
noncomputable def probEventTuple (P : PMF (Fin Q → α)) (E : (Fin Q → α) → Bool) : ℝ≥0∞ := ...
noncomputable def advantageTuple ... : ℝ := ...

theorem uniformPMFTuple_marginal_uniform (i : Fin Q) :
    PMF.map (fun f => f i) (uniformPMFTuple α Q) = uniformPMF α := by
  ...  -- key fact for the hybrid argument
```

**Acceptance:** module builds; the marginal lemma is the building block
needed by E8b. All declarations docstring'd.

#### E7c — `i`-th hybrid distribution · M · 1 h 30 min

**File:** same.

**Approach:** define the `i`-th hybrid: first `i` queries from `m₀`, last
`Q - i` from `m₁`. This is the canonical hybrid construction.
```lean
noncomputable def hybridDist (m₀ m₁ : M) (scheme : ...) (i : Fin (Q + 1)) :
    PMF (Fin Q → X) := ...
```

**Acceptance:**
- Definition compiles.
- `hybridDist_zero = all-m₀`, `hybridDist_Q = all-m₁` lemmas.

**Dependencies:** E7a → E7b → E7c sequential.

**Risk:** if `PMF.pi` is absent in pinned Mathlib and `Fin.foldr`
construction breaks definitional equality lemmas, fall back to `Fin Q → α`
modeled by repeated `PMF.bind` over `List.range Q` and prove the
required lemmas by hand.

### E8 — Multi-query IND-Q-CPA via hybrid argument (F-11) · L · 8 h

**Parent goal:** prove `indQCPAAdvantage A ≤ Q · ε` via the hybrid
argument. Decompose into definition / single-step / telescoping / wrap.

#### E8a — Define `indQCPAAdvantage` · S · 1 h

**File:** `Orbcrypt/Crypto/CompSecurity.lean`

**Approach:**
```lean
noncomputable def indQCPAAdvantage [...] {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (A : DistinctMultiQueryAdversary X M Q) : ℝ :=
  advantage (A.guess scheme.reps)
    (PMF.bind (uniformPMFTuple G Q) (fun gs =>
       PMF.pure (fun i => gs i • scheme.reps (A.choose scheme.reps i).1)))
    (PMF.bind (uniformPMFTuple G Q) (fun gs =>
       PMF.pure (fun i => gs i • scheme.reps (A.choose scheme.reps i).2)))
```

**Acceptance:** definition compiles; docstring explains the all-left vs.
all-right framing.

#### E8b — Single-step hybrid lemma · M · 2 h 30 min

**File:** same.

**Approach:** the core lemma — adjacent hybrids differ by at most ε.
```lean
theorem hybrid_step_bound
    (scheme : ...) (A : DistinctMultiQueryAdversary X M Q) (ε : ℝ)
    (hOIA : ConcreteOIA scheme ε) (i : Fin Q) :
    advantage (A.guess scheme.reps) (hybridDist .. i.castSucc) (hybridDist .. i.succ) ≤ ε := by
  -- Marginal at index i is uniform-G • reps m₀ vs uniform-G • reps m₁
  -- which is exactly orbitDist m₀ vs orbitDist m₁. Apply hOIA.
  sorry  -- planning placeholder; landed commit has zero sorry
```

**Acceptance:** theorem compiles, zero sorry; depends on E7b's marginal
uniformity lemma and B3's `DistinctMultiQueryAdversary`.

#### E8c — Telescope to `indQCPA_bound_via_hybrid` · M · 2 h 30 min

**File:** same.

**Approach:** apply E8b inside `hybrid_argument_nat`.
```lean
theorem indQCPA_bound_via_hybrid
    (scheme : OrbitEncScheme G X M) (ε : ℝ) (Q : ℕ)
    (hOIA : ConcreteOIA scheme ε) (A : DistinctMultiQueryAdversary X M Q) :
    indQCPAAdvantage scheme A ≤ Q * ε := by
  -- 1. Identify indQCPAAdvantage = advantage (... A.guess) (hybridDist 0) (hybridDist Q).
  -- 2. Apply hybrid_argument_nat with per-step bound = ε via E8b.
  -- 3. Sum bounds = Q * ε.
  sorry  -- planning placeholder; landed commit has zero sorry
```

**Acceptance:**
- Theorem compiles, zero sorry.
- `#print axioms indQCPA_bound_via_hybrid` = standard Lean only.

#### E8d — Q = 1 regression check · XS · 30 min

**File:** same.

**Approach:** prove a sanity corollary that recovers the existing
single-query bound at Q = 1.
```lean
theorem indQCPA_bound_recovers_single_query
    (scheme : ...) (ε : ℝ) (hOIA : ConcreteOIA scheme ε)
    (A : DistinctMultiQueryAdversary X M 1) :
    indQCPAAdvantage scheme A ≤ ε := by
  simpa using indQCPA_bound_via_hybrid scheme ε 1 hOIA A
```

**Acceptance:** corollary compiles; serves as regression sentinel.

**Dependencies:** B3 (DistinctMultiQueryAdversary), E7a/b/c (product PMF
+ hybrids). E8a–E8d strictly sequential.

**Risk:** marginal-uniformity simplification (E8b) is the most subtle
step. If the per-coordinate marginal does not simplify cleanly, change
the hybrid definition to use independent samples per coordinate
(E7c-style `PMF.pi`-based) rather than a single `Fin Q → G` tuple.

### E9 — Update axiom transparency report (cross-cutting) · S · 2 h

**Files:** `Orbcrypt.lean`

**Approach:** in the axiom transparency section, add an explicit
"**Vacuity map**" table replicating §5.1 of the audit, marking each
theorem as:
- **Non-vacuous** (real content): `correctness`, `kem_correctness`,
  `aead_correctness`, `hybrid_correctness`, `invariant_attack`,
  `hgoe_weight_attack`, `nonce_reuse_leaks_orbit`,
  `symmetric_key_agreement_limitation`, `concrete_oia_implies_1cpa`,
  `comp_oia_implies_1cpa`, the new `concrete_*` theorems from E1–E8.
- **Vacuous today, replaced by probabilistic form**: `oia_implies_1cpa`
  (→ `concrete_oia_implies_1cpa`), `kemoia_implies_secure`
  (→ `concrete_kemoia_implies_secure`),
  `hardness_chain_implies_security`
  (→ `concrete_hardness_chain_implies_1cpa_advantage_bound`),
  `equivariant_combiner_breaks_oia`
  (→ `nondegenerate_equivariant_combiner_advantage_lower_bound`).

**Acceptance:**
- `Orbcrypt.lean` builds.
- New § is ~40–60 lines of documentation.
- Every pair ("deterministic vacuous" → "probabilistic non-vacuous") is
  cross-referenced.

---

## 9. Workstream F — Implementation Gaps (research)

**Goal:** address the findings that require new mathematical content (not
just refactoring): F-05, F-06, F-09, F-14, F-21. Each is a separable
research-grade WU and **must not block** Workstreams A–E.

### F1 — HGOEKeyExpansion → SeedKey concrete bridge (F-05) · XL · 30 h

**Parent goal:** turn the `HGOEKeyExpansion` specification into a
realised concrete `SeedKey` with full correctness theorems. This was
formerly a "split later" plan note — broken out here into four sub-WUs
totalling ~30 h.

#### F1a — `PRF` abstraction · M · 6 h

**Files:** new `Orbcrypt/KeyMgmt/PRF.lean`

**Approach:**
```lean
/-- A Pseudo-Random Function: deterministic seed → indexed output. -/
structure PRF (Seed : Type*) (Out : Type*) where
  eval : Seed → ℕ → Out
  /-- Computational pseudorandomness — Prop, carried as hypothesis. -/
  pseudorandom : Prop
```

Plus three trivial lemmas:
- `PRF.eval_deterministic` — same seed + same index → same output (rfl).
- `PRF.distinct_indices_distinct_outputs` (assuming injectivity).
- `PRF.compose` — composing PRFs.

**Acceptance:** module builds; structure docstring'd; `pseudorandom`
field has a clear "this is an assumption, not a proof" note.

#### F1b — `hgoeKeyFromExpansion` constructor · L · 8 h

**Files:** new `Orbcrypt/KeyMgmt/HGOEExpansion.lean`

**Approach:**
```lean
def hgoeKeyFromExpansion {n : ℕ} {M : Type*}
    (exp : HGOEKeyExpansion n M) (prf : PRF Seed (Bitstring n)) :
    SeedKey Seed (Equiv.Perm (Fin n)) (Bitstring n) where
  seed := ...  -- PRF seed
  expand := fun s => {
    canon := fun x => ...,  -- canonical form within exp's group
    mem_orbit := ...,
    orbit_iff := ...
  }
  sampleGroup := fun s i => ...  -- derive permutation from prf.eval s i
```

**Acceptance:**
- Module builds.
- All `SeedKey` fields populated.
- Each component cites its origin in the 7-stage pipeline (Stage 1: param,
  Stage 2: code, Stage 3: group, Stage 4: representatives).

#### F1c — Correctness: `hgoeKeyFromExpansion_reps_same_weight` · M · 6 h

**Files:** same.

**Approach:** show that the expansion's `reps_same_weight` field
propagates to the concrete `SeedKey`'s representative-producing pipeline.
```lean
theorem hgoeKeyFromExpansion_reps_same_weight
    (exp : HGOEKeyExpansion n M) (prf : PRF ..) (m : M) :
    hammingWeight (exp.reps m) = exp.weight :=
  exp.reps_same_weight m
```

Plus: prove `hgoeKeyFromExpansion_kem_correctness` via
`seed_kem_correctness`.

**Acceptance:** both theorems compile, zero sorry.

#### F1d — Integration with `Construction/HGOEKEM.lean` · M · 6 h

**Files:** `Orbcrypt/Construction/HGOEKEM.lean` (extend)

**Approach:** add a constructor `hgoeKEMFromExpansion` that takes an
`HGOEKeyExpansion` + `PRF` and produces a fully populated `OrbitKEM`.
Prove `hgoeKEMFromExpansion_correctness` via `kem_correctness`.

**Acceptance:**
- Module builds.
- New theorem listed in `CLAUDE.md` headline table as theorem #19.
- Cross-link to `docs/HARDNESS_ANALYSIS.md` for the QC code parameter
  basis.

**Dependencies:** F1a → F1b → F1c → F1d sequential. Each sub-WU is its
own commit. Total effort: 6 + 8 + 6 + 6 = 26 h (under 30 h budget).

### F2 — Seed secrecy interface `SampleGroupSpec` (F-06) · M · 6 h

**Files:** `Orbcrypt/KeyMgmt/SeedKey.lean` (extend)

**Problem:** `OrbitEncScheme.toSeedKey` takes `sampleG : ℕ → G` with no
secrecy obligation.

**Approach:**

```lean
/-- A sampler interface that carries a pseudorandomness obligation. -/
structure SampleGroupSpec (Seed G : Type*) [Group G] where
  sample : Seed → ℕ → G
  /-- PRF property: for a uniformly chosen seed, the sampler outputs
      are computationally indistinguishable from uniform in G. -/
  pseudorandom : Prop  -- concrete definition TBD in this WU
```

Then upgrade `OrbitEncScheme.toSeedKey` to consume a `SampleGroupSpec`
rather than a bare function. Prove `toSeedKey_pseudorandom` directly from
the spec's `pseudorandom` field.

**Acceptance:**
- Module builds.
- `SampleGroupSpec` has a docstring citing PRF literature.
- Old `OrbitEncScheme.toSeedKey` signature preserved as deprecated
  wrapper taking a `SampleGroupSpec` with `pseudorandom := trivial`
  (honest escape hatch, but at least the interface now surfaces the
  assumption).

**Risk:** defining `pseudorandom` concretely requires a computational
indistinguishability Prop. Reuse `advantage` from Phase 8.

### F3 — Concrete GI ≤_p CE reduction (F-09 step 1) · XL · 40 h

**Parent goal:** prove `GIReducesToCE` concretely for the CFI gadget.
Decompose into four sub-units; each is a substantial Lean proof.

#### F3a — CFI gadget definition · L · 8 h

**Files:** new `Orbcrypt/Hardness/CFIGadget.lean`

**Approach:** following Cai–Fürer–Immerman 1992: define the CFI graph's
encoding into a code. For each graph vertex `v` with degree `d`, attach
`2^d` "configurations" via parity bits. Define
`cfiCode : Graph → Finset (Fin N → F₂)`.

**Acceptance:** module builds; `cfiCode` definition + 2 sanity lemmas
(image cardinality, dimension).

#### F3b — `cfiCode` PAut = graph Aut (forward) · L · 12 h

**Files:** same.

**Approach:** show every graph automorphism induces a code automorphism.
```lean
theorem graphAut_to_cfiCodeAut (G : Graph) (σ : G.Aut) :
    permuteCodewordExtension σ ∈ PAut (cfiCode G) := ...
```

**Acceptance:** theorem compiles; uses helper lemmas about parity bit
preservation under vertex permutation.

#### F3c — `cfiCode` PAut = graph Aut (reverse) · L · 12 h

**Files:** same.

**Approach:** the harder direction — every code automorphism comes from
a graph automorphism. This is the core CFI rigidity argument: parity-bit
symmetries decouple from vertex permutations only via graph
automorphisms.
```lean
theorem cfiCodeAut_to_graphAut (G : Graph) (π ∈ PAut (cfiCode G)) :
    ∃ σ : G.Aut, π = liftToCode σ := ...
```

**Acceptance:** theorem compiles, zero sorry; proof is ≤ 200 lines.

#### F3d — Wire into `GIReducesToCE` witness · M · 4 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean` (extend), same.

**Approach:** assemble F3b + F3c into the actual reduction.
```lean
theorem GIReducesToCE_proved : GIReducesToCE := by
  intro G H
  refine ⟨cfiCode G, cfiCode H, ?_, ?_, ?_⟩
  · -- encoding is uniform / poly-time (Prop only)
  · -- graph iso → code equivalence (F3b)
  · -- code equivalence → graph iso (F3c)
```

**Acceptance:**
- Module builds.
- `GIReducesToCE_proved` compiles, zero sorry.
- Cited in `docs/HARDNESS_ANALYSIS.md` as the formalised reduction.
- E4 can swap its hypothesis for this concrete witness.

**Dependencies:** F3a → F3b, F3a → F3c (parallelisable), F3a/b/c → F3d.
Total: 8 + 12 + 12 + 4 = 36 h (under 40 h budget).

**Risk:** XL — this is phase-sized research. The CFI rigidity argument
(F3c) is the bottleneck and has no Mathlib precedent. May need to
abstract over the gadget and prove rigidity for a class.

### F4 — Concrete GI ≤ TI reduction (F-09 step 2) · XL · 40 h

**Parent goal:** prove `GIReducesToTI` concretely via the symmetric
3-tensor encoding of graphs.

#### F4a — `adjacencyToTensor3` encoding · M · 6 h

**Files:** new `Orbcrypt/Hardness/AdjacencyToTensor.lean`

**Approach:** define a symmetric 3-tensor `T_G[i][j][k] := if (i,j) ∈ E ∧ (j,k) ∈ E ∧ (i,k) ∈ E then 1 else 0`
(triangle-indicator tensor). Standard graph-to-tensor encoding.

**Acceptance:** module builds; encoding has docstring + sanity lemma
(symmetry under index permutation).

#### F4b — Forward direction: graph iso → tensor iso · L · 12 h

**Files:** same.

**Approach:** show every graph automorphism (vertex permutation
preserving adjacency) induces the diagonal action `(σ, σ, σ)` on the
triangle tensor.
```lean
theorem graphIso_implies_tensorIso (G H : Graph) :
    G ≃g H → AreTensorIsomorphic (adjacencyToTensor3 G) (adjacencyToTensor3 H) := ...
```

**Acceptance:** theorem compiles, zero sorry.

#### F4c — Reverse direction: tensor iso → graph iso · L · 16 h

**Files:** same.

**Approach:** the harder direction. From a tensor isomorphism
`(g₁, g₂, g₃) • T_G = T_H`, recover a vertex permutation. The trick is to
restrict to the diagonal: the triangle indicator's marginals encode the
degree sequence, which constrains the GL action to be permutation-like.

```lean
theorem tensorIso_implies_graphIso (G H : Graph)
    (h : AreTensorIsomorphic (adjacencyToTensor3 G) (adjacencyToTensor3 H)) :
    G ≃g H := ...
```

**Acceptance:** theorem compiles, zero sorry; proof ≤ 250 lines.

#### F4d — Wire into `GIReducesToTI` witness · M · 6 h

**Files:** `Orbcrypt/Hardness/TensorAction.lean` (extend), same.

**Approach:** assemble F4b + F4c into the actual reduction.
```lean
theorem GIReducesToTI_proved : GIReducesToTI := by
  intro G H
  exact ⟨adjacencyToTensor3 G, adjacencyToTensor3 H,
         graphIso_implies_tensorIso, tensorIso_implies_graphIso⟩
```

**Acceptance:**
- Module builds.
- `GIReducesToTI_proved` compiles, zero sorry.
- E4 can swap its hypothesis for this concrete witness.

**Dependencies:** F4a → F4b, F4a → F4c (parallelisable), F4a/b/c → F4d.
Total: 6 + 12 + 16 + 6 = 40 h.

**Risk:** XL — F4c is the bottleneck. The "constrain GL to permutation"
argument requires that the tensor's marginal structure determines the
action up to permutation. May need a stronger encoding (e.g.,
"colored" triangle tensor) if rigidity fails for the simple version.

### F5 — Non-trivial `CommGroupAction` witness (F-14) · XL · 30 h

**Parent goal:** at least one cryptographically meaningful (or at least
non-trivial) `CommGroupAction` instance. Decompose into tiered
sub-units; only Tier 1 is practical without a Mathlib elliptic-curve
API.

#### F5a — Tier 1: `ZMod N` acting on `ZMod N × ZMod N` · M · 4 h

**Files:** new `Orbcrypt/PublicKey/ZModAction.lean`

**Approach:**
```lean
instance zModSelfAction (N : ℕ) [NeZero N] :
    CommGroupAction (ZMod N) (ZMod N × ZMod N) where
  smul a p := (a + p.1, a + p.2)
  ...
  comm := fun a b p => by simp [add_comm, add_left_comm]
```

**Acceptance:**
- Module builds.
- Instance is a non-self-action witness.
- `CommOrbitPKE` instantiated with it builds.
- Docstring flags as "structural witness; offers no hardness."

#### F5b — Tier 2: class-group action skeleton · XL · 16 h

**Files:** new `Orbcrypt/PublicKey/ClassGroupAction.lean`

**Approach:** stub the structure of a class-group `Cl(O)` acting on a
set of supersingular elliptic curves over `F_p`. Without a full Mathlib
elliptic-curve formalization, this remains a *signature*: the class
group is given as an abstract `CommGroup`, the curve set as an abstract
`Type`, and the action as a parameter satisfying `comm`. The structure
matches CSIDH but without realising any specific curve.

**Acceptance:**
- Module builds.
- Skeleton has docstring citing CSIDH (Castryck–Lange–Martindale–Panny–Renes 2018).
- Marked as "abstract; concrete instance pending Mathlib elliptic-curve API."

#### F5c — Tier 3: CSI-DLP hardness Prop · L · 10 h

**Files:** same.

**Approach:** define `CSIDLPHardness (Cl_O : CommGroup) (E : Type) [action] (ε : ℝ) : Prop`
as the assumption that no PPT adversary, given `(E, a • E)`, can recover
`a` with advantage > ε. Mirrors `ConcreteOIA` style.

**Acceptance:**
- Definition compiles.
- Documented as a *cryptographic hardness assumption*, not a proof.

**Dependencies:** F5a is independent; F5b extends it; F5c extends F5b.
Tier 1 (F5a) is the only sub-unit budgeted on the critical path; F5b/c
are explicitly research-grade.

**Risk:** Tier 1 is low risk. Tier 2/3 require Mathlib elliptic-curve
machinery that does not yet exist; treat as open research.

### F6 — Additional separating-invariant screening (F-21) · L · 12 h

**Parent goal:** add screening defenses for invariants beyond Hamming
weight. Decompose into one sub-WU per invariant.

#### F6a — Weight enumerator screening · M · 4 h

**Files:** new `Orbcrypt/Construction/InvariantScreening.lean`

**Approach:**
```lean
def weightEnumerator (C : Finset (Bitstring n)) : Fin (n+1) → ℕ :=
  fun w => (C.filter (fun x => hammingWeight x = w)).card

theorem weightEnumerator_invariant_subgroup
    (G : Subgroup (Equiv.Perm (Fin n))) ... :
    IsGInvariant (weightEnumerator ...) := ...

theorem same_weight_enumerator_not_separating
    (scheme : OrbitEncScheme G ...)
    (hAll : ∀ m, weightEnumerator ... = weightEnumerator ...) :
    ¬ IsSeparating (weightEnumerator ∘ ...) ... := ...
```

**Acceptance:** module builds; three declarations; docstring cites
Singleton bound and weight-enumerator literature.

#### F6b — Dual code minimum distance screening · M · 4 h

**Files:** same.

**Approach:** mirror F6a for the dual code's minimum distance.
```lean
def dualMinDistance (C : Finset (Bitstring n)) : ℕ := ...
theorem same_dualMinDistance_not_separating ... := ...
```

**Acceptance:** as F6a.

#### F6c — Automorphism-group order signature screening · M · 4 h

**Files:** same.

**Approach:**
```lean
def autGroupOrder (C : Finset (Bitstring n)) : ℕ := (PAut C).toFinset.card
theorem same_autGroupOrder_not_separating ... := ...
```

**Acceptance:** as F6a; `CLAUDE.md` threat-model coverage table extended
with the three new defenses.

**Dependencies:** F6a/b/c are independent and can ship in parallel.
Total: 4 + 4 + 4 = 12 h.

**Risk:** low. The theorems are structural analogues of
`same_weight_not_separating`.

---

## 10. Workstream G — Documentation & Transparency

**Goal:** keep `CLAUDE.md`, `docs/DEVELOPMENT.md`, `docs/COUNTEREXAMPLE.md`, and
`Orbcrypt.lean` in sync as Workstreams A–F land. This is a standing
workstream — each other WU has a doc obligation (see §3.3.5), and
Workstream G collects the cross-cutting doc changes.

### G1 — CLAUDE.md: add `CombineImpossibility.lean` to source layout (A8 companion) · XS · 10 min

**Files:** `CLAUDE.md`

**Problem:** the Phase 13 public-key source layout lists three files
(`ObliviousSampling`, `KEMAgreement`, `CommutativeAction`) but not
`CombineImpossibility.lean`, which was added later.

**Approach:** add the missing file and its role description (4-th Phase
13 entry). Add theorem #s to the headline table if additional public
theorems from the file warrant it (audit notes 3+ headline-worthy
theorems in that file: `combine_section_form`,
`equivariant_combiner_breaks_oia`, `oia_forces_combine_constant_on_orbit`,
`oblivious_sample_equivariant_obstruction`).

**Acceptance:** `CLAUDE.md` diff applies cleanly; on-disk module count
matches table.

### G2 — docs/DEVELOPMENT.md: "Vacuity Map" section · S · 2 h

**Files:** `docs/DEVELOPMENT.md`

**Approach:** add a new section (suggested: §9 "Formalization Vacuity
Map") summarizing audit §5.1 and Workstream E's resolution. Include:
- Table of deterministic vs. probabilistic theorems.
- The ConcreteOIA(1) satisfiability note.
- Cross-reference to `Crypto/OIA.lean` module docstring.
- Note that this audit and its workstream plan exist at
  `docs/audits/LEAN_MODULE_AUDIT_2026-04-18.md` and
  `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`.

**Acceptance:** docs/DEVELOPMENT.md builds (no markdown errors); the new
section is discoverable from the TOC.

### G3 — Phase doc: `PHASE_14_AUDIT_RESOLUTION.md` · S · 2 h

**Files:** new `docs/planning/PHASE_14_AUDIT_RESOLUTION.md` (if chosen),
or extend `docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md`.

**Approach:** record the meta-phase: "Phase 14 = resolve
`LEAN_MODULE_AUDIT_2026-04-18` via the workstream plan at
`docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`." Keep this file tight
(~50 lines): status board (which WUs have landed), commit hashes, build
verification results.

**Acceptance:** file exists; status reflects reality; links to this
document.

### G4 — Orbcrypt.lean axiom-transparency: hardness-parameter Props (A8 companion) · S · 1 h

**Files:** `Orbcrypt.lean`

**Approach:** following A8, add a "Hardness parameter Props" section in
the axiom transparency report listing:
- `GIReducesToCE` / `GIReducesToTI` — reduction claims, not proofs
- `TensorOIAImpliesCEOIA` / `CEOIAImpliesGIOIA` / `GIOIAImpliesOIA`
- `HardnessChain`

For each: note "This is a Prop parameter. Callers supplying it
effectively assume the reduction. See `docs/HARDNESS_ANALYSIS.md` for
the literature basis." After Workstream F lands, update the entries
whose reductions are now proved.

**Acceptance:** root file builds; new section is clear and cross-linked.

---

## 11. Cross-cutting Verification Protocol

Every WU ends with a uniform verification checklist. The CI workflow is
not sufficient — it builds the root target, which misses modules not
reachable from `Orbcrypt.lean`'s import tree. Per-module verification is
mandatory per `CLAUDE.md`.

### 11.1 Per-WU verification script

Run this after every commit:

```bash
# 1. Build the specific module(s) the WU touched
source ~/.elan/env
for mod in $TOUCHED_MODULES; do
  lake build "$mod" || { echo "FAIL: $mod"; exit 1; }
done

# 2. Confirm no sorry surfaces
grep -Prn "(^|[^A-Za-z_])sorry([^A-Za-z_]|$)" Orbcrypt/ --include="*.lean" \
  | grep -v '/-.*sorry.*-/' && { echo "FAIL: sorry found"; exit 1; } || true

# 3. Confirm no custom axiom added
grep -Prn "^axiom\s+\w+\s*[\[({:]" Orbcrypt/ --include="*.lean" \
  && { echo "FAIL: axiom found"; exit 1; } || true

# 4. If WU touches a headline theorem, dump its axioms
if [ -n "$HEADLINE_THEOREM" ]; then
  echo "#print axioms $HEADLINE_THEOREM" \
    | lake env lean --stdin 2>&1 \
    | grep -E "propext|Classical|Quot\.sound" \
    || echo "WARN: unexpected axioms"
fi
```

### 11.2 Workstream-level regression gate

Before closing any workstream, run the full-tree build once:

```bash
source ~/.elan/env && lake build 2>&1 | tail -80
```

Exit code 0 is required. If any module compiled via WU edits is not
reachable from `Orbcrypt.lean`, add the import to the root file (and to
`CLAUDE.md`'s module listing) as part of that WU — do not defer.

### 11.3 Axiom-transparency regression

After E9 lands, the `Orbcrypt.lean` axiom transparency report becomes the
canonical "what is vacuous vs. what is real" document. Each subsequent
WU must preserve the accuracy of that report.

### 11.4 Documentation sync check

Each workstream must leave the five ownership docs consistent:

| Doc | Owns | Must match |
|-----|------|------------|
| `CLAUDE.md` | Dev guidance, project status, module list | On-disk tree, headline theorem list |
| `docs/DEVELOPMENT.md` | Scheme design, security proofs | Lean theorem statements |
| `docs/dev_history/formalization/FORMALIZATION_PLAN.md` | Lean architecture | Module dependency graph in `Orbcrypt.lean` |
| `docs/HARDNESS_ANALYSIS.md` | Literature basis | Prop parameters in `Hardness/` |
| `Orbcrypt.lean` module docstring | Axiom report | `#print axioms` of every headline theorem |

---

## 12. Risks & Mitigations

### 12.1 Risk matrix

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Mathlib API drift during WU work | Low (pinned to `fa6418a8`) | Low | Keep the pin; never bump inside a WU. |
| E2 tensor PMF machinery hard to express | Medium | Medium | Fallback to Prop-quantified distributions as noted in E2. |
| E4 advantage-loss arithmetic (additive vs. multiplicative) disagrees with literature | Medium | Low | Start additive; document; tighten in a follow-up after E lands. |
| `verify_inj` field break retroactively invalidates a downstream MAC consumer | Low (grep confirms zero consumers today) | Low | Audit consumers as part of C1. |
| D1 `_symm` proof requires unforeseen Mathlib surface | Medium | Low | Fallback: state `_symm` with an explicit bijectivity hypothesis, defer the derivation-from-`hcard` to a follow-up. |
| E6 lower-bound proof is computationally intricate | Medium | Medium | Fallback: prove the weaker `∃ pos-bound` variant; file a follow-up for the concrete bound. |
| F3 / F4 reductions are phase-sized and slip | High | Low (does not block Workstream E) | Keep them outside the critical path; they're improvements, not prerequisites. |
| E7 product PMF requires new Mathlib contribution upstream | Low | High (would block E8) | Before E7, spike ≤ 1 day to confirm viability on pinned Mathlib; if blocked, file an upstream issue and defer E8 to a future phase. |
| Documentation drift between Workstream landings | High | Medium | Per-WU §11.4 doc-sync check is mandatory. |
| A7 helper extraction breaks universe inference | Low | Low | Back out the helpers; keep the inline `@`-qualified form. |
| A6b / D3 set-identity proof fails | Low (D1+D2 land first) | Low | Keep A6a's rename; defer A6b as optional. |

### 12.2 Categories of failure to avoid

1. **Breaking-change creep.** Adding a field to a Lean `structure` is a
   breaking positional-constructor change. Before every such change, grep
   the tree for constructor callers and update them *in the same WU*.
   Never leave the tree in a half-broken state across commits.

2. **Hidden axiom introduction.** A WU that refactors a proof must
   leave `#print axioms` unchanged for every headline theorem it
   touches. If standard Lean axioms (`propext`, `Classical.choice`,
   `Quot.sound`) grow, document the reason. If a **custom** axiom
   appears (forbidden), revert.

3. **Vacuity regression.** When adding a new Prop parameter in
   Workstream E or F, verify it is satisfiable. Mirror the existing
   `concreteOIA_one` pattern: accompany every new indistinguishability
   Prop with a trivial `_one` satisfiability lemma.

4. **Module-path silent failures.** `lake build` (default) only builds
   what's imported by `Orbcrypt.lean`. A new module that slips past the
   root import will silently pass CI. Every new module added by a WU
   must land in `Orbcrypt.lean`'s import list and `CLAUDE.md`'s
   dependency graph.

5. **Forgotten docstrings.** `autoImplicit := false` catches many errors;
   missing docstrings on public declarations do not. The §3.3.3
   acceptance gate is mandatory.

### 12.3 Rollback strategy

Each WU is a single commit, producing a single clean revert target.
Workstream E's WUs are interdependent (E3 needs E2, E4 needs E3, etc.):
rollback at the workstream granularity — revert E1 through E9 as a unit
if any one is found broken after merge. This is why each WU is scoped
small and independently buildable: rollback costs scale with WU count,
not WU size.

---

## 13. Acceptance Criteria Summary (all WUs)

### 13.1 Definition of Done, per WU

A WU is **Done** iff *all five* of the following hold:

1. **Build:** `lake build <every module touched>` exits 0.
2. **No regressions:** `lake build` (full tree) exits 0.
3. **No sorry, no custom axiom:** hardened greps from §11.1 return empty.
4. **Docstrings:** every public `def` / `theorem` / `structure` /
   `instance` / `abbrev` added or edited carries a `/-- ... -/` docstring.
5. **Docs synced:** `CLAUDE.md`, `Orbcrypt.lean`, and the relevant phase
   doc reflect the new state per the ownership matrix in §11.4.

### 13.2 Definition of Done, per Workstream

A Workstream is **Done** iff:

- All its WUs are Done.
- A dedicated commit updates `CLAUDE.md`'s "Active development status"
  block to mark the workstream complete with the closing commit hash.
- The workstream's doc WU (G1–G4 as applicable) has landed.

### 13.3 Definition of Done, overall plan

The plan is **Done** iff:

- Workstreams A–E are Done. (F is long-running research; it runs in
  parallel with later phase work and is not required for plan closure.)
- The root `Orbcrypt.lean` axiom transparency report has been regenerated
  (E9) and every headline theorem is classified as "non-vacuous" or
  "vacuous under deterministic OIA, see probabilistic companion".
- No theorem in the codebase carries the vacuous-only disclaimer without
  a non-vacuous companion.
- The audit's §8 recommendations are each either:
  (a) resolved by a landed WU, or
  (b) explicitly deferred with a follow-up plan link.

---

## 14. Recommended Sequencing Timeline

The following is a **recommended** ordering, not a required one. It
maximises landing-velocity in the early days while de-risking the large
Workstream E.

### 14.1 Day 0 — "afternoon of fixes" (Workstream A, ~ 4 h)

Land A1 → A2 → A3 → A8 → A4 → A6a → A5 → A7 in eight separate commits.
All independent. Every one is a net-positive quality-of-life win with
near-zero risk. Close Workstream A.

### 14.2 Days 1–3 — "model refinement" (Workstreams B, C, G1, G4)

In parallel across three engineering sessions:
- B1 → B2 → B3 (adversary + family refinements, ~8 h)
- C1 → C2 → C3 → C4 (MAC integrity, ~12 h)
- G1, G4 (doc updates, ~2 h)

These touch disjoint modules; they can interleave freely.

### 14.3 Days 4–6 — "CE API" (Workstream D)

D1 → D2 → D4 → D3 (~14 h). D3 is optional; stop at D4 if time-boxed.

### 14.4 Days 7–20 — "the big lift" (Workstream E)

This is the critical path. The following sub-WU ordering reflects the
decomposition in §8.

**Track 1 (PMF foundations) — sequential:**
1. E7a → E7b → E7c (product PMF, hybrids — 6 h)

**Track 2 (KEM probabilistic security) — sequential:**
2. E1a → E1b → E1c → E1d (ConcreteKEMOIA — 6 h)

**Track 3 (Concrete OIA family) — three parallel leaves:**
3. E2a, E2b, E2c (Concrete{CE,Tensor,GI}OIA — 8 h, parallelisable to ~3 h)

**Track 4 (Reductions + chain) — sequential after Track 3:**
4. E3-prep (encoding interface — 1 h)
5. E3a, E3b, E3c parallel (≤ 3 h with parallel)
6. E3d (composition sanity — 1 h)
7. E4a → E4b → E4c (ConcreteHardnessChain — 4 h)
8. E5 (chain → IND-1-CPA — 3 h)

**Track 5 (Combiner + multi-query) — needs Tracks 1, 2:**
9. E6a → E6b → E6c (probabilistic combiner no-go — 6 h)
10. E8a → E8b → E8c → E8d (multi-query, needs E7 + B3 — 8 h)

**Track 6 (Transparency closure):**
11. E9 + G2 (axiom transparency + vacuity-map doc — 4 h)

Total: ~55 h sequential, ~30 h with Tracks 1/2/3 parallelised across
~2 engineering streams.

### 14.5 After Workstream E — close out G2, G3

Land the docs/DEVELOPMENT.md vacuity-map (G2) and the PHASE_14_AUDIT_RESOLUTION
doc (G3). This is the formal plan closure point.

### 14.6 Workstream F — open-ended

F1 (HGOE expansion, XL), F3/F4 (reductions, XL), F5 Tier 2/3
(CommGroupAction, XL) are each phase-sized. Schedule them as their own
phase docs (`PHASE_15_*.md`, `PHASE_16_*.md`). F2 (M, 6 h) and F5 Tier 1
(M, 4 h) can land earlier if time permits. F6 (L, 12 h) fits comfortably
in a single work-week.

### 14.7 Milestone map

| Milestone | Deliverables | Date target (from start) |
|-----------|-------------|--------------------------|
| M1: Quick fixes landed | Workstream A complete | Day 0 |
| M2: Refinements in | Workstreams B, C, D complete | Day 6 |
| M3: Non-vacuous security | Workstream E complete, G2 updated | Day 20 |
| M4: Plan closure | G3 phase doc landed, audit resolved | Day 22 |
| M5: Research deliverables | Workstream F (as separate phases) | Open |

---

## 15. Appendix A — Finding → Work Unit Mapping (full)

Every audit finding resolves to at least one WU. The table is
sorted by finding id for direct audit traceability.

| Finding | Severity | Primary WU(s) | Supporting WU(s) | Status after plan completion |
|---------|----------|---------------|------------------|-------------------------------|
| F-01 | High (vacuity) | E5 (probabilistic chain conclusion), E9 (axiom map) | E1, E2, E3, E4 | Vacuity documented; probabilistic companion theorem established |
| F-02 | Low | B1 (IsSecureDistinct) · **LANDED** | B3 (distinct multi-query wrapper) · **LANDED**; E8 (multi-query uses it) | Both variants coexist; downstream theorems can opt-in |
| F-03 | Low | A1 (hardened regex) | — | CI robust to docstring prose |
| F-04 | Low | A2 (`push_neg`) | — | Idiomatic Mathlib style |
| F-05 | Info | F1 (concrete HGOE expansion) | F2 (seed secrecy) | Open (research); honest gap flagged in docs |
| F-06 | Low | F2 (SampleGroupSpec) | — | Secrecy obligation surfaced |
| F-07 · **LANDED** | Medium | C1 (verify_inj) · **LANDED**, C2 (INT_CTXT proof) · **LANDED** | C3 (headline listing) · **LANDED**, C4 (witness) · **LANDED** | INT_CTXT proved for honest composition (given orbit-cover hypothesis); Carter–Wegman witness provided |
| F-08 · **LANDED** | Info | D1 (symm/trans) · **LANDED**, D2 (Subgroup) · **LANDED** | D3 · **LANDED**, D4 · **LANDED** | Full equivalence API + Mathlib integration |
| F-09 | High | E3 (probabilistic reductions as Props) | F3, F4 (concrete proofs, research) | Prop-level sharp; concrete proofs as research deliverable |
| F-10 | High | E1 (ConcreteKEMOIA), E2 (concrete hardness OIAs) | E6, E9 | Every OIA variant has probabilistic companion |
| F-11 | Info | E8 (IND-Q-CPA via hybrid) | E7 (product PMF) | Multi-query theorem proved |
| F-12 | Info | A8 (doc), E4 (actually consume them) | — | Props consumed by ConcreteHardnessChain |
| F-13 | Low | A7 (helper defs) | — | Readable Comp* definitions |
| F-14 | Info | F5 Tier 1 (trivial non-self witness) | F5 Tier 2/3 (CSIDH) | Structural witness present; cryptographic witness is research |
| F-15 | Low | B2 (explicit universes) · **LANDED** | — | SchemeFamily universe-clean |
| F-16 · **LANDED** | Low | A6a (rename) · **LANDED**, A6b/D3 (prove set identity) · **LANDED** | — | Name accurate; set identity proved via D3 |
| F-17 | Info (documented) | E6 (probabilistic combiner bound) | E1 | Non-vacuous quantitative bound |
| F-18 | Info | A3 (rename shadow) | — | No shadowed binding |
| F-19 | Info | A5 (strengthen to bi-view identity) | — | Theorem carries real content |
| F-20 | High | E5 (concrete chain conclusion), E9 (axiom map) | E3, E4 | Non-vacuous hardness-to-security transfer |
| F-21 | Info | F6 (screen additional invariants) | — | Extended threat-model coverage |
| F-22 | Low | A4 (pin elan SHA-256) | — | CI install is integrity-checked |

### 15.1 Traceability: every finding is covered by at least one WU

```
F-01 → E1, E2, E3, E4, E5, E9     (probabilistic companion + vacuity map)
F-02 → B1                         (IsSecureDistinct)
F-03 → A1                         (CI regex)
F-04 → A2                         (push_neg)
F-05 → F1                         (HGOE expansion — research)
F-06 → F2                         (SampleGroupSpec)
F-07 → C1, C2, C3, C4             (MAC integrity + INT_CTXT)
F-08 → D1, D2, D3, D4             (CE API)
F-09 → E3, F3, F4                 (Prop-level in E; concrete in F)
F-10 → E1, E2, E6, E9             (probabilistic OIA family)
F-11 → E7, E8                     (multi-query)
F-12 → A8, E4                     (document + consume)
F-13 → A7                         (helpers)
F-14 → F5                         (CommGroupAction witness)
F-15 → B2                         (universes)
F-16 → A6a, A6b                   (rename + optional strengthen)
F-17 → E6                         (probabilistic combiner)
F-18 → A3                         (shadow)
F-19 → A5                         (bi-view identity)
F-20 → E5, E9                     (probabilistic chain)
F-21 → F6                         (additional invariants)
F-22 → A4                         (SHA pin)
```

No finding is orphaned; no WU addresses a non-existent finding.

### 15.2 Inverse map: atomic WU → findings (post-decomposition)

| WU | Effort | Covers | One-line purpose |
|----|--------|--------|------------------|
| **A — Immediate fixes (8 atomic)** | | | |
| A1 | 10 m | F-03 | Harden CI `sorry` regex |
| A2 | 5 m | F-04 | `push Not` → `push_neg` |
| A3 | 10 m | F-18 | Remove shadowed `hn_pos` |
| A4 | 30 m | F-22 | Pin elan SHA-256 in CI |
| A5 | 45 m | F-19 | Strengthen `kem_agreement_correctness` to bi-view identity |
| A6 | 1 h | F-16 | Rename `paut_coset_is_equivalence_set` (+ optional set identity) |
| A7 | 1 h | F-13 | Helper `def`s in CompOIA/CompSecurity |
| A8 | 20 m | F-12 | Document hardness-parameter Props |
| **B — Adversary refinements (5 atomic)** · **ALL LANDED** | | | |
| B1a · **LANDED** | 45 m | F-02 | Define `hasAdvantageDistinct`/`IsSecureDistinct` |
| B1b · **LANDED** | 30 m | F-02 | Prove `IsSecure → IsSecureDistinct` |
| B1c · **LANDED** | 30 m | F-02 | Docstring + audit traceability |
| B2 · **LANDED** | 1 h | F-15 | Explicit universes on `SchemeFamily` |
| B3 · **LANDED** | 4 h | E8 prereq (F-02 multi-query) | Per-query distinct adversary wrapper + `perQueryAdvantage` |
| **C — MAC INT_CTXT (6 atomic)** · **ALL LANDED** | | | |
| C1 · **LANDED** | 2 h | F-07 step 1 | Add `verify_inj` to MAC |
| C2a · **LANDED** | 45 m | F-07 step 2a | `verify` false branch lemma (`authDecaps_none_of_verify_false`) |
| C2b · **LANDED** | 1 h 15 m | F-07 step 2b | Key-uniqueness lemma (`keyDerive_canon_eq_of_mem_orbit`) — chose Option B (hypothesis-threaded) rather than structure field |
| C2c · **LANDED** | 1 h | F-07 step 2c | Assemble `authEncrypt_is_int_ctxt` — carries `hOrbitCover` hypothesis |
| C3 · **LANDED** | 20 m | F-07 step 3 | Wire into headline theorem list (#19, #20) and axiom transparency report |
| C4 · **LANDED** | 3 h | F-07 witness | Concrete MAC instance (`deterministicTagMAC` + `carterWegmanMAC` + `carterWegmanMAC_int_ctxt`) |
| **D — CE API (8 atomic)** · **ALL LANDED** | | | |
| D1a · **LANDED** | 1 h 30 m | F-08 helper | `permuteCodeword` self-bijection lemma |
| D1b · **LANDED** | 1 h | F-08 | `arePermEquivalent_symm` (via `permuteCodeword_inv_mem_of_card_eq` helper) |
| D1c · **LANDED** | 30 m | F-08 | `arePermEquivalent_trans` |
| D2a + D2b · **LANDED** | 2 h | F-08 | `PAutSubgroup` (single-commit; `paut_inv_closed` discharges `inv_mem'` from D1a) |
| D2c · **LANDED** | 30 m | F-08 | `PAut_eq_PAutSubgroup_carrier` (rfl) + `mem_PAutSubgroup` simp lemma |
| D3 · **LANDED** | 4 h | F-16 (extended) | `paut_equivalence_set_eq_coset` — full set identity |
| D4 · **LANDED** | 1 h | F-08 | `arePermEquivalent_setoid` instance over `{C // C.card = k}` |
| **E — Probabilistic chain (28 atomic)** | | | |
| E1a | 1 h 30 m | F-10 | `kemEncapsDist` PMF push-forward |
| E1b | 1 h | F-10 | `ConcreteKEMOIA` + `_one` lemma |
| E1c | 1 h 30 m | F-10 | `det_kemoia_implies_concreteKEMOIA_zero` bridge |
| E1d | 2 h | F-10 | `concrete_kemoia_implies_secure` |
| E2a | 2 h 30 m | F-10 | `ConcreteCEOIA` + `codeOrbitDist` |
| E2b | 3 h | F-10 | `ConcreteTensorOIA` + `tensorOrbitDist` |
| E2c | 2 h 30 m | F-10 | `ConcreteGIOIA` + `graphOrbitDist` |
| E3-prep | 1 h | F-09 | `OrbitPreservingEncoding` interface |
| E3a | 2 h 30 m | F-09, F-20 | `ConcreteTensorOIAImpliesConcreteCEOIA` Prop |
| E3b | 2 h 30 m | F-09, F-20 | `ConcreteCEOIAImpliesConcreteGIOIA` Prop |
| E3c | 2 h 30 m | F-09, F-20 | `ConcreteGIOIAImpliesConcreteOIA` Prop |
| E3d | 1 h | F-20 | Sanity composition `_zero_*` lemma |
| E4a | 1 h | F-20 | `ConcreteHardnessChain` structure |
| E4b | 2 h 30 m | F-20 | `concreteOIA_from_chain` proof |
| E4c | 30 m | F-20 | `ConcreteHardnessChain.tight` constructor |
| E5 | 3 h | F-20 | `concrete_hardness_chain_implies_1cpa_advantage_bound` |
| E6a | 2 h | F-17 | `combinerOrbitDist`, `combinerDistinguisherAdvantage` |
| E6b | 2 h | F-17 | Lower bound from non-degeneracy |
| E6c | 1 h 30 m | F-17 | Combine into headline theorem |
| E7a | 2 h | F-11 prereq | `uniformPMFTuple` |
| E7b | 2 h 30 m | F-11 prereq | `probEventTuple`, `advantageTuple`, marginals |
| E7c | 1 h 30 m | F-11 prereq | `hybridDist` interpolation |
| E8a | 1 h | F-11 | `indQCPAAdvantage` definition |
| E8b | 2 h 30 m | F-11 | Single-step hybrid lemma |
| E8c | 2 h 30 m | F-11 | Telescope to `indQCPA_bound_via_hybrid` |
| E8d | 30 m | F-11 | Q = 1 regression check |
| E9 | 2 h | F-01, F-10, F-17, F-20 | Axiom transparency + vacuity map |
| **F — Implementation gaps (19 atomic)** | | | |
| F1a | 6 h | F-05 | `PRF` abstraction |
| F1b | 8 h | F-05 | `hgoeKeyFromExpansion` constructor |
| F1c | 6 h | F-05 | Correctness theorems |
| F1d | 6 h | F-05 | Integration with HGOEKEM |
| F2 | 6 h | F-06 | `SampleGroupSpec` interface |
| F3a | 8 h | F-09 | CFI gadget definition |
| F3b | 12 h | F-09 | `cfiCode` PAut = graph Aut (forward) |
| F3c | 12 h | F-09 | `cfiCode` PAut = graph Aut (reverse) |
| F3d | 4 h | F-09 | Wire into `GIReducesToCE` witness |
| F4a | 6 h | F-09 | `adjacencyToTensor3` encoding |
| F4b | 12 h | F-09 | Forward direction |
| F4c | 16 h | F-09 | Reverse direction |
| F4d | 6 h | F-09 | Wire into `GIReducesToTI` witness |
| F5a | 4 h | F-14 | Tier 1: `ZMod N` action witness |
| F5b | 16 h | F-14 | Tier 2: class-group skeleton |
| F5c | 10 h | F-14 | Tier 3: CSI-DLP hardness Prop |
| F6a | 4 h | F-21 | Weight enumerator screening |
| F6b | 4 h | F-21 | Dual code minimum distance screening |
| F6c | 4 h | F-21 | Automorphism-group order screening |
| **G — Documentation (4 atomic)** | | | |
| G1 | 10 m | meta | `CLAUDE.md`: add `CombineImpossibility.lean` |
| G2 | 2 h | meta | `docs/DEVELOPMENT.md` Vacuity Map section |
| G3 | 2 h | meta | `PHASE_14_AUDIT_RESOLUTION.md` status file |
| G4 | 1 h | meta | Axiom-transparency hardness-Props section |

**Atomic-WU total: 8 + 5 + 6 + 8 + 27 + 19 + 4 = 77** (matches §3.1).
Note that `A6` and `D3` are jointly-optional sub-WUs (A6 has both A6a
and A6b alternatives; D3 is the optional set-identity proof). The
mandatory-only count is `A6a` + 8 elsewhere = also 77 with A6b counted
once for either landing.

---

## 16. Appendix B — References and Cross-links

### 16.1 Audit and plan artifacts

- `docs/audits/LEAN_MODULE_AUDIT_2026-04-18.md` — the authoritative audit
  this plan addresses.
- `docs/audits/LEAN_MODULE_AUDIT_2026-04-14.md` — predecessor audit
  (F-22 carried over).
- `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` — this document.
- `docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` — broader improvement
  roadmap; Workstream F items may promote into this doc as their own
  phases.

### 16.2 Canonical ownership

Per `CLAUDE.md`:

| Doc | Canonical owner of |
|-----|---------------------|
| `docs/DEVELOPMENT.md` | Scheme specification, security proofs, hardness reductions |
| `docs/dev_history/formalization/FORMALIZATION_PLAN.md` | Lean 4 architecture and conventions |
| `docs/COUNTEREXAMPLE.md` | Invariant attack analysis |
| `docs/POE.md` | High-level concept exposition |
| `README.md` | Project status/description |
| `CLAUDE.md` | Development guidance for agents |

Every WU must respect these ownership boundaries when updating docs.

### 16.3 Lean-side headline theorems affected by this plan

The following headline theorems are mentioned in `CLAUDE.md`'s "Three
core theorems" table (renumbered 1–18 there). Workstream E either
adds probabilistic companions or updates the deterministic statements:

- Theorem 3 (`oia_implies_1cpa`) → E5 adds probabilistic companion.
- Theorem 5 (`kemoia_implies_secure`) → E1 adds `concrete_kemoia_implies_secure`.
- Theorem 14 (`hardness_chain_implies_security`) → E5 adds
  `concrete_hardness_chain_implies_1cpa_advantage_bound`.
- Theorem 16 (`kem_agreement_correctness`) → A5 strengthens.

After plan completion, `CLAUDE.md`'s table grows from 18 to ≥ 22
theorems (adding four probabilistic companions and `INT_CTXT`).

### 16.4 Terminology

- **Vacuous theorem.** A theorem whose hypothesis is unsatisfiable on
  any cryptographically interesting scheme; therefore the theorem's
  implication carries no information content on such schemes. Example:
  `oia_implies_1cpa` today. *Not* the same as "false" or "proof error".
- **Non-vacuous theorem.** A theorem whose hypothesis is satisfiable
  on at least some intended scheme instantiation. Example: `correctness`,
  `concrete_oia_implies_1cpa`.
- **Probabilistic companion.** A refined theorem that replaces a
  deterministic assumption with an ε-bounded probabilistic one, recovering
  non-vacuity.
- **WU** (Work Unit) — one focused code change, one commit, one
  acceptance gate.
- **Workstream** — a set of WUs sharing a theme.

---

## 17. Conclusion

This plan addresses every one of the 22 findings from the 2026-04-18
Lean module audit. No finding is erroneous: each was spot-checked
against the current tree (§2). The plan is structured to:

1. **Land quickly** the six small CI/style fixes (Workstream A) that
   improve project hygiene with near-zero risk.
2. **De-vacuise** the security theorem stack (Workstream E) — the
   single highest-value follow-up named by the audit itself.
3. **Fill composition gaps** (Workstreams C, D) so INT_CTXT and code
   equivalence have the algebraic machinery they need.
4. **Defer research-grade items** (Workstream F) into properly scoped
   future phases, never onto the critical path.
5. **Sync documentation continuously** (Workstream G) so that
   `CLAUDE.md`, `Orbcrypt.lean`, and `docs/DEVELOPMENT.md` never diverge
   from the Lean surface.

The plan preserves the project's zero-`sorry`, zero-custom-axiom
discipline. Every new theorem lands with a `#print axioms` check and a
docstring. Every new Prop lands with a satisfiability witness. Every
refactor preserves the full-tree `lake build` exit code.

**Single most important line in this plan:** after Workstream E lands,
no headline security theorem in Orbcrypt's Lean formalization will be
vacuously true on a cryptographically interesting scheme.

---

**End of workstream plan.**
