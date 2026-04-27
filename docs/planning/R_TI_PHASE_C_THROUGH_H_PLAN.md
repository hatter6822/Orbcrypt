# Plan: Complete R-TI Karp Reduction — Refined Tangle-Free Strategy

> **Branch:** `claude/audit-workstream-planning-aoRDo` (commit `03a2e00`).
> **Last update:** 2026-04-27.
> **Lakefile version:** `0.1.21`.

---

## Current Status (2026-04-27 session checkpoint)

### Completed in this session (commit `03a2e00`)

**Layer 6.7–6.10 — CompleteOrthogonalIdempotents machinery** (in
`Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean`, +76 LOC):

- `vertexIdempotent_completeOrthogonalIdempotents (m : ℕ)` — the
  canonical vertex-idempotent family forms a Mathlib
  `CompleteOrthogonalIdempotents` structure (idem from
  `vertexIdempotent_isIdempotentElem`; ortho from
  `vertexIdempotent_mul_vertexIdempotent` + `if_neg`; complete from
  `pathAlgebraOne` definition).
- `AlgEquiv_preserves_completeOrthogonalIdempotents` — `AlgEquiv`
  preserves COIs (each field follows from `AlgEquiv.map_mul`,
  `map_zero`, `map_sum`, `map_one`).
- `vertexIdempotent_completeOrthogonalIdempotents_card` — cardinality
  fact `Fintype.card (Fin m) = m`.

**Layer 6b — Wedderburn–Mal'cev for `J² = 0`** (NEW file
`Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean`, 762 LOC):

- **6b.1 Jacobson radical (DONE):**
  * `pathAlgebraRadical (m : ℕ) : Submodule ℚ (pathAlgebraQuotient m)`
    = `Submodule.span ℚ (Set.range arrowElement)`.
  * `arrowElement_mem_pathAlgebraRadical`, `arrow_mul_arrow_eq_zero`.
  * `arrowElement_mul_member_radical`, `member_radical_mul_arrowElement`.
  * `pathAlgebraRadical_mul_radical_eq_zero` — `J · J = 0` via
    `Submodule.span_induction` reducing to L1.4
    `arrowElement_mul_arrowElement_eq_zero`.

- **6b.2 Element decomposition modulo radical (DONE):**
  * `pathAlgebra_arrow_part_mem_radical`, `pathAlgebra_vertexPart`,
    `pathAlgebra_arrowPart`, `pathAlgebra_arrowPart_mem_radical`,
    `pathAlgebra_decompose_radical` — restates `pathAlgebra_decompose`
    (Layer 5.3) using named projections.

- **6b.4 Inner conjugation machinery (DONE):**
  * `oneAddRadical_mul_oneSubRadical`, `oneSubRadical_mul_oneAddRadical`
    — `(1 + j)(1 - j) = 1` via `j² = 0` + `noncomm_ring`.
  * `arrowElement_mul_anything_mem_radical`,
    `member_radical_mul_anything_mem_radical`,
    `radical_sandwich_eq_zero` — establishes `j · c · j = 0`.
  * `innerAut_simplified : (1 + j) * c * (1 - j) = c + j*c - c*j` for
    `j ∈ J`. **This is the structural simplification that drives the
    WM verification.**

- **6b.3 HEADLINE Wedderburn–Mal'cev conjugacy (FULL PROOF, no Prop
  hypothesis):**
  * **Vertex coefficient analysis:**
    - `coi_vertex_coef_zero_or_one` (each `(e' i)(.id z) ∈ {0, 1}`).
    - `coi_vertex_coef_orth` (`(e' i)(.id z) * (e' j)(.id z) = 0` for
      `i ≠ j`, via `pathAlgebraMul_apply_id`).
    - `coi_vertex_coef_complete` (`∑_i (e' i)(.id z) = 1`, via
      `sum_pathAlgQ_apply` + `pathAlgebraOne_apply_id`).
    - `pathAlgebra_idempotent_zero_of_id_coef_zero` — an idempotent
      with all `.id` coefs zero IS zero (via mu-constraint).
    - `coi_nonzero_has_active_vertex` — non-zero COI element has
      active `.id` coordinate.
  * **σ extraction:**
    - `coi_unique_active_per_z` — `∃! i, (e' i)(.id z) = 1`
      (existence from completeness; uniqueness from orthogonality).
    - `coi_chooseActive`, `coi_chooseActive_spec`, `_unique`.
    - `coi_chooseActive_surjective` (each i has an active z by
      non-zero hypothesis).
    - `coi_chooseActive_bijective` via `Finite.injective_iff_surjective`.
    - `coi_vertexPerm` — σ as the inverse of `coi_chooseActive`.
    - `coi_vertexPerm_active`, `coi_vertexPerm_iff`,
      `coi_vertexPerm_eval` — σ-defining properties.
  * **j construction:**
    - `coi_conjugator h_coi h_nz := -∑_{w, s} (e' w)(.edge (σ w) s)
      • α(σ w, s)`.
    - `coi_conjugator_mem_radical`.
    - `coi_conjugator_apply_id` (always 0 — sum of arrows has no
      `.id` part).
    - `coi_conjugator_apply_edge` (= `-(e' (σ⁻¹ u))(.edge u t)`).
  * **Idempotency consequences:**
    - `pathAlgebra_idempotent_self_loop_zero` (active-vertex
      self-loop coefficient = 0 from `2X = X` ⟹ `X = 0`).
    - `pathAlgebra_idempotent_offdiag_arrow_zero` (off-diagonal
      arrow with both endpoints inactive = 0, from mu-constraint).
    - `coi_cross_arrow_compat` — the **compatibility condition**
      `(e' v)(.edge u t) + (e' (σ⁻¹ u))(.edge u t) = 0` when
      `t = σv`, `u ≠ σv`, derived from `e' (σ⁻¹u) * e' v = 0`
      evaluated at `.edge u t` via `pathAlgebraMul_apply_edge`.
  * **Main verification:**
    - `coi_conjugation_identity` — pointwise `(1 + j) * vertexIdempotent
      m (σ v) * (1 - j) = e' v` proven by `funext c; cases c` and
      4-case analysis on `(σv = u, σv = t)`:
      * Case `σv = u, σv = t` (self-loop): `2α - α = α`, then `α = 0`
        via self-loop lemma.
      * Case `σv = u, σv ≠ t`: yields `(e' v)(.edge u t)` directly
        (since `σ.symm u = v`).
      * Case `σv ≠ u, σv = t`: yields `-(e' (σ.symm u))(.edge u t)`
        which equals `(e' v)(.edge u t)` by `coi_cross_arrow_compat`.
      * Case `σv ≠ u, σv ≠ t`: both sides 0 via off-diag lemma.
  * **`wedderburn_malcev_conjugacy m e' h_coi h_nz`** — HEADLINE
    theorem composing the σ-extraction, j-construction, and
    conjugation identity into:
    ```
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) = e' v
    ```

**Phase F starter (Layer 9.1) — DONE:**
- `algEquiv_image_vertexIdempotent_COI` — the AlgEquiv-image of the
  canonical COI is itself a COI (via L6.9).
- `algEquiv_image_vertexIdempotent_ne_zero` — each
  `φ (vertexIdempotent v) ≠ 0` (φ injective).
- `algEquiv_extractVertexPerm` — **the cryptographic-rigidity entry
  point**: from any `AlgEquiv` on the path algebra, extract σ and j
  with `(1 + j) * vertexIdempotent (σ v) * (1 - j) = φ (vertexIdempotent v)`.
  This is the consumer of WM that Phase F.2–F.5 builds on.

### Verification posture

- Full `lake build` succeeds across **3,391 jobs** (zero warnings,
  zero errors).
- Phase 16 audit script: 639 `#print axioms` lines, 0 `sorryAx`,
  0 errors. All declarations depend only on the standard
  Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
- Module count: 47 → **48** (added `WedderburnMalcev.lean`).
- `lakefile.lean` version: `0.1.20` → **`0.1.21`**.

### 2026-04-27 audit-pass fixes (post-WM landing)

A subsequent deep audit of Layers 0–6b verified each layer's
content against the implementation and ran the build + Phase 16
script to convergence. Audit-driven cleanups:

1. **`AlgebraWrapper.lean`** Layer 1 basis-element theorems:
   removed redundant `try (first | rfl | simp_all [...])` chains
   (12 build warnings → 0). Pattern was `all_goals try (...)` where
   `try` was triggering "tactic never executed" because `rfl`
   always closed first. Replaced with `split_ifs <;> rfl` or
   `split_ifs <;> first | rfl | simp_all`.
2. **`WedderburnMalcev.lean`** linter cleanups (5 warnings → 0):
   * Removed unused `[DecidableEq ι]` from section variable.
   * Replaced deprecated `push_neg` with `push Not` (Mathlib at
     `fa6418a8` prefers the unified form).
   * Removed unused `with hσ_def` trailers on two `set` patterns.
3. **Audit script** extended with the Phase F starter declarations
   (`algEquiv_image_vertexIdempotent_COI`,
   `algEquiv_image_vertexIdempotent_ne_zero`,
   `algEquiv_extractVertexPerm`) and a non-vacuity `example`
   exercising `algEquiv_extractVertexPerm` on `AlgEquiv.refl` at
   `m = 1`.

The audit confirmed all Layers 0–6b are fully discharged with no
shortcuts: no `sorry`, no custom axioms, no Prop-hypothesis
fallbacks, no incomplete proofs masquerading as theorems.

### Remaining work (the user pre-approved Prop fallback ONLY for Phase D)

| Layer | Status | LOC est. | Risk | Notes |
|-------|--------|----------|------|-------|
| 7 — Phase D rigidity | PENDING | ~700 | **HIGH** | Prop fallback pre-approved if elementary discharge fails |
| 8 — Phase E AlgEquiv lift | PENDING | ~350 | M | Builds GL³ → AlgEquiv from σ extracted in Phase D |
| 9 — Phase F (sandwich, arrow image, adjacency) | PARTIAL (9.1 done) | ~500 | L–M | Consumes `algEquiv_extractVertexPerm` (already landed) |
| 10 — Phase G composition | PENDING | ~400 | L | D → E → F → adjacency invariance |
| 11 — Phase H final assembly | PENDING | ~150 | L | Discharge `grochowQiao_isInhabitedKarpReduction_under_obligations` |

### Critical files

- `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean`
  (NEW, 762 LOC) — 6b.1 + 6b.2 + 6b.3 + 6b.4 + Phase F starter.
- `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean`
  (1900 LOC) — Layers 1–6 (idempotent + COI infrastructure landed).
- `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean`
  (Track B, GL³ matrix-action verification, used by `grochowQiao_forwardObligation`).
- `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Reverse.lean`
  — top-level `GrochowQiaoRigidity` Prop is what Phases D–G discharge.
- `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao.lean`
  — `grochowQiao_isInhabitedKarpReduction_under_rigidity` is the
  conditional Karp-reduction inhabitant Phase H discharges.

### Next-session quick-start

The most impactful remaining task is **Phase F continuation (Layers
9.2–9.5)** because:
- Phase F's σ-extraction (9.1) is already landed via WM.
- Phase F.2 (`vertex_sandwich_isolates_arrow`) is purely structural
  — uses `pathAlgebra_decompose` + L1.* lemmas. ~120 LOC.
- Phase F.3 (`inner_aut_preserves_arrow`) follows from `J · J = 0`.
  ~150 LOC.
- Phase F.4 (`algEquiv_arrow_image_scalar`) composes F.1 + F.2 + F.3.
  ~120 LOC.
- Phase F.5 (`algEquiv_adj_preservation`) — adjacency invariance.
  ~80 LOC.

After Phase F is fully landed, **Phase G composition (~400 LOC)** can
discharge `GrochowQiaoRigidity` modulo Phase D + E. **Phase D is the
HIGH RISK piece** — the Prop fallback (`GLPreservesVertexSignatureBijection`)
is pre-approved by the user if the elementary
slot-signature-bijection extraction stalls.

The user's mid-session ban on Prop hypotheses applies **only to
Layer 6b.3** (Wedderburn–Mal'cev), which is now closed. Phase D's
pre-approved Prop fallback remains valid.

---

## Context

This is a **refinement** of the previous plan after encountering
specific tangling issues during execution. The previous plan (kept
below for reference) is correct in its overall structure but needs a
more disciplined proof methodology to avoid the tangling that occurred
on `pathAlgebra_one_mul` / `pathAlgebra_mul_one`.

### Currently committed (works cleanly, on branch
`claude/audit-workstream-planning-aoRDo`)

* **Track B** (`PermMatrix.lean`): `liftedSigmaGL`,
  `tensorContract_permMatrix_triple`, **discharges
  `GrochowQiaoForwardObligation` unconditionally**.
* **Track A.1** (`PathAlgebra.lean`): `pathMul_assoc` (8-case
  structural recursion).
* **Track A.2 partial** (`AlgebraWrapper.lean`):
  * `pathAlgebraQuotient m := QuiverArrow m → ℚ` carrier.
  * `Pi.addCommGroup`, `Pi.module ℚ` instances.
  * `pathAlgebraMul` + `Mul` instance + `pathAlgebraMul_apply`.
  * `vertexIdempotent`, `arrowElement` basis elements with `@[simp]`
    apply lemmas.
  * `pathMul_indicator_collapse` (C1), `pathMul_indicator_collapse_right`
    (C1') for path-multiplication-chain indicator collapse.
  * **`pathAlgebraMul_assoc` proven** via the canonical-form
    decomposition C2 + C3 + top-level (Plan A from
    `docs/planning/PATH_ALGEBRA_MUL_ASSOC_PLAN.md`).
  * `pathAlgebraOne := ∑_v vertexIdempotent v` + `One` instance.
  * `pathAlgebraOne_apply_id` / `pathAlgebraOne_apply_edge`.
  * `sum_pathAlg_apply` helper bridging `Finset.sum_apply` through
    the `pathAlgebraQuotient m` type alias.
* **`grochowQiao_isInhabitedKarpReduction_under_rigidity`** in
  top-level `GrochowQiao.lean` — single-Prop conditional inhabitant
  using the Track B forward-obligation discharge.

### Tangling issues encountered (root causes)

1. **`simp` chains on `if-then-else` inside multiplication.** When
   the goal has `(if cond then 1 else 0) * f * g`, `simp` rewrites
   were unpredictable: sometimes firing `if_pos`, sometimes leaving
   the conditional unreduced, sometimes erasing parts of the goal
   that subsequent tactics needed. **Tactic `simp [pathMul_id_id]`
   often left untyped goals that downstream `cases`/`exact` could
   not match.**

2. **`Finset.sum_apply` doesn't fire through the type alias.**
   `pathAlgebraQuotient m := QuiverArrow m → ℚ` is a `def`, not an
   `abbrev`, so direct `rw [Finset.sum_apply]` fails when the LHS
   has type `pathAlgebraQuotient m`. **Fix: always invoke through
   `sum_pathAlg_apply` helper** (already established).

3. **After `cases h_pxy : pathMul x y`, subsequent `rw [h_pxy]`
   fails** because `cases` already substituted `pathMul x y` with
   `none` / `some a₀` in the goal. **Fix: do not `rw [h_pxy]` after
   `cases h_pxy`.**

4. **Multi-step `Finset.sum_eq_single` proofs become inscrutable**
   when nested 3+ deep. The intermediate goal states are large and
   the side conditions (the "other terms vanish" branches) require
   careful Bool/Prop manipulation that `simp` can't always close.
   **Fix: factor each `Finset.sum_eq_single` into a private helper
   lemma with an explicit pre/post specification.**

5. **`simp [h_ne]` doesn't reliably reduce `if some a₀ = some a then
   ... else ...` even with `h_ne : some a₀ ≠ some a` in scope.**
   **Fix: use `rw [if_neg h_ne]` (explicit) rather than relying on
   `simp` to discover the negation.**

## Refined strategy: bottom-up basis-element lemmas first

The original plan proceeded from `mul_assoc` → `one_mul` directly,
attempting `Finset.sum_eq_single` four levels deep. This is what
tangled.

The **refined strategy** establishes a **basis-element multiplication
table** as `@[simp]` lemmas first, then uses bilinearity (which is
free from the definition) to lift to general elements. Each lemma
has scope ≤ ~50 LOC and a single output coordinate to track.

### Layered approach (each layer self-contained)

```
Layer 0: pathAlgebraMul_assoc + pathAlgebraOne   [DONE]
Layer 1: basis-element multiplication table (5 lemmas, ~250 LOC)
   ├── vertexIdempotent_mul_vertexIdempotent
   ├── vertexIdempotent_mul_arrowElement
   ├── arrowElement_mul_vertexIdempotent
   ├── arrowElement_mul_arrowElement
   └── vertexIdempotent_mul_apply (the key formula at any c)
Layer 2: distributivity + annihilation (4 lemmas, ~150 LOC)
   ├── pathAlgebra_left_distrib
   ├── pathAlgebra_right_distrib
   ├── pathAlgebra_zero_mul
   └── pathAlgebra_mul_zero
Layer 3: one_mul + mul_one via bilinearity (2 lemmas, ~150 LOC)
   ├── pathAlgebra_one_mul
   └── pathAlgebra_mul_one
Layer 4: Ring instance (~80 LOC)
Layer 5: Algebra ℚ instance + decomposition + basis (~300 LOC)
   ├── pathAlgebra_smul_mul, pathAlgebra_mul_smul
   ├── Algebra ℚ instance via Algebra.ofModule
   ├── pathAlgebra_decompose
   └── pathAlgebraQuotient_basis
Layer 6: Phase C — idempotent + complete orthogonal decomposition theory (~600 LOC)
Layer 6b: Phase C-bis — Wedderburn-Mal'cev for J² = 0 (NEW, ~400 LOC)
Layer 7: Phase D — partition rigidity (~700 LOC, HIGH RISK)
Layer 8: Phase E — AlgEquiv from GL³ (~350 LOC)
Layer 9: Phase F — vertex permutation extraction via COI conjugation (~600 LOC)
Layer 10: Phase G — reverse direction discharge (~400 LOC)
Layer 11: Phase H — final assembly + Documentation (~150 LOC)
```

**Total: ~3,470 LOC across ~3,500–5,000 LOC budget. The user has
authorised completing all phases without sorry/axiom (modulo D.2
fallback approved earlier).**

The user has authorised completing these obligations with full proofs.
**Sorry/axiom usage will be requested explicitly per item where needed.**

---

## Tactical anti-patterns and idioms (lessons from the tangling)

### Anti-pattern 1 — `simp [foo]` after `cases h : pathMul ...`

After `cases h : pathMul m x y with | none => _ | some a₀ => _`, the
hypothesis `h` is in scope but the *goal* has `pathMul m x y`
substituted with `none` (or `some a₀`). Naïve `rw [h]` fails: the
pattern is gone.

**Idiom:** in the `none` branch, the goal already has `none` —
proceed directly. In the `some a₀` branch, use `Finset.sum_eq_single
a₀` to pick out the single nonzero term and evaluate via
`if_pos rfl` / `if_neg h_ne`.

### Anti-pattern 2 — relying on `simp` to discharge `if c then 1 else 0` with non-trivial c

If the condition `c` has `Option.some` injectivity issues
(e.g., `some a₀ = some a` reduces to `a₀ = a` only via
`Option.some.inj`), `simp` may stall.

**Idiom:** prefer
```lean
have h_ne : (some a₀ : Option (QuiverArrow m)) ≠ some a := by
  intro h_eq
  exact ha (Option.some.inj h_eq).symm
rw [if_neg h_ne, zero_mul]
```
over
```lean
simp [h_ne]
```
The `rw` is mechanical and predictable.

### Anti-pattern 3 — `Finset.sum_apply` directly on `pathAlgebraQuotient m`

`pathAlgebraQuotient m` is a `def`, not `abbrev`, so the type alias
blocks the lemma's pattern match.

**Idiom:** invoke `sum_pathAlg_apply` (the existing helper) which
takes the explicit subtype arguments and forces the unfolding.

### Anti-pattern 4 — Trying `Finset.sum_eq_single` 4 levels deep in one proof

Nested 4-level `Finset.sum_eq_single` produces a goal state of ~30
hypotheses with multiple `_ ≠ _` constraints. Tactic-level
manipulation becomes inscrutable.

**Idiom:** for each "single nonzero (a, b)" pattern, factor into a
**private helper lemma** with the goal exactly:
```lean
private lemma helper_at_specific_c (... f g : pathAlgebraQuotient m) :
    pathAlgebraMul m (single_basis_element_a) (single_basis_element_b) c =
      ... := by
  ... -- 1-2 sum_eq_single, each with 1 single nonzero index
```
Then `pathAlgebra_one_mul` becomes a clean composition of these
helpers, not a 4-level nested proof.

### Idiom — `funext c; cases c`

For any equality `f = g` between `pathAlgebraQuotient m` values,
the standard opening is:
```lean
funext c
cases c with
| id w => ...
| edge u v => ...
```
This splits into the two basis-element branches **before** any sum
manipulation, giving cleaner intermediate states.

### Idiom — `Finset.sum_eq_single` selection criterion

When proving `(∑ a, F a) = G` where exactly one `a₀` makes `F a₀ ≠ 0`:
```lean
rw [Finset.sum_eq_single a₀]
· -- main term: F a₀ = G
  ...
· -- other terms vanish: ∀ a ≠ a₀, F a = 0
  intros a _ ha
  ...
· -- a₀ ∈ Finset.univ
  intro h; exact absurd (Finset.mem_univ _) h
```
This is the canonical 3-arg pattern. Always include the third
argument explicitly — Lean will not auto-fill it.

---

## Layer 1 — Basis-element multiplication table (5 lemmas, ~250 LOC)

### L1.1 — `vertexIdempotent_mul_vertexIdempotent`

**Combined statement** (matched/unmatched in one):
```lean
theorem vertexIdempotent_mul_vertexIdempotent (m : ℕ) (v w : Fin m) :
    pathAlgebraMul m (vertexIdempotent m v) (vertexIdempotent m w) =
    if v = w then vertexIdempotent m v else 0
```

**Proof structure:**
```lean
funext c
cases c with
| id z =>
  show (∑ a, ∑ b, vertexIdempotent m v a * vertexIdempotent m w b *
        (if pathMul m a b = some (.id z) then (1:ℚ) else 0)) = _
  -- Only (a, b) = (.id v, .id w) makes the product of basis-element
  -- evaluations nonzero. AND the indicator survives only if pathMul
  -- (.id v) (.id w) = some (.id z), which requires v = w = z.
  rw [Finset.sum_eq_single (.id v)]
  · rw [Finset.sum_eq_single (.id w)]
    · -- main term: vIdem v (.id v) * vIdem w (.id w) = 1 · 1 = 1
      -- pathMul (.id v) (.id w) = if v = w then some (.id v) else none
      -- match if v = w = z
      simp only [vertexIdempotent_apply_id, if_pos rfl, mul_one,
                 pathMul_id_id]
      split_ifs with h_vw h_vz
      all_goals {
        -- evaluate RHS `if v = w then vIdem v else 0` at .id z
        first
        | (subst h_vw; simp [vertexIdempotent_apply_id])
        | rfl
      }
    · intros b _ hb
      -- b ≠ .id w: vertexIdempotent m w b = 0 (by cases on b's constructor)
      cases b with
      | id w' =>
        rw [vertexIdempotent_apply_id]
        rw [if_neg (fun h_eq => hb (by rw [h_eq]))]
        ring
      | edge _ _ =>
        rw [vertexIdempotent_apply_edge]
        ring
    · intro h; exact absurd (Finset.mem_univ _) h
  · intros a _ ha
    -- a ≠ .id v: vertexIdempotent m v a = 0
    cases a with
    | id v' =>
      apply Finset.sum_eq_zero
      intros b _
      rw [vertexIdempotent_apply_id]
      rw [if_neg (fun h_eq => ha (by rw [h_eq]))]
      ring
    | edge _ _ =>
      apply Finset.sum_eq_zero
      intros b _
      rw [vertexIdempotent_apply_edge]
      ring
  · intro h; exact absurd (Finset.mem_univ _) h
| edge u₀ v₀ =>
  -- pathMul (.id v) (.id w) yields .id _, never .edge _ _.
  -- So the indicator [pathMul a b = some (.edge u₀ v₀)] is always 0
  -- when a, b ∈ {.id v, .id w}. RHS: (if v = w then vertexIdempotent v
  -- else 0) at .edge u₀ v₀ = 0.
  ...
```

**Risk:** medium. The `split_ifs with h_vw h_vz` must handle 4
cases, half of which are vacuous. Anticipated 80 LOC.

### L1.2 — `vertexIdempotent_mul_arrowElement`

```lean
theorem vertexIdempotent_mul_arrowElement (m : ℕ) (v u w : Fin m) :
    pathAlgebraMul m (vertexIdempotent m v) (arrowElement m u w) =
    if v = u then arrowElement m u w else 0
```

**Proof structure:** `funext c; cases c`. For `c = .id z`: the result
is 0 (no path-product gives `id z` from `id v * edge u w`). For
`c = .edge u' w'`: only (a, b) = (.id v, .edge u w) contributes; the
indicator survives iff v = u and (u', w') = (u, w). Anticipated
60 LOC.

### L1.3 — `arrowElement_mul_vertexIdempotent`

```lean
theorem arrowElement_mul_vertexIdempotent (m : ℕ) (u v w : Fin m) :
    pathAlgebraMul m (arrowElement m u v) (vertexIdempotent m w) =
    if v = w then arrowElement m u v else 0
```

Symmetric to L1.2. Anticipated 60 LOC.

### L1.4 — `arrowElement_mul_arrowElement_eq_zero`

```lean
theorem arrowElement_mul_arrowElement_eq_zero (m : ℕ) (u v u' v' : Fin m) :
    pathAlgebraMul m (arrowElement m u v) (arrowElement m u' v') = 0
```

`funext c`. For any c, only (a, b) = (.edge u v, .edge u' v') has
product of basis-element evaluations nonzero. But
`pathMul (.edge _ _) (.edge _ _) = none`, so the indicator is always
0. Anticipated 30 LOC.

### L1.5 — `vertexIdempotent_mul_apply` (the key formula)

For applying `e_v * f` at any output coordinate:
```lean
theorem vertexIdempotent_mul_apply (m : ℕ) (v : Fin m)
    (f : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (pathAlgebraMul m (vertexIdempotent m v) f) c =
      match c with
      | .id z => if v = z then f (.id z) else 0
      | .edge u w => if v = u then f (.edge u w) else 0
```

This is the **bilinear form** that drives `pathAlgebra_one_mul`.
Proof: `cases c`. For `.id z`: only (a, b) = (.id v, .id z) makes
the indicator survive (pathMul (.id v) (.id z) = some (.id z) iff v
= z). The product at that pair is `1 * f(.id z) * 1 = f(.id z)`.
For `.edge u w`: only (a, b) = (.id v, .edge u w) makes the
indicator survive (pathMul (.id v) (.edge u w) = some (.edge u w)
iff v = u). The product at that pair is `1 * f(.edge u w) * 1 =
f(.edge u w)`. Anticipated 70 LOC.

**Companion lemma** (symmetric, for `mul_one`):
```lean
theorem mul_vertexIdempotent_apply (m : ℕ) (f : pathAlgebraQuotient m)
    (v : Fin m) (c : QuiverArrow m) :
    (pathAlgebraMul m f (vertexIdempotent m v)) c =
      match c with
      | .id z => if v = z then f (.id z) else 0
      | .edge u w => if v = w then f (.edge u w) else 0
```
Same structure; anticipated 70 LOC.

---

## Layer 2 — Distributivity + Annihilation (~150 LOC)

### L2.1 — `pathAlgebra_left_distrib`

```lean
theorem pathAlgebra_left_distrib (m : ℕ) (f g h : pathAlgebraQuotient m) :
    pathAlgebraMul m f (g + h) = pathAlgebraMul m f g + pathAlgebraMul m f h
```

**Proof.** `funext c`. The LHS expands as
`∑_a ∑_b f(a) · (g + h)(b) · I` = `∑_a ∑_b f(a) · (g(b) + h(b)) · I`.
Distribute: `= ∑_a ∑_b f(a) · g(b) · I + ∑_a ∑_b f(a) · h(b) · I` via
`mul_add`, `add_mul`, and `Finset.sum_add_distrib`. Each step is
algebraic.

```lean
funext c
show (∑ a, ∑ b, f a * (g + h) b * (if pathMul m a b = some c then (1:ℚ) else 0)) =
     (∑ a, ∑ b, f a * g b * _) + (∑ a, ∑ b, f a * h b * _)
simp only [Pi.add_apply, mul_add, add_mul]
rw [show (∑ a, ∑ b, (f a * g b * _ + f a * h b * _)) =
        (∑ a, ∑ b, f a * g b * _) + (∑ a, ∑ b, f a * h b * _) from by
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl; intro a _
  rw [← Finset.sum_add_distrib]]
```

Anticipated 50 LOC.

### L2.2 — `pathAlgebra_right_distrib`

Symmetric. Anticipated 50 LOC.

### L2.3 — `pathAlgebra_zero_mul`

```lean
theorem pathAlgebra_zero_mul (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m 0 f = 0
```

**Proof.** `funext c`. `(0 : pathAlgebraQuotient m) a = 0` by
`Pi.zero_apply`. So every term `0 · f(b) · I = 0`. Sum is 0.

```lean
funext c
show (∑ a, ∑ b, (0 : pathAlgebraQuotient m) a * f b * _) = (0 : pathAlgebraQuotient m) c
simp only [Pi.zero_apply, zero_mul, Finset.sum_const_zero]
```

Anticipated 25 LOC.

### L2.4 — `pathAlgebra_mul_zero`

Symmetric. Anticipated 25 LOC.

---

## Layer 3 — One_mul + Mul_one via bilinearity + Layer 1 (~150 LOC)

### L3.1 — `pathAlgebra_one_mul`

```lean
theorem pathAlgebra_one_mul (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m (pathAlgebraOne m) f = f
```

**Proof strategy** (uses Layer 2 distributivity + Layer 1
`vertexIdempotent_mul_apply`):

Step 1: `1 = ∑_v vertexIdempotent v` (definition).
Step 2: By repeated `pathAlgebra_left_distrib` over the sum,
`(∑_v e_v) * f = ∑_v (e_v * f)` (induction on Finset; or use
Mathlib's `Finset.sum_mul` since we now have distribution).
Step 3: For each `c`, by L1.5 (`vertexIdempotent_mul_apply`), each
term `(e_v * f)(c)` equals `if (v matches the source of c) then f(c)
else 0`. Exactly one v matches; the others vanish. So
`(∑_v (e_v * f))(c) = f(c)`.

```lean
funext c
-- Step 1 + 2: unfold pathAlgebraOne, distribute over the sum.
show (pathAlgebraMul m (∑ v : Fin m, vertexIdempotent m v) f) c = f c
-- distribute (∑_v e_v) * f via Finset.sum_mul (need a helper since
-- our Mul isn't yet a Ring; use distribution induction OR a direct
-- bilinearity lemma):
rw [show pathAlgebraMul m (∑ v : Fin m, vertexIdempotent m v) f =
        ∑ v : Fin m, pathAlgebraMul m (vertexIdempotent m v) f from
  Finset.sum_induction _ _ (fun a b => by rw [pathAlgebra_right_distrib])
    (by simp [pathAlgebra_zero_mul]) _]
-- (Or use Finset.induction_on with a custom step lemma.)
-- Now goal: (∑ v, e_v * f) c = f c.
rw [sum_pathAlg_apply]
-- Step 3: evaluate each term via L1.5.
cases c with
| id z =>
  simp_rw [vertexIdempotent_mul_apply]
  -- Each term is (if v = z then f (.id z) else 0). Sum = f (.id z).
  rw [Finset.sum_eq_single z]
  · simp [if_pos rfl]
  · intros v _ hv; simp [if_neg hv]
  · intro h; exact absurd (Finset.mem_univ _) h
| edge u w =>
  simp_rw [vertexIdempotent_mul_apply]
  rw [Finset.sum_eq_single u]
  · simp [if_pos rfl]
  · intros v _ hv; simp [if_neg hv]
  · intro h; exact absurd (Finset.mem_univ _) h
```

**Risk:** medium. The `Finset.sum_induction` step (distribute over
the sum) requires both `pathAlgebra_right_distrib` and
`pathAlgebra_zero_mul` from Layer 2. Anticipated 80 LOC.

### L3.2 — `pathAlgebra_mul_one`

Symmetric using `mul_vertexIdempotent_apply`. Anticipated 70 LOC.

---

## Layer 4 — Ring instance (~80 LOC)

```lean
noncomputable instance pathAlgebraQuotient.instRing (m : ℕ) :
    Ring (pathAlgebraQuotient m) where
  mul := pathAlgebraMul m
  mul_assoc := pathAlgebraMul_assoc m
  one := pathAlgebraOne m
  one_mul := pathAlgebra_one_mul m
  mul_one := pathAlgebra_mul_one m
  left_distrib := pathAlgebra_left_distrib m
  right_distrib := pathAlgebra_right_distrib m
  mul_zero := pathAlgebra_mul_zero m
  zero_mul := pathAlgebra_zero_mul m
  -- Add, neg, sub, AddCommGroup fields inherited from Pi.addCommGroup
  __ := pathAlgebraQuotient.addCommGroup m
```

**Risk:** low. Composition. Anticipated 80 LOC including any
typeclass-resolution adjustments.

---

## Layer 5 — Algebra ℚ + decompose + basis (~300 LOC)

### L5.1 — Smul-mul compatibility

```lean
theorem pathAlgebra_smul_mul (m : ℕ) (r : ℚ) (f g : pathAlgebraQuotient m) :
    pathAlgebraMul m (r • f) g = r • pathAlgebraMul m f g

theorem pathAlgebra_mul_smul (m : ℕ) (r : ℚ) (f g : pathAlgebraQuotient m) :
    pathAlgebraMul m f (r • g) = r • pathAlgebraMul m f g
```

Both follow from bilinearity: `(r • f) a · g(b) = r · f(a) · g(b)`
distributes. Anticipated ~80 LOC.

### L5.2 — `Algebra ℚ` instance

```lean
noncomputable instance pathAlgebraQuotient.instAlgebra (m : ℕ) :
    Algebra ℚ (pathAlgebraQuotient m) :=
  Algebra.ofModule
    (fun r f g => (pathAlgebra_smul_mul m r f g).symm)
    (fun r f g => (pathAlgebra_mul_smul m r f g).symm)
```

Anticipated ~30 LOC.

### L5.3 — `pathAlgebra_decompose`

```lean
theorem pathAlgebra_decompose (m : ℕ) (f : pathAlgebraQuotient m) :
    f = (∑ v : Fin m, f (.id v) • vertexIdempotent m v) +
        (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2)
```

Proof: `funext c; cases c`. Each side reduces to `f c` after
evaluating the basis-element decomposition. Anticipated ~80 LOC.

### L5.4 — `pathAlgebraQuotient_basis`

Construct a `Basis (QuiverArrow m) ℚ (pathAlgebraQuotient m)` via
`Basis.ofEquivFun (LinearEquiv.refl ℚ (QuiverArrow m → ℚ))` (since
`pathAlgebraQuotient m = QuiverArrow m → ℚ` is already the free
module). Anticipated ~50 LOC including the type-alias bridge via a
`LinearEquiv`.

---

## Layer 6 — Phase C: Idempotent + complete orthogonal decomposition theory (~600 LOC)

### Mathematical correction (2026-04-26 finding)

The originally-planned `isPrimitive_iff_vertex` characterization
is **mathematically false** in `F[Q_G] / J²`. Counterexample:
`e_v + α · α(v, w)` (for `w ≠ v`, any `α ∈ ℚ`) is idempotent and
primitive, but not a vertex idempotent.

In `F[Q_G] / J²`, primitive idempotents are *conjugate* to vertex
idempotents (Auslander–Reiten–Smalø III.2), not equal to them. The
correct rigidity argument therefore proceeds via **complete
orthogonal idempotent decompositions** (which ARE unique up to
conjugation) plus a Wedderburn–Mal'cev-style conjugation lemma.

This Layer 6 is a corrected scaffold; the new Layer 6b below
implements the Wedderburn–Mal'cev step.

### L6.1 — Idempotent characterization at linear-combination level (LANDED)

```lean
theorem pathAlgebra_isIdempotentElem_iff (b : pathAlgebraQuotient m) :
    IsIdempotentElem b ↔
    (∀ v, b (.id v) ^ 2 = b (.id v)) ∧
    (∀ u v, b (.edge u v) = b (.id u) * b (.edge u v) + b (.edge u v) * b (.id v))
```

Proof: `congrFun` at vertex / arrow indices via `pathAlgebraMul_apply_id`
and `pathAlgebraMul_apply_edge`. ~80 LOC. **LANDED.**

### L6.2 — Coefficient consequences (LANDED)

```lean
theorem pathAlgebra_idempotent_lambda_squared
    (h : IsIdempotentElem b) (v : Fin m) :
    b (.id v) = 0 ∨ b (.id v) = 1
theorem pathAlgebra_idempotent_mu_constraint
    (h : IsIdempotentElem b) (u v : Fin m) :
    b (.edge u v) = 0 ∨ b (.id u) + b (.id v) = 1
```

Anticipated ~50 LOC. **LANDED.**

### L6.3 — `IsPrimitiveIdempotent` definition (LANDED)

Hand-rolled (Mathlib lacks this predicate). ~30 LOC. **LANDED.**

### L6.4 — `vertexIdempotent_isPrimitive` (LANDED)

`e_v` is a primitive idempotent. Proof via decomposition argument:
helper lemmas `vertexIdempotent_decomp_lambda_at_v` /
`vertexIdempotent_decomp_lambda_off_v` reduce to the case
`b₁(.id w) = 0 ∀ w` (or symmetric for `b₂`); idempotency at
`.edge u w` then evaluates to `0 + 0 = 0`. ~150 LOC. **LANDED.**

### L6.5 — `isPrimitive_iff_vertex` is FALSE (LANDED as documentation)

Replaced by:
* `vertex_implies_isPrimitive`: forward direction (true) re-export.
* `exists_nonVertex_idempotent`: explicit constructive
  counterexample `e_v + α(v, w)` for `m ≥ 2`. **LANDED.**

### L6.6 — `AlgEquiv` preserves `IsIdempotentElem` and `IsPrimitiveIdempotent` (LANDED)

```lean
theorem AlgEquiv_preserves_isIdempotentElem
    (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsIdempotentElem b) :
    IsIdempotentElem (φ b)

theorem AlgEquiv_preserves_isPrimitiveIdempotent
    (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsPrimitiveIdempotent b) :
    IsPrimitiveIdempotent (φ b)
```

Direct from `AlgEquivClass.map_mul`, `map_add`, `map_zero` plus
the symm-pullback for the decomposition. ~60 LOC. **LANDED.**

### L6.7 — `CompleteOrthogonalIdempotents` recap (NEW, uses Mathlib structure)

Mathlib provides `CompleteOrthogonalIdempotents` in
`Mathlib.RingTheory.Idempotents`:
```lean
structure CompleteOrthogonalIdempotents {ι : Type*} [Fintype ι] {R : Type*}
    [Semiring R] (e : ι → R) : Prop where
  idem : ∀ i, IsIdempotentElem (e i)
  ortho : Pairwise (fun i j => e i * e j = 0)
  complete : ∑ i, e i = 1
```

This is the right vehicle for Phase F's vertex permutation
extraction.

**Reuse:** Mathlib's `OrthogonalIdempotents.mul_eq` and the
`CompleteOrthogonalIdempotents` API.

### L6.8 — `vertexIdempotent` family is a `CompleteOrthogonalIdempotents` (NEW, ~80 LOC)

```lean
theorem vertexIdempotent_completeOrthogonal (m : ℕ) :
    CompleteOrthogonalIdempotents (vertexIdempotent m)
```

Proof:
* `idem`: by `vertexIdempotent_isIdempotentElem` (L6.4 prereq).
* `ortho`: by `vertexIdempotent_mul_vertexIdempotent` and
  `Ne.symm` plus `if_neg`.
* `complete`: `pathAlgebraOne` is *defined* as `∑_v
  vertexIdempotent v`; this is `rfl` modulo unfolding.

Anticipated ~80 LOC.

### L6.9 — `AlgEquiv` preserves `CompleteOrthogonalIdempotents` (NEW, ~60 LOC)

```lean
theorem AlgEquiv_preserves_completeOrthogonalIdempotents
    {A B : Type*} [Ring A] [Ring B] [Algebra ℚ A] [Algebra ℚ B]
    [Fintype ι]
    (φ : A ≃ₐ[ℚ] B) {e : ι → A}
    (h : CompleteOrthogonalIdempotents e) :
    CompleteOrthogonalIdempotents (φ ∘ e)
```

Each field follows from L6.6 + `AlgEquivClass.map_mul` +
`AlgEquivClass.map_sum` + `map_one`.

### L6.10 — Cardinality fact (NEW, ~30 LOC)

```lean
-- The vertex idempotent COI has cardinality `m`.
-- Useful for ruling out COIs of different cardinalities.
theorem vertexIdempotent_coi_card (m : ℕ) :
    Fintype.card (Fin m) = m
```

Trivial; used as a building block.

---

## Layer 6b — Phase C-bis: Wedderburn–Mal'cev conjugation for `F[Q_G] / J²` (NEW, ~400 LOC)

### Context

The Wedderburn–Mal'cev theorem for finite-dimensional algebras over
characteristic-zero fields says: any two complete orthogonal
idempotent decompositions of `1` are conjugate by an inner
automorphism. For our radical-2 truncated path algebra, the
statement and proof simplify dramatically because `J² = 0`.

### L6b.1 — Jacobson radical of the path algebra (NEW, ~80 LOC)

```lean
/-- The arrow span — the Jacobson radical of `F[Q_G] / J²`. -/
def pathAlgebraRadical (m : ℕ) : Submodule ℚ (pathAlgebraQuotient m) :=
  Submodule.span ℚ
    (Set.range (fun (p : Fin m × Fin m) => arrowElement m p.1 p.2))

theorem pathAlgebraRadical_mul_radical_eq_zero (m : ℕ)
    (j₁ j₂ : pathAlgebraQuotient m)
    (h₁ : j₁ ∈ pathAlgebraRadical m) (h₂ : j₂ ∈ pathAlgebraRadical m) :
    j₁ * j₂ = 0
```

Proof: every element of `pathAlgebraRadical m` is a finite ℚ-linear
combination of `arrowElement` values. By bilinearity of
multiplication and `arrowElement_mul_arrowElement_eq_zero` (L1.4),
all cross-terms are zero. ~80 LOC.

### L6b.2 — Element decomposition modulo radical (NEW, ~120 LOC)

```lean
/-- Every element is a sum of its "vertex part" and "arrow part",
    where the arrow part is in the radical. -/
theorem pathAlgebra_decompose_radical (m : ℕ) (b : pathAlgebraQuotient m) :
    ∃ s : pathAlgebraQuotient m,
      (s ∈ pathAlgebraRadical m) ∧
      b = (∑ v : Fin m, b (.id v) • vertexIdempotent m v) + s ∧
      s = (∑ p : Fin m × Fin m, b (.edge p.1 p.2) • arrowElement m p.1 p.2)
```

Direct from `pathAlgebra_decompose` (L5.3); set
`s := ∑_{(u,v)} b(.edge u v) • α(u, v)`. Membership in radical from
the definition. ~120 LOC.

### L6b.3 — Wedderburn–Mal'cev for J² = 0 (NEW, ~150 LOC)

**Key theorem.** Let `e' : Fin m → pathAlgebraQuotient m` be a
complete orthogonal idempotent decomposition (COI) of size `m`.
Then there exists `j ∈ pathAlgebraRadical m` and `σ : Equiv.Perm
(Fin m)` such that `(1 + j) * vertexIdempotent v * (1 - j) = e' (σ
v)` for all `v`.

```lean
theorem wedderburn_malcev_conjugacy (m : ℕ)
    (e' : Fin m → pathAlgebraQuotient m)
    (h : CompleteOrthogonalIdempotents e') :
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m v * (1 - j) = e' (σ v)
```

**Proof sketch.** Decompose each `e' v = (∑_w (e' v)(.id w) • e_w) + j_v`
where `j_v ∈ J`. Idempotency of `e' v` constrains the vertex
coefficients to be 0 or 1. Orthogonality `(e' v) * (e' w) = 0` for
`v ≠ w` plus completeness `∑_v e' v = 1` forces the vertex
coefficients to be a permutation matrix: there's a unique σ such
that `(e' v)(.id w) = 1` iff `w = σ v`. The arrow components `j_v`
are constrained but non-zero in general; the conjugation by
`(1 + j)` (with `j = ∑_v j_v · e_{σ v}` or similar explicit formula)
moves them away.

Computation: `(1 + j) * e_v * (1 - j) = e_v + j · e_v - e_v · j -
j · e_v · j = e_v + j · e_v - e_v · j` (last term vanishes by J² =
0). The choice `j = ∑_v (vertex part of e' v - e_v)` adjusted by
the σ-permutation makes this equal `e' (σ v)`.

**Risk:** medium-high. The combinatorics of choosing `j` correctly
is delicate. Anticipated ~150 LOC. **Mitigation:** if the explicit
construction is too complex, factor into:
* L6b.3a: the σ permutation extraction from vertex coefficients
  (using L6.2 + completeness, ~50 LOC).
* L6b.3b: the conjugating element construction (~50 LOC).
* L6b.3c: the conjugation identity verification (~50 LOC).

### L6b.4 — Conjugation by `1 + j` is an inner algebra automorphism (NEW, ~50 LOC)

```lean
/-- For `j ∈ pathAlgebraRadical m`, `1 + j` is invertible (with
    inverse `1 - j` since `j² = 0`). -/
theorem one_add_radical_invertible (m : ℕ) (j : pathAlgebraQuotient m)
    (h : j ∈ pathAlgebraRadical m) :
    (1 + j) * (1 - j) = 1 ∧ (1 - j) * (1 + j) = 1

/-- The associated inner automorphism. -/
noncomputable def innerAutOfRadical (m : ℕ) (j : pathAlgebraQuotient m)
    (h : j ∈ pathAlgebraRadical m) :
    pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m
```

Build via `AlgEquiv.ofBijective` from the conjugation `x ↦ (1 + j)
* x * (1 - j)`. Bijective because `j² = 0` makes `1 + j` and `1 - j`
two-sided inverses. ~50 LOC.

---

## Layer 7 — Phase D: distinguished-padding rigidity (~700 LOC, HIGH RISK)

The user pre-approved a Prop-hypothesis fallback for D.2 if the
elementary cardinality argument fails. The plan in Phase D from the
original (now-overwritten) plan is preserved as the structural
roadmap; specific helper lemmas:

* **D.1–D.3**: define `isVertexSignature`, `isPaddingSignature`,
  `isArrowSignature` predicates on `Tensor3 n ℚ` with concrete
  diagonal-row signature thresholds.
* **D.4**: encoder-side: `isVertexSignature (grochowQiaoEncode m
  adj) i ↔ ∃ v, slotEquiv m i = .vertex v`.
* **D.5–D.7**: encoder slot classification + edge case for isolated
  vertices (the row-signature uniqueness bound).
* **D.8**: row-signature determines slot kind (with the user-approved
  Prop fallback `GLPreservesVertexSignatureBijection` if the
  elementary argument fails).
* **D.9–D.12**: GL³ preserves signatures (the highest-risk piece;
  ~250 LOC if elementary, switch to D.10 Prop hypothesis fallback
  if it stalls).
* **D.13–D.15**: extract `extractVertexPermutation` σ : Equiv.Perm
  (Fin m).

Anticipated total: ~700 LOC. **If D.12 fails elementarily, switch to
the Prop hypothesis fallback per user pre-approval.**

---

## Layer 8 — Phase E: GL³ → AlgEquiv lift (~350 LOC)

### L8.1 — Construct the linear map

```lean
noncomputable def gl_to_algebraMap
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL × GL × GL) (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂)
    (σ : Equiv.Perm (Fin m)) (h_σ : ...) :
    pathAlgebraQuotient m →ₗ[ℚ] pathAlgebraQuotient m
```

Built from the σ extracted in Phase D, mapping `vertexIdempotent v`
to `vertexIdempotent (σ v)` and similarly for arrows. Use the
`pathAlgebraQuotient_basis` (L5.4) to define the linear map on a
basis and extend by linearity.

### L8.2 — Multiplicativity via L1.* lemmas

The map preserves multiplication on basis elements (by L1.1–L1.4
applied at the σ-permuted vertex/arrow). Lift to general elements
via bilinearity (Layer 2 distributivity).

### L8.3 — Unit preservation

`map(1) = 1` since `map(∑_v e_v) = ∑_v e_{σ v} = ∑_v e_v` (sum over
a permuted index set).

### L8.4 — Bijectivity from GL invertibility

The map has an inverse via `σ⁻¹`. Construct via `LinearEquiv` then
upgrade to `AlgEquiv.ofBijective`.

### L8.5 — Assemble `AlgEquiv`

Combine L8.1–L8.4 into the final `AlgEquiv pathAlgebraQuotient m
≃ₐ[ℚ] pathAlgebraQuotient m`.

Anticipated total: ~350 LOC.

---

## Layer 9 — Phase F: vertex permutation + adjacency via COI conjugation (~600 LOC)

### Mathematical correction

The originally-planned Phase F used the (false) `isPrimitive_iff_vertex`
to extract the vertex permutation. The corrected approach uses
**complete orthogonal idempotent decompositions** + the
**Wedderburn–Mal'cev conjugation lemma** (Layer 6b).

### L9.1 — Composite COI-permutation extraction (NEW, ~150 LOC)

```lean
/-- AlgEquiv applied to the vertex idempotent COI yields another
    COI of size m. By Wedderburn–Mal'cev (L6b.3), this image COI
    is conjugate (via an inner automorphism by `1 + j` with `j`
    in the radical) to the original COI, up to a permutation σ. -/
theorem algEquiv_extractVertexPerm
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) :
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        φ (vertexIdempotent m v) =
          (1 + j) * vertexIdempotent m (σ v) * (1 - j)
```

**Proof.** Apply `AlgEquiv_preserves_completeOrthogonalIdempotents`
(L6.9) to `vertexIdempotent_completeOrthogonal` (L6.8), giving a
COI `φ ∘ vertexIdempotent`. By Wedderburn–Mal'cev (L6b.3) applied
to this image COI, there exists σ and j such that
`(1 + j) * vertexIdempotent (σ v) * (1 - j) = φ (vertexIdempotent v)`
for each v. ~150 LOC.

### L9.2 — Sandwich-isolation lemma via L1.2 + L1.3 + L1.4 (~120 LOC)

For `f : pathAlgebraQuotient m`,
`e_u * f * e_v = f(.edge u v) • arrowElement m u v + f(.id u) • vertexIdempotent m u · ?`

Actually the cleaner statement: in any path algebra,
```lean
theorem vertex_sandwich_isolates_arrow
    (m : ℕ) (u v : Fin m) (f : pathAlgebraQuotient m) (h_uv : u ≠ v) :
    vertexIdempotent m u * f * vertexIdempotent m v =
    f (.edge u v) • arrowElement m u v
```

For `u = v` the sandwich also includes the `e_v · 1 · e_v = e_v`
contribution, so the statement carries a `u ≠ v` hypothesis.
Anticipated ~120 LOC.

### L9.3 — Arrow-image structure under conjugation by `1 + j` (NEW, ~150 LOC)

```lean
/-- Conjugating an arrow basis element by `1 + j` (with j in the
    radical) gives back the same arrow modulo radical contributions
    that vanish in the J² = 0 setting:
    `(1 + j) * α(u, v) * (1 - j) = α(u, v)` because every other term
    involves a product of two arrows. -/
theorem inner_aut_preserves_arrow
    (m : ℕ) (j : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m)
    (u v : Fin m) :
    (1 + j) * arrowElement m u v * (1 - j) = arrowElement m u v
```

Proof: expand `(1 + j) * α * (1 - j) = α + j · α - α · j - j · α · j`.
The last term is `j · α · j` where `j · α ∈ J · J = 0` and `α · j ∈
J · J = 0`. So `j · α = 0` and `α · j = 0` (using L6b.1's `J · J = 0`),
hence the entire expression collapses to `α`. ~80 LOC.

This means: under the inner automorphism `c ↦ (1 + j) * c * (1 - j)`,
arrows are FIXED. So the φ-image of arrows can be characterized
purely from the σ-permutation of vertex idempotents.

### L9.4 — Arrow image determined by σ + scalar (NEW, ~120 LOC)

```lean
/-- AlgEquiv image of an arrow has the form `c • arrowElement (σu) (σv)`
    for some non-zero scalar c, where σ is the vertex permutation
    extracted in L9.1. -/
theorem algEquiv_arrow_image_scalar
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m)
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_σ_j : ∀ v, φ (vertexIdempotent m v) =
                  (1 + j) * vertexIdempotent m (σ v) * (1 - j))
    (h_j : j ∈ pathAlgebraRadical m)
    (u v : Fin m) (h_uv : u ≠ v) :
    ∃ c : ℚ, c ≠ 0 ∧
      φ (arrowElement m u v) = c • arrowElement m (σ u) (σ v)
```

**Proof.** Use `arrowElement m u v = vertexIdempotent m u *
arrowElement m u v * vertexIdempotent m v` (sandwich identity).
Apply φ:
```
φ(α(u, v)) = φ(e_u) · φ(α(u, v)) · φ(e_v)
           = ((1 + j) e_{σu} (1 - j)) · φ(α(u, v)) · ((1 + j) e_{σv} (1 - j))
```
By L9.3, the inner conjugation `c ↦ (1 + j) c (1 - j)` fixes
arrows. So the central `e_{σu} · ? · e_{σv}` of the inner
expression projects out to `(? at index .edge (σu) (σv)) · α(σu, σv)`
by L9.2 (sandwich-isolates-arrow). Pulling out the conjugation
gives `c • α(σu, σv)` for some scalar `c`. Non-zero because φ is
injective and `α(u, v) ≠ 0`.

~120 LOC.

### L9.5 — Adjacency invariance via arrow image (NEW, ~80 LOC)

The vertex permutation σ extracted in L9.1 from a tensor
isomorphism (which factors through an AlgEquiv) preserves adjacency:

```lean
theorem algEquiv_adj_preservation
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m)
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_σ_j : ∀ v, φ (vertexIdempotent m v) =
                  (1 + j) * vertexIdempotent m (σ v) * (1 - j))
    -- Plus the φ-arises-from-tensor-isomorphism hypothesis
    (h_arrow_compat : ∀ u v, adj₁ u v = true ↔ adj₂ (σ u) (σ v) = true) :
    ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)
```

The `h_arrow_compat` hypothesis comes from threading the encoder
equivariance through the conjugation. Specifically: when `φ` arises
from a tensor iso, the φ-image of `arrowElement u v` lives in the
"image" path algebra (= `pathAlgebraQuotient` for `adj₂`), so its
non-zeroness corresponds to `adj₂ (σu) (σv) = true`.

~80 LOC.

### Total Phase F: ~620 LOC.

---

## Layer 10 — Phase G: reverse direction discharge (~400 LOC)

### L10.1 — `GL_triple_yields_vertex_permutation`

Compose Phase D (extract slot bijection π) → Phase E (lift to
AlgEquiv) → Phase F (extract vertex permutation σ from AlgEquiv +
adjacency invariance). Anticipated ~250 LOC.

### L10.2 — `grochowQiao_rigidity` discharge

```lean
theorem grochowQiao_rigidity : GrochowQiaoRigidity := by
  intro m adj₁ adj₂ ⟨g, hg⟩
  match m with
  | 0 => exact grochowQiaoEncode_reverse_zero adj₁ adj₂ ⟨g, hg⟩
  | n + 1 =>
    have h_m : 1 ≤ m := by omega
    exact GL_triple_yields_vertex_permutation (n+1) h_m adj₁ adj₂ g hg
```

If Phase D took the Prop fallback, this becomes
`grochowQiao_rigidity_under_hyp` taking the additional Prop. Anticipated
~150 LOC.

---

## Layer 11 — Phase H: final assembly + Documentation (~150 LOC)

### L11.1 — `grochowQiao_isInhabitedKarpReduction`

Compose B.8 (forward obligation, already discharged) + L10.2
(rigidity, newly discharged) into the unconditional inhabitant:
```lean
theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_obligations
    grochowQiao_forwardObligation
    grochowQiao_rigidity
```

If Phase D took the Prop fallback, this is
`grochowQiao_isInhabitedKarpReduction_conditional` taking the Prop.

### L11.2 — Audit script extensions

New `#print axioms` entries for every Layer 1–11 declaration; new
non-vacuity examples on K_3 and a non-isomorphic 4-vertex pair.

### L11.3 — Documentation sweep

* `CLAUDE.md`: new "Workstream R-TI Layers C–H complete (or Layer
  D Prop hypothesis)" change-log entry.
* `Orbcrypt.lean`: extend transparency report; update Vacuity map.
* `docs/VERIFICATION_REPORT.md`: Document history + Headline results
  table extension.
* `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`: mark
  R-15-residual-TI-reverse closed (or partial).
* `lakefile.lean`: version bump `0.1.19 → 0.1.20`.

---

## Implementation order (strict dependency chain)

Execute layer-by-layer; do **not** start Layer N until Layer N–1
compiles cleanly with zero warnings.

1. **Layer 1** (basis-element multiplication table, ~250 LOC).
   Five lemmas: `vertexIdempotent_mul_vertexIdempotent`,
   `vertexIdempotent_mul_arrowElement`,
   `arrowElement_mul_vertexIdempotent`,
   `arrowElement_mul_arrowElement_eq_zero`,
   `vertexIdempotent_mul_apply` + `mul_vertexIdempotent_apply`.
   **Commit checkpoint after Layer 1 lands.**

2. **Layer 2** (distrib + annihilation, ~150 LOC). Each lemma is a
   one-step `simp_rw` + `Finset.sum_add_distrib`. **Commit
   checkpoint.**

3. **Layer 3** (one_mul + mul_one via Layer 1.5 + Layer 2, ~150 LOC).
   The Finset.sum_induction over `pathAlgebraOne = ∑_v e_v` plus
   per-c evaluation via L1.5.

4. **Layer 4** (Ring instance, ~80 LOC). Pure assembly. **Commit
   checkpoint after Algebra typeclass infrastructure lands.**

5. **Layer 5** (Algebra ℚ + decompose + basis, ~300 LOC). Smul-mul
   compatibility, then `Algebra.ofModule`, then decomposition,
   then basis. **Commit + push.**

6. **Layer 6** (Phase C — idempotent + COI theory, ~600 LOC).
   * L6.1–L6.6: idempotent characterization and basic primitivity
     (LANDED in commits up to `9ab5928`).
   * L6.7–L6.10: NEW work — `CompleteOrthogonalIdempotents`
     family for vertex idempotents, AlgEquiv preservation,
     cardinality fact. Each ~50–80 LOC. Reuses Mathlib's
     `Mathlib.RingTheory.Idempotents` API.

6b. **Layer 6b** (Phase C-bis — Wedderburn–Mal'cev for J²=0, ~400 LOC,
    NEW).
    * L6b.1: Jacobson radical = arrow span; J · J = 0.
    * L6b.2: element decomposition modulo radical.
    * L6b.3: Wedderburn–Mal'cev conjugacy lemma (HIGH RISK,
      ~150 LOC). Sub-layered into L6b.3a/b/c.
    * L6b.4: inner automorphism `c ↦ (1 + j) c (1 - j)` is a valid
      `AlgEquiv`.
    * **Risk profile.** L6b.3 is medium-high risk because the
      explicit construction of `j` is delicate. **Mitigation:**
      sub-layer into 3 helpers; if intractable, factor as a Prop
      hypothesis `WedderburnMalcevConjugacy m` (analogous to
      `GrochowQiaoRigidity`) for a *conditional* Phase F. Per
      user pre-approval policy.

7. **Layer 7** (Phase D — rigidity, ~700 LOC, **HIGH RISK**).
   * Time-box D.11/D.12 to ~6 hours. If elementary proof fails,
     switch to Prop hypothesis fallback per user pre-approval.
   * Layer 7 is one of two places (along with L6b.3) where
     sorry/axiom may need to be requested (per user policy
     "pause per-occurrence" for non-D.2 sorry candidates).

8. **Layer 8** (Phase E — AlgEquiv lift, ~350 LOC).

9. **Layer 9** (Phase F — vertex perm + adjacency via COI conjugation, ~620 LOC).
   * Reduced from the originally-planned 770 LOC because the
     `CompleteOrthogonalIdempotents` machinery from L6.7–L6.10 +
     L6b.3 (Wedderburn–Mal'cev) does most of the heavy lifting.
   * L9.1: σ extraction via L6b.3 (~150 LOC).
   * L9.2: sandwich-isolation lemma (~120 LOC).
   * L9.3: arrow image fixed under inner-radical conjugation
     (~150 LOC).
   * L9.4: arrow image is `c • α(σu, σv)` (~120 LOC).
   * L9.5: adjacency invariance (~80 LOC).

10. **Layer 10** (Phase G — composition, ~400 LOC).

11. **Layer 11** (Phase H — final assembly + docs, ~150 LOC).

### Per-layer verification gate

After each Layer N completes:
1. `lake build Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper`
   (or relevant module) — zero errors, zero warnings.
2. `lake env lean scripts/audit_phase_16.lean | grep "^error"` —
   empty output.
3. `lake env lean scripts/audit_phase_16.lean | grep "sorryAx"` —
   empty output.
4. New `#print axioms` for every Layer N public declaration —
   only `[propext, Classical.choice, Quot.sound]` allowed.

If any of (1)–(4) fail, do **not** advance to Layer N+1. Pause and
diagnose.

---

## Critical files (paths + reuse map)

### Files to modify

* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean`
  — extended with Layers 1–5 + Phase C (or split off into
  `Idempotents.lean` if the file exceeds ~1500 LOC).
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Reverse.lean`
  — extended with Phase G (rigidity discharge) if not too large.
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao.lean`
  — extended with the unconditional inhabitant (Phase H).
* `/home/user/Orbcrypt/Orbcrypt.lean` — root file imports + axiom
  transparency report extension.
* `/home/user/Orbcrypt/scripts/audit_phase_16.lean` — new
  `#print axioms` entries + non-vacuity witnesses.
* `/home/user/Orbcrypt/lakefile.lean` — version bump.
* `/home/user/Orbcrypt/CLAUDE.md` — change-log entry.
* `/home/user/Orbcrypt/docs/VERIFICATION_REPORT.md` — Document
  history.
* `/home/user/Orbcrypt/docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  — mark closed.

### Files to potentially create (since AlgebraWrapper.lean has now exceeded ~1700 LOC)

* `Orbcrypt/Hardness/GrochowQiao/CompleteOrthogonal.lean` (NEW, ~600
  LOC) — Layer 6.7–6.10 content (`CompleteOrthogonalIdempotents`
  machinery for vertex idempotents + AlgEquiv preservation).
* `Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean` (NEW, ~400
  LOC) — Layer 6b content (Jacobson radical, conjugacy lemma,
  inner automorphism). The most algebraically dense module.
* `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` (NEW, ~700 LOC) —
  Phase D content.
* `Orbcrypt/Hardness/GrochowQiao/AlgEquivLift.lean` (NEW, ~350 LOC)
  — Phase E content.
* `Orbcrypt/Hardness/GrochowQiao/VertexPerm.lean` (NEW, ~620 LOC) —
  Phase F content (vertex permutation extraction + adjacency
  invariance).

### Existing utilities to reuse

* **`pathAlgebraMul_apply`** (AlgebraWrapper.lean ~123) — explicit
  unfolding of multiplication. Used by every basis-element lemma in
  Layer 1.
* **`vertexIdempotent_apply_id` / `_apply_edge`** (~146–157) —
  basis-evaluation `@[simp]` lemmas; used in Layer 1's
  `Finset.sum_eq_single` proofs.
* **`pathMul_id_id` / `pathMul_id_edge` / `pathMul_edge_id` /
  `pathMul_edge_edge_none`** (PathAlgebra.lean) — multiplication
  table at the basis-element level; used to evaluate the indicator
  `if pathMul a b = some c then ...` when `a, b` are basis elements.
* **`pathMul_assoc`** (PathAlgebra.lean) — already used by
  `pathAlgebraMul_assoc`.
* **`pathMul_indicator_collapse`** (~179) and
  **`pathMul_indicator_collapse_right`** (~219) — indicator-sum
  collapse lemmas; reused by Phase C if needed.
* **`pathAlgebraMul_assoc`** (~394) — multiplicative associativity.
* **`pathAlgebraOne_apply_id` / `_apply_edge`** (~430, 440) —
  basis-evaluation of the multiplicative identity. Used by
  `pathAlgebra_one_mul`.
* **`sum_pathAlg_apply`** (~424) — sum-of-functions evaluation
  helper for the type alias. Reused everywhere a sum-indexed
  expression is evaluated at a coordinate.
* **`liftedSigma`, `liftedSigmaSlot`** (Forward.lean) — slot
  permutation. Reused by Phase D + E for the σ-lift to algebra
  automorphism.
* **`grochowQiaoEncode_equivariant`** (Forward.lean) — encoder
  equivariance. Reused by Phase F to chain the AlgEquiv argument.
* **`GrochowQiaoForwardObligation`, `grochowQiao_forwardObligation`**
  (GrochowQiao.lean) — already discharged (Track B). Reused in
  Phase H final assembly.
* **`grochowQiao_isInhabitedKarpReduction_under_obligations`**
  (GrochowQiao.lean ~265) — pre-existing conditional inhabitant.
  Reused in Phase H.
* **`grochowQiao_isInhabitedKarpReduction_under_rigidity`**
  (GrochowQiao.lean) — pre-existing single-Prop conditional
  inhabitant. Reused in Phase H if the rigidity proof needs an
  extra Prop hypothesis (D.2 fallback path).

---

## Verification

### Per-WU continuous verification

After each WU lands:
```bash
source ~/.elan/env
lake build Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper 2>&1 | tail -10
```
Must succeed with exit code 0, zero errors, zero warnings.

### Per-layer verification

After each Layer N completes:
```bash
lake build 2>&1 | tail -10                                    # full project
lake env lean scripts/audit_phase_16.lean 2>&1 > /tmp/out.txt
grep -c "depends on axioms" /tmp/out.txt                       # count exercised
grep -cE "sorryAx|^error" /tmp/out.txt                          # must be 0
```

### End-to-end verification

After Layer 11 completes:

1. **Headline theorem builds:**
   `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`
   compiles unconditionally (or `_conditional` form if D-fallback
   was taken).

2. **K_3 round-trip example** (audit script):
   ```lean
   example :
     let adj₁ := fun i j : Fin 3 => decide (i ≠ j)  -- K_3
     let adj₂ := fun i j : Fin 3 => decide (i ≠ j)  -- K_3, same
     ∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
     ((grochowQiao_isInhabitedKarpReduction.snd.right 3 _ _).mpr
       (areTensorIsomorphic_refl _))
   ```

3. **Non-isomorphic discriminator example** (audit script):
   For `C_4` vs `K_{1,3}` on 4 vertices, the inhabitant's iff
   direction shows the encoded tensors are NOT isomorphic.

4. **Full project build:** `lake build` succeeds with all WUs
   landed. Job count expected: ~3,400+ jobs.

5. **Audit script:** `lake env lean scripts/audit_phase_16.lean`
   exits 0 with all new entries (~50+ new `#print axioms` lines).

6. **Documentation parity:** `CLAUDE.md`,
   `docs/VERIFICATION_REPORT.md`, `Orbcrypt.lean` Vacuity map all
   reflect that R-TI is **fully closed** (or **conditional on Prop
   hypothesis** if D-fallback was taken).

---

## Risk register (refined)

| Risk | Layer | Severity | Mitigation |
|------|-------|----------|------------|
| Layer 1.1 `split_ifs` chain handles 4 cases correctly | L1.1 | Low-Med | Factor each constructor branch into a private helper if needed (LANDED) |
| `simp_rw [mul_add, add_mul, Finset.sum_add_distrib]` doesn't fully simplify | L2 | Low | Fall back to manual `apply Finset.sum_congr rfl; ring` per term (LANDED) |
| Distribution induction over `Finset.sum` for `(∑_v e_v) * f` | L3.1 | Medium | Use `Finset.induction_on` explicitly (LANDED via `pathAlgebra_sum_mul`) |
| `Algebra.ofModule` smul compatibility direction | L5.2 | Low | Both directions follow from `pathAlgebra_smul_mul` symmetry (LANDED) |
| `Basis.ofEquivFun` typeclass synthesis through alias | L5.4 | Low-Med | Use explicit `LinearEquiv.refl` (LANDED via `pathAlgebra_decompose`) |
| **Mathematical: `isPrimitive_iff_vertex` is FALSE in F[Q_G]/J²** | L6.5 | **DISCOVERED** | Pivoted to COI + Wedderburn–Mal'cev approach (Layers 6.7–6.10 + 6b) |
| `vertexIdempotent_isPrimitive` decomposition argument | L6.4 | Medium | Helpers `decomp_lambda_at_v`/`_off_v` reduce to `b₁(.id _) = 0` ⇒ idempotency at arrows trivializes (LANDED) |
| `CompleteOrthogonalIdempotents` Mathlib API at fa6418a8 | L6.7 | Low | Verified present in `Mathlib.RingTheory.Idempotents` |
| **L6b.3 Wedderburn–Mal'cev conjugacy** | L6b | **HIGH** | The explicit `j` construction is delicate. Sub-layer into 3 helpers (σ extraction, j construction, conjugation verification). If intractable, fall back to Prop hypothesis `WedderburnMalcevConjugacy m`. |
| L6b.1 Jacobson radical = arrow span | L6b.1 | Low | Uses `arrowElement_mul_arrowElement_eq_zero` (LANDED) + bilinearity |
| L6b.4 inner aut from `1 + j` | L6b.4 | Low | `(1+j)(1-j) = 1` because `j² = 0` |
| L9.3 inner aut fixes arrows | L9.3 | Low | Direct from L6b.1 (`j · α = α · j = 0` for arrow α) |
| **Phase D rigidity (D.11/D.12)** | L7 | **HIGH** | User pre-approved Prop fallback; time-box ~6 hours then switch |
| AlgEquiv construction from σ + basis | L8.1 | Medium | Use `Basis.constr` Mathlib idiom |
| Sandwich-isolation lemma elaboration | L9.2 | Medium | Prove via `funext` + `pathAlgebra_decompose` + L1.2/L1.3/L1.4 |
| Total LOC blows past 5000 | All | Low | Acceptable; user has authorised |

---

## Summary

**Refined strategy** (post-2026-04-26 mathematical correction):

1. Build basis-element multiplication table (Layer 1) as `@[simp]`
   lemmas FIRST. **LANDED.**
2. Use bilinearity (Layer 2) to lift to general elements; prove
   `one_mul`/`mul_one` via Layer-3 induction over the vertex sum.
   **LANDED.**
3. Assemble `Ring` + `Algebra ℚ` typeclasses (Layers 4–5).
   **LANDED.**
4. Phase C / Layer 6 (~600 LOC, **partially LANDED**):
   - **LANDED**: idempotent characterization, vertex idempotent is
     primitive, AlgEquiv preservation, mathematical finding that
     `isPrimitive_iff_vertex` is FALSE.
   - **Remaining (NEW)**: `CompleteOrthogonalIdempotents` for
     vertex idempotents, AlgEquiv preservation of COIs.
5. **NEW Layer 6b** (~400 LOC): Wedderburn–Mal'cev conjugacy for
   `J² = 0`. The deep algebraic content that closes the
   "primitive idempotents are conjugate to vertex idempotents" gap.
6. Phase D (Layer 7, ~700 LOC, HIGH RISK): rigidity argument.
7. Phase E (Layer 8, ~350 LOC): AlgEquiv lift from GL³.
8. Phase F (Layer 9, ~620 LOC): vertex permutation extraction via
   COI conjugation (uses Layer 6b's Wedderburn–Mal'cev).
9. Phase G (Layer 10, ~400 LOC) + Phase H (Layer 11, ~150 LOC):
   composition + final assembly.

**Total scope** (post-pivot): **~3,620 LOC** across 12 layers
(Layer 6b is new). The user has authorised completing all phases.

**Mathematical soundness:** the corrected approach uses
`CompleteOrthogonalIdempotents` (which ARE unique up to conjugation
in a finite-dimensional algebra over ℚ) plus the Wedderburn–Mal'cev
theorem (which simplifies dramatically when `J² = 0`). This is the
standard textbook approach (Auslander–Reiten–Smalø III.2; Pierce
*Associative Algebras* §11) and is correct for `F[Q_G] / J²` over
characteristic-zero fields.

**Sorry/axiom posture:** Layers 1–6 (LANDED) used zero sorry / zero
custom axioms. Layers 6.7–6.10 are mechanical extensions and should
also stay sorry-free. Layer 6b.3 (Wedderburn–Mal'cev) is the new
HIGH-RISK piece; user may need to approve a Prop hypothesis fallback
if the explicit construction is intractable. Layer 7 (Phase D
rigidity) retains its pre-approved Prop fallback.

**Confidence in completion without sorry**:
* Layers 1–5 (Algebra typeclass): **LANDED ✓** (no sorry).
* Layer 6 LANDED portion: **DONE ✓** (no sorry).
* Layer 6.7–6.10 (COI + AlgEquiv preservation): **~85%** confidence.
* **Layer 6b (Wedderburn–Mal'cev): ~50% confidence**, fallback to
  Prop hypothesis available.
* Layer 7 (Phase D rigidity): **~50%** confidence; fallback
  available.
* Layers 8–11 (Phase E–H): **~85%** confidence assuming Layers 6b
  and 7 succeed (or their Prop fallbacks are taken).

**Implementation can resume immediately upon plan approval.**

**Confidence in completion without sorry**:
* Layers 1–5 (Algebra typeclass): **~85%** confidence.
* Layers 6 (Phase C): **~80%** confidence.
* Layer 7 (Phase D rigidity): **~50%** confidence; fallback to Prop
  hypothesis available.
* Layers 8–11 (Phase E–H): **~85%** confidence assuming Layer 7
  succeeds (or its Prop fallback is taken).

**Implementation can begin immediately upon plan approval.**

## Mathlib API status (commit `fa6418a8`, verified)

| API | Available? | Path | Use |
|-----|-----------|------|-----|
| `Algebra.ofModule` | ✓ | `Mathlib/Algebra/Algebra/Defs.lean` | Phase A path-algebra wrapper |
| `Equiv.Perm.permMatrix` | ✓ | `Mathlib/LinearAlgebra/Matrix/Permutation.lean` | Phase B GL³ matrix lift |
| `Matrix.permMatrix_mul` | ✓ | (same) | Phase B invertibility |
| `IsIdempotentElem` | ✓ | `Mathlib/Algebra/Ring/Idempotent.lean` | Phase C primitivity |
| `OrthogonalIdempotents` structure | ✓ | `Mathlib/RingTheory/Idempotents.lean` | Phase C helpers |
| `IsPrimitiveIdempotent` | ✗ NOT in Mathlib | — | **Hand-roll in Phase C.2** |
| `AlgEquiv` | ✓ | `Mathlib/Algebra/Algebra/Equiv.lean` | Phase E AlgEquiv from GL³ |
| `Ideal.jacobson` | ✓ | `Mathlib/RingTheory/Jacobson/Ideal.lean` | Phase D radical theory |
| `Module.finBasis` | ✓ | `Mathlib/LinearAlgebra/Dimension/Free.lean` | Phase A basis indexing |
| `Finset.sum_eq_single` | ✓ | `Mathlib/Algebra/BigOperators/` | Phase B triple-sum collapse |

## Architecture (file organisation)

| File | Status | Lines added | Purpose |
|------|--------|-------------|---------|
| `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` | Extend | +400 | T1.7 `pathMul_assoc` + linear-combination helpers |
| `Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean` | NEW | ~300 | T4.8 `pathAlgebraQuotient` Mathlib `Algebra ℚ` |
| `Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean` | NEW | ~250 | T3.6 permutation-matrix tensor-action |
| `Orbcrypt/Hardness/GrochowQiao/Forward.lean` | Extend | +150 | T3.6 forward GL³ action discharge |
| `Orbcrypt/Hardness/GrochowQiao/Idempotents.lean` | NEW | ~400 | Phase C primitive-idempotent theory |
| `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` | NEW | ~600 | Phase D + E partition + AlgEquiv |
| `Orbcrypt/Hardness/GrochowQiao/Reverse.lean` | Extend | +400 | Phase F + G full reverse direction |
| `Orbcrypt/Hardness/GrochowQiao.lean` | Extend | +50 | T6.3 unconditional inhabitant |
| `scripts/audit_phase_16.lean` | Extend | +200 | New `#print axioms` + non-vacuity examples |
| `Orbcrypt.lean` | Extend | +80 | Workstream snapshot + axiom transparency |
| `lakefile.lean` | Edit | 1 line | Bump `0.1.18 → 0.1.19` |

**Total: ~2,830 new lines of Lean code across 8 files (5 new modules,
3 extensions).**

---

## Phase A — Path Algebra as Mathlib `Algebra ℚ` (T1.7 + T4.8)

### A.1 — `pathMul_assoc` (64-case proof) (~250 lines, PathAlgebra.lean)

**Goal:** prove
```lean
theorem pathMul_assoc (m : ℕ) (a b c : QuiverArrow m) :
    Option.bind (pathMul m a b) (fun ab => pathMul m ab c) =
    Option.bind (pathMul m b c) (fun bc => pathMul m a bc)
```

**Strategy: avoid the naive 64-case explosion.** The four cases of
`pathMul`'s codomain (none / some-id / some-edge / impossible) collapse
under symmetry. Concretely:

* Case A — *all three are `id`*: `id u · id v · id w = some (id u)` iff
  `u = v ∧ v = w`. Both bracketings agree by associativity of `=`.
  (1 case, ~30 lines.)

* Case B — *exactly one is `edge`*: three sub-cases (edge in slot 1, 2,
  or 3). Each reduces to a triple `if … = …` with the edge passing
  through unchanged. (3 sub-cases × ~20 lines = ~60 lines.)

* Case C — *exactly two are `edge`*: three sub-cases by which slot is
  `id`. In each, exactly one inner `pathMul (edge,edge)` produces
  `none`, killing the bracket. The other bracket also produces `none`
  (the surviving `pathMul (id, edge)` either matches or doesn't, but
  the next step `pathMul edge edge` always returns `none`). (3 sub-
  cases × ~25 lines = ~75 lines.)

* Case D — *all three `edge`*: every inner `pathMul (edge, edge) =
  none`, both brackets reduce to `none`. (1 case, ~10 lines.)

**Total: 8 cases (1 + 3 + 3 + 1), ~175 lines.** Each is mechanical
`rfl` + `if-then-else` rewriting. Tactic skeleton:
```lean
  cases a with
  | id u => cases b with
    | id v => cases c with
      | id w => -- Case A
      | edge w₁ w₂ => -- Case B-3
    | edge v₁ v₂ => cases c with
      | id w => -- Case B-2
      | edge w₁ w₂ => -- Case C-1
  | edge u₁ u₂ => cases b with
    | id v => cases c with
      | id w => -- Case B-1
      | edge w₁ w₂ => -- Case C-2
    | edge v₁ v₂ => cases c with
      | id w => -- Case C-3
      | edge w₁ w₂ => -- Case D
```

Each leaf: `simp only [pathMul]; split_ifs <;> rfl` should close
~80% of cases. The remaining ~20% need explicit `Eq.trans`/`congr`
chaining.

**Risk:** medium. The `Option.bind` semantics interact with `if-then-
else` in non-trivial ways. Budget +75 lines reserve for tactic-level
tweaking.

### A.2 — `pathAlgebraQuotient` Mathlib `Algebra ℚ` instance (~300 lines, AlgebraWrapper.lean)

**Carrier choice:** `pathAlgebraQuotient m adj := QuiverArrow m → ℚ`
with the *constraint* that the support is contained in `presentArrows
m adj`. Three options:

1. `Fin (pathAlgebraDim m adj) → ℚ` — uses `pathStructureConstant`
   directly. Pro: matches Layer T1.5. Con: requires `pathArrowEquiv`
   plumbing (T1.3, deferred earlier).
2. `QuiverArrow m → ℚ` *unrestricted* — supports basis elements not
   in `presentArrows`. Pro: no plumbing. Con: the algebra has more
   elements than `F[Q_G] / J²` does.
3. `{ f : QuiverArrow m → ℚ // ∀ a, f a ≠ 0 → a ∈ presentArrows m adj }`
   — Subtype. Pro: matches the math exactly. Con: subtype overhead.

**Recommendation: Option 2 (unrestricted)**, with a "support is
present" predicate as a separate Prop. The unrestricted algebra is
isomorphic to `F[Q_G] / J²` when we restrict to support-`presentArrows`
elements; the rigidity argument needs the *whole* unrestricted algebra
because GL³ may map present arrows to (formally) non-present
combinations whose actual support is in the present set. Going with
Option 2 sidesteps the T1.3 plumbing.

**Algebra construction:**
```lean
def pathAlgebraQuotient (m : ℕ) : Type := QuiverArrow m → ℚ

instance : AddCommGroup (pathAlgebraQuotient m) := Pi.addCommGroup
instance : Module ℚ (pathAlgebraQuotient m) := Pi.module _ _ _

noncomputable def pathAlgebraMul (m : ℕ)
    (f g : pathAlgebraQuotient m) : pathAlgebraQuotient m :=
  fun c => ∑ a ∈ Finset.univ, ∑ b ∈ Finset.univ,
    f a * g b * (if pathMul m a b = some c then 1 else 0)

instance : Mul (pathAlgebraQuotient m) := ⟨pathAlgebraMul m⟩
instance : One (pathAlgebraQuotient m) :=
  ⟨fun a => match a with | .id _ => 1 | .edge _ _ => 0⟩
```

**Discharge plan:**
* `mul_assoc` ← lifts from `pathMul_assoc` (A.1) via
  `Finset.sum_comm` and structure-constant manipulation. ~80 lines.
* `mul_one`, `one_mul` ← unfold to `pathMul (·, .id v)` / `pathMul (.id v, ·)`
  cases of the multiplication table. ~40 lines.
* `left_distrib`, `right_distrib` ← `Finset.sum_add_distrib` /
  `mul_add`. ~30 lines.
* `mul_zero`, `zero_mul` ← elementwise. ~20 lines.
* `Algebra` instance via `Algebra.ofModule` (smul-compatibility):
  ~40 lines.

**Risk:** medium-low. Standard Mathlib structure-constant algebra
construction. The non-trivial step is `mul_assoc`, which depends
critically on A.1. Once A.1 lands clean, A.2 is mostly bookkeeping.

### Phase A deliverables

* `pathMul_assoc` (T1.7).
* `pathAlgebraQuotient m` type, ring + algebra instances (T4.8).
* `vertexIdempotent m v : pathAlgebraQuotient m` and
  `arrowElement m u v : pathAlgebraQuotient m` named witnesses.
* `pathAlgebraQuotient_basis : Basis (QuiverArrow m) ℚ (pathAlgebraQuotient m)` (free over QuiverArrow).
* Simp lemmas: `vertexIdempotent_mul_self`, `vertexIdempotent_mul_other_eq_zero`,
  `vertexIdempotent_mul_arrow`, `arrow_mul_vertexIdempotent`,
  `arrow_mul_arrow_eq_zero`.

---

## Phase B — GL³ Matrix Action Verification (T3.6, discharges `GrochowQiaoForwardObligation`)

### B.1 — Permutation matrix infrastructure (~100 lines, PermMatrix.lean)

Use Mathlib's `Equiv.Perm.permMatrix` directly — no need to hand-roll.

```lean
import Mathlib.LinearAlgebra.Matrix.Permutation

def liftedSigmaMatrix (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  (liftedSigma m σ).permMatrix

lemma liftedSigmaMatrix_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i j : Fin (dimGQ m)) :
    liftedSigmaMatrix m σ i j =
    if liftedSigma m σ i = j then 1 else 0
```

Mathlib's `permMatrix` already gives multiplicativity (`permMatrix_mul`),
identity (`permMatrix_one`), and `det = ±1`. Invertibility via
`det ≠ 0`.

```lean
def liftedSigmaGL (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    GL (Fin (dimGQ m)) ℚ :=
  Matrix.GeneralLinearGroup.mk' (liftedSigmaMatrix m σ)
    (by rw [liftedSigmaMatrix, Matrix.det_permutation]; exact …)
```

### B.2 — Tensor-action collapse for permutation matrices (~150 lines, PermMatrix.lean)

**Goal:** prove that the GL³ action with three copies of a permutation
matrix permutes the three tensor indices:

```lean
theorem matMulTensor1_permMatrix (π : Equiv.Perm (Fin n))
    (T : Tensor3 n ℚ) :
    matMulTensor1 π.permMatrix T = fun i j k => T (π⁻¹ i) j k
```

**Proof.** Unfold `matMulTensor1` to `fun i j k => ∑ a, π.permMatrix i a * T a j k`.
The summand is non-zero iff `π a = i`, i.e., `a = π⁻¹ i`. Use
`Finset.sum_eq_single (π⁻¹ i)`:
* All other terms are zero (since `permMatrix i a = 0` when `π a ≠ i`).
* Only the `a = π⁻¹ i` term survives, contributing `1 * T (π⁻¹ i) j k`.

Same for `matMulTensor2` and `matMulTensor3` via index-2 / index-3
analogues.

**Compose for `tensorContract`:**
```lean
theorem tensorContract_permMatrix_triple (π : Equiv.Perm (Fin n))
    (T : Tensor3 n ℚ) :
    tensorContract π.permMatrix π.permMatrix π.permMatrix T =
    fun i j k => T (π⁻¹ i) (π⁻¹ j) (π⁻¹ k)
```

~100 lines combined.

### B.3 — Discharge `GrochowQiaoForwardObligation` (~50 lines, Forward.lean extension)

```lean
theorem grochowQiao_forwardObligation : GrochowQiaoForwardObligation := by
  intro m adj₁ adj₂ ⟨σ, h⟩
  refine ⟨(liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹), ?_⟩
  funext i j k
  -- LHS: tensorContract (liftedSigmaMatrix σ⁻¹) (...) (...) (encode m adj₁) i j k
  -- = encode m adj₁ ((liftedSigma σ⁻¹)⁻¹ i) (...) (...)  by B.2
  -- = encode m adj₁ (liftedSigma σ i) (liftedSigma σ j) (liftedSigma σ k)  since (σ⁻¹)⁻¹ = σ
  -- = encode m adj₂ i j k  by encoder-equivariance + h
  rw [show (liftedSigmaGL m σ⁻¹).val = (liftedSigma m σ⁻¹).permMatrix from rfl]
  rw [tensorContract_permMatrix_triple]
  -- Use grochowQiaoEncode_equivariant with σ replaced by σ⁻¹⁻¹ = σ
  …
```

### Phase B deliverables

* `liftedSigmaMatrix`, `liftedSigmaGL`, invertibility lemma.
* `matMulTensor{1,2,3}_permMatrix` (single-axis permutation lemmas).
* `tensorContract_permMatrix_triple` (full GL³ collapse).
* `grochowQiao_forwardObligation : GrochowQiaoForwardObligation`
  — **closes the Prop unconditionally** when paired with B.2.

**Risk:** low-medium. All Mathlib API confirmed available (`permMatrix`,
`Finset.sum_eq_single`). The tricky step is `Finset.sum_eq_single`
with the right witness; this is standard.

---

## Phase C — Linear-Combination Idempotent Theory (~250 lines, Rigidity.lean §1)

### C.1 — Idempotent characterization at the linear-combination level

**Goal:** for `b : pathAlgebraQuotient m`, characterize `b · b = b`.

Decompose `b = Σ_v λ_v · vertexIdempotent v + Σ_{u,v ∈ E} μ_{u,v} ·
arrowElement u v` (using A.2's basis). Compute `b · b` using A.2's
multiplication and match coefficients:

* Coefficient of `e_w` in `b · b`:
  - From `e_w · e_w = e_w`: contributes `λ_w²`.
  - All other products (`e_u · e_v` for `u ≠ v`, `e_u · α(u,v)`, etc.)
    contribute zero to `e_w` coefficient.
  - Result: `λ_w² = λ_w`, hence **`λ_w ∈ {0, 1}`**.
* Coefficient of `α(u, v)` in `b · b`:
  - From `e_u · α(u, v)`: `λ_u · μ_{u,v}`.
  - From `α(u, v) · e_v`: `μ_{u,v} · λ_v`.
  - From `α(u, v) · α(v, w)`: zero (J²-killed).
  - Result: `(λ_u + λ_v) · μ_{u,v} = μ_{u,v}`, hence
    **`μ_{u,v} = 0 ∨ λ_u + λ_v = 1`**.

**Lean encoding:**
```lean
theorem pathAlgebra_idempotent_iff (b : pathAlgebraQuotient m) :
    b * b = b ↔
    (∀ v, (b (.id v))^2 = b (.id v)) ∧
    (∀ u v, b (.edge u v) * (b (.id u) + b (.id v) - 1) = 0)
```

(Discharged by `funext c`-then-case on `c`'s constructor, then expand
via A.2 simp lemmas.)

### C.2 — Primitive-idempotent characterization

**Definition (hand-rolled, since Mathlib lacks `IsPrimitiveIdempotent`):**
```lean
def IsPrimitiveIdempotent (b : pathAlgebraQuotient m) : Prop :=
  IsIdempotentElem b ∧ b ≠ 0 ∧
  ∀ b₁ b₂ : pathAlgebraQuotient m,
    IsIdempotentElem b₁ → IsIdempotentElem b₂ →
    b₁ * b₂ = 0 → b₂ * b₁ = 0 → b = b₁ + b₂ →
    b₁ = 0 ∨ b₂ = 0
```

**Goal:** prove
```lean
theorem isPrimitiveIdempotent_iff_vertex (b : pathAlgebraQuotient m) :
    IsPrimitiveIdempotent b ↔ ∃ v, b = vertexIdempotent m v
```

**Forward direction.** Suppose `b` is a primitive idempotent. By C.1,
`b = Σ_S e_v + Σ μ_{u,v} α(u,v)` for some subset `S ⊆ Fin m` and
coefficients with the constraint. If `|S| ≥ 2`, pick `v₀ ∈ S` and
write `b = e_{v₀} + (b - e_{v₀})`. Both summands are non-zero
idempotents (using C.1 to verify the residual is idempotent), and
they multiply to zero (orthogonality of vertex idempotents +
arrow-vertex actions). This contradicts primitivity. So `|S| = 1`.
With one `λ_v = 1` and `λ_w = 0` for `w ≠ v`, the constraint
`(λ_u + λ_v) μ_{u,v} = μ_{u,v}` forces all `μ_{u,v} = 0`. Hence
`b = e_v`.

**Backward direction.** Each `e_v` is idempotent, non-zero, and
cannot decompose: if `e_v = b₁ + b₂` with `b₁ b₂ = 0`, by support
analysis `b₁ = c · e_v`, `b₂ = (1-c) · e_v` for some `c ∈ ℚ`. Then
`b₁ b₂ = c(1-c) e_v = 0` forces `c ∈ {0, 1}`, i.e., one of `b₁, b₂`
is zero.

**Estimated:** ~150 lines for the forward direction (case-split on
`|S|`), ~50 lines for the backward direction. **No sorry needed.**

### Phase C deliverables

* `pathAlgebra_idempotent_iff` (linear-combination idempotency).
* `IsPrimitiveIdempotent` definition (custom).
* `isPrimitiveIdempotent_iff_vertex` (primitive ↔ vertex idempotent).
* `vertexIdempotent_isPrimitive` (concrete witness).
* Auxiliary: `pathAlgebra_decompose` (any element = vertex part + arrow part).

---

## Phase D — Distinguished-Padding Rigidity via Cardinality Invariant (T4.1, ~600 lines, Rigidity.lean §2)

**Approach revision (per Plan agent Q3): use the elementary
cardinality / diagonal-distinguishability argument, NOT Wedderburn-
Mal'cev.** The intrinsic algebraic invariant is:

> A slot `i` is a **vertex-idempotent slot** iff
> `grochowQiaoEncode m adj i i i = 1` AND there exists `j ≠ i` with
> `grochowQiaoEncode m adj i i j ≠ 0`.

Vertex slots satisfy this (`e_v · e_v = e_v` plus `e_v · e_v · α(v,
w) = α(v, w)`). Arrow-present slots satisfy a different signature
(structure constants of arrow-arrow products are zero, but
arrow-id-arrow gives one non-zero off-diagonal entry). Padding slots
satisfy yet another signature (only the triple-diagonal `(i, i, i)` is
non-zero).

### D.1 — Slot-classification invariants (~150 lines)

**Define three slot-classification predicates:**
```lean
def isVertexSignature (T : Tensor3 (dimGQ m) ℚ) (i : Fin (dimGQ m)) : Prop :=
  T i i i = 1 ∧ ∃ j ≠ i, T i i j ≠ 0

def isArrowSignature (T : Tensor3 (dimGQ m) ℚ) (i : Fin (dimGQ m)) : Prop :=
  T i i i = 0 ∧ ∃ j k, j ≠ i ∧ k ≠ i ∧ T j i k ≠ 0

def isPaddingSignature (T : Tensor3 (dimGQ m) ℚ) (i : Fin (dimGQ m)) : Prop :=
  T i i i = 1 ∧ ∀ j ≠ i, T i i j = 0
```

**Prove on the encoder:**
* `isVertexSignature_iff_vertex` — for `T = grochowQiaoEncode m adj`,
  `isVertexSignature T i ↔ ∃ v, slotEquiv m i = .vertex v`. (~50 lines.)
* `isArrowSignature_iff_arrow` — `↔ ∃ u v, slotEquiv m i = .arrow u v ∧ adj u v = true`. (~50 lines.)
* `isPaddingSignature_iff_padding` — `↔ ∃ u v, slotEquiv m i = .arrow u v ∧ adj u v = false`. (~50 lines.)

These are **provable directly** from the encoder's definition + the
multiplication table (A.2). No GL³ machinery needed.

### D.2 — GL³ preserves the signatures (~250 lines)

**Key lemma:** the three signature predicates are *invariants* of
`AreTensorIsomorphic`. Specifically, if `g • T₁ = T₂`, then for any
slot `i`, `isVertexSignature T₂ i ↔ isVertexSignature T₁ (π_g i)`
for some bijection `π_g` extracted from `g`.

**Strategy.** GL³ acts diagonally:
```
T₂(i, i, i) = (g • T₁)(i, i, i) = ∑_{a,b,c} g_X(i,a) g_Y(i,b) g_Z(i,c) T₁(a, b, c)
```

This is a *triple-linear* function in the `i`-th rows of `g_X, g_Y,
g_Z`. The signature predicates are *quadratic* statements about `T`
at fixed coordinate positions. To extract a bijection `π_g`, we do
NOT need full GL³ rigidity — we just need the bijection of *vertex-
signature* slots.

**Approach: count vertex-signature slots.** Both `T₁` and `T₂` have
exactly `m` vertex-signature slots (one per vertex). The GL³ action
preserves this count via the linear-algebraic fact:
> If a slot `i` is a vertex-signature slot of `T₂`, then there is a
> unique slot `j` such that `i = j` linearly under the GL³ action's
> support — concretely, `g_X(i, j) ≠ 0` AND `j` is a vertex-
> signature slot of `T₁`.

**Concrete construction.** Define
```lean
π_g : (vertex-signature slots of T₂) ≃ (vertex-signature slots of T₁)
```
via the support of `g_X⁻¹` restricted to vertex-signature rows.
Prove uniqueness by induction on the dimension count (the matrix
`g_X⁻¹` restricted to vertex-signature submatrix is itself a permutation
matrix because both source and target are vertex-signature sets of
the same cardinality `m`, and the support cardinality is preserved
under GL³ since `det(g_X) ≠ 0`).

**Risk:** medium. The "support is a permutation" step requires
careful linear-algebraic argument. Plausibly ~250 lines, but if it
gets stuck, see "anticipated sorry/axiom" section below.

### D.3 — Extract σ : Fin m → Fin m bijection (~200 lines)

**Goal:** from D.2's bijection on vertex-signature slots, extract a
vertex permutation σ.

By D.1 + D.2, the GL³ action induces a bijection between the `m`
vertex-signature slots of `T₁` and the `m` vertex-signature slots of
`T₂`. By D.1's classification, vertex-signature slots are in
bijection with `Fin m` (the vertex set). Composing gives σ : Fin m →
Fin m.

```lean
noncomputable def extractVertexPermutation
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL × GL × GL)
    (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    Equiv.Perm (Fin m)
```

### Phase D deliverables

* `isVertexSignature`, `isArrowSignature`, `isPaddingSignature`
  predicates + their characterisations on the encoder.
* `gl_preserves_vertexSignature` (GL³ preserves vertex-signature
  count, induces bijection on vertex-signature slots).
* `extractVertexPermutation` σ : Equiv.Perm (Fin m).

---

## Phase E — GL³ → Algebra Automorphism (T4.2, ~350 lines, Rigidity.lean §3)

**Goal:** lift a GL³ tensor-isomorphism preserving `grochowQiaoEncode`
to an algebra automorphism of `pathAlgebraQuotient`.

### E.1 — GL₁ component restricts to path algebra

From D.2's vertex-signature preservation, the GL₁ component (g_X)
restricts to a linear map between the path-algebra subspaces. Make
this precise:

```lean
def restrictToPathAlgebra (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL × GL × GL)
    (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    pathAlgebraQuotient m →ₗ[ℚ] pathAlgebraQuotient m
```

The construction: identify `pathAlgebraQuotient m = QuiverArrow m → ℚ`
with `(present arrows under adj₁) → ℚ` via support restriction (using
the σ from D.3). Then `restrictToPathAlgebra` is the linear map
induced by g_X on the path-algebra slot subspace, post-composed with
the natural projection.

### E.2 — Multiplication preservation

The structure-tensor preservation `g • T = T'` says
```
∀ i j k, T'(i, j, k) = ∑_{a,b,c} g_X(i,a) g_Y(j,b) g_Z(k,c) T(a, b, c)
```

For the **path-algebra subblock** (slots that are vertex/present-arrow
under both adj₁ and adj₂), this translates to:
```
(restrictToPathAlgebra ⊗ restrictToPathAlgebra) ∘ μ_{adj₁} =
μ_{adj₂} ∘ restrictToPathAlgebra
```
where `μ` is the multiplication map. This is exactly the algebra-
automorphism property.

```lean
theorem restrictToPathAlgebra_isAlgEquiv :
    pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m
```

(More precisely: an isomorphism between the algebras "supports under
adj₁" and "supports under adj₂", but since both are subalgebras of
the unrestricted `pathAlgebraQuotient m`, we get an `AlgEquiv` after
identifying the quotients.)

**Risk:** low-medium. Once D.2 lands, this is structural lifting.
~350 lines.

### Phase E deliverables

* `restrictToPathAlgebra` linear map.
* `restrictToPathAlgebra_isAlgEquiv : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m`.

---

## Phase F — Vertex Permutation + Adjacency Invariance (T4.3 + T4.4 + T4.5, ~770 lines, Rigidity.lean §4)

### F.1 — `AlgEquiv` permutes vertex idempotents (T4.3, ~400 lines)

From Phase C: vertex idempotents are exactly the primitive
idempotents. Algebra automorphisms preserve `IsIdempotentElem` and
`IsPrimitiveIdempotent`. So φ : pathAlgebraQuotient m ≃ₐ[ℚ]
pathAlgebraQuotient m maps `{e_v}` bijectively to `{e_w}`.

```lean
theorem algEquiv_permutes_vertexIdempotents
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) :
    ∃ τ : Equiv.Perm (Fin m), ∀ v, φ (vertexIdempotent m v) = vertexIdempotent m (τ v)
```

**Proof sketch.** For each `v : Fin m`, `φ (vertexIdempotent m v)` is
a primitive idempotent (by `IsPrimitiveIdempotent` preservation under
`AlgEquiv`). By Phase C.2, primitive idempotents are exactly vertex
idempotents. So `φ (vertexIdempotent m v) = vertexIdempotent m (τ v)`
for some unique `τ v`. Bijectivity of τ from `φ` being an `AlgEquiv`.

### F.2 — Arrow-corner uniqueness (T4.4, ~250 lines)

```lean
theorem algEquiv_maps_arrow_to_scalar_arrow
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] ...)
    (τ : Equiv.Perm (Fin m)) (h_idem : ∀ v, φ (e_v) = e_{τ v})
    (u v : Fin m) (h_pres : adj₁ u v = true) :
    ∃ c : ℚˣ, φ (arrowElement m u v) = c • arrowElement m (τ u) (τ v)
```

**Proof.** `e_u · α(u, v) · e_v = α(u, v)` (multiplication-table identity).
Apply φ: `e_{τ u} · φ(α(u, v)) · e_{τ v} = φ(α(u, v))`. The basis
expansion of φ(α(u, v)) is `Σ μ'_{a,b} α(a, b) + Σ λ'_w e_w`. The
sandwich `e_{τ u} · X · e_{τ v}` projects out everything except `α(τ u, τ v)`-
proportional content. Hence `φ(α(u, v)) = c · α(τ u, τ v)` for some
`c ∈ ℚ`. Invertibility (φ is `AlgEquiv`) ⇒ `c ≠ 0`, so `c ∈ ℚˣ`.

### F.3 — Adjacency invariance (T4.5, ~120 lines)

```lean
theorem adj_invariance_under_algEquiv
    (φ : pathAlgebraQuotient m adj₁ ≃ₐ pathAlgebraQuotient m adj₂)
    (τ : Equiv.Perm (Fin m)) (h_idem h_arrow) :
    ∀ u v, adj₁ u v = adj₂ (τ u) (τ v)
```

`adj₁ u v = true ⇔ α(u, v) is a non-zero present arrow ⇔ φ(α(u, v))
≠ 0 ⇔ c · α(τ u, τ v) ≠ 0 ⇔ α(τ u, τ v) is a non-zero present arrow
⇔ adj₂ (τ u) (τ v) = true`.

### Phase F deliverables

* `algEquiv_permutes_vertexIdempotents` (T4.3).
* `algEquiv_maps_arrow_to_scalar_arrow` (T4.4).
* `adj_invariance_under_algEquiv` (T4.5).

---

## Phase G — Reverse Direction Composition (T5.1 + T5.4, ~400 lines, ReverseFull.lean)

### G.1 — T5.1 composite theorem

```lean
theorem GL_triple_yields_vertex_permutation
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (h_m : 1 ≤ m)
    (g : GL × GL × GL)
    (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ σ : Equiv.Perm (Fin m), ∀ u v, adj₁ u v = adj₂ (σ u) (σ v) := by
  -- Phase D: extract vertex permutation π from g
  -- Phase E: build AlgEquiv φ from g + π
  -- Phase F.1: extract τ permuting vertex idempotents from φ
  -- Phase F.2-F.3: τ preserves adjacency
  -- Conclude σ := τ
```

### G.2 — T5.4 reverse direction discharge

```lean
theorem grochowQiao_rigidity : GrochowQiaoRigidity := by
  intro m adj₁ adj₂ ⟨g, hg⟩
  match m with
  | 0 => exact grochowQiaoEncode_reverse_zero adj₁ adj₂ ⟨g, hg⟩
  | 1 => -- m = 1 case (existing edge case + G.1)
  | m+2 => exact GL_triple_yields_vertex_permutation _ _ _ (by omega) g hg
```

This **closes `GrochowQiaoRigidity` unconditionally** assuming Phases
D–F land successfully.

### Phase G deliverables

* `GL_triple_yields_vertex_permutation` (T5.1).
* `grochowQiao_rigidity : GrochowQiaoRigidity` (T5.4).

---

## Phase H — Final Assembly: Unconditional `@GIReducesToTI ℚ _` (T6.3, ~50 lines, GrochowQiao.lean extension)

```lean
theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_obligations
    grochowQiao_forwardObligation
    grochowQiao_rigidity
```

The conditional inhabitant `grochowQiao_isInhabitedKarpReduction_under_obligations`
is already proven (took two `Prop`-typed obligations); applying it to
the discharges from Phases B and G gives an unconditional inhabitant.

### Phase H deliverables

* `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`
  — **the headline theorem of Workstream R-TI**.

---

## Anticipated Sorry/Axiom Requests

Per the user's instruction: *"You can use Sorry/Axiom but you need to
tell me why you think it is necessary and ask me if it is alright
before you are use it in the codebase."*

### **No sorry/axiom anticipated for Phases A, B, C, E, F, G, H**

These phases use elementary algebra + standard Mathlib API. No
research-scope content; budgets are realistic.

### **Phase D.2 — possible sorry candidate (1 of 2 risk areas)**

**The step:** "GL³ preserves vertex-signature slot count, induces a
bijection π_g on vertex-signature slots."

**Why it might need sorry.** The proof requires showing that the
restriction of `g_X⁻¹` (a row-restriction of an invertible matrix) to
vertex-signature rows of `T₁` and vertex-signature columns of `T₂` is
itself invertible (a permutation matrix on the vertex-signature
sub-block). The Mathlib API for "row/column-restricted invertibility"
is:

* `Matrix.det_block_diagonal` — works for block-diagonal matrices,
  but `g_X` is not block-diagonal in general.
* `Matrix.det_subMatrix` — Mathlib has `Matrix.submatrix_det` but the
  general result "subMatrix of invertible is invertible iff the
  submatrix has full rank" requires careful linear algebra.

**Mitigation strategy (no sorry needed if it works):** prove the
following alternative lemma, which sidesteps the sub-matrix
invertibility:

```lean
theorem vertexSig_card_invariant_under_gl
    (g : GL (Fin (dimGQ m)) ℚ × GL × GL)
    (T₁ T₂ : Tensor3 (dimGQ m) ℚ)
    (h : g • T₁ = T₂) :
    (Finset.univ.filter (isVertexSignature T₁)).card =
    (Finset.univ.filter (isVertexSignature T₂)).card
```

This says vertex-signature **count** is preserved (not the bijection
yet). Provable via: vertex-signature requires `T(i,i,i) = 1`, and
the GL³ action's diagonal entries `(g • T)(i,i,i) = ∑_{a,b,c}
g_X(i,a) g_Y(i,b) g_Z(i,c) T(a,b,c)` is a quadratic form in the i-th
rows of g_X, g_Y, g_Z; preservation of the quadratic form on the
vertex-signature subset across all `i` gives a count-preservation
argument via inclusion-exclusion.

If THIS approach fails too, fall back to a `sorry` requesting user
permission. **Estimated probability of needing sorry: ~25%.**

### **Phase D.2 (alternative phrasing) — `IsPrimitiveIdempotent` formalization**

**The step:** prove "Algebra automorphisms preserve `IsPrimitiveIdempotent`."

**Why it might need work.** Mathlib does NOT have
`IsPrimitiveIdempotent`. Phase C.2 hand-rolls it. The preservation
under `AlgEquiv` is conceptually trivial (both `IsIdempotentElem`
and the orthogonal-decomposition predicate are `AlgEquiv`-invariant
by direct unfolding), but requires careful Lean tactic work.

**Mitigation:** the proof is direct unfolding + `AlgEquiv.map_mul`,
`AlgEquiv.map_zero`, `AlgEquiv.map_add` lemmas. **Estimated
probability of needing sorry: ~5%.**

### **User decisions (answered before implementation)**

**Q1 — Phase D.2 fallback strategy.** If D.2 cannot be discharged
elementarily within budget:

> **DECISION: Add Prop hypothesis.**

If a sub-step of D.2 proves intractable, land it as an additional
research-scope Prop (e.g., `GLPreservesVertexSignatureBijection`)
and thread it through Phase G as another explicit hypothesis. Phase
H's `grochowQiao_isInhabitedKarpReduction_under_obligations` is
extended to take three Props instead of two. **No sorry** — preserves
the codebase's zero-sorry posture. Cost: a 3rd open Prop alongside
the existing conditional inhabitant pattern.

**Q2 — Secondary sorry candidate policy** (Mathlib API gaps,
individual matrix-algebra lemmas):

> **DECISION: Pause per-occurrence.**

At each candidate sorry site, halt implementation, explain the
technical issue (what Mathlib API is missing, what hand-roll would
be required), and request explicit per-site approval before
proceeding. Maximum oversight. Default response should be: hand-roll
the missing API rather than introduce sorry, but ask the user before
either choice.

---

## Verification Plan

### Per-sub-task

1. `lake build <module>` — must succeed with zero errors, zero
   warnings.
2. `lake env lean scripts/audit_phase_16.lean` — every
   `#print axioms` returns "does not depend on any axioms" or
   `[propext, Classical.choice, Quot.sound]`. Zero `sorryAx`. Zero
   custom axioms (unless explicitly approved by user per above).

### Per-phase

1. Full `lake build` — zero warnings, zero errors.
2. New `#print axioms` entries for every public declaration in the
   phase's module(s).
3. New `example` non-vacuity witnesses exercising the phase's
   headline theorems on concrete `m ∈ {2, 3}` graphs.

### Final (after Phase H)

1. **`grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`** —
   the headline theorem must compile and depend only on the standard
   Lean trio (or whatever the user-approved sorry list is).
2. **Concrete K_3 round-trip example.** `grochowQiao_isInhabitedKarpReduction`
   applied to two specific isomorphic 3-vertex graphs gives a
   computable witness pair.
3. **Concrete non-isomorphic discriminator example.** Two 4-vertex
   graphs that are non-isomorphic (e.g., `C_4` vs `K_{1,3}`); the
   inhabitant's iff direction shows the encoded tensors are NOT
   isomorphic.
4. **Documentation sweep.** Update `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
   `Orbcrypt.lean` transparency report, `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
   to reflect that R-TI is **fully closed** (modulo any user-approved
   sorry sites).
5. **`lakefile.lean` version bump** `0.1.18 → 0.1.19`.

---

## Implementation Sequencing (Dependency-Ordered)

Each step depends only on completed predecessors. Build artifacts
verified after each step.

1. **Phase A.1** (`pathMul_assoc`) — independent, mechanical. ✓ start.
2. **Phase A.2** (`pathAlgebraQuotient` + Algebra ℚ) — needs A.1.
3. **Phase B** (PermMatrix + GL³ matrix-action) — independent of A.
   Can run in parallel with A. **Phase B closes `GrochowQiaoForwardObligation`.**
4. **Phase C** (linear-combination idempotent + primitivity) — needs A.2.
5. **Phase D.1** (signature predicates) — needs A.2 + StructureTensor (already done).
6. **Phase D.2** (GL³ preserves signatures) — needs D.1. **Highest risk.**
7. **Phase D.3** (extract σ) — needs D.2.
8. **Phase E** (GL³ → AlgEquiv) — needs A.2 + D.
9. **Phase F.1** (AlgEquiv permutes idempotents) — needs C + E.
10. **Phase F.2** (arrow-corner uniqueness) — needs A.2 + F.1.
11. **Phase F.3** (adjacency invariance) — needs F.2.
12. **Phase G** (composition) — needs D.3 + E + F.
13. **Phase H** (final assembly) — needs B + G.

**Critical-path length:** A.1 → A.2 → C → F.1 → F.2 → F.3 → G → H.
**Phase B is fully parallel** — can be landed first as a quick win.

---

## Risk Register

| Risk | Phase | Severity | Mitigation |
|------|-------|----------|------------|
| `pathMul_assoc` 64-case proof times out at compile | A.1 | Med | Factor into 8 sub-lemmas (per case-bucket) |
| `Pi.algebra` doesn't auto-derive instances | A.2 | Low | Hand-roll `mul_assoc`, `mul_comm`-not-needed |
| `Equiv.Perm.permMatrix` elaboration in `Tensor3` context | B | Low | Verified Mathlib API at fa6418a8 |
| Linear-comb idempotent expansion blows up case count | C.2 | Low-Med | Use Finsupp approach; case-split on `|S|` |
| **Vertex-signature bijection extraction (D.2)** | D.2 | **HIGH** | See sorry/axiom discussion above |
| `AlgEquiv` construction from linear bijection + multiplicativity | E | Low | Use Mathlib's `AlgEquiv.ofBijective` |
| Mathlib API for `Module.finBasis` reindexing on `presentArrows` | A.2 | Low | Side-step by using `QuiverArrow m → ℚ` |
| Compile-time of large `Tensor3` proofs | B, D | Med | Profile with `set_option maxHeartbeats` |
| 3,720 LOC may exceed safe edit budget per session | All | Med | Build incrementally; commit after each phase |

---

## Critical Files Reference

**Files to modify:**

* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` (extend +400 LOC)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Forward.lean` (extend +50 LOC, B.3)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Reverse.lean` (extend +50 LOC if needed)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao.lean` (extend +50 LOC, H)
* `/home/user/Orbcrypt/Orbcrypt.lean` (extend +80 LOC, snapshot)
* `/home/user/Orbcrypt/CLAUDE.md` (extend, change-log entry)
* `/home/user/Orbcrypt/docs/VERIFICATION_REPORT.md` (extend, history entry)
* `/home/user/Orbcrypt/docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` (mark R-15 closed)
* `/home/user/Orbcrypt/scripts/audit_phase_16.lean` (extend +200 LOC)
* `/home/user/Orbcrypt/lakefile.lean` (version bump)

**Files to create:**

* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean` (~600 LOC)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean` (~400 LOC)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` (~1500 LOC)
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/ReverseFull.lean` (~400 LOC)

**Existing functions/utilities to reuse:**

* `Orbcrypt.GrochowQiao.QuiverArrow` (PathAlgebra.lean:136)
* `Orbcrypt.GrochowQiao.pathMul` (PathAlgebra.lean:308)
* `Orbcrypt.GrochowQiao.pathMul_quiverMap` (PathAlgebra.lean:455) — basis-level σ-equivariance
* `Orbcrypt.GrochowQiao.grochowQiaoEncode` (StructureTensor.lean:310)
* `Orbcrypt.GrochowQiao.grochowQiaoEncode_equivariant` (Forward.lean:355)
* `Orbcrypt.GrochowQiao.GrochowQiaoForwardObligation` (GrochowQiao.lean:165)
* `Orbcrypt.GrochowQiao.GrochowQiaoRigidity` (Reverse.lean:122)
* `Orbcrypt.GrochowQiao.grochowQiao_isInhabitedKarpReduction_under_obligations`
  (GrochowQiao.lean:245) — already proven, takes both Props
* `Orbcrypt.tensorContract` (TensorAction.lean:101)
* `Mathlib.Equiv.Perm.permMatrix` (LinearAlgebra/Matrix/Permutation.lean)
* `Mathlib.Algebra.ofModule` (Algebra/Algebra/Defs.lean)
* `Mathlib.AlgEquiv` (Algebra/Algebra/Equiv.lean)
* `Mathlib.IsIdempotentElem` (Algebra/Ring/Idempotent.lean)

---

## Documentation Updates Checklist

After Phase H lands:

1. **`CLAUDE.md` change-log:** new "Workstream R-TI Layers T1.7 +
   T3.6 + T4 + T5 + T6.3 — full Karp reduction closure" entry
   describing the unconditional `@GIReducesToTI ℚ _` inhabitant.
2. **`Orbcrypt.lean` transparency report:** update Vacuity map to
   show `GIReducesToTI` is now **fully discharged**; new Workstream
   snapshot section.
3. **`docs/VERIFICATION_REPORT.md`:** Document history entry for the
   landing; "Headline results" table extended with the unconditional
   inhabitant.
4. **`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`:**
   mark R-15-residual-TI-reverse and R-15-residual-TI-forward-matrix
   as **closed** (or **partially closed** if any sorry remains).
5. **`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`:** update
   Workstream R-TI status from "in progress" to **complete** (or
   conditional, depending on sorry status).
6. **`scripts/audit_phase_16.lean`:** new `#print axioms` entries
   for every Phase A–H public declaration; new non-vacuity examples
   exercising `grochowQiao_isInhabitedKarpReduction` on concrete
   graph pairs.
7. **`lakefile.lean`:** version bump `0.1.18 → 0.1.19`.

---

## Summary

This plan completes Workstream R-TI by closing both research-scope
Props (`GrochowQiaoForwardObligation` via Phase B's elementary
permutation-matrix tensor-action collapse, and `GrochowQiaoRigidity`
via Phases C–G's elementary path-algebra rigidity argument). The
**key strategic shift from earlier sessions:** abandon the
Wedderburn-Mal'cev approach (which would require missing Mathlib API
and is excessively heavy) in favour of an **elementary cardinality
+ structure-constant signature** approach (Phase D), confirmed by
the Plan agent's analysis to be:

* **More tractable** in Mathlib `fa6418a8` (no missing API).
* **Equally rigorous** — the Plan agent confirmed it produces the
  same conclusion as the Wedderburn approach.
* **Substantially shorter** (~600 LOC vs. ~1,200 for Wedderburn).

**Total budget: ~3,720 LOC of new Lean across 4 new + 5 extended
modules.** Estimated probability of full closure without any sorry:
**~75%** — limited by Phase D.2's "vertex-signature bijection
extraction" step, where the user-approved fallback options are
documented above.

**User-approved policies for implementation:**

1. **Phase D.2 fallback:** if intractable, add a Prop hypothesis
   (`GLPreservesVertexSignatureBijection` or similar) and thread it
   through Phase G/H. **No sorry.** Phase H's conditional inhabitant
   would then take 3 Props instead of 2.
2. **Secondary sorry candidates:** pause per-occurrence, explain the
   issue, prefer hand-rolling missing Mathlib API over sorry, request
   explicit user approval at every candidate site.

---

# Detailed Atomic Work-Unit Breakdown

Each work unit (WU) is sized at ~30–150 lines of Lean and specifies
a single theorem-level deliverable. WUs are dependency-ordered so
later units consume earlier units' results. Total count: **63 WUs
across 8 phases.**

Format per WU:
> **WU id** — Title.
> *File:* path; *Predecessors:* WU-ids; *LOC:* estimate; *Risk:* L/M/H.
> *Deliverable:* Lean signature of the headline declaration.
> *Tactic skeleton:* condensed proof sketch.

## Phase A.1 — `pathMul_assoc` (8 WUs, ~300 LOC total)

### Strategy
Three nested `cases QuiverArrow` give 2 × 2 × 2 = 8 leaves (id/edge
on each of three positions). Each leaf is closed by (a) `rfl` for the
arrow-arrow-arrow case (both sides are `none`), (b) `simp only
[pathMul_*]` + `split_ifs` for cases involving `id` (the `if-then-
else` cascades). The 8 leaves form a symmetric pattern under index
swaps; we factor common machinery into auxiliary lemmas.

### Auxiliary lemmas (foundational, prove first)

> **A1.aux1** — `pathMul_id_id_id_assoc`.
> *File:* PathAlgebra.lean; *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathMul_id_id_id_assoc (m : ℕ) (u v w : Fin m) :
>     Option.bind (pathMul m (.id u) (.id v))
>                 (fun ab => pathMul m ab (.id w)) =
>     Option.bind (pathMul m (.id v) (.id w))
>                 (fun bc => pathMul m (.id u) bc)
> ```
> *Tactic:* `simp only [pathMul_id_id, Option.bind]`; `split_ifs`
> on `u = v`, `v = w`, `u = w`; close all 8 sub-cases by `rfl` or
> `congr 1; omega` for the `Fin` equality chain.

> **A1.aux2** — `pathMul_id_id_edge_assoc`.
> *File:* PathAlgebra.lean; *Pred:* none; *LOC:* 35; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathMul_id_id_edge_assoc (m : ℕ) (u v w₁ w₂ : Fin m) :
>     Option.bind (pathMul m (.id u) (.id v))
>                 (fun ab => pathMul m ab (.edge w₁ w₂)) =
>     Option.bind (pathMul m (.id v) (.edge w₁ w₂))
>                 (fun bc => pathMul m (.id u) bc)
> ```
> *Tactic:* `simp only [pathMul_id_id, pathMul_id_edge, Option.bind]`;
> case-split on `u = v`, `v = w₁`, `u = w₁`. Each branch closes by
> `rfl` after the `if-then-else` reductions.

> **A1.aux3** — `pathMul_id_edge_id_assoc`.
> *File:* PathAlgebra.lean; *Pred:* none; *LOC:* 35; *Risk:* L.
> *Tactic:* analogous to A1.aux2 with edge in middle slot.

> **A1.aux4** — `pathMul_edge_id_id_assoc`.
> *File:* PathAlgebra.lean; *Pred:* none; *LOC:* 35; *Risk:* L.
> *Tactic:* analogous; edge in first slot.

### Edge-edge cases (uniform `none` discharge)

> **A1.aux5** — `pathMul_id_edge_edge_assoc` (one edge in middle, one in third).
> *File:* PathAlgebra.lean; *Pred:* none; *LOC:* 25; *Risk:* L.
> *Tactic:* both brackets reduce to `Option.bind … none = none` because
> `pathMul (.edge _ _) (.edge _ _) = none`. ~5 line `simp` + `rfl`.

> **A1.aux6** — `pathMul_edge_id_edge_assoc`. Similar. *LOC:* 25.

> **A1.aux7** — `pathMul_edge_edge_id_assoc`. Similar. *LOC:* 25.

> **A1.aux8** — `pathMul_edge_edge_edge_assoc`. Both brackets are
> `none`. *LOC:* 15. *Tactic:* `simp only [pathMul_edge_edge_none]; rfl`.

### Top-level theorem

> **A1.main** — `pathMul_assoc`.
> *File:* PathAlgebra.lean; *Pred:* A1.aux1–A1.aux8; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathMul_assoc (m : ℕ) (a b c : QuiverArrow m) :
>     Option.bind (pathMul m a b) (fun ab => pathMul m ab c) =
>     Option.bind (pathMul m b c) (fun bc => pathMul m a bc)
> ```
> *Tactic:* `cases a with | id u => ... | edge u₁ u₂ => ...`; nested
> `cases b`, `cases c`; each leaf invokes the appropriate aux lemma.

## Phase A.2 — `pathAlgebraQuotient` Mathlib `Algebra ℚ` (12 WUs, ~600 LOC)

### Carrier + scalar/additive structure

> **A2.1** — Carrier type definition.
> *File:* AlgebraWrapper.lean (NEW); *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def pathAlgebraQuotient (m : ℕ) : Type := QuiverArrow m → ℚ
> instance pathAlgebraQuotient.addCommGroup : AddCommGroup (pathAlgebraQuotient m) := Pi.addCommGroup
> instance pathAlgebraQuotient.module : Module ℚ (pathAlgebraQuotient m) := Pi.module _ _ _
> ```
> *Tactic:* `unfold pathAlgebraQuotient; infer_instance` for each
> typeclass. Pi-structure derives automatically.

### Multiplication

> **A2.2** — `pathAlgebraMul` definition + Mul instance.
> *File:* AlgebraWrapper.lean; *Pred:* A2.1; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def pathAlgebraMul (m : ℕ)
>     (f g : pathAlgebraQuotient m) : pathAlgebraQuotient m :=
>   fun c => ∑ a ∈ Finset.univ, ∑ b ∈ Finset.univ,
>     f a * g b * (if pathMul m a b = some c then (1 : ℚ) else 0)
> instance : Mul (pathAlgebraQuotient m) := ⟨pathAlgebraMul m⟩
> ```
> *Tactic:* explicit `def` + `instance ⟨⟩` wrapper.

> **A2.3** — Basis-element multiplication lemmas.
> *File:* AlgebraWrapper.lean; *Pred:* A2.2; *LOC:* 80; *Risk:* L.
> *Deliverable:*
> ```lean
> def vertexIdempotent (m : ℕ) (v : Fin m) : pathAlgebraQuotient m :=
>   fun a => match a with | .id w => if v = w then 1 else 0 | .edge _ _ => 0
> def arrowElement (m : ℕ) (u v : Fin m) : pathAlgebraQuotient m :=
>   fun a => match a with | .id _ => 0 | .edge u' v' => if u = u' ∧ v = v' then 1 else 0
> @[simp] theorem vertexIdempotent_mul_self (v : Fin m) :
>     vertexIdempotent m v * vertexIdempotent m v = vertexIdempotent m v
> @[simp] theorem vertexIdempotent_mul_other_eq_zero (v w : Fin m) (h : v ≠ w) :
>     vertexIdempotent m v * vertexIdempotent m w = 0
> @[simp] theorem vertexIdempotent_mul_arrowElement (u v w : Fin m) :
>     vertexIdempotent m u * arrowElement m v w =
>     if u = v then arrowElement m v w else 0
> @[simp] theorem arrowElement_mul_vertexIdempotent (u v w : Fin m) :
>     arrowElement m u v * vertexIdempotent m w =
>     if v = w then arrowElement m u v else 0
> @[simp] theorem arrowElement_mul_arrowElement_eq_zero (u v u' v' : Fin m) :
>     arrowElement m u v * arrowElement m u' v' = 0
> ```
> *Tactic:* unfold `Mul.mul`, `pathAlgebraMul`, `vertexIdempotent`,
> `arrowElement`. The double `Finset.sum` reduces to a single non-zero
> term via `Finset.sum_eq_single` on the unique `(a, b)` matching the
> indicator. ~15 lines per lemma.

### Associativity (depends on Phase A.1)

> **A2.4** — `pathAlgebraMul_assoc` (lifts A1.main to algebra level).
> *File:* AlgebraWrapper.lean; *Pred:* A2.2, A1.main; *LOC:* 100; *Risk:* M.
> *Deliverable:*
> ```lean
> theorem pathAlgebraMul_assoc (f g h : pathAlgebraQuotient m) :
>     (f * g) * h = f * (g * h)
> ```
> *Tactic:* `funext c`; unfold `Mul.mul, pathAlgebraMul`; obtain
> ```
> ∑_a ∑_b ∑_d (∑_x ∑_y f(x) g(y) [pathMul x y = some a]) ·
>             h(b) · [pathMul a b = some c]
> = analogous nested sum
> ```
> Use `Finset.sum_comm`, `mul_assoc` of ℚ, then `pathMul_assoc` (A1.main)
> to match the inner-bind structures. ~80 lines of careful sum
> manipulation. Risk: M because Finset.sum manipulations under
> nested binders can run into elaboration issues.

### Unitality

> **A2.5** — Unit element + One instance.
> *File:* AlgebraWrapper.lean; *Pred:* A2.3; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def pathAlgebraOne (m : ℕ) : pathAlgebraQuotient m :=
>   ∑ v : Fin m, vertexIdempotent m v
> instance : One (pathAlgebraQuotient m) := ⟨pathAlgebraOne m⟩
> ```

> **A2.6** — `one_mul`, `mul_one`.
> *File:* AlgebraWrapper.lean; *Pred:* A2.3, A2.5; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathAlgebra_one_mul (f : pathAlgebraQuotient m) : 1 * f = f
> theorem pathAlgebra_mul_one (f : pathAlgebraQuotient m) : f * 1 = f
> ```
> *Tactic:* `funext c`; case-split on constructor of `c`; apply
> A2.3 simp lemmas + sum-over-Fin-m collapse via
> `Finset.sum_eq_single`.

### Distributivity

> **A2.7** — `left_distrib`, `right_distrib`.
> *File:* AlgebraWrapper.lean; *Pred:* A2.2; *LOC:* 50; *Risk:* L.
> *Tactic:* `funext c`; unfold; `Finset.sum_add_distrib`; `mul_add`.

### Zero compatibility

> **A2.8** — `mul_zero`, `zero_mul`.
> *File:* AlgebraWrapper.lean; *Pred:* A2.2; *LOC:* 30; *Risk:* L.

### Ring + Algebra instance assembly

> **A2.9** — `Ring (pathAlgebraQuotient m)` instance.
> *File:* AlgebraWrapper.lean; *Pred:* A2.4, A2.6, A2.7, A2.8; *LOC:* 40; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable instance : Ring (pathAlgebraQuotient m) where
>   mul := pathAlgebraMul m
>   mul_assoc := pathAlgebraMul_assoc
>   one := pathAlgebraOne m
>   one_mul := pathAlgebra_one_mul
>   mul_one := pathAlgebra_mul_one
>   left_distrib := …
>   right_distrib := …
>   mul_zero := …
>   zero_mul := …
>   …  -- Add/Neg/Sub from Pi.addCommGroup
> ```

> **A2.10** — `Algebra ℚ (pathAlgebraQuotient m)` instance via `Algebra.ofModule`.
> *File:* AlgebraWrapper.lean; *Pred:* A2.9; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable instance : Algebra ℚ (pathAlgebraQuotient m) :=
>   Algebra.ofModule
>     (fun r f g => by funext c; …)  -- r • f * g = r • (f * g)
>     (fun r f g => by funext c; …)  -- f * r • g = r • (f * g)
> ```
> *Tactic:* the two compatibility conditions reduce to `funext c +
> Finset.smul_sum` and ring axioms.

### Decomposition

> **A2.11** — `pathAlgebra_decompose`: every element splits into
> vertex part + arrow part.
> *File:* AlgebraWrapper.lean; *Pred:* A2.3; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathAlgebra_decompose (f : pathAlgebraQuotient m) :
>     f = (∑ v : Fin m, f (.id v) • vertexIdempotent m v) +
>         (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2)
> ```
> *Tactic:* `funext c`; `cases c`; both sides expand to `f c`.

### Basis

> **A2.12** — Free basis over `QuiverArrow m`.
> *File:* AlgebraWrapper.lean; *Pred:* A2.11; *LOC:* 40; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def pathAlgebraQuotient_basis (m : ℕ) :
>     Basis (QuiverArrow m) ℚ (pathAlgebraQuotient m) :=
>   Basis.ofEquivFun (LinearEquiv.refl _ _)
> ```
> *Tactic:* `pathAlgebraQuotient m = QuiverArrow m → ℚ` is already
> the free module on `QuiverArrow m`; `Basis.ofEquivFun` gives the
> canonical basis directly.

## Phase B — GL³ Matrix-Action Verification (8 WUs, ~400 LOC)

### Permutation matrix infrastructure

> **B.1** — `liftedSigmaMatrix` definition.
> *File:* PermMatrix.lean (NEW); *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def liftedSigmaMatrix (m : ℕ) (σ : Equiv.Perm (Fin m)) :
>     Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
>   (liftedSigma m σ).permMatrix
>
> @[simp] theorem liftedSigmaMatrix_apply (σ) (i j) :
>     liftedSigmaMatrix m σ i j = if liftedSigma m σ j = i then 1 else 0
> ```
> *Tactic:* unfold `Equiv.Perm.permMatrix` + `PEquiv.toMatrix_apply`.

> **B.2** — Determinant + invertibility.
> *File:* PermMatrix.lean; *Pred:* B.1; *LOC:* 40; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem liftedSigmaMatrix_det_ne_zero (σ) :
>     (liftedSigmaMatrix m σ).det ≠ 0
> noncomputable def liftedSigmaGL (m : ℕ) (σ : Equiv.Perm (Fin m)) :
>     GL (Fin (dimGQ m)) ℚ :=
>   Matrix.GeneralLinearGroup.mkOfDetNeZero (liftedSigmaMatrix m σ)
>     (liftedSigmaMatrix_det_ne_zero σ)
> ```
> *Tactic:* `Matrix.det_permutation` gives `det = sign σ ∈ {±1} ≠ 0`.

> **B.3** — Group homomorphism law for `liftedSigmaGL`.
> *File:* PermMatrix.lean; *Pred:* B.2; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> @[simp] theorem liftedSigmaGL_one : liftedSigmaGL m 1 = 1
> @[simp] theorem liftedSigmaGL_mul (σ τ) :
>     liftedSigmaGL m (σ * τ) = liftedSigmaGL m σ * liftedSigmaGL m τ
> @[simp] theorem liftedSigmaGL_inv (σ) :
>     (liftedSigmaGL m σ)⁻¹ = liftedSigmaGL m σ⁻¹
> ```
> *Tactic:* unfold `liftedSigmaGL`, use Mathlib's `permMatrix_mul`,
> `permMatrix_one`. Apply `Matrix.GeneralLinearGroup.ext`.

### Tensor-action collapse

> **B.4** — Single-axis permutation collapse (axis 1).
> *File:* PermMatrix.lean; *Pred:* B.1; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem matMulTensor1_permMatrix
>     (π : Equiv.Perm (Fin n)) (T : Tensor3 n ℚ) :
>     matMulTensor1 (π.permMatrix : Matrix _ _ ℚ) T =
>     fun i j k => T (π.symm i) j k
> ```
> *Tactic:* `funext i j k`; unfold `matMulTensor1`. Use
> `Finset.sum_eq_single (π.symm i)`:
> * Show all other indices `a ≠ π.symm i` give `permMatrix i a = 0`
>   (since `π a ≠ i`).
> * The unique surviving term is `permMatrix i (π.symm i) * T (π.symm i) j k = 1 * T (...) = T (...)`.

> **B.5** — Single-axis collapse (axes 2 and 3).
> *File:* PermMatrix.lean; *Pred:* B.1; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem matMulTensor2_permMatrix (π) (T) :
>     matMulTensor2 π.permMatrix T = fun i j k => T i (π.symm j) k
> theorem matMulTensor3_permMatrix (π) (T) :
>     matMulTensor3 π.permMatrix T = fun i j k => T i j (π.symm k)
> ```
> *Tactic:* identical proof structure to B.4 with axis swap.

> **B.6** — Triple collapse for `tensorContract`.
> *File:* PermMatrix.lean; *Pred:* B.4, B.5; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem tensorContract_permMatrix_triple (π) (T) :
>     tensorContract π.permMatrix π.permMatrix π.permMatrix T =
>     fun i j k => T (π.symm i) (π.symm j) (π.symm k)
> ```
> *Tactic:* unfold `tensorContract = matMulTensor1 ∘ matMulTensor2 ∘ matMulTensor3`;
> rewrite with B.5 (axis 3 first), B.5 (axis 2), B.4 (axis 1).

> **B.7** — GL³ smul collapse.
> *File:* PermMatrix.lean; *Pred:* B.6; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem gl_triple_permMatrix_smul (σ) (T : Tensor3 (dimGQ m) ℚ) :
>     (liftedSigmaGL m σ, liftedSigmaGL m σ, liftedSigmaGL m σ) • T =
>     fun i j k => T ((liftedSigma m σ).symm i)
>                    ((liftedSigma m σ).symm j)
>                    ((liftedSigma m σ).symm k)
> ```
> *Tactic:* unfold `tensorAction.smul`, apply B.6.

### Discharge of `GrochowQiaoForwardObligation`

> **B.8** — `grochowQiao_forwardObligation`.
> *File:* PermMatrix.lean (or Forward.lean ext); *Pred:* B.7 + existing
> `grochowQiaoEncode_equivariant`; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem grochowQiao_forwardObligation : GrochowQiaoForwardObligation := by
>   intro m adj₁ adj₂ ⟨σ, h⟩
>   refine ⟨(liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹), ?_⟩
>   funext i j k
>   rw [gl_triple_permMatrix_smul]
>   simp only [Equiv.Perm.symm_inv]
>   exact (grochowQiaoEncode_equivariant m adj₁ adj₂ σ h
>            ((liftedSigma m σ).symm i) ((liftedSigma m σ).symm j) ((liftedSigma m σ).symm k)).symm.trans
>         (by simp [Equiv.apply_symm_apply])
> ```
> *Note:* The `σ⁻¹` choice in the GL triple gives
> `((liftedSigma σ⁻¹).symm i) = liftedSigma σ i`, which matches
> `grochowQiaoEncode_equivariant`'s shape. **This WU closes
> `GrochowQiaoForwardObligation` unconditionally.**

## Phase C — Linear-Combination Idempotent + Primitivity (8 WUs, ~400 LOC)

### Linear-combination idempotent characterization

> **C.1** — Coefficient extraction lemmas for `b · b`.
> *File:* Rigidity.lean (NEW) §1; *Pred:* A2.3; *LOC:* 80; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem mul_apply_id (f g : pathAlgebraQuotient m) (w : Fin m) :
>     (f * g) (.id w) = f (.id w) * g (.id w)
> theorem mul_apply_edge (f g) (u v : Fin m) :
>     (f * g) (.edge u v) =
>       f (.id u) * g (.edge u v) + f (.edge u v) * g (.id v)
> ```
> *Tactic:* unfold `Mul.mul, pathAlgebraMul`; the double sum collapses
> on each constructor of the index `c`. For `c = .id w`, only the
> `(a, b) = (.id w, .id w)` term survives (any arrow product gives
> `none` or a non-`.id`). For `c = .edge u v`, the surviving terms
> are `(a, b) ∈ {(.id u, .edge u v), (.edge u v, .id v)}`.

> **C.2** — Idempotent characterization theorem.
> *File:* Rigidity.lean §1; *Pred:* C.1; *LOC:* 80; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathAlgebra_isIdempotent_iff (b : pathAlgebraQuotient m) :
>     IsIdempotentElem b ↔
>     (∀ v : Fin m, b (.id v) * b (.id v) = b (.id v)) ∧
>     (∀ u v : Fin m, b (.edge u v) =
>         b (.id u) * b (.edge u v) + b (.edge u v) * b (.id v))
> ```
> *Tactic:* `IsIdempotentElem b ↔ b * b = b ↔ funext c, b·b c = b c`;
> for each constructor of `c` apply C.1 and read off the equation.

> **C.3** — Coefficient consequences (λ_v ∈ {0,1}, μ_{u,v} = 0 ∨ λ_u + λ_v = 1).
> *File:* Rigidity.lean §1; *Pred:* C.2; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem pathAlgebra_idem_lambda_squared (h : IsIdempotentElem b) (v) :
>     b (.id v) = 0 ∨ b (.id v) = 1
> theorem pathAlgebra_idem_mu_constraint (h : IsIdempotentElem b) (u v) :
>     b (.edge u v) = 0 ∨ b (.id u) + b (.id v) = 1
> ```
> *Tactic:* C.2's first conjunct gives `λ_v² = λ_v` ⇒ `λ_v(λ_v - 1) = 0`
> ⇒ `λ_v ∈ {0, 1}` (in ℚ field). Second conjunct: `μ = λ_u μ + μ λ_v`
> ⇒ `(1 - λ_u - λ_v) μ = 0` ⇒ `μ = 0 ∨ λ_u + λ_v = 1`.

### Primitive idempotent definition + characterization

> **C.4** — `IsPrimitiveIdempotent` definition.
> *File:* Idempotents.lean (NEW); *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def IsPrimitiveIdempotent {A : Type*} [Ring A]
>     (b : A) : Prop :=
>   IsIdempotentElem b ∧ b ≠ 0 ∧
>   ∀ b₁ b₂ : A,
>     IsIdempotentElem b₁ → IsIdempotentElem b₂ →
>     b₁ * b₂ = 0 → b₂ * b₁ = 0 → b = b₁ + b₂ →
>     b₁ = 0 ∨ b₂ = 0
> ```

> **C.5** — Vertex idempotent is primitive (forward direction).
> *File:* Rigidity.lean §1; *Pred:* C.3, C.4, A2.3; *LOC:* 80; *Risk:* L-M.
> *Deliverable:*
> ```lean
> theorem vertexIdempotent_isPrimitive (m : ℕ) (v : Fin m) :
>     IsPrimitiveIdempotent (vertexIdempotent m v)
> ```
> *Tactic:* idempotency from A2.3; non-zero by `vertexIdempotent v
> (.id v) = 1`. Decomposition step: suppose `e_v = b₁ + b₂` with
> `b₁ b₂ = 0`. Apply C.3 to `b₁`: each coefficient `b₁ (.id w) ∈
> {0, 1}`. Then `b₁ (.id v) + b₂ (.id v) = e_v (.id v) = 1` AND
> `b₁ (.id w) + b₂ (.id w) = 0` for `w ≠ v`. Combining `b₁ b₂ = 0`
> evaluated at `(.id w)` gives `b₁ (.id w) · b₂ (.id w) = 0` so
> for each `w ≠ v` either `b₁ (.id w) = 0` or `b₂ (.id w) = 0`, but
> the sum is zero, so both are 0. At `w = v`, sum = 1 with each
> ∈ {0,1}, so one is 0 and the other is 1. Case-split: if
> `b₁ (.id v) = 1` and `b₂ (.id v) = 0`, then `b₂` has all `.id`
> coefficients zero; from C.3's μ-constraint applied to `b₂`,
> all `b₂ (.edge _ _) = 0` too (since `λ_u + λ_v = 0 ≠ 1` always
> when both `λ`s are 0). So `b₂ = 0`. Symmetrically.

> **C.6** — Primitive ⟹ vertex idempotent (reverse direction).
> *File:* Rigidity.lean §1; *Pred:* C.3, C.4; *LOC:* 100; *Risk:* M.
> *Deliverable:*
> ```lean
> theorem isPrimitive_iff_vertex (b : pathAlgebraQuotient m) :
>     IsPrimitiveIdempotent b ↔ ∃ v : Fin m, b = vertexIdempotent m v
> ```
> *Tactic for ⟹.* Let `S := {v | b (.id v) = 1}`. By C.3, all
> `λ_v ∈ {0, 1}`, so `b (.id v) = 1` if `v ∈ S` else `0`. If `S = ∅`,
> all `λ_v = 0` and the μ-constraint forces all μ = 0 too (since
> `λ_u + λ_v = 0 ≠ 1`), so `b = 0`, contradicting non-zero.
> If `|S| ≥ 2`, pick `v₀ ∈ S`. Define `b₁ := vertexIdempotent v₀`,
> `b₂ := b - b₁`. Show `b₂` is idempotent (using C.2 — `b₂` has
> coefficient `0` at `.id v₀` and same `λ_v` as `b` elsewhere; the μ-
> constraint requires `μ_{u,v} = 0` or `λ_u + λ_v = 1`, this holds
> for `b₂` because we removed only the `v₀` part. Specifically, for
> `μ_{u, v₀} = b (.edge u v₀)`: original constraint says
> `λ_u + λ_{v₀} = 1` if `μ ≠ 0`. After subtracting `b₁`, this μ
> remains the same (since `b₁ (.edge _ _) = 0`), but now `λ_{v₀} = 0`
> in `b₂`. So we'd need `λ_u = 1` ⟹ `u ∈ S \ {v₀}`. This holds because
> the μ-constraint is preserved. ∎). Both `b₁`, `b₂` are non-zero,
> orthogonal, `b = b₁ + b₂`, contradicting primitivity. Hence
> `|S| = 1`, say `S = {v}`. By C.3 + μ-constraint, all μ = 0. So
> `b = vertexIdempotent v`.
> *Reverse:* C.5.

### Algebra-equivalence preserves primitivity

> **C.7** — `AlgEquiv` preserves `IsIdempotentElem`.
> *File:* Idempotents.lean; *Pred:* C.4; *LOC:* 25; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem AlgEquiv.preserves_isIdempotent
>     {A B : Type*} [Ring A] [Ring B] [Algebra ℚ A] [Algebra ℚ B]
>     (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsIdempotentElem b) :
>     IsIdempotentElem (φ b)
> ```
> *Tactic:* `IsIdempotentElem` ↔ `b * b = b`; `φ (b * b) = φ b * φ b`
> via `AlgEquiv.map_mul`.

> **C.8** — `AlgEquiv` preserves `IsPrimitiveIdempotent`.
> *File:* Idempotents.lean; *Pred:* C.4, C.7; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem AlgEquiv.preserves_isPrimitiveIdempotent
>     (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsPrimitiveIdempotent b) :
>     IsPrimitiveIdempotent (φ b)
> ```
> *Tactic:* `(h_idem, h_ne, h_prim) := h`. φ(b)·φ(b) = φ(b·b) = φ(b)
> (idempotent). φ(b) ≠ 0 by `AlgEquiv.injective`. For decomposition:
> suppose `φ(b) = c₁ + c₂` with `c₁ c₂ = 0`. Pull back `c₁ = φ(d₁)`,
> `c₂ = φ(d₂)` via `φ.symm`. Then `b = d₁ + d₂`, `d₁ d₂ = 0`
> (by `AlgEquiv.injective` applied to `φ(d₁ d₂) = c₁ c₂ = 0`).
> Apply `h_prim` to get `d₁ = 0 ∨ d₂ = 0`, hence `c₁ = 0 ∨ c₂ = 0`.

## Phase D — Distinguished-Padding Rigidity (15 WUs, ~700 LOC)

### Slot-signature predicates (D.1)

> **D.1** — `isVertexSignature` predicate.
> *File:* Rigidity.lean §2; *Pred:* none (uses `Tensor3` only); *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def isVertexSignature {n : ℕ} (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   T i i i = 1 ∧ ∃ j ≠ i, T i i j ≠ 0
> ```

> **D.2** — `isPaddingSignature` predicate.
> *File:* Rigidity.lean §2; *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def isPaddingSignature {n : ℕ} (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   T i i i = 1 ∧ ∀ j ≠ i, T i i j = 0
> ```

> **D.3** — `isArrowSignature` predicate.
> *File:* Rigidity.lean §2; *Pred:* none; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> def isArrowSignature {n : ℕ} (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   T i i i = 0
> ```

### Encoder-side characterizations (D.4–D.6)

> **D.4** — Vertex-signature characterization on encoder.
> *File:* Rigidity.lean §2; *Pred:* D.1, encoder definitions; *LOC:* 70; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem isVertexSignature_grochowQiaoEncode_iff (m : ℕ) (h_m : 1 ≤ m)
>     (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
>     isVertexSignature (grochowQiaoEncode m adj) i ↔
>     ∃ v : Fin m, slotEquiv m i = .vertex v
> ```
> *Tactic:* unfold `isVertexSignature`, `grochowQiaoEncode`. Forward:
> if `T i i i = 1`, the path-algebra branch fires (else ambient = if
> i=j=k then 1 else 0 — matches but then arrow constraint fails for
> ∃ j ≠ i, T i i j ≠ 0, which forces vertex slot since arrows have
> `e_v · e_v · α(v, w) = α(v, w)` non-zero). Backward: vertex slot v
> has `T (vertex v)³ = 1` (idempotent law) and `T (vertex v)² (arrow v w) ≠ 0` for each present arrow `(v, w)`. **If the graph has no
> outgoing arrows from v, the second condition fails!** **Need to
> handle the isolated-vertex case carefully** — the predicate may
> need refinement.

**Note (D.4 risk):** the predicate `∃ j ≠ i, T i i j ≠ 0` may fail
on isolated vertices. **Refined predicate:**
```lean
def isVertexSignature' (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
  T i i i = 1
```
This collapses to "diagonal is 1", which both vertex slots and
padding slots satisfy. Need a stronger discriminator. **Revised
approach below in D.5.**

> **D.5** — REVISED vertex-vs-padding discriminator: row signature.
> *File:* Rigidity.lean §2; *Pred:* D.1, D.2; *LOC:* 80; *Risk:* M.
> *Deliverable:*
> ```lean
> def rowSignature (T : Tensor3 n ℚ) (i : Fin n) : Set (Fin n × Fin n) :=
>   { (j, k) | T i j k ≠ 0 }
>
> theorem rowSignature_grochowQiaoEncode_vertex (v : Fin m) :
>     rowSignature (grochowQiaoEncode m adj)
>       ((slotEquiv m).symm (.vertex v)) =
>     { (slotEquiv-symmetric vertex v slot pair) ∪
>       arrow slots emanating from v under adj }
>
> theorem rowSignature_grochowQiaoEncode_padding (i : padding slot) :
>     rowSignature (grochowQiaoEncode m adj) i = {(i, i)}
> ```
> Padding slots have rowSignature cardinality 1 (only `(i, i)`).
> Vertex slot `v` has rowSignature cardinality `1 + (#out-arrows from v)`
> in the path-algebra subblock. **If a vertex has no out-arrows AND
> no in-arrows, the row signature reduces to {(i, i)}**, indistinguishable
> from padding by row signature alone.
>
> **Strengthened:** use *both* row and column signatures:
> ```lean
> def isVertexSlot (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   T i i i = 1
> ```
> This is the cleanest invariant — vertex slots have `T i i i = 1`
> from `e_v · e_v = e_v`; padding slots have `T i i i = 1` from
> `ambientSlotStructureConstant i i i = 1` (since `i = i ∧ i = i`);
> arrow slots have `T i i i = 0` (since `α(u, v) · α(u, v) = 0`).
> But this doesn't distinguish vertex from padding! **Need a deeper
> invariant.**

**KEY INSIGHT — algebraic invariant via product structure:**
> A slot `i` is a **vertex-or-padding slot** iff `T i i i = 1`.
> A slot `i` is a **vertex slot** iff additionally `T i i i = 1` AND
> there is some `j` with `T j j i = 1` AND `T i j i ≠ 0`. Vertex
> slots `e_v` interact non-trivially with arrows incident at `v`;
> padding slots only have non-zero entries on the triple-diagonal.
>
> More carefully: a slot `i` is **vertex** iff
> ```
> ∃ j k, T j i k ≠ 0  ∧  ¬ (j = i ∧ i = k)
> ```
> i.e., there's an off-diagonal triple involving slot `i` in the
> middle position. Vertex slots have this via `e_u · e_v · e_w`-style
> idempotent products (when `u = v = w`, but also via `e_v · α(v, w)`).
> Padding slots fail this because `ambientStructureConstant` is non-
> zero only on triple-diagonal.

> **D.5'** — REVISED: cleaner algebraic invariant.
> *File:* Rigidity.lean §2; *Pred:* D.1, D.2; *LOC:* 100; *Risk:* M.
> *Deliverable:*
> ```lean
> def hasOffDiagonalMiddle (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   ∃ j k, ¬ (j = i ∧ i = k) ∧ T j i k ≠ 0
>
> theorem isVertex_of_diagonal_and_offMiddle (i) :
>     T i i i = 1 ∧ hasOffDiagonalMiddle T i ↔
>     ∃ v, slotEquiv m i = .vertex v   (when T = grochowQiaoEncode m adj, h_m : 1 ≤ m)
>
> theorem isPadding_of_diagonal_no_offMiddle (i) :
>     T i i i = 1 ∧ ¬ hasOffDiagonalMiddle T i ↔
>     ∃ u v, slotEquiv m i = .arrow u v ∧ adj u v = false
> ```
> *Tactic:* case-split on `slotEquiv m i`. For vertex slot v, `e_v ·
> e_v · α(v, w)` (or the symmetric `α(u, v) · e_v · e_v`) is non-zero
> for any present arrow incident at v. **If v is isolated**, then
> there's no such arrow — but `e_v · e_v · e_v = e_v` is still on
> the triple-diagonal, so `hasOffDiagonalMiddle` could still fail.
>
> **For isolated vertices:** consider `T i j k` with `j ≠ i` or
> `k ≠ i`. We need `T j i k ≠ 0` for some off-diag pair. From
> `pathSlotStructureConstant`, we have at least: `T (.vertex w) (.vertex v) (.vertex w) = ?`. Compute: `slotToArrow (vertex w) = .id w`,
> `pathMul (.id w) (.id v) = some (.id v) if w = v else none`.
> If `w = v`, we'd need `(.id v) = .id w` but `w = v` so yes; the
> result is `some (.id v)`, then `if (.id v) = (.id w) then 1 else 0
> = 1`. So `T (.vertex w) (.vertex v) (.vertex w) = 1` when `w = v`.
> But this is the triple-diagonal case (i = w = v).
>
> **Key:** for isolated vertex v, are there ANY off-diagonal middle
> indices? `T j v k` requires `slotToArrow(j) · slotToArrow(v) =
> some c` where `c = slotToArrow(k)`. Since `slotToArrow v = .id v`,
> we need `slotToArrow(j) · (.id v) = c`. From multiplication table:
> `(.id u) · (.id v) = some (.id v)` if `u = v`, so `j` must be
> vertex-v slot AND `k` must be vertex-v slot ⟹ triple-diagonal.
> `(.edge u w) · (.id v) = some (.edge u w)` if `w = v`, so `j` is
> arrow-(u, v) slot for some present incoming arrow. **If v is
> totally isolated (no in or out arrows), no such j exists.** In
> that case, `T j v k = 0` for all `(j, k) ≠ (v-slot, v-slot)`.
> So `hasOffDiagonalMiddle` fails — the isolated vertex is
> indistinguishable from padding by this invariant!

**Mitigation: combine slot signature with column counts.** A
better invariant counts how many `(j, k)` pairs have `T j i k = 1`.
For vertex v: at least 1 (triple-diagonal) + (# in-arrows at v) +
(# out-arrows at v) + (# loops at v). For padding: exactly 1.
Distinguish by **diagonal-count cardinality ≥ 2 vs = 1**, plus
isolated-vertex edge case.

> **D.6** — Slot-classification invariant on encoder (with isolated-vertex care).
> *File:* Rigidity.lean §2; *Pred:* D.1–D.5; *LOC:* 120; *Risk:* M.
> *Deliverable:* a partition function
> ```lean
> def slotClass (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
>     Sum (Sum (Fin m) (Fin m × Fin m)) (Fin m × Fin m)
>   -- vertex slot v / present arrow (u, v) / padding (u, v)
> ```
> with theorem `slotClass i = (vertex v) ↔ slotEquiv i = .vertex v`,
> etc., **all derivable from the encoder's structure**.
>
> *Note:* for isolated vertices, the slot-class of "vertex v" is
> still distinguishable from padding by a stronger invariant — see
> D.7.

### Stronger algebraic invariants (D.7)

> **D.7** — Triple-product membership invariant.
> *File:* Rigidity.lean §2; *Pred:* D.1; *LOC:* 80; *Risk:* M.
> *Deliverable:*
> ```lean
> -- A slot i is "in the multiplicative closure" iff it appears as
> -- the result of some non-trivial product in the structure tensor.
> def isTripleResult (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
>   ∃ j₁ j₂ k₁ k₂, T j₁ k₁ i ≠ 0 ∧ T j₂ k₂ i ≠ 0 ∧
>     (j₁, k₁) ≠ (i, i) ∧ (j₂, k₂) ≠ (i, i) ∧
>     (j₁, k₁) ≠ (j₂, k₂)
> ```
> Captures "slot i is the third index of two distinct non-trivial
> triples". For padding slots, the only non-zero triple with `i` as
> third index is `(i, i, i)` itself — fails the predicate. For
> vertex slot `v` with at least 2 incident arrows or 1 incoming + 1
> self-loop: the predicate succeeds. Refinement still needed for
> isolated vertices.

**FALLBACK FOR ISOLATED VERTICES:** if an `m`-vertex graph has any
isolated vertex `v`, the encoder slot for `v` is **algebraically
indistinguishable from a padding slot** by the invariants above.
**This is a genuine obstruction.** Two options:

* Restrict the rigidity argument to graphs with no isolated vertices
  (no algorithmic loss for hard GI instances; CFI / Petrank-Roth
  graphs always have isolated-vertex-free reductions).
* Use a richer invariant (e.g., the *full row signature* {(j, k) | T i j k ≠ 0} as a multi-set fingerprint).

**For this plan, we choose Option 2:** use the full row signature,
which uniquely identifies each slot's "kind" by counting non-zero
patterns.

### Row signature uniqueness (D.8)

> **D.8** — Row signature determines slot kind on encoder.
> *File:* Rigidity.lean §2; *Pred:* D.1, encoder evaluation lemmas; *LOC:* 100; *Risk:* M.
> *Deliverable:*
> ```lean
> def rowSig (T : Tensor3 n ℚ) (i : Fin n) : Finset (Fin n × Fin n) :=
>   Finset.univ.filter (fun (j, k) => T i j k ≠ 0)
>
> theorem rowSig_inj_on_grochowQiaoEncode (m) (h_m) (adj) (i₁ i₂) :
>     rowSig (grochowQiaoEncode m adj) i₁ = rowSig (grochowQiaoEncode m adj) i₂ →
>     -- Slot kinds match (vertex-vertex, arrow-arrow, padding-padding)
>     -- with potentially different vertex labels
>     SameSlotClass m adj i₁ i₂
> ```
> Even isolated vertices have *distinct* row signatures from padding
> slots: an isolated-vertex slot `v` has rowSig containing
> `{(v-slot, v-slot)}` (idempotent law), while a padding slot `(u, v)`
> with `adj u v = false` has rowSig `{(padding-(u,v), padding-(u,v))}`
> at index `(i, i)`. **Both are singletons containing `(i, i)`**.
> Indistinguishable!
>
> **Final mitigation: use Phase D.2 fallback per user decision.**
> Land the partition-preservation as a Prop hypothesis
> `GLPreservesVertexSignatureBijection` and thread through. ← **The
> isolated-vertex obstruction is precisely why D.2 might require the
> Prop fallback per user's earlier decision.**

### GL³ preservation (D.9–D.12)

> **D.9** — Diagonal-1 invariance under GL³.
> *File:* Rigidity.lean §2; *Pred:* D.1; *LOC:* 60; *Risk:* M.
> *Deliverable:*
> ```lean
> theorem gl_preserves_diagonal_one
>     (g : GL × GL × GL) (T₁ T₂ : Tensor3 n ℚ)
>     (h : g • T₁ = T₂) (i : Fin n) (h_diag : T₂ i i i = 1) :
>     ∃ S : Finset (Fin n), …
> ```
> Establish that the set `{i | T i i i = 1}` is preserved up to a
> linear bijection by the GL³ action. **This is the first place
> where the Prop hypothesis fallback may be needed.**

> **D.10** — `GLPreservesVertexSignatureBijection` Prop (fallback).
> *File:* Rigidity.lean §2; *Pred:* D.1, D.2; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> -- If the elementary D.9-D.11 chain fails to discharge, use:
> def GLPreservesVertexSignatureBijection : Prop :=
>   ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
>     (g : GL × GL × GL)
>     (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂),
>   ∃ π : Fin (dimGQ m) ≃ Fin (dimGQ m),
>     (∀ i, isVertexSignature (grochowQiaoEncode m adj₁) i ↔
>           isVertexSignature (grochowQiaoEncode m adj₂) (π i)) ∧
>     (∀ i, isPaddingSignature (grochowQiaoEncode m adj₁) i ↔
>           isPaddingSignature (grochowQiaoEncode m adj₂) (π i))
> ```
> *Status:* introduced **only if D.9-D.12 elementary attempts fail.**
> Per user-approved policy.

> **D.11** — Elementary attempt: `gl_preserves_vertexSig_count`.
> *File:* Rigidity.lean §2; *Pred:* D.1, B.6; *LOC:* 100; *Risk:* H.
> *Deliverable:*
> ```lean
> theorem gl_preserves_vertexSig_count (g) (h) :
>     (Finset.univ.filter (isVertexSignature (grochowQiaoEncode m adj₁))).card =
>     (Finset.univ.filter (isVertexSignature (grochowQiaoEncode m adj₂))).card
> ```
> *Tactic strategy:* `g • T₁ = T₂` is a linear isomorphism on the
> tensor space. Both `T₁` and `T₂` have exactly `m` slots with
> `T i i i = 1` (by encoder count) ... but this gives *count*
> equality only, not bijectivity preserving the signature predicate.
> **HIGH RISK** — likely the actual obstruction. If proof attempts
> fail after good-faith effort, switch to D.10 Prop fallback per
> user policy.

> **D.12** — Either: full elementary discharge, or fallback to D.10.
> *File:* Rigidity.lean §2; *Pred:* D.11 (or D.10); *LOC:* 100 (or 50); *Risk:* H or L (depending on path).
> *Deliverable:*
> ```lean
> -- Variant A (elementary, if D.11 succeeds):
> theorem gl_preserves_vertexSig_bijection ... : ∃ π, ...
>
> -- Variant B (fallback, if D.11 fails):
> theorem gl_preserves_vertexSig_bijection_under_hyp
>     (h_hyp : GLPreservesVertexSignatureBijection) ... : ∃ π, ...
> ```

### Vertex permutation extraction (D.13–D.15)

> **D.13** — Slot-to-vertex extraction map.
> *File:* Rigidity.lean §2; *Pred:* encoder defs; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def vertexSlotToFin (m) (h_m : 1 ≤ m) (adj) (i : Fin (dimGQ m))
>     (h_vertex : isVertexSignature (grochowQiaoEncode m adj) i ∨ … ) : Fin m
> ```
> Extracts the underlying vertex `v` from a vertex-signature slot
> via `slotEquiv m i = .vertex v`.

> **D.14** — Bijection on `Fin m` from D.12.
> *File:* Rigidity.lean §2; *Pred:* D.12, D.13; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def extractVertexPermutation
>     (m : ℕ) (h_m : 1 ≤ m) (adj₁ adj₂ : Fin m → Fin m → Bool)
>     (g : GL × GL × GL)
>     (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂)
>     [optional: h_hyp : GLPreservesVertexSignatureBijection] :
>     Equiv.Perm (Fin m)
> ```
> Compose D.13 with the bijection from D.12.

> **D.15** — `extractVertexPermutation` is well-defined.
> *File:* Rigidity.lean §2; *Pred:* D.14; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem extractVertexPermutation_bijective : Function.Bijective (extractVertexPermutation …)
> ```

## Phase E — GL³ → Algebra Automorphism (5 WUs, ~350 LOC)

> **E.1** — Linear map from GL₁ to algebra.
> *File:* Rigidity.lean §3; *Pred:* A2.12, D.14; *LOC:* 80; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def gl_to_algebraMap
>     (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
>     (g : GL × GL × GL) (h : g • grochowQiaoEncode m adj₁ = …)
>     [optional Prop hyp] :
>     pathAlgebraQuotient m →ₗ[ℚ] pathAlgebraQuotient m
> ```
> The linear map sends vertex idempotent `e_v` to the value of
> `gX⁻¹.val` at `(slotEquiv (vertex v))`-indexed entries; arrow
> elements similarly. Constructed from the σ extracted in D.14
> via `quiverMap`.

> **E.2** — Map preserves multiplication on basis elements.
> *File:* Rigidity.lean §3; *Pred:* E.1, encoder equivariance, A2.3; *LOC:* 100; *Risk:* M.
> *Deliverable:*
> ```lean
> theorem gl_to_algebraMap_mul (a b : QuiverArrow m) :
>     gl_to_algebraMap m … (Pi.single a 1 * Pi.single b 1) =
>     gl_to_algebraMap m … (Pi.single a 1) * gl_to_algebraMap m … (Pi.single b 1)
> ```
> *Tactic:* unfold via the structure-tensor preservation `g • T₁ = T₂`
> evaluated on basis-element triples; combine with A2.3 multiplication
> table.

> **E.3** — Map preserves multiplication on linear combinations.
> *File:* Rigidity.lean §3; *Pred:* E.2, A2.11; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem gl_to_algebraMap_mul_general (f g : pathAlgebraQuotient m) :
>     gl_to_algebraMap m … (f * g) = gl_to_algebraMap m … f * gl_to_algebraMap m … g
> ```
> *Tactic:* expand `f`, `g` via A2.11; bilinearity of `*` reduces to
> E.2 on basis elements.

> **E.4** — Map preserves unit.
> *File:* Rigidity.lean §3; *Pred:* E.1, A2.5; *LOC:* 40; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem gl_to_algebraMap_one : gl_to_algebraMap m … 1 = 1
> ```
> *Tactic:* `1 = ∑_v vertexIdempotent v`; the map sends this to
> `∑_v vertexIdempotent (σ v) = 1` (sum over a permuted index set).

> **E.5** — Algebra automorphism assembly.
> *File:* Rigidity.lean §3; *Pred:* E.1–E.4; *LOC:* 80; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def gl_to_algEquiv
>     (m) (adj₁ adj₂) (g) (h) [hyp] :
>     pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m :=
>   AlgEquiv.ofBijective
>     { toLinearMap := gl_to_algebraMap m … g h
>       map_mul' := gl_to_algebraMap_mul_general
>       map_one' := gl_to_algebraMap_one
>       commutes' := by …  -- ℚ-scalar commutation }
>     (by … bijective_of_invertible_GL)
> ```
> *Tactic:* `AlgEquiv.ofBijective` requires AlgHom + bijection. The
> AlgHom is built from E.1+E.3+E.4. Bijectivity from `g` invertible
> (GL is invertible).

## Phase F — Vertex Permutation + Adjacency Invariance (8 WUs, ~770 LOC)

### F.1 — AlgEquiv permutes vertex idempotents (T4.3)

> **F.1.1** — AlgEquiv image of vertex idempotent is primitive.
> *File:* Rigidity.lean §4; *Pred:* C.5, C.8; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem algEquiv_vertexIdempotent_isPrimitive
>     (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) (v : Fin m) :
>     IsPrimitiveIdempotent (φ (vertexIdempotent m v))
> ```
> *Tactic:* `vertexIdempotent_isPrimitive` (C.5) + `AlgEquiv.preserves_isPrimitiveIdempotent` (C.8).

> **F.1.2** — Existence of σ-image vertex.
> *File:* Rigidity.lean §4; *Pred:* C.6, F.1.1; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem algEquiv_vertexIdempotent_eq (φ) (v) :
>     ∃ τ_v : Fin m, φ (vertexIdempotent m v) = vertexIdempotent m τ_v
> ```
> *Tactic:* `φ (e_v)` is primitive (F.1.1), so by C.6 it equals
> `vertexIdempotent m τ_v` for some `τ_v`.

> **F.1.3** — τ is bijective.
> *File:* Rigidity.lean §4; *Pred:* F.1.2; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> noncomputable def algEquiv_vertexPerm (φ) : Equiv.Perm (Fin m)
> theorem algEquiv_vertexPerm_apply (φ) (v) :
>     φ (vertexIdempotent m v) = vertexIdempotent m (algEquiv_vertexPerm φ v)
> ```
> *Tactic:* uniqueness of τ_v from F.1.2 (each `vertexIdempotent m v`
> is a distinct primitive idempotent — apply at distinct `v`s, get
> injective function, hence bijective on `Fin m`).

### F.2 — Arrow-corner uniqueness (T4.4)

> **F.2.1** — Sandwich identity in path algebra.
> *File:* Rigidity.lean §4; *Pred:* A2.3; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem vertex_arrow_vertex_sandwich (u v : Fin m) :
>     vertexIdempotent m u * arrowElement m u v * vertexIdempotent m v =
>     arrowElement m u v
> ```
> *Tactic:* unfold using A2.3's mul lemmas (`vertexIdempotent_mul_arrowElement`,
> `arrowElement_mul_vertexIdempotent`).

> **F.2.2** — AlgEquiv image of arrow has expected sandwich.
> *File:* Rigidity.lean §4; *Pred:* F.1.3, F.2.1; *LOC:* 60; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem algEquiv_arrow_sandwich (φ) (u v) :
>     vertexIdempotent m (algEquiv_vertexPerm φ u) *
>       φ (arrowElement m u v) *
>       vertexIdempotent m (algEquiv_vertexPerm φ v) =
>     φ (arrowElement m u v)
> ```
> *Tactic:* apply φ to F.2.1; `AlgEquiv.map_mul` + F.1.2.

> **F.2.3** — Sandwich projection isolates arrow basis.
> *File:* Rigidity.lean §4; *Pred:* A2.3, A2.11; *LOC:* 80; *Risk:* M.
> *Deliverable:*
> ```lean
> theorem vertex_sandwich_isolates_arrow (u v : Fin m) (f : pathAlgebraQuotient m) :
>     vertexIdempotent m u * f * vertexIdempotent m v =
>     f (.edge u v) • arrowElement m u v
> ```
> *Tactic:* expand `f` via A2.11; left-multiply by `e_u`, right-
> multiply by `e_v`; A2.3 simp lemmas annihilate all components
> except `f (.edge u v) · α(u, v)`.

> **F.2.4** — Arrow-element image is scalar multiple.
> *File:* Rigidity.lean §4; *Pred:* F.2.2, F.2.3; *LOC:* 60; *Risk:* L-M.
> *Deliverable:*
> ```lean
> theorem algEquiv_arrow_eq_scalar
>     (φ) (u v : Fin m) (h_pres : adj₁ u v = true) :
>     ∃ c : ℚ, c ≠ 0 ∧
>       φ (arrowElement m u v) =
>       c • arrowElement m (algEquiv_vertexPerm φ u) (algEquiv_vertexPerm φ v)
> ```
> *Tactic:* combine F.2.2 + F.2.3 specialized to the σ-image
> indices; the only basis element with that sandwich is `α(σ u, σ v)`.
> Non-zero `c` from `φ` injective.

### F.3 — Adjacency invariance (T4.5)

> **F.3.1** — Image of present arrow is non-zero.
> *File:* Rigidity.lean §4; *Pred:* F.2.4; *LOC:* 30; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem algEquiv_present_arrow_nonzero (u v) (h : adj₁ u v = true) :
>     φ (arrowElement m u v) ≠ 0
> ```

> **F.3.2** — adjacency preservation.
> *File:* Rigidity.lean §4; *Pred:* F.2.4, F.3.1; *LOC:* 50; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem algEquiv_adj_preservation (φ) (u v) :
>     adj₁ u v = adj₂ (algEquiv_vertexPerm φ u) (algEquiv_vertexPerm φ v)
> ```
> *Tactic:* `adj₁ u v = true` ⟺ `arrowElement u v ∈ pathAlgebraQuotient m adj₁`-support
> ⟺ `φ(arrowElement u v) ≠ 0` (F.3.1) ⟺ `arrowElement (σu)(σv) ∈ adj₂`-support
> ⟺ `adj₂ (σu)(σv) = true`.

## Phase G — Reverse Direction Composition (3 WUs, ~400 LOC)

> **G.1** — `GL_triple_yields_vertex_permutation` (T5.1).
> *File:* ReverseFull.lean (NEW); *Pred:* D.14, E.5, F.3.2; *LOC:* 200; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem GL_triple_yields_vertex_permutation
>     (m : ℕ) (h_m : 1 ≤ m) (adj₁ adj₂)
>     (g : GL × GL × GL) (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂)
>     [optional: h_hyp : GLPreservesVertexSignatureBijection] :
>     ∃ σ : Equiv.Perm (Fin m), ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)
> ```
> *Tactic:* compose D.14 → E.5 → F.1.3 → F.3.2.

> **G.2** — `grochowQiao_rigidity` (T5.4) under hypothesis.
> *File:* ReverseFull.lean; *Pred:* G.1, edge cases; *LOC:* 100; *Risk:* L.
> *Deliverable:*
> ```lean
> theorem grochowQiao_rigidity_under_hyp
>     [h_hyp : GLPreservesVertexSignatureBijection] :
>     GrochowQiaoRigidity := by
>   intro m adj₁ adj₂ ⟨g, hg⟩
>   match h_m_dec : m with
>   | 0 => exact grochowQiaoEncode_reverse_zero adj₁ adj₂ ⟨g, hg⟩
>   | n + 1 =>
>     have h_m : 1 ≤ m := …
>     exact GL_triple_yields_vertex_permutation m h_m adj₁ adj₂ g hg
> ```

> **G.3** — Conditional vs unconditional discharge.
> *File:* ReverseFull.lean; *Pred:* G.2; *LOC:* 100; *Risk:* L.
> Two outcomes:
> * **If D.12 elementary path succeeds:** `theorem grochowQiao_rigidity : GrochowQiaoRigidity`
>   unconditional.
> * **If D.12 falls back to D.10:** keep `grochowQiao_rigidity_under_hyp`
>   and document `GLPreservesVertexSignatureBijection` as a 3rd open
>   research-scope Prop.

## Phase H — Final Assembly (3 WUs, ~80 LOC)

> **H.1** — Update `grochowQiao_isInhabitedKarpReduction_under_obligations`
> if needed (extend to 3 Props if Phase D fell back).
> *File:* GrochowQiao.lean; *Pred:* G.3; *LOC:* 30; *Risk:* L.

> **H.2** — Unconditional inhabitant.
> *File:* GrochowQiao.lean; *Pred:* B.8, G.3 (or G.2 + hyp); *LOC:* 30; *Risk:* L.
> *Deliverable:* one of
> ```lean
> -- Variant A (if D elementary works):
> theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _
>
> -- Variant B (if D fallback Prop hypothesis used):
> theorem grochowQiao_isInhabitedKarpReduction_conditional
>     (h_hyp : GLPreservesVertexSignatureBijection) : @GIReducesToTI ℚ _
> ```

> **H.3** — Concrete witness examples for audit script.
> *File:* scripts/audit_phase_16.lean; *Pred:* H.2; *LOC:* 40; *Risk:* L.
> *Deliverable:*
> ```lean
> example : @GIReducesToTI ℚ _ := grochowQiao_isInhabitedKarpReduction
> -- Plus K_3 round-trip + non-iso pair for m = 4
> ```

---

# Optimized Implementation Schedule (End-to-End)

## Total work-unit count: 63 WUs across 8 phases

| Phase | WUs | LOC | Cumulative LOC | Risk profile |
|-------|-----|-----|----------------|--------------|
| A.1 | 9 | ~300 | 300 | All L |
| A.2 | 12 | ~600 | 900 | 11 L + 1 M (A2.4 mul_assoc) |
| B | 8 | ~400 | 1300 | All L |
| C | 8 | ~400 | 1700 | 6 L + 2 L-M (C.5, C.6) |
| D | 15 | ~700 | 2400 | 9 L + 4 M + 2 H (D.11, D.12) |
| E | 5 | ~350 | 2750 | 4 L + 1 M (E.2) |
| F | 8 | ~770 | 3520 | 7 L + 1 M (F.2.3) |
| G | 3 | ~400 | 3920 | All L |
| H | 3 | ~80 | 4000 | All L |
| Audit + docs | 5 | ~250 | 4250 | All L |

**Final total: ~4,250 LOC across 5 new files + 5 extended files,
with 63 atomic work units. ~85% of work units are Low-risk.**

## Critical-path optimization

**Independent track A (Algebra wrapper):** A.1 → A.2.

**Independent track B (Permutation matrix):** B.1 → B.2 → B.3 → B.4 → B.5 → B.6 → B.7 → B.8.
(Closes `GrochowQiaoForwardObligation` early.)

**Track A and Track B are fully parallel** — implement B first
(simpler, lower risk, immediate visible win).

After tracks A and B land, **rigidity track:** A.2 → C → D → E → F → G → H.

### Recommended execution order

1. **Track B first** (~400 LOC, ~1 day): WUs B.1–B.8.
   * Closes `GrochowQiaoForwardObligation`.
   * Validates Mathlib API for `Equiv.Perm.permMatrix` early.
   * Visible milestone: forward direction is now unconditional.

2. **Track A.1** (~300 LOC, ~1 day): WUs A1.aux1–A1.aux8 + A1.main.
   * `pathMul_assoc` lands.
   * No external dependencies.

3. **Track A.2** (~600 LOC, ~2 days): WUs A2.1–A2.12.
   * Path-algebra Mathlib `Algebra ℚ` instance.
   * Depends on A1.main.

4. **Phase C** (~400 LOC, ~1 day): WUs C.1–C.8.
   * Linear-comb idempotent + primitivity.
   * Depends on A.2.

5. **Phase D** (~700 LOC, ~2-3 days): WUs D.1–D.15.
   * **HIGH RISK PHASE.** Risk gate at D.11/D.12 — if elementary
     attempts fail, switch to D.10 Prop fallback per user policy.

6. **Phase E** (~350 LOC, ~1 day): WUs E.1–E.5.
   * GL³ → AlgEquiv lift.

7. **Phase F** (~770 LOC, ~2 days): WUs F.1.1–F.3.2.
   * Vertex permutation extraction + adjacency invariance.

8. **Phase G** (~400 LOC, ~1 day): WUs G.1–G.3.
   * Composition into reverse direction discharge.

9. **Phase H** (~80 LOC, < 0.5 day): WUs H.1–H.3.
   * Final assembly + audit examples.

10. **Documentation sweep** (~250 LOC): CLAUDE.md, VERIFICATION_REPORT.md,
    Orbcrypt.lean, plan files, audit script, lakefile bump.

## Optimization decisions

* **Skip A2.12 if redundant.** The free-basis WU is structurally
  trivial (`pathAlgebraQuotient = QuiverArrow → ℚ` is already free)
  but isn't strictly used downstream. Land it only if needed by
  Phase E.2.

* **Phase B.5 unification.** B.4 + B.5 (single-axis collapse for
  axes 2 and 3) can be unified via a single helper lemma
  `matMulTensorAxisN_permMatrix` parameterised over axis index. Saves
  ~60 LOC. **Recommendation:** keep separate to match existing
  `matMulTensor1/2/3` Orbcrypt convention; ~30 LOC duplication is
  acceptable for clarity.

* **Phase D early termination.** If D.11 fails after 200 LOC of good-
  faith effort, switch to D.10 (Prop fallback) without further
  attempts. This preserves the budget and matches user-approved
  policy.

* **Phase F parallel sub-tracks.** F.1 (vertex permutation) and F.2
  (arrow corner) can run in parallel after F.1.3 lands. F.3 needs
  both.

## Risk mitigation refinements (per WU)

| WU | Specific mitigation |
|---|---|
| A1.main | If `cases QuiverArrow` chain elaboration is slow, factor into helper lemmas with explicit type annotations |
| A2.4 (mul_assoc) | Pre-establish helper `pathAlgebraMul_apply` that gives an explicit `f g c → ℚ` formula; `mul_assoc` then becomes a `funext c` + `Finset.sum` manipulation |
| C.5, C.6 | If proofs blow up past 200 LOC, factor the case-split on `|S|` into helpers `_decompose_at_v` indexed by `v ∈ S` |
| D.4–D.8 (signature predicates) | Skip if isolated-vertex-handling fails; collapse to D.10 fallback |
| **D.11–D.12 (HIGH RISK)** | Budget 200 LOC for elementary attempt; switch to D.10 fallback if it fails. Time-box: ~4 hours of focused work |
| E.2 | If multiplication-preservation under linear bijection is hard to express, add intermediate `LinearMap.pathAlgebraHom` structure and use Mathlib's `LinearMap.toAlgHom` |
| F.2.3 | Sandwich-projection lemma may need `Finset.sum_comm` re-bracketing; have backup of `funext c` + case-split on c's constructor |

---

# End-to-End Verification Plan

## Continuous verification (per WU)

After each WU lands:
1. `lake build <module>` — must succeed with zero errors, zero
   warnings.
2. The WU's deliverable theorem must satisfy `#print axioms` =
   `[propext, Classical.choice, Quot.sound]` or no axioms.

## Per-phase verification

After each phase (A, B, C, D, E, F, G, H):
1. Full `lake build` — zero errors, zero warnings.
2. New `#print axioms` entries added to `audit_phase_16.lean` for
   every public deliverable in the phase.
3. Add ≥1 non-vacuity `example` per phase head theorem.
4. Re-run audit script — expect zero `sorryAx`, zero non-trio axioms.

## Final integration verification

After H.3:

1. **Headline theorem builds:** `grochowQiao_isInhabitedKarpReduction
   : @GIReducesToTI ℚ _` must compile (or, if D-fallback was taken,
   `_under_hyp` variant).

2. **Round-trip example.**
   ```lean
   example :
     let adj₁ := fun i j : Fin 3 => decide (i ≠ j)  -- K_3
     let adj₂ := fun i j : Fin 3 => decide (i ≠ j)  -- K_3, same
     ∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) := …
   ```
   Discharged via `grochowQiao_isInhabitedKarpReduction.snd.mpr` +
   the encoder reflexivity.

3. **Non-isomorphic discriminator.**
   ```lean
   example :
     let adj₁ := fun i j : Fin 4 => /* C_4 */
     let adj₂ := fun i j : Fin 4 => /* K_{1,3} */
     ¬ AreTensorIsomorphic (grochowQiaoEncode 4 adj₁)
                            (grochowQiaoEncode 4 adj₂) := …
   ```

4. **Full project build:** `lake build` succeeds with all WUs landed.
   Job count expected: ~3,400+ jobs.

5. **Audit script:** `lake env lean scripts/audit_phase_16.lean` exits
   0 with all new entries.

---

# Documentation Sweep Checklist

After H.3 lands, update these files in a single docs commit:

1. **`CLAUDE.md`** — new "Workstream R-TI Layers T1.7 + T3.6 + T4 +
   T5 + T6.3 — full Karp reduction closure" change-log entry. Mark
   the rigidity argument as **closed** (or **conditional on Prop
   hyp** if D-fallback was taken).

2. **`Orbcrypt.lean`** — extend transparency report with new
   Workstream R-TI Snapshot section. Update Vacuity map: `GIReducesToTI`
   moves from "Karp-claim Prop, research-scope" to **fully discharged
   via Grochow-Qiao**.

3. **`docs/VERIFICATION_REPORT.md`** — Document history entry.
   Headline results table extended with `grochowQiao_isInhabitedKarpReduction`.

4. **`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`** —
   mark `R-15-residual-TI-reverse` and `R-15-residual-TI-forward-matrix`
   as **closed** (fully or partially depending on D outcome).

5. **`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`** —
   Workstream R-TI status: **complete**.

6. **`scripts/audit_phase_16.lean`** — verified throughout phases.

7. **`lakefile.lean`** — version bump `0.1.18 → 0.1.19`.

---

# Final Plan Summary (Optimized)

**Total scope:** ~4,250 LOC across 5 new + 5 extended modules,
broken into 63 atomic work units, in 8 phases.

**Strategic shift:** abandon Wedderburn-Mal'cev approach in favor of
elementary cardinality + structure-constant signature argument
(per Plan agent confirmation). Reduces D from ~1,200 LOC (Wedderburn)
to ~700 LOC (elementary), with no loss of rigor.

**Risk profile:** ~85% of WUs are Low-risk. The single highest-risk
sub-phase is **D.11–D.12 (vertex-signature bijection extraction)**.
User has pre-approved Prop-hypothesis fallback for D.2 if elementary
discharge fails.

**Sorry policy:** zero sorry baseline. Per-occurrence pause-and-ask
for any candidate site outside D.2. D.2 fallback uses Prop hypothesis
(no sorry).

**Critical path:** ~10–14 work-days of focused implementation if
all phases land elementarily; +2 days docs sweep.

**Outcome upon completion:**
* `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _` —
  the headline theorem of Workstream R-TI.
* All previously-open R-TI Props closed (or 1 new Prop introduced
  if D-fallback used, with full transparency).
* R-15 Karp reduction track complete for the Grochow-Qiao route.

**Implementation can begin upon ExitPlanMode approval.**



