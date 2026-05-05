# Legacy per-workstream audit scripts

This directory contains historical audit scripts from prior Orbcrypt
audit cycles. Each script exercises a specific workstream's
`#print axioms` checks at the time the workstream landed.

**Status: archive only — not run by CI.**

The authoritative audit script is `scripts/audit_phase_16.lean` at
the parent directory. It supersedes every script in this directory
by exercising every public declaration in a single pass.

## File index

| Script | Workstream | Audit cycle | Status |
|--------|------------|-------------|--------|
| `audit_a7_defeq.lean` | Workstream A7 (defeq checks for `SchemeFamily.{repsAt,orbitDistAt,advantageAt}`) | 2026-04-18 | archived |
| `audit_b_workstream.lean` | Workstream B (adversary refinements F-02 + F-15) | 2026-04-18 | archived |
| `audit_c_workstream.lean` | Workstream C (MAC integrity F-07) | 2026-04-18 | archived |
| `audit_d_workstream.lean` | Workstream D (Code Equivalence API F-08 + F-16) | 2026-04-18 | archived |
| `audit_e_workstream.lean` | Workstream E (probabilistic chain F-01 + F-10 + F-11 + F-17 + F-20) | 2026-04-18 | archived |
| `audit_phase15.lean` | Phase 15 (decryption optimisation, theorems #24 / #25 / #26) | 2026-04-20 | archived |
| `audit_print_axioms.lean` | Pre-Phase-16 per-headline `#print axioms` baseline (Workstream A historical) | various | archived |

## Re-running for historical reference

If you need to re-run a legacy script (e.g., for archeological
audit-trail recovery), invoke from the repository root:

```bash
source ~/.elan/env
lake env lean scripts/legacy/<script-name>.lean
```

Note that the legacy scripts have not been re-validated against
the current Lean toolchain or Mathlib pin since the audit cycle
in which they originally landed. They may fail to elaborate
against the current pin; if so, this is *expected* archive
behaviour and not a regression. The authoritative current
sentinel is `scripts/audit_phase_16.lean`.

## Why not delete?

These scripts preserve the per-workstream audit trail. Each was
the canonical regression sentinel for its workstream at the time
it landed; deleting them would lose that historical
cross-reference. The post-2026-04-29 plan (Workstream **B2** of
`docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`)
moved them to this archive directory rather than deleting them, on
the principle that archive material is cheap to retain and
expensive to reconstruct.

## Authoritative current sentinel

`scripts/audit_phase_16.lean` is the current regression sentinel.
It is run by every CI invocation and is the document-of-record for
the running posture (zero `sorry`, zero custom axioms, standard-
trio-only axiom dependencies — `propext`, `Classical.choice`,
`Quot.sound`).

Running totals (declarations exercised, non-vacuity `example`
bindings, total LOC) are not pinned in this README to avoid
per-workstream staleness; the current values are tracked in
`CLAUDE.md`'s most recent per-workstream changelog entry and in
the `README.md` Snapshot metrics table.
