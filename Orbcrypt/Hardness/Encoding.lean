import Mathlib.GroupTheory.GroupAction.Defs

/-!
# Orbcrypt.Hardness.Encoding

An orbit-preserving encoding interface for hardness reductions. Formalises
"object `x : α` is encoded as `encode x : β`, with the encoding preserving
the relevant orbit structure", which is the shared signature used by every
Karp-style reduction in the Orbcrypt hardness chain.

## Status (post-Workstream-G, 2026-04-21 audit)

**Relation to `Orbcrypt/Hardness/Reductions`.** Workstream G's Fix C
(audit F-AUDIT-2026-04-21-H1) landed per-encoding reduction Props
(`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
`ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
`ConcreteGIOIAImpliesConcreteOIA_viaEncoding`) that take **raw
function-valued encoders** (e.g. `enc : Tensor3 n F → Finset (Fin m →
F)`) rather than `OrbitPreservingEncoding` bundles. Three reasons:

* The advantage-transfer Prop is stated at the Prop level; the
  orbit-preservation + orbit-reflection fields of
  `OrbitPreservingEncoding` are needed at the *proof* level (inside any
  concrete ε < 1 discharge) but not at the Prop's type signature.
* The cross-layer encoders (tensors ↦ codes, codes ↦ adjacency
  matrices) have different natural MulAction structures on their
  targets. `Finset (Fin n → F)` does not carry a Mathlib-provided
  `MulAction (Equiv.Perm (Fin n))` instance (the natural action is
  `(σ, C) ↦ C.image (permuteCodeword σ)`, which would need to be
  registered separately). Packaging each reduction through
  `OrbitPreservingEncoding` would require first proving those
  MulAction instances.
* The per-encoding Props' primary cryptographic content is the
  *function* that callers supply; `OrbitPreservingEncoding` is the
  richer semantic bundle that a concrete discharge (CFI gadget,
  Grochow–Qiao structure tensor — see audit plan § 15.1) would use
  to *prove* the Prop holds for a specific encoder.

**Why keep this module.** It documents the Karp-reduction semantics
that any concrete discharge of the Workstream-G per-encoding Props
will *prove satisfies*. A concrete CFI or Grochow–Qiao witness would
typically:
1. Exhibit an `OrbitPreservingEncoding` between the source and target
   orbit spaces, with concrete `preserves` and `reflects` proofs.
2. Use its `encode` field as the raw encoder slot in the per-encoding
   Prop.
3. Discharge the Prop by appealing to the `preserves` / `reflects`
   fields plus a PMF-pushforward argument (see Mathlib's
   `PMF.map_comp`).

This module is a reference target for (1); the per-encoding Prop is
the consumer in (2); the concrete discharge is the research-scope
follow-up (3).

**Does not replace the per-encoding Props.** `OrbitPreservingEncoding`
is not a substitute for the per-encoding Props — it is the
*infrastructure* a concrete discharge uses. The Props in
`Reductions.lean` state the hardness claim in terms of the encoder's
`encode` field; `OrbitPreservingEncoding` provides the machinery for
proving such a claim.

## Main definitions

* `Orbcrypt.OrbitPreservingEncoding` — bundles an encoding function
  `encode : α → β` with two structural properties: it maps `A`-orbits
  to `B`-orbits (**preserves**) and reflects `B`-orbits back to
  `A`-orbits (**reflects**). A *many-one* Karp-style reduction.
  Consumed by concrete discharges of Workstream G's per-encoding
  reduction Props.

## Main results

* `Orbcrypt.identityEncoding` — the identity map `α → α` as a trivial
  `OrbitPreservingEncoding` when `A = B` and the action is shared.
  Satisfiability witness demonstrating the structure is inhabitable.

## References

* `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 3 — Workstream G
  Fix B + Fix C landing; § 15.1 — research-scope concrete encoder
  discharges (CFI gadget, Grochow–Qiao structure tensor).
* `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E3-prep —
  original Workstream E3-prep rationale for the interface.
* `docs/audits/AUDIT_2026-04-20_WORKSTREAM_E_REVIEW.md` — the
  post-Workstream-E review that clarified the scope of this module.
-/

namespace Orbcrypt

/--
An **orbit-preserving encoding** from `α` (with `A`-action) to `β` (with
`B`-action).

The encoding is required to both *preserve* orbit equivalence (equivalent
inputs go to equivalent outputs) and *reflect* it (equivalent outputs come
from equivalent inputs). Together this makes the encoding a *many-one*
reduction between the two equivalence problems.

This structure is the reference target for concrete discharges of
Workstream G's per-encoding reduction Props
(`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` etc. in
`Orbcrypt/Hardness/Reductions.lean`). Those Props consume the raw
`encode : α → β` function; the `preserves` and `reflects` fields
here provide the orbit-semantics infrastructure a concrete discharge
(CFI gadget, Grochow–Qiao structure tensor) uses to prove the Prop
holds at its claimed ε bounds.
-/
structure OrbitPreservingEncoding
    (α : Type*) (β : Type*)
    (A : Type*) (B : Type*) [Group A] [Group B]
    [MulAction A α] [MulAction B β] where
  /-- The forward encoding function. -/
  encode : α → β
  /-- **Preserves.** `A`-equivalent inputs map to `B`-equivalent outputs. -/
  preserves : ∀ x y : α, (∃ a : A, a • x = y) → (∃ b : B, b • encode x = encode y)
  /-- **Reflects.** `B`-equivalent encodings come from `A`-equivalent inputs. -/
  reflects : ∀ x y : α, (∃ b : B, b • encode x = encode y) → (∃ a : A, a • x = y)

/--
**Trivial satisfiability witness.** The identity encoding `α → α` under a
single shared group action is orbit-preserving.

Both `preserves` and `reflects` are immediate: the forward witness is the
same group element. This establishes that `OrbitPreservingEncoding` is
non-vacuous; concrete LESS/MEDS-style encodings between codes and tensors
(research-scope follow-ups — audit plan § 15.1) will discharge the
structure with more substantive proofs.
-/
def identityEncoding {α : Type*} {A : Type*} [Group A] [MulAction A α] :
    OrbitPreservingEncoding α α A A where
  encode := id
  preserves := fun _ _ h => h
  reflects := fun _ _ h => h

end Orbcrypt
