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

```
A (quick fixes) ──┐
                  ├── independent, can land immediately
B (defs)       ──┘

C (MAC/INT_CTXT) ── independent, unblocks future CCA work
D (CE API)       ── independent, enables F-09 research later

E (prob chain) ── depends on A2 (F-04 fix unblocks the Construction module),
                  builds on existing Phase 8 infrastructure
                  ├── E1 (ConcreteKEMOIA)  ── needed before E6
                  ├── E2 (Concrete*OIA family) ── independent leaves
                  ├── E3 (probabilistic reductions) ── needs E2
                  ├── E4 (ConcreteHardnessChain) ── needs E3
                  ├── E5 (final → IND-1-CPA) ── needs E4
                  ├── E6 (probabilistic combiner no-go) ── needs E1
                  ├── E7 (product PMF) ── independent prereq for E8
                  └── E8 (multi-query IND-Q-CPA) ── needs E7
F (research)   ── long-term; F3/F4 strengthen E4; F5 strengthens Phase 13
G (docs)       ── continuous; each workstream has a doc WU
```

### 3.1 Workstream summary

| WS | Title | WUs | Findings covered | Horizon | Total effort |
|----|-------|-----|------------------|---------|--------------|
| A | Immediate CI & Style Fixes | 8 | F-03, F-04, F-12, F-13, F-16, F-18, F-19, F-22 | Hours | ~6 h |
| B | Adversary & Family Type Refinements | 3 | F-02, F-15 | Hours–days | ~8 h |
| C | MAC Integrity & INT_CTXT | 4 | F-07 | Days | ~12 h |
| D | Code Equivalence API | 4 | F-08, F-16 (extension) | Days | ~14 h |
| E | Probabilistic Refinement Chain | 9 | F-01, F-10, F-11, F-17, F-20 | Weeks | ~60 h |
| F | Implementation Gaps (research) | 6 | F-05, F-06, F-09, F-14, F-21 | Months | ~180 h |
| G | Documentation & Transparency | 4 | cross-cutting, all | Continuous | ~8 h |
| — | **Total** | **38** | **22** | — | **~288 h** |

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
   is not "done" until `CLAUDE.md`, `DEVELOPMENT.md`, and the root
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

**Goal:** dispatch the seven lowest-risk findings in a single afternoon.
Every WU here is independent and can be landed in its own commit.

### A1 — Harden the CI `sorry` regex (F-03) · XS · 10 min

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

### A2 — Fix `push Not at h` (F-04) · XS · 5 min

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

### A3 — Remove shadowed `have hn_pos` (F-18) · XS · 10 min

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

### A4 — Pin elan SHA-256 in CI workflow (F-22) · S · 30 min

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

### A5 — Retire or strengthen `kem_agreement_correctness` (F-19) · S · 45 min

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

### A6 — Rename / strengthen `paut_coset_is_equivalence_set` (F-16) · S · 1 h

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

### A7 — Extract helper `def`s in Comp* modules (F-13) · S · 1 h

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

### A8 — Delete or consume `GIReducesTo*` (F-12) · XS · 20 min

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

**Goal:** tighten the adversary and scheme-family definitions in
`Crypto/Security.lean` and `Crypto/CompOIA.lean` so downstream probabilistic
theorems (Workstream E) can consume them cleanly.

### B1 — Introduce `IsSecureDistinct` predicate (F-02) · M · 3 h

**Files:** `Orbcrypt/Crypto/Security.lean`

**Problem:** `Adversary.choose` is unconstrained, so `(m, m)` is allowed.
`IsSecure` is therefore *stronger* than the classical IND-1-CPA game
(which requires `m₀ ≠ m₁`). Not a bug — but a documented asymmetry that
should be surfaced and, optionally, alternatively framed.

**Approach:**
1. Keep `Adversary` and `IsSecure` as-is (don't break existing theorems).
2. Add:
   ```lean
   def hasAdvantageDistinct [...] (scheme : OrbitEncScheme G X M)
       (A : Adversary X M) : Prop :=
     let (m₀, m₁) := A.choose scheme.reps
     m₀ ≠ m₁ ∧
     ∃ g₀ g₁ : G,
       A.guess scheme.reps (g₀ • scheme.reps m₀) ≠
       A.guess scheme.reps (g₁ • scheme.reps m₁)

   def IsSecureDistinct [...] (scheme : OrbitEncScheme G X M) : Prop :=
     ∀ A, ¬ hasAdvantageDistinct scheme A
   ```
3. Prove `IsSecure scheme → IsSecureDistinct scheme` as a one-liner
   (weaker game inherits security from stronger definition).
4. Update the docstring of `IsSecure` to cite the asymmetry.

**Acceptance:**
- `lake build Orbcrypt.Crypto.Security` exits 0.
- New definitions have full docstrings.
- `IsSecure_implies_IsSecureDistinct` theorem compiles (should be
  `intro A h; exact h ⟨_, _⟩`-style, ≤ 3 lines).
- `#print axioms IsSecure_implies_IsSecureDistinct` = standard Lean only.

**Risk:** the new definitions add API surface but do not change existing
theorems. Downstream effect limited to Workstream E6 (combiner no-go
refinement) which may prefer `IsSecureDistinct` for realism.

### B2 — Explicit universes on `SchemeFamily` (F-15) · S · 1 h

**Files:** `Orbcrypt/Crypto/CompOIA.lean:121–141`

**Problem:** `SchemeFamily` uses `G, X, M : ℕ → Type*` with implicit
universe polymorphism. `@`-qualified call sites do currently work, but any
downstream code that tries to instantiate in a specific universe meets
inference pain.

**Approach:**
1. Add an explicit universe declaration at module scope:
   ```lean
   universe u v w
   ```
2. Change `SchemeFamily`'s field types to
   `G : ℕ → Type u`, `X : ℕ → Type v`, `M : ℕ → Type w`.
3. Parameterise `SchemeFamily` by the three universe variables:
   `structure SchemeFamily.{u, v, w} where ...`.
4. Update consumer signatures in `CompOIA`, `CompSecurity`, and the
   forthcoming `ConcreteHardnessChain` (Workstream E4) to thread
   `{u v w}` explicitly.

**Acceptance:**
- `lake build Orbcrypt.Crypto.CompOIA` exits 0.
- `lake build Orbcrypt.Crypto.CompSecurity` exits 0.
- A new `examples/SchemeFamilyUniverseCheck.lean` (temporary) instantiates
  `SchemeFamily` at `(u, v, w) = (0, 0, 0)` and at `(1, 1, 1)` without
  errors.
- Delete the temporary example before commit; final commit carries only
  the universe annotations.

**Risk:** universe polymorphism regressions are Mathlib-sensitive. Run
`lake exe cache get` to hit the pinned Mathlib before rebuilding. If
inference errors arise, add explicit `.{u}` annotations at call sites.

### B3 — Add a per-query choose structure for multi-query groundwork (prereq for E8) · M · 4 h

**Files:** new `Orbcrypt/Crypto/MultiQueryAdversary.lean` (or extend
`Crypto/CompSecurity.lean`)

**Problem:** the current `MultiQueryAdversary` structure
(`CompSecurity.lean:195`) has a `choose : (M → X) → Fin Q → M × M` field,
but there is no `IsDistinct` obligation and no notion of per-query advantage.
Workstream E8 needs both.

**Approach:**
1. Add an optional `choose_distinct : ∀ i, (choose reps i).1 ≠ (choose reps i).2`
   *field* to `MultiQueryAdversary` (or package as a separate
   `DistinctMultiQueryAdversary` wrapper).
2. Define `perQueryAdvantage : MultiQueryAdversary → ℕ (query index) → ℝ`
   via an extraction that treats each query as a single-query scenario.
3. Prove `perQueryAdvantage_nonneg`, `perQueryAdvantage_le_one` as
   one-liners from `advantage_nonneg` / `advantage_le_one`.

**Acceptance:**
- `lake build Orbcrypt.Crypto.CompSecurity` exits 0 (or new file builds).
- Three new declarations carry docstrings.
- No new axioms surface in `#print axioms perQueryAdvantage_nonneg`.

**Risk:** the `Fin Q → M × M` structure forces `Q : ℕ` as an explicit
parameter — we already have it, so no universe pain.

---

## 6. Workstream C — MAC Integrity & INT_CTXT (F-07)

**Goal:** discharge F-07 — INT_CTXT is currently defined but unprovable
from the existing `MAC` abstraction. Add the missing uniqueness
requirement and prove INT_CTXT for an honestly-composed AuthOrbitKEM.

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
- `DEVELOPMENT.md` (AEAD section) references `verify_inj` as a MAC
  assumption.

**Risk:** downstream `authEncaps` / `authDecaps` should not change; they
only use `correct`. Spot-check required. If any construction MAC instances
exist outside `Orbcrypt/`, they must be extended too (audit scan shows
none).

### C2 — Prove `INT_CTXT` from `verify_inj` (F-07 step 2) · M · 3 h

**Files:** `Orbcrypt/AEAD/AEAD.lean`

**Problem:** INT_CTXT is currently a `Prop` definition with no proof for
any concrete composition.

**Approach:** prove

```lean
theorem authEncrypt_is_int_ctxt
    (akem : AuthOrbitKEM G X K Tag) :
    INT_CTXT akem := by
  intro c t hc_t_fresh
  -- Show authDecaps returns none: we need verify (derived_key) c t = false.
  -- Destructure authDecaps: if verify fails → none. If verify succeeds →
  -- by verify_inj, t = tag k c. But then c = encaps.1 and t = tag k c =
  -- (authEncaps akem g).2.2 for some g (the one that produced c), contradicting
  -- hc_t_fresh with that g.
  sorry
```

The full proof chain:
1. Unfold `authDecaps`.
2. `by_cases h : verify k c t = true`.
3. In the `false` branch: `authDecaps` returns `none` by definition.
4. In the `true` branch: by `verify_inj`, `t = tag k c`. Since `c` must
   equal `(authEncaps akem g).1` for some `g` to produce `k` via
   `decaps`, use `hc_t_fresh g` to derive `c ≠ (authEncaps akem g).1 ∨
   t ≠ (authEncaps akem g).2.2` and get a contradiction.

**Subtlety:** step 4 assumes that the MAC key `k = keyDerive (canon c)` is
unique per ciphertext. For a collision-free `canon` + `keyDerive`, this
holds. The theorem may need a `keyDerive_inj`-style hypothesis — to be
confirmed when the proof is written. **Must land with zero sorry.**

**Acceptance:**
- `lake build Orbcrypt.AEAD.AEAD` exits 0.
- `#print axioms authEncrypt_is_int_ctxt` = standard Lean only.
- The theorem takes only hypotheses that are already carried by a standard
  honest `AuthOrbitKEM` (MAC.verify_inj + canon-keyDerive injectivity);
  if a new hypothesis is needed, it is stated as an extra parameter, not
  an axiom.

**Risk:** canon/keyDerive injectivity is not currently a field of
`AuthOrbitKEM`. May need to land as a hypothesis, or lift to a stronger
`AuthOrbitKEM` with a `key_unique` field. Document the choice in the
theorem docstring.

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

**Goal:** turn `ArePermEquivalent` and `PAut` into first-class Mathlib-style
API with `symm`, `trans`, and `Subgroup` structure. Eliminates the gap at
F-08 and unblocks Workstream E's probabilistic CE refinements.

### D1 — `ArePermEquivalent.symm` and `_trans` (F-08 step 1) · M · 4 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Problem:** only `_refl` is proved. Without `_symm` and `_trans`,
equivalence-preserving reductions cannot be composed.

**Approach:** prove symmetry modulo the natural equal-cardinality side
condition:

```lean
theorem arePermEquivalent_symm
    [DecidableEq (Fin n → F)]
    (C₁ C₂ : Finset (Fin n → F))
    (hcard : C₁.card = C₂.card) :
    ArePermEquivalent C₁ C₂ → ArePermEquivalent C₂ C₁ := by
  rintro ⟨σ, hσ⟩
  refine ⟨σ⁻¹, ?_⟩
  intro c hc
  -- permuteCodeword σ⁻¹ c is in C₁ iff c = permuteCodeword σ (that preimage).
  -- Use injectivity of permuteCodeword σ on the finite C₁ and card equality
  -- to lift the one-sided map to a bijection.
  sorry

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

The `sorry` in `_symm` is intentional in the plan — the actual proof
requires `Finset.card_image_of_injective` + `Finset.eq_of_subset_of_card_le`
to lift the forward map to a bijection. **Must land with zero sorry.**

**Acceptance:**
- `lake build Orbcrypt.Hardness.CodeEquivalence` exits 0.
- No `sorry`; full proofs.
- Symm requires `hcard`; trans is unconditional.
- Docstrings cite the cardinality hypothesis.

**Risk:** the `_symm` direction needs Mathlib's `Finset` injectivity
machinery. Budget 4 h including research; fall-back is to state
`_symm` with a `bijective` hypothesis on `permuteCodeword σ|_{C₁}`
rather than deriving it from `hcard`.

### D2 — Promote `PAut` to `Subgroup (Equiv.Perm (Fin n))` (F-08 step 2) · M · 3 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean`

**Problem:** `PAut C` is a `Set`, not a `Subgroup`. Mathlib's subgroup
machinery (`.carrier`, `.mul_mem`, `.inv_mem`, quotient group,
Lagrange's theorem) is unavailable.

**Approach:**

```lean
/-- PAut as a subgroup of the full permutation group. -/
def PAutSubgroup (C : Finset (Fin n → F)) : Subgroup (Equiv.Perm (Fin n)) where
  carrier := PAut C
  mul_mem' := by intro σ τ hσ hτ; exact paut_mul_closed C σ τ hσ hτ
  one_mem' := paut_contains_id C
  inv_mem' := by
    intro σ hσ
    -- Need: σ ∈ PAut C → σ⁻¹ ∈ PAut C
    -- Finset of fixed size, σ|_C is a bijection, so σ⁻¹|_C is too.
    sorry
```

The `inv_mem'` direction needs the same finite-bijection argument as D1's
`_symm`. Share the helper lemma:

```lean
lemma permuteCodeword_bijection_of_self_preserving
    [DecidableEq (Fin n → F)]
    (C : Finset (Fin n → F)) (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C, permuteCodeword σ c ∈ C) :
    ∀ c ∈ C, permuteCodeword σ⁻¹ c ∈ C := by
  -- Standard finite set + injective self-map = bijection argument.
  sorry
```

**Must land with zero sorry.**

**Acceptance:**
- `lake build Orbcrypt.Hardness.CodeEquivalence` exits 0.
- `PAutSubgroup` definition + three field proofs land with no sorry.
- Existing `paut_contains_id` / `paut_mul_closed` retained (used by the
  field proofs).
- A theorem `PAut_eq_PAutSubgroup_coe : PAut C = (PAutSubgroup C : Set _)`
  exhibits the equivalence.

**Risk:** `inv_mem'` requires `[DecidableEq (Fin n → F)]` instance to be
available — already present from module context. Otherwise low risk.

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

**Goal:** thread Phase 8's `ConcreteOIA` / `CompOIA` framework through the
KEMOIA layer (F-10), the Phase 12 hardness chain (F-20), and the Phase 13
combiner no-go theorem (F-17). **After this workstream lands, no headline
security theorem will be vacuously true on any scheme with ≥ 2 orbit
representatives.**

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

**Files:** `Orbcrypt/KEM/Security.lean` (or new `Orbcrypt/KEM/CompSecurity.lean`)

**Approach:**
1. Define:
   ```lean
   def ConcreteKEMOIA [...] (kem : OrbitKEM G X K) (ε : ℝ) : Prop :=
     ∀ (D : X → K → Bool) (g₀ g₁ : G),
       advantage (fun p => D p.1 p.2)
         (kemEncapsDist kem g₀) (kemEncapsDist kem g₁) ≤ ε
   ```
   where `kemEncapsDist kem g := PMF.pure (encaps kem g)` lifted to account
   for the uniform group distribution (mirrors `orbitDist`).
2. Prove `det_kemoia_implies_concrete_zero` paralleling
   `det_oia_implies_concrete_zero`.
3. Define `kemIndCPAAdvantage (kem, A)` via `advantage`.
4. Prove `concrete_kemoia_implies_secure : ConcreteKEMOIA kem ε → ∀ A, kemIndCPAAdvantage kem A ≤ ε`.

**Acceptance:**
- New file / module builds.
- Four new declarations, all with docstrings.
- `#print axioms concrete_kemoia_implies_secure` = standard Lean only.
- A concrete trivial witness (`concrete_kemoia_one : ConcreteKEMOIA kem 1`)
  established.

**Risk:** KEM distribution has a product structure `X × K`; the advantage
definition must be precise about *which* function is being distinguished.
Budget 6 h including debugging the PMF push-forward.

### E2 — `ConcreteTensorOIA`, `ConcreteCEOIA`, `ConcreteGIOIA` (F-10 step 2) · L · 8 h

**Files:** `Orbcrypt/Hardness/CodeEquivalence.lean`,
`Orbcrypt/Hardness/TensorAction.lean`, `Orbcrypt/Hardness/Reductions.lean`

**Approach:** replicate the `ConcreteOIA` pattern for each hardness
variant. Each takes a `PMF` over the corresponding object (codes / tensors
/ adjacency matrices) and bounds the advantage of every distinguisher.

```lean
/-- Concrete CE indistinguishability with advantage bound ε. -/
def ConcreteCEOIA [...] (C₀ C₁ : Finset (Fin n → F)) (ε : ℝ) : Prop :=
  ∀ (D : Finset (Fin n → F) → Bool),
    advantage D (codeOrbitDist C₀) (codeOrbitDist C₁) ≤ ε

/-- Concrete TI with advantage bound ε. -/
def ConcreteTensorOIA [...] (T₀ T₁ : Tensor3 n F) (ε : ℝ) : Prop := ...

/-- Concrete GI with advantage bound ε. -/
def ConcreteGIOIA [...] (adj₀ adj₁ : ...) (ε : ℝ) : Prop := ...
```

Each definition needs an orbit distribution (uniform over group action).
Build three small helpers `codeOrbitDist`, `tensorOrbitDist`,
`graphOrbitDist` mirroring `orbitDist`.

**Acceptance:**
- All three modules build.
- Six new declarations (3 definitions + 3 trivial `_one` satisfiability
  lemmas).
- Docstrings cite LESS/MEDS/TI literature where applicable (reuse
  `docs/HARDNESS_ANALYSIS.md` citations).

**Risk:** tensor PMF handling is less standard in Mathlib. If push-forward
via `PMF.map (tensorAction •)` over `uniformPMF GL³` proves too fiddly,
fall back to a `Prop`-level definition quantifying over PMFs rather than
deriving from group action — less clean but viable.

### E3 — Probabilistic reduction steps (F-09 at the Prop level, F-20 step 1) · L · 10 h

**Files:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:** state the three reductions as ε-preserving Props (still
parameters, not proofs, paralleling the deterministic layer):

```lean
def ConcreteTensorOIAImpliesConcreteCEOIA
    [...] (εT εC : ℝ) : Prop :=
  ∀ T₀ T₁, ConcreteTensorOIA T₀ T₁ εT →
    ∀ C₀ C₁ (_ : encodesTensorInCE T₀ C₀) (_ : encodesTensorInCE T₁ C₁),
      ConcreteCEOIA C₀ C₁ εC

def ConcreteCEOIAImpliesConcreteGIOIA (εC εG : ℝ) : Prop := ...

def ConcreteGIOIAImpliesConcreteOIA (εG εS : ℝ) : Prop := ...
```

The ε parameters make the *advantage loss* at each reduction explicit.
Whether `εT = εC` or `εT ≤ εC` depends on the reduction's tightness; the
Prop formulation exposes this as a parameter to be filled in by Workstream
F's concrete reductions.

**Acceptance:**
- Module builds.
- Three new Prop definitions with docstrings naming the advantage-loss
  parameters.
- Each cites the literature reduction it mirrors (e.g.
  "Beullens–Persichetti 2023 for CE→GI" in docstring).

**Risk:** deciding on the ε relationship (additive loss, multiplicative,
preserving). Start with a generic `ConcreteXReducesToY εX εY` without
enforcing `εX ≤ εY`; downstream composition can tighten.

### E4 — `ConcreteHardnessChain` (F-20 step 2) · L · 4 h

**Files:** `Orbcrypt/Hardness/Reductions.lean`

**Approach:** bundle the three reduction Props + the base hardness
assumption into one structure:

```lean
structure ConcreteHardnessChain
    [...] (scheme : OrbitEncScheme G X M) (ε : ℝ) where
  εT : ℝ
  εC : ℝ
  εG : ℝ
  tensor_hard : ∀ T₀ T₁, ConcreteTensorOIA T₀ T₁ εT
  tensor_to_ce : ConcreteTensorOIAImpliesConcreteCEOIA εT εC
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA εC εG
  gi_to_oia : ConcreteGIOIAImpliesConcreteOIA εG ε
```

Then prove:

```lean
theorem concreteOIA_from_chain
    (hc : ConcreteHardnessChain scheme ε) : ConcreteOIA scheme ε := by
  -- Chain the four Props to get ConcreteOIA scheme ε.
  sorry  -- full proof, zero sorry at commit
```

**Acceptance:**
- Module builds.
- `#print axioms concreteOIA_from_chain` = standard Lean only.
- Structure composes cleanly; no unused ε parameters.

**Risk:** the advantage-loss composition may need `εT * coeff + const`
arithmetic if the reductions are not tight. Start with the simplest
additive model `ε = εT + εC + εG` and document; tighten later.

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

**Files:** `Orbcrypt/PublicKey/CombineImpossibility.lean`

**Approach:**
1. Define `ConcreteEquivariantCombiner` as today, but the Prop statement
   bounds advantage rather than proving `false`:
   ```lean
   theorem nondegenerate_equivariant_combiner_advantage_lower_bound
       [...] (comb : GEquivariantCombiner G X)
       (hND : NonDegenerateCombiner comb)
       (ε : ℝ) (hOIA : ConcreteOIA scheme ε) :
       ε ≥ nonDegenerateAdvantageLowerBound scheme comb hND
   ```
   where `nonDegenerateAdvantageLowerBound` is a computable (or
   `noncomputable`) bound ≥ some positive real derived from the
   non-degeneracy witness.

2. Derive: if `ε < nonDegenerateAdvantageLowerBound`, then `hOIA` is
   **falsified** (not just that `false` is reached).

**Acceptance:**
- Module builds.
- The new theorem carries a concrete lower bound (not just `> 0`).
- The original `equivariant_combiner_breaks_oia` remains, but its docstring
  adds the pointer.

**Risk:** deriving a concrete lower bound may be fiddly. Acceptable fallback:
a `Prop`-level "there exists a positive bound" statement with the
quantitative refinement left for future work, *as long as* the theorem is
no longer vacuously true under a realistic ConcreteOIA assumption.

### E7 — Product PMF infrastructure (F-11 prereq) · M · 6 h

**Files:** `Orbcrypt/Probability/Monad.lean` (extend)

**Approach:** add / expose:

```lean
/-- Uniform PMF over Q-tuples. -/
noncomputable def uniformPMFTuple (α : Type*) [Fintype α] [Nonempty α]
    (Q : ℕ) : PMF (Fin Q → α) :=
  PMF.bind (uniformPMF α) (fun _ => PMF.pure (fun _ => ...))
  -- or use Mathlib's PMF.pi if available
```

Then `probEventTuple`, `advantageTuple` mirror single-query helpers.

**Acceptance:**
- Module builds.
- Three new declarations with docstrings.
- A sanity lemma `uniformPMFTuple_support = Set.univ`.

**Risk:** Mathlib's PMF doesn't directly support `PMF.pi` for arbitrary
fintypes. If absent, construct via `PMF.bind` fold. Budget 6 h including
Mathlib research.

### E8 — Multi-query IND-Q-CPA via hybrid argument (F-11) · L · 8 h

**Files:** `Orbcrypt/Crypto/CompSecurity.lean`

**Approach:** using E7's product PMF and the existing `hybrid_argument`:

```lean
theorem indQCPA_bound_via_hybrid
    [...] (scheme : OrbitEncScheme G X M) (ε : ℝ) (Q : ℕ)
    (hOIA : ConcreteOIA scheme ε)
    (A : DistinctMultiQueryAdversary X M Q) :
    indQCPAAdvantage scheme A ≤ Q * ε := by
  -- Telescope via hybrid_argument
  ...
```

This upgrades `single_query_bound` from a trivial rename to a real building
block. The `DistinctMultiQueryAdversary` type comes from B3.

**Acceptance:**
- Module builds.
- `indQCPAAdvantage` defined.
- `indQCPA_bound_via_hybrid` proved, zero sorry.
- `#print axioms indQCPA_bound_via_hybrid` = standard Lean only.
- A regression test: when `Q = 1`, recovers `concrete_oia_implies_1cpa`.

**Risk:** the hybrid argument requires a *sequence* of distributions that
interpolate between all-left and all-right. Construction is standard but
tedious. Use `Finset.sum_range_succ` + `advantage_triangle` telescoping
as in `hybrid_argument_nat`.

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

**Files:** `Orbcrypt/KeyMgmt/SeedKey.lean` (extend), new
`Orbcrypt/KeyMgmt/HGOEExpansion.lean`

**Problem:** `HGOEKeyExpansion` is spec-only. No theorem links it to a
computable `SeedKey` producing the 7-stage pipeline output.

**Approach:**
1. Formalize a PRF abstraction `PRF : Seed → ℕ → Bitstring n` with
   correctness + (assumed) pseudorandomness.
2. Define `hgoeKeyFromExpansion : HGOEKeyExpansion n M → PRF seed → SeedKey Seed G X`
   producing the concrete key from the expansion specification.
3. Prove `hgoeKeyFromExpansion_reps_same_weight`: the constructed key
   produces representatives of uniform Hamming weight.
4. Prove `hgoeKeyFromExpansion_kem_correctness` via `seed_kem_correctness`.

**Acceptance:**
- All four items proved.
- `#print axioms hgoeKeyFromExpansion_kem_correctness` = standard Lean
  only (or documents a single PRF pseudorandomness hypothesis).
- `CLAUDE.md` table adds this as theorem #19 or subtype.

**Risk:** XL — this is a phase-sized task. Split into three sub-WUs in a
follow-up plan doc (`F1a`, `F1b`, `F1c`).

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

**Files:** new `Orbcrypt/Hardness/ReductionGIToCE.lean`

**Problem:** `GIReducesToCE` is a Prop parameter. Prove it concretely for
CFI graphs.

**Approach:** follow Babai's CFI construction:
1. Encode each vertex with 4 points, each edge with 2 additional points.
2. Show the resulting code's permutation automorphism group equals the
   graph's automorphism group.
3. Lift GI distinguishers to CE distinguishers.

**Acceptance:**
- Module builds.
- `GIReducesToCE_proved : GIReducesToCE` exhibited with zero sorry.
- Cites Cai–Fürer–Immerman 1992.
- Workstream E4's `ConcreteHardnessChain` can use this as the `ce_to_gi`
  field's witness.

**Risk:** XL — this is phase-sized research. Defer until after E lands.

### F4 — Concrete GI ≤ TI reduction (F-09 step 2) · XL · 40 h

**Files:** new `Orbcrypt/Hardness/ReductionGIToTI.lean`

**Approach:** encode adjacency matrices into 3-tensors (symmetric
3-tensor encoding of graphs). Show that graph isomorphism implies tensor
isomorphism and vice versa under this encoding.

**Acceptance:** analogous to F3.

**Risk:** XL, same as F3.

### F5 — Non-trivial `CommGroupAction` witness (F-14) · XL · 30 h

**Files:** new `Orbcrypt/PublicKey/EllipticCommAction.lean` or similar

**Problem:** only `selfAction` on a `CommGroup` acts on itself. No
concrete elliptic curve isogeny action, no CSIDH witness.

**Approach (tiered):**
1. **Tier 1 (M, 4 h):** integer `ZMod N` action on itself — a
   *non-trivial* instance that just serves as a concrete witness, even
   though it provides no cryptographic hardness.
2. **Tier 2 (XL, 30 h):** a formalization of a class-group action on a
   set of supersingular elliptic curves, matching CSIDH's structure.
   Prohibitively expensive without a Mathlib elliptic-curve API.
3. **Tier 3 (XL, 60 h):** full CSIDH correctness + CSI-DLP hardness Prop.

**Recommendation:** land Tier 1 as a quick win; defer Tier 2/3 to a
dedicated future phase.

**Acceptance (Tier 1):**
- Module builds.
- A `CommGroupAction` instance on `ZMod N × ZMod N` (or similar) is
  exhibited.
- `CommOrbitPKE` instantiated with this instance builds.
- Documentation explicitly flags the instance as "structural witness,
  not cryptographically hard."

**Risk:** low for Tier 1; high for Tier 2/3.

### F6 — Additional separating-invariant screening (F-21) · L · 12 h

**Files:** `Orbcrypt/Construction/HGOE.lean` (extend), new
`Orbcrypt/Construction/InvariantScreening.lean`

**Problem:** `same_weight_not_separating` blocks the Hamming-weight
attack, but other separating invariants (dual code weight enumerator,
automorphism group signature, spectrum of adjacency matrix) are not
screened.

**Approach:** add negative theorems of the form "if all representatives
have the same `X` invariant, then `X` does not separate them," for:
- Weight enumerator polynomial.
- Coset weight distribution.
- Dual code minimum distance.
- Automorphism group order (up to |PAut| equivalence).

Each theorem is a straightforward extension of `same_weight_not_separating`.

**Acceptance:**
- New module builds.
- ≥ 3 new `not_separating` theorems.
- `CLAUDE.md` threat-model coverage table extended.

**Risk:** low. The theorems are structural analogues.

---

## 10. Workstream G — Documentation & Transparency

**Goal:** keep `CLAUDE.md`, `DEVELOPMENT.md`, `COUNTEREXAMPLE.md`, and
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

### G2 — DEVELOPMENT.md: "Vacuity Map" section · S · 2 h

**Files:** `DEVELOPMENT.md`

**Approach:** add a new section (suggested: §9 "Formalization Vacuity
Map") summarizing audit §5.1 and Workstream E's resolution. Include:
- Table of deterministic vs. probabilistic theorems.
- The ConcreteOIA(1) satisfiability note.
- Cross-reference to `Crypto/OIA.lean` module docstring.
- Note that this audit and its workstream plan exist at
  `docs/audits/LEAN_MODULE_AUDIT_2026-04-18.md` and
  `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`.

**Acceptance:** DEVELOPMENT.md builds (no markdown errors); the new
section is discoverable from the TOC.

### G3 — Phase doc: `PHASE_14_AUDIT_RESOLUTION.md` · S · 2 h

**Files:** new `docs/planning/PHASE_14_AUDIT_RESOLUTION.md` (if chosen),
or extend `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md`.

**Approach:** record the meta-phase: "Phase 14 = resolve
`LEAN_MODULE_AUDIT_2026-04-18` via the workstream plan at
`docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`." Keep this file tight
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
| `DEVELOPMENT.md` | Scheme design, security proofs | Lean theorem statements |
| `formalization/FORMALIZATION_PLAN.md` | Lean architecture | Module dependency graph in `Orbcrypt.lean` |
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

This is the critical path. Recommended ordering:

1. E7 (product PMF, ~6 h) — do first; it's a general building block.
2. E1 (ConcreteKEMOIA, ~6 h) — independent of E2/E3.
3. E2 (ConcreteTensorOIA / CEOIA / GIOIA, ~8 h) — independent leaves.
4. E3 (probabilistic reductions, ~10 h) — needs E2.
5. E4 (ConcreteHardnessChain, ~4 h) — needs E3.
6. E5 (final → IND-1-CPA, ~3 h) — needs E4.
7. E6 (probabilistic combiner no-go, ~6 h) — needs E1.
8. E8 (IND-Q-CPA via hybrid, ~8 h) — needs E7 + B3.
9. E9 (axiom transparency update + G2 vacuity-map doc, ~4 h).

Total: ~55 h sequential, ~35–40 h with E1/E2/E7 parallelised.

### 14.5 After Workstream E — close out G2, G3

Land the DEVELOPMENT.md vacuity-map (G2) and the PHASE_14_AUDIT_RESOLUTION
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
| F-02 | Low | B1 (IsSecureDistinct) | E8 (multi-query uses it) | Both variants coexist; downstream theorems can opt-in |
| F-03 | Low | A1 (hardened regex) | — | CI robust to docstring prose |
| F-04 | Low | A2 (`push_neg`) | — | Idiomatic Mathlib style |
| F-05 | Info | F1 (concrete HGOE expansion) | F2 (seed secrecy) | Open (research); honest gap flagged in docs |
| F-06 | Low | F2 (SampleGroupSpec) | — | Secrecy obligation surfaced |
| F-07 | Medium | C1 (verify_inj), C2 (INT_CTXT proof) | C3 (headline listing), C4 (witness) | INT_CTXT proved for honest composition |
| F-08 | Info | D1 (symm/trans), D2 (Subgroup) | D3, D4 | Full equivalence API + Mathlib integration |
| F-09 | High | E3 (probabilistic reductions as Props) | F3, F4 (concrete proofs, research) | Prop-level sharp; concrete proofs as research deliverable |
| F-10 | High | E1 (ConcreteKEMOIA), E2 (concrete hardness OIAs) | E6, E9 | Every OIA variant has probabilistic companion |
| F-11 | Info | E8 (IND-Q-CPA via hybrid) | E7 (product PMF) | Multi-query theorem proved |
| F-12 | Info | A8 (doc), E4 (actually consume them) | — | Props consumed by ConcreteHardnessChain |
| F-13 | Low | A7 (helper defs) | — | Readable Comp* definitions |
| F-14 | Info | F5 Tier 1 (trivial non-self witness) | F5 Tier 2/3 (CSIDH) | Structural witness present; cryptographic witness is research |
| F-15 | Low | B2 (explicit universes) | — | SchemeFamily universe-clean |
| F-16 | Low | A6a (rename), A6b/D3 (prove set identity) | — | Name accurate; set identity optional |
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

### 15.2 Inverse map: WU → findings

| WU | Covers | One-line purpose |
|----|--------|------------------|
| A1 | F-03 | Harden CI `sorry` regex |
| A2 | F-04 | `push Not` → `push_neg` |
| A3 | F-18 | Remove shadowed `hn_pos` |
| A4 | F-22 | Pin elan SHA-256 in CI |
| A5 | F-19 | Strengthen `kem_agreement_correctness` to bi-view identity |
| A6a | F-16 | Rename `paut_coset_is_equivalence_set` |
| A6b | F-16 (extended) | Prove actual set identity (optional) |
| A7 | F-13 | Helper `def`s in CompOIA/CompSecurity |
| A8 | F-12 | Document hardness-parameter Props |
| B1 | F-02 | `IsSecureDistinct` predicate |
| B2 | F-15 | Explicit universes on `SchemeFamily` |
| B3 | prereq for E8 | Per-query distinct adversary wrapper |
| C1 | F-07 step 1 | Add `verify_inj` to MAC |
| C2 | F-07 step 2 | Prove `INT_CTXT` from `verify_inj` |
| C3 | F-07 step 3 | Wire into headline theorem list |
| C4 | F-07 witness | Concrete MAC instance |
| D1 | F-08 step 1 | `ArePermEquivalent.symm` / `_trans` |
| D2 | F-08 step 2 | Promote `PAut` to `Subgroup` |
| D3 | F-16 step 2 | Coset set identity (optional, uses D1+D2) |
| D4 | F-08 step 3 | `Setoid` instance |
| E1 | F-10 step 1 | `ConcreteKEMOIA` + secure bound |
| E2 | F-10 step 2 | `Concrete{Tensor,CE,GI}OIA` |
| E3 | F-09 (Prop), F-20 prep | Probabilistic reductions as Props |
| E4 | F-20 step 2 | `ConcreteHardnessChain` bundle |
| E5 | F-20 step 3 | Chain → IND-1-CPA advantage bound |
| E6 | F-17 | Probabilistic combiner no-go |
| E7 | F-11 prereq | Product PMF infrastructure |
| E8 | F-11 | IND-Q-CPA via hybrid argument |
| E9 | cross-cutting | Axiom transparency + vacuity map |
| F1 | F-05 | HGOEKeyExpansion → SeedKey (XL) |
| F2 | F-06 | `SampleGroupSpec` |
| F3 | F-09 step 1 | Concrete GI ≤_p CE (XL) |
| F4 | F-09 step 2 | Concrete GI ≤ TI (XL) |
| F5 | F-14 | Non-trivial `CommGroupAction` (tiered) |
| F6 | F-21 | Additional separating-invariant screening |
| G1 | documentation | Add `CombineImpossibility.lean` to `CLAUDE.md` |
| G2 | documentation | DEVELOPMENT.md Vacuity Map section |
| G3 | documentation | `PHASE_14_AUDIT_RESOLUTION.md` status file |
| G4 | documentation | Axiom-transparency hardness-Props section |

---

## 16. Appendix B — References and Cross-links

### 16.1 Audit and plan artifacts

- `docs/audits/LEAN_MODULE_AUDIT_2026-04-18.md` — the authoritative audit
  this plan addresses.
- `docs/audits/LEAN_MODULE_AUDIT_2026-04-14.md` — predecessor audit
  (F-22 carried over).
- `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` — this document.
- `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` — broader improvement
  roadmap; Workstream F items may promote into this doc as their own
  phases.

### 16.2 Canonical ownership

Per `CLAUDE.md`:

| Doc | Canonical owner of |
|-----|---------------------|
| `DEVELOPMENT.md` | Scheme specification, security proofs, hardness reductions |
| `formalization/FORMALIZATION_PLAN.md` | Lean 4 architecture and conventions |
| `COUNTEREXAMPLE.md` | Invariant attack analysis |
| `POE.md` | High-level concept exposition |
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
   `CLAUDE.md`, `Orbcrypt.lean`, and `DEVELOPMENT.md` never diverge
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
