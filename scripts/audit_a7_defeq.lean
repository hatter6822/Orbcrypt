/-
Ephemeral A7 audit script: verify that `SchemeFamily.{repsAt,orbitDistAt,
advantageAt}` are definitionally equal to the pre-refactor `@`-threaded
forms. If the `rfl` lemmas below elaborate, the helper rewrite did not
break definitional equality and Workstream A7 is sound.

Run: `source ~/.elan/env && lake env lean scripts/audit_a7_defeq.lean`
-/

import Orbcrypt

open Orbcrypt

universe u v w

section A7Defeq

variable (sf : SchemeFamily) (n : ℕ)

/-- `repsAt` reduces to the fully-explicit `@`-threaded form. -/
example (m : sf.M n) :
    sf.repsAt n m =
      @OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
        (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m := rfl

/-- `orbitDistAt` reduces to `orbitDist` of `repsAt` with all instances. -/
example (m : sf.M n) :
    sf.orbitDistAt n m =
      @orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
        (sf.instNonempty n) (sf.instAction n)
        (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
          (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m) := rfl

/-- `advantageAt` reduces to pointwise `advantage` between two orbit
    distributions. -/
example (D : ∀ n, sf.X n → Bool) (m₀ m₁ : ∀ n, sf.M n) :
    sf.advantageAt D m₀ m₁ n =
      @advantage (sf.X n) (D n)
        (sf.orbitDistAt n (m₀ n)) (sf.orbitDistAt n (m₁ n)) := rfl

end A7Defeq
