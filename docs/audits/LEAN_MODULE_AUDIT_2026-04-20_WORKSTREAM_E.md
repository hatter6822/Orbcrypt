# Workstream E — Post-landing Audit (2026-04-20)

## Scope

Workstream E ("Probabilistic Refinement Chain", findings F-01, F-10, F-11,
F-17, F-20) landed on 2026-04-20 as commit `42e7aee` of branch
`claude/audit-workstream-planning-DlFrP`. This document records the
findings of a targeted post-landing audit, and the follow-up fixes
applied in the same branch.

## Audit methodology

1. **Read every new file** (no reliance on docstrings or commit messages).
2. **Trace the semantics of each definition** carefully (especially
   point-mass vs. probabilistic distributions, quantifier interactions
   in Prop-valued reductions).
3. **Verify each proof discharges each hypothesis it claims to.** A
   definition is "decoupled" when its hypothesis can be trivially
   satisfied, making the Prop equivalent to a weaker universal claim
   — these are flagged as bugs.
4. **Check that `#print axioms` is not the whole story.** A result can be
   axiom-clean yet say nothing useful; concrete instances exercise
   non-vacuity.

## Findings

### Finding E-A1 (critical): E3 reduction Props were decoupled

**Location.** `Orbcrypt/Hardness/Reductions.lean`, definitions
`ConcreteTensorOIAImpliesConcreteCEOIA`,
`ConcreteCEOIAImpliesConcreteGIOIA`, `ConcreteGIOIAImpliesConcreteOIA`.

**Problem.** The landed form was
`∀ T₀ T₁ C₀ C₁, ConcreteTensorOIA T₀ T₁ εT → ConcreteCEOIA C₀ C₁ εC`.
By the identity `∀ T, (P(T) → Q) = (∃ T, P(T)) → Q` (where `Q` is
independent of `T`), this is equivalent to
`(∃ T₀ T₁, ConcreteTensorOIA T₀ T₁ εT) → (∀ C₀ C₁,
ConcreteCEOIA C₀ C₁ εC)`. Taking `T₀ = T₁` makes the hypothesis trivially
satisfiable (same-tensor advantage is zero). So the Prop collapses to the
unrelated claim `∀ C₀ C₁, ConcreteCEOIA C₀ C₁ εC` — a universal CEOIA
statement that never actually consumed tensor-layer hardness.

**Impact.** The entire Workstream E chain was syntactically type-correct
but semantically disconnected at the tensor / code / graph boundary. The
`ConcreteHardnessChain` composition theorem passed the tensor hardness
hypothesis through a decoupled implication that delivered a trivial
conclusion (`ConcreteCEOIA ∅ ∅ εC`), and the "real" work happened only
at the `gi_to_oia` link.

**Fix.** Reshaped the three reduction Props to
**universal→universal** form:
- `UniversalConcreteTensorOIA εT → UniversalConcreteCEOIA εC`
- `UniversalConcreteCEOIA εC → UniversalConcreteGIOIA εG`
- `UniversalConcreteGIOIA εG → ConcreteOIA scheme ε`

Now the hypothesis is non-trivial (universal TI-hardness at εT is a
genuine cryptographic assumption, not trivially satisfiable) and the
conclusion is delivered meaningfully.

### Finding E-A2 (critical): E4 `ConcreteHardnessChain` carried a per-pair tensor witness

**Location.** `Orbcrypt/Hardness/Reductions.lean` structure
`ConcreteHardnessChain` and theorem
`ConcreteHardnessChain.concreteOIA_from_chain`.

**Problem.** The landed structure packaged `(n, G_TI, T₀, T₁,
tensor_hard)` with `tensor_hard : ConcreteTensorOIA T₀ T₁ εT` — a
per-pair witness. The composition theorem passed `hc.tensor_hard`
through the decoupled `tensor_to_ce` (see E-A1) landing on the trivially-
true `ConcreteCEOIA (∅ : Finset (Fin 0 → F)) ∅ εC`; then `hc.ce_to_gi`
produced `ConcreteGIOIA` on 0-vertex graphs (also trivially true). Only
`hc.gi_to_oia` did real work.

**Fix.** Dropped the `(n, G_TI, T₀, T₁)` parameters from the chain.
`tensor_hard` is now `UniversalConcreteTensorOIA εT`. Composition
is `hc.gi_to_oia (hc.ce_to_gi (hc.tensor_to_ce hc.tensor_hard))` —
three function applications, each consuming the previous layer
meaningfully. Added `ConcreteHardnessChain.tight_one_exists` as a
non-vacuity witness at ε = 1.

### Finding E-A3 (medium): E1 `ConcreteKEMOIA` collapses on `ε ∈ [0, 1)`

**Location.** `Orbcrypt/KEM/CompSecurity.lean` definition
`ConcreteKEMOIA`.

**Problem.** The landed form used `advantage D (PMF.pure p₀) (PMF.pure
p₁) ≤ ε`. Point-mass advantage is binary: 0 when `D p₀ = D p₁`, 1
otherwise. Bounding by `ε < 1` forces the 0-advantage case. So
`ConcreteKEMOIA kem ε` for `ε ∈ [0, 1)` is equivalent to
`ConcreteKEMOIA kem 0`. The docstring's claim that intermediate ε
"parameterises realistic KEM security" was false.

**Fix.** Kept `ConcreteKEMOIA` as the bridge target for the
deterministic-to-probabilistic conversion, but revised its docstring
to disclose the collapse. Added `ConcreteKEMOIA_uniform` that replaces
the point masses with `kemEncapsDist` (uniform-over-G push-forward) —
advantage there can take any real value in [0, 1], so intermediate ε
parameterise meaningful security. Added `concreteKEMOIA_uniform_one`
and `concreteKEMOIA_uniform_mono` for the uniform form.

**Deep-audit follow-up (2026-04-20, second pass).** The uniform form
was initially introduced without a companion reduction theorem, so
callers who wanted a genuinely ε-smooth KEM-security statement had no
reduction to cite. Added:

- `kemAdvantage_uniform kem A g_ref` — the per-reference uniform-form
  KEM advantage (advantage of the adversary's guess between
  `kemEncapsDist kem` and `PMF.pure (encaps kem g_ref)`), with
  `_nonneg` and `_le_one` sanity lemmas.
- `concrete_kemoia_uniform_implies_secure` — the genuinely ε-smooth
  KEM reduction: `ConcreteKEMOIA_uniform kem ε → ∀ A g_ref,
  kemAdvantage_uniform kem A g_ref ≤ ε`.

Now both forms (point-mass and uniform) have bridge-→-definition-→-
reduction triples, and downstream users can pick based on whether
they need the 0-or-1 point-mass discipline or a genuine ε spectrum.

### Finding E-A4 (low): E6 `combinerOrbitDist_mass_bounds` was over-claimed

**Location.** `Orbcrypt/PublicKey/CombineImpossibility.lean` theorem
`combinerOrbitDist_mass_bounds` and sibling
`concrete_combiner_advantage_bounded_by_oia`.

**Problem.** The landed docstring claimed that mass bounds on the
basepoint orbit (Pr[true] ≥ 1/|G| AND Pr[false] ≥ 1/|G|) combine with
the ConcreteOIA upper bound to refute `ConcreteOIA 0` under
`NonDegenerateCombiner`. The actual content is an *intra-orbit* bound
— it witnesses non-trivial variance on one orbit, not a cross-orbit
advantage lower bound. Two orbits could both have Pr[true] = 0.5 with
advantage 0.

**Fix.** Revised both docstrings to state the intra-orbit scope
honestly. The proof is unchanged; only the documentation was over-
claiming.

### Finding E-A5 (low): Orphan `OrbitPreservingEncoding`

**Location.** `Orbcrypt/Hardness/Encoding.lean`.

**Problem.** The structure was defined in E3-prep but no reduction
Prop consumed it. The landed docstring claimed "Each reduction carries
an OrbitPreservingEncoding as an explicit input" — false.

**Fix.** Revised the module docstring to clarify the structure is the
*reference interface* for a future per-encoding refactor (Workstream
F3/F4 will discharge the three reduction Props at specific encodings
via `OrbitPreservingEncoding` witnesses). Kept the structure itself
intact.

### Finding E-A6 (low): `audit_e_workstream.lean` was only axiom dumps

**Location.** `scripts/audit_e_workstream.lean`.

**Problem.** The preamble promised 10 "invariants including non-vacuity
checks" but the body only contained `#print axioms` lines.

**Fix.** Appended a Part 2 of ~15 concrete `example` bindings
exercising every Workstream-E result on a well-typed instance
(ConcreteKEMOIA at ε = 1 on an arbitrary kem, `uniformPMFTuple` on
`Fin 3 → Bool` giving mass 1/8, a 2-step hybrid giving a 2·ε bound,
`ConcreteHardnessChain.tight_one_exists` instantiated to produce
`ConcreteOIA scheme 1`, `identityEncoding.preserves` discharged,
etc.). Type-checking the script is now equivalent to confirming
each headline result is non-vacuous on at least one concrete instance.

## Verification

After applying the fixes, the following commands should all succeed
with exit code 0 and no error/warning output:

```bash
source ~/.elan/env
lake build                               # full build
lake env lean scripts/audit_e_workstream.lean   # E axioms + pressure tests
lake env lean scripts/audit_d_workstream.lean   # D regression
lake env lean scripts/audit_c_workstream.lean   # C regression
lake env lean scripts/audit_b_workstream.lean   # B regression
```

The `#print axioms` output for every Workstream-E headline result lists
only standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`)
or "does not depend on any axioms". No custom axiom, no `sorryAx`.

## Impact

- **Semantics:** the chain now genuinely threads tensor → code → graph →
  scheme hardness.
- **Public surface:** `ConcreteHardnessChain` signature simplified from
  `scheme F n G_TI ε` to `scheme F ε` (the per-pair tensor parameters
  are absorbed into the universal `tensor_hard` field).
- **Satisfiability:** `ConcreteHardnessChain.tight_one_exists` and
  the pressure tests in `audit_e_workstream.lean` confirm non-vacuity.
- **Honesty:** the `ConcreteKEMOIA` point-mass collapse and the
  `combinerOrbitDist_mass_bounds` intra-orbit scope are now disclosed
  in docstrings.

No new custom axioms, no `sorry`, no warnings. `lake build` exit 0
across 3364 jobs.
