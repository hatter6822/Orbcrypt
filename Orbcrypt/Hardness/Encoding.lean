import Mathlib.GroupTheory.GroupAction.Defs

/-!
# Orbcrypt.Hardness.Encoding

An orbit-preserving encoding interface for hardness reductions. Formalises
"object `x : α` is encoded as `encode x : β`, with the encoding preserving
the relevant orbit structure", which is the shared signature used by every
Karp-style reduction in the Orbcrypt hardness chain.

## Workstream E3-prep

This module is the shared prelude for the three probabilistic reductions
`ConcreteTensorOIAImpliesConcreteCEOIA`, `ConcreteCEOIAImpliesConcreteGIOIA`,
and `ConcreteGIOIAImpliesConcreteOIA`. Without this abstraction each
reduction reinvents the encoding signature; by centralising it here the
reductions share a common surface and the proof obligations are stated
uniformly.

## Main definitions

* `Orbcrypt.OrbitPreservingEncoding` — bundles an encoding function
  `encode : α → β` with two structural properties: it maps `A`-orbits
  to `B`-orbits (**preserves**) and reflects `B`-orbits back to
  `A`-orbits (**reflects**). A *many-one* Karp-style reduction.

## Main results

* `Orbcrypt.identityEncoding` — the identity map `α → α` as a trivial
  `OrbitPreservingEncoding` when `A = B` and the action is shared.
  Satisfiability witness.

## References

* `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E3-prep
-/

namespace Orbcrypt

/--
An **orbit-preserving encoding** from `α` (with `A`-action) to `β` (with
`B`-action).

The encoding is required to both *preserve* orbit equivalence (equivalent
inputs go to equivalent outputs) and *reflect* it (equivalent outputs come
from equivalent inputs). Together this makes the encoding a *many-one*
reduction between the two equivalence problems.

This structure is used by Workstream E3 to state the three probabilistic
reductions `ConcreteTensorOIA → ConcreteCEOIA`, `ConcreteCEOIA →
ConcreteGIOIA`, `ConcreteGIOIA → ConcreteOIA` uniformly. Each reduction
carries an `OrbitPreservingEncoding` as an explicit input.
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
(Workstream F3/F4) will discharge the structure with more substantive
proofs.
-/
def identityEncoding {α : Type*} {A : Type*} [Group A] [MulAction A α] :
    OrbitPreservingEncoding α α A A where
  encode := id
  preserves := fun _ _ h => h
  reflects := fun _ _ h => h

end Orbcrypt
