# Reading log — Grochow & Qiao 2021 (R-TI Layer T0.4)

**Status.** Paper synthesis deliverable for Workstream R-TI Layer T0
(audit plan § "Decision GQ-D"). Bibliography + per-section paper
citation cross-reference for the Grochow–Qiao reduction.

## 1. Primary references

* **Grochow, J. A. & Qiao, Y.** (2019). *Algorithms for Tensor
  Isomorphism with Applications to Cryptography.* arXiv:1907.00309
  (preprint), full version in *SIAM Journal on Computing* 52(3),
  pp. 568–617 (2023). DOI: 10.1137/22M1481443.
  - Sections cited:
    - §1 — Introduction; states the GI ≤ TI reduction as Theorem 1.1.
    - §3 — Tensor isomorphism background; `Tensor3`, GL³ action,
      isomorphism class.
    - §4 — Path-algebra reduction; **Theorem 4.4** is the GI ≤ TI
      headline result this workstream formalises.
    - §4.1 — Quiver / path-algebra construction; Decision GQ-A
      sources the radical-2 truncation here.
    - §4.2 — Distinguished padding strategy; Decision GQ-B sources
      the `m + m²` dimension here.
    - §4.3 — Rigidity argument; Decision GQ-D's Layer T0.3 sketch
      (`grochow_qiao_padding_rigidity.md`) follows the argument
      structure here.
    - §5 — Open problems; the asymmetric `(P, Q, R) • T = T'` case
      (T5.6 stretch goal) is mentioned here.

* **Auslander, M., Reiten, I., Smalø, S. O.** (1995).
  *Representation Theory of Artin Algebras.* Cambridge University
  Press, Cambridge Studies in Advanced Mathematics 36.
  - Sections cited:
    - §III.2 — Primitive idempotents in artinian algebras; underlies
      Layer T1.6 (vertex-idempotent uniqueness).
    - §I.5 — Path algebras; the `F[Q]` definition Decision GQ-A uses.

* **Babai, L.** (2015). *Graph Isomorphism in Quasipolynomial Time*.
  arXiv:1512.03547. Background reference for the `2^O(√(n log n))`
  GI bound; not directly cited in the reduction proofs, but
  contextualises why GI is "easy" and TI is "hard" in the Orbcrypt
  hardness chain.

## 2. Secondary references

* **Lascoux, A. & Schützenberger, M.-P.** (1981). *Le monoïde
  plaxique.* Quaderni della Ricerca Scientifica 109, CNR, Rome.
  Tangentially relevant for path-algebra basis enumeration; not
  directly cited.

* **Pierce, R. S.** (1982). *Associative Algebras*. Springer GTM 88.
  Background on artinian algebras / Wedderburn decomposition;
  Decision GQ-C's rejection of `ZMod 2` is informed by this
  reference's treatment of similar matrices over finite fields
  (Smith normal form / elementary divisor invariants). Pierce §13
  covers the conjugacy-class structure relevant to the rigidity
  argument's field-choice constraint.

## 3. Per-decision cross-reference

| Decision | Justification | Paper section |
|----------|---------------|---------------|
| **GQ-A** (encoder = `F[Q_G] / J²`) | Cospectral graphs have isomorphic `F[A_G]` but non-isomorphic `Aut(G)`; path algebras avoid this defect | Grochow–Qiao §4.1 (radical-2 truncation), Auslander–Reiten–Smalø §III.2 (vertex idempotents) |
| **GQ-B** (dimension `m + m * m` w/ distinguished padding) | Variable dim or zero-padding is rigidity-degenerate; ambient-Mat padding forces partition preservation | Grochow–Qiao §4.2 (padding strategy, Lemma 4.2 in arXiv version) |
| **GQ-C** (field `F := ℚ`) | Smith normal form over finite fields breaks similarity-conjugacy; characteristic-0 makes rigidity straight-line | Pierce §13 (similar-vs-conjugate over fields), Grochow–Qiao §4.3 (rigidity proof outline assumes char 0) |
| **GQ-D** (Layer T0 paper synthesis) | Audit-plan defensive measure; converts "1–2 week pre-implementation review" caveat into a budgeted activity | Audit plan § "R-TI strengthened design", Decision GQ-D |

## 4. Per-layer cross-reference

| Layer | Plan sub-tasks | Paper section | Notes |
|-------|----------------|---------------|-------|
| T0 | T0.1–T0.4 | (this document) | Paper synthesis |
| T1 | T1.1–T1.8 | Grochow–Qiao §4.1, ARS §I.5 | Path algebra `F[Q_G] / J²` construction |
| T2 | T2.1–T2.7 | Grochow–Qiao §4.2 | Structure tensor + distinguished padding |
| T3 | T3.1–T3.8 | Grochow–Qiao §4 (forward direction) | σ → GL³ triple via vertex-idempotent permutation |
| T4 | T4.1–T4.8 | Grochow–Qiao §4.3, Pierce §13 | Linear-algebra prerequisites |
| T5 | T5.1–T5.5 (T5.6–T5.8 stretch) | Grochow–Qiao §4.3, Lemma 4.5 | Rigidity (reverse direction) |
| T6 | T6.1–T6.4 | Grochow–Qiao Theorem 4.4 | Iff assembly + Karp-reduction inhabitant |

## 5. Open questions (research-scope follow-ups)

* **Polynomial-time complexity bounds** for the Grochow–Qiao
  encoder. The plan does not require this; the Karp reduction iff
  alone closes R-15 for the Grochow–Qiao route. Tracked as
  R-15-poly in audit plan § "What this plan does NOT cover".
* **Characteristic-positive generalisation.** Decision GQ-C fixes
  `F := ℚ` for tractability; T5.8 (stretch) generalises to arbitrary
  characteristic-zero fields. Generalisation to finite fields
  (`ZMod p` for any prime `p`) requires Smith-normal-form arguments
  that are explicitly out of scope for v1.0 (Pierce §13 / Wedderburn
  decomposition; tracked as research-scope).
* **Asymmetric GL³ rigidity** (T5.6 stretch). Grochow–Qiao §5 (Open
  problems) discusses extending the rigidity from `(P, P, P) • T`
  to `(P, Q, R) • T` for general `(P, Q, R) ∈ GL³`. The symmetric
  case suffices for graphs (the path algebra is unitary); the
  asymmetric case matches the *full* result Grochow–Qiao prove for
  the abstract TI problem on tensors that may not arise from
  unitary algebras.
* **CFI graph gadget integration.** A CFI-based hardness amplification
  feeding into Petrank–Roth (R-CE) → Grochow–Qiao (R-TI) → ConcreteOIA
  would complete the substantive ε < 1 chain. Tracked as research-
  scope outside this audit plan.

## 6. Self-audit

**Citation completeness.** Every Decision GQ-A through GQ-D has at
least one paper-section citation in the cross-reference table above.
✅

**Layer-paper traceability.** Every Layer T1–T6 sub-task has a
paper section it implements. ✅

**Open-question disclosure.** Research-scope items not covered by
this workstream are explicitly enumerated in Section 5. ✅

**Reading log exit criterion met.** Every R-TI design choice cites a
specific paper section as justification. T0.4 deliverable complete.
