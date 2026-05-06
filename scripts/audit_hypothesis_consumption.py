#!/usr/bin/env python3
#
# Orbcrypt  - Symmetry Keyed Encryption
# Copyright (C) 2026  Adam Hall
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
#
"""
audit_hypothesis_consumption.py — pre-merge gate for the "theatrical
theorem" pattern.

A "theatrical theorem" is one whose proof body never references a
non-underscored hypothesis name in the parameter list. The pattern has
recurred across post-landing audits — R-TI Phase 3 v1, Workstream I v1,
the Stage-3/Stage-5 identity-case witnesses, and the audit-2 cleanup
of the post-Path-B Discharge.lean — and each recurrence has been caught
only by a deep-audit pass *after* landing. This gate catches the
regression pre-merge.

Strategy: regex-parse Lean theorem/lemma declarations under `Orbcrypt/`,
extract their parameter lists, and check whether each non-underscored
hypothesis name appears as a token in the proof body. Tactics that
consume hypotheses by type (`omega`, `simp`, `simp_all`, `assumption`,
`aesop`, `decide`, `linarith`, etc.) short-circuit the check (treat the
body as covering all hypotheses).

Allow-list: theorems whose hypothesis is intentionally a release-facing
*signature marker* — its presence is the API content even if the proof
does not consume it. Underscored names (`_h_foo`) are exempt by
convention (Lean's "intentionally unused" prefix).

Output: list of `<file>:<line>: theorem '<name>': hypothesis '<hyp>'
not consumed` violations. Exit code 1 on any finding.

Usage:
    python3 scripts/audit_hypothesis_consumption.py

This is a Workstream-2 deliverable of the 2026-05-06 structural review;
see `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 2.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ORBCRYPT = ROOT / "Orbcrypt"

# Tactics that consume hypotheses by type (not by name). When any of these
# appears in the proof body, we cannot reliably detect unused hypotheses
# and short-circuit the per-theorem check (treat all hypotheses as
# consumed). The list is conservative — adding a tactic only weakens
# detection on theorems that already use it; missing one only causes
# false positives that the allow-list can handle.
HYPOTHESIS_CONSUMING_TACTICS = frozenset({
    # Arithmetic decision procedures — close goals using all in-context
    # numeric hypotheses without referencing them by name.
    "omega", "linarith", "nlinarith", "polyrith",
    # Simp family — consumes any hypothesis tagged `[simp]` and uses
    # local hypotheses in `simp_all` mode.
    "simp", "simp_all", "simp_arith", "simp_rw", "simpa",
    # Decidability decision procedures.
    "decide", "decide!",
    # Hypothesis lookups by type.
    "assumption",
    # Automation closing tactics — use any hypothesis they need.
    "aesop", "tauto",
    # Algebraic normalization — close goals from hypotheses by
    # rewriting / cancellation.
    "field_simp", "ring", "ring_nf", "noncomm_ring", "abel", "abel_nf",
    # Hint / search tactics.
    "exact?", "apply?", "hint", "search_proof",
    # Case splits that materialize / consume implicit goals.
    "fin_cases", "interval_cases",
    # Linear combination tactic.
    "linear_combination",
    # NOTE: `rfl`, `trivial`, and `match_target` are NOT in the list.
    # `rfl` is pure reflexivity (doesn't consume hypotheses); a proof
    # body of just `rfl` with an unused hypothesis IS theatrical and
    # should be flagged. `trivial` is similar (it's `rfl ; assumption`
    # in older Lean, but in Lean 4's Mathlib it's mostly `rfl`-like).
})

# Allow-list: (file_suffix, theorem_name) pairs whose unused hypothesis
# is a deliberate release-facing signature marker. Each entry must be
# justified inline. The list starts empty; entries land only when a
# review establishes the hypothesis is API-essential despite being
# unconsumed.
ALLOW_LIST: set[tuple[str, str]] = {
    # K4 companion (audit 2026-04-21 finding M1, Workstream K4 of
    # `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md`): the
    # `_hDistinct` hypothesis is a release-facing signature marker —
    # it pins the theorem to the classical IND-1-CPA distinct-challenge
    # game shape. The bound holds for every adversary (collision or
    # not) per `indCPAAdvantage_collision_zero`, so `_hDistinct` is
    # not consumed in the proof. Already underscored, so this entry is
    # defensive (the gate's underscore exemption already covers it).
    ("Hardness/Reductions.lean",
     "concrete_hardness_chain_implies_1cpa_advantage_bound_distinct"),
}


def strip_comments(src: str) -> str:
    """Remove Lean block comments (recursively nested `/- ... -/`,
    `/-! ... -/`, `/-- ... -/`) and line comments (`-- ...`), preserving
    line numbers by replacing each removed character with a space.
    Strings (`"..."`) are preserved verbatim."""
    out: list[str] = []
    n = len(src)
    i = 0
    block_depth = 0
    in_line_comment = False
    in_string = False
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if in_string:
            out.append(c)
            if c == '"' and (i == 0 or src[i - 1] != "\\"):
                in_string = False
            i += 1
            continue
        if in_line_comment:
            if c == "\n":
                in_line_comment = False
                out.append("\n")
            else:
                out.append(" ")
            i += 1
            continue
        if block_depth > 0:
            if c == "/" and nxt == "-":
                block_depth += 1
                out.append("  ")
                i += 2
                continue
            if c == "-" and nxt == "/":
                block_depth -= 1
                out.append("  ")
                i += 2
                continue
            out.append(" " if c != "\n" else "\n")
            i += 1
            continue
        # Top-level (not in any comment / string).
        if c == "/" and nxt == "-":
            block_depth = 1
            out.append("  ")
            i += 2
            continue
        if c == "-" and nxt == "-":
            in_line_comment = True
            out.append("  ")
            i += 2
            continue
        if c == '"':
            in_string = True
        out.append(c)
        i += 1
    return "".join(out)


# Top-level keywords that begin a new declaration. When found at the
# start of a line, they end the previous declaration's text region.
TOPLEVEL_RE = re.compile(
    r"^(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|noncomputable\s+|"
    r"partial\s+|unsafe\s+)*"
    r"(?:theorem|lemma|def|abbrev|structure|class|instance|axiom|"
    r"inductive|opaque|example|namespace|end|section|import|open|"
    r"variable|set_option|attribute|deriving|export|notation|"
    r"infix|infixl|infixr|prefix|postfix|macro|elab|syntax)\b",
    re.MULTILINE,
)

# A theorem/lemma declaration start. Captures keyword + name.
DECL_START_RE = re.compile(
    r"^(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|noncomputable\s+|"
    r"partial\s+|unsafe\s+)*"
    r"(theorem|lemma)\s+([A-Za-z_][A-Za-z_0-9.\']*)",
    re.MULTILINE,
)

# Identifier pattern for hypothesis names.
IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z_0-9\']*$")


def find_decl_block_end(src: str, decl_start: int) -> int:
    """Return the offset where the declaration starting at `decl_start`
    ends (i.e., the start of the next top-level declaration, or end of
    file)."""
    m = TOPLEVEL_RE.search(src, pos=decl_start + 1)
    return m.start() if m else len(src)


def split_decl_into_parts(
    decl_block: str, name_end: int
) -> tuple[str, str, str] | None:
    """Split a declaration block into `(binders, conclusion, body)`.

    `decl_block` starts at the keyword (`theorem`/`lemma`); `name_end`
    is the offset just past the declaration name. We scan from
    `name_end` for the *first* depth-zero `:` (introduces the
    conclusion type) and the *first* depth-zero `:=` (introduces the
    proof body). Returns `None` if either separator is absent.

    Edge case: a binder like `(h : ∀ x : T, P x)` contains an inner
    `:` at depth 1 (inside the paren). Our depth-tracking handles this
    correctly — we only flag the depth-zero `:`."""
    depth_paren = 0
    depth_brack = 0
    depth_brace = 0
    in_string = False
    binder_end = -1
    body_start = -1
    i = name_end
    n = len(decl_block)
    while i < n:
        c = decl_block[i]
        nxt = decl_block[i + 1] if i + 1 < n else ""
        if in_string:
            if c == '"' and (i == 0 or decl_block[i - 1] != "\\"):
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c == "(":
            depth_paren += 1
        elif c == ")":
            depth_paren -= 1
        elif c == "[":
            depth_brack += 1
        elif c == "]":
            depth_brack -= 1
        elif c == "{":
            depth_brace += 1
        elif c == "}":
            depth_brace -= 1
        elif (
            depth_paren == 0
            and depth_brack == 0
            and depth_brace == 0
        ):
            if c == ":" and nxt == "=":
                body_start = i + 2
                break
            if binder_end < 0 and c == ":" and nxt != "=":
                binder_end = i
        i += 1
    if body_start < 0:
        return None
    if binder_end < 0:
        # Theorem with no binders — the `:` immediately follows the name.
        # Find the first depth-zero `:` (which will be the same as
        # body_start - 2 minus 0 — but we know `body_start - 2` is `:=`,
        # so the first `:` was at body_start - 2 which we already
        # processed). In this case there are no binders to walk.
        binder_end = name_end
    return (
        decl_block[name_end:binder_end],
        decl_block[binder_end + 1: body_start - 2],
        decl_block[body_start:],
    )


def extract_explicit_binders(signature: str) -> list[tuple[str, int]]:
    """Extract names of explicit-binder hypotheses from a declaration's
    signature. An explicit binder is a top-level `(name1 name2 : Type)`
    paren group with a `:` separator. Implicit `{...}`, instance `[...]`,
    and strict-implicit `⦃...⦄` binders are not hypotheses for the
    purposes of this gate.

    Returns a list of `(name, after_binder_offset)` pairs, where
    `after_binder_offset` is the offset *just past* the closing paren of
    the binder that bound `name`. The check then verifies that `name`
    appears in `signature[after_binder_offset:] + body`, which captures
    use in either the conclusion type or the proof body."""
    names: list[tuple[str, int]] = []
    depth_paren = 0
    depth_brack = 0
    depth_brace = 0
    in_string = False
    paren_start = -1
    i = 0
    n = len(signature)
    while i < n:
        c = signature[i]
        if in_string:
            if c == '"' and (i == 0 or signature[i - 1] != "\\"):
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c == "(":
            if depth_paren == 0 and depth_brack == 0 and depth_brace == 0:
                paren_start = i
            depth_paren += 1
        elif c == ")":
            depth_paren -= 1
            if (
                depth_paren == 0
                and depth_brack == 0
                and depth_brace == 0
                and paren_start >= 0
            ):
                binder = signature[paren_start + 1: i]
                # Find the top-level `:` separator inside this binder.
                inner_p = inner_b = inner_c = 0
                colon_pos = -1
                for j, cc in enumerate(binder):
                    if cc == "(":
                        inner_p += 1
                    elif cc == ")":
                        inner_p -= 1
                    elif cc == "[":
                        inner_b += 1
                    elif cc == "]":
                        inner_b -= 1
                    elif cc == "{":
                        inner_c += 1
                    elif cc == "}":
                        inner_c -= 1
                    elif (
                        inner_p == 0
                        and inner_b == 0
                        and inner_c == 0
                        and cc == ":"
                    ):
                        # Reject `:=` — that signals a let-style binding
                        # rather than a type ascription.
                        if j + 1 < len(binder) and binder[j + 1] == "=":
                            colon_pos = -1
                            break
                        colon_pos = j
                        break
                after_binder = i + 1
                if colon_pos > 0:
                    names_part = binder[:colon_pos].strip()
                    for tok in names_part.split():
                        if IDENT_RE.match(tok):
                            names.append((tok, after_binder))
                paren_start = -1
        elif c == "[":
            depth_brack += 1
        elif c == "]":
            depth_brack -= 1
        elif c == "{":
            depth_brace += 1
        elif c == "}":
            depth_brace -= 1
        i += 1
    return names


def body_uses_consuming_tactic(body: str) -> bool:
    """Return `True` iff the proof body contains any token that is in
    `HYPOTHESIS_CONSUMING_TACTICS`."""
    # Find every identifier-like token; check membership.
    for tok in re.finditer(r"\b[a-zA-Z_][a-zA-Z_0-9!?]*\b", body):
        if tok.group(0) in HYPOTHESIS_CONSUMING_TACTICS:
            return True
    return False


def hypothesis_appears_in_body(name: str, body: str) -> bool:
    """Return `True` iff `name` appears as a standalone token in `body`.

    Uses negative lookbehind/lookahead instead of `\\b` because Lean
    identifiers can contain `'` (e.g., `u'`, `v'`, `e'`), which
    Python's `\\b` treats as a word boundary and would split into
    `u` + `'`. The custom boundary treats `[A-Za-z_0-9']` as
    word-equivalent."""
    pattern = (
        r"(?<![A-Za-z_0-9\'])"
        + re.escape(name)
        + r"(?![A-Za-z_0-9\'])"
    )
    return bool(re.search(pattern, body))


def line_of_offset(raw_src: str, offset: int) -> int:
    """Convert a character offset into a 1-indexed line number in the
    original source (before comment-stripping)."""
    return raw_src.count("\n", 0, offset) + 1


def audit_file(path: Path) -> list[tuple[int, str, str]]:
    """Audit one `.lean` file. Returns a list of `(line, theorem_name,
    hypothesis_name)` violations."""
    raw = path.read_text(encoding="utf-8", errors="replace")
    src = strip_comments(raw)
    rel = path.relative_to(ROOT)
    findings: list[tuple[int, str, str]] = []
    for m in DECL_START_RE.finditer(src):
        thm_name = m.group(2)
        decl_start = m.start()
        name_end_global = m.end()
        decl_end = find_decl_block_end(src, decl_start)
        decl_block = src[decl_start:decl_end]
        name_end_local = name_end_global - decl_start
        split = split_decl_into_parts(decl_block, name_end_local)
        if split is None:
            continue
        binders_text, conclusion, body = split
        if body_uses_consuming_tactic(body):
            continue
        binders = extract_explicit_binders(binders_text)
        # `extract_explicit_binders` returns offsets into `binders_text`.
        # Convert each to an offset just past its closing paren in
        # `decl_block`, then check `decl_block[that_offset:]` for the
        # name. This covers consumption via subsequent binders' types,
        # the conclusion type, and the proof body uniformly.
        binders_text_offset_in_decl = name_end_local
        for name, after_binder_in_text in binders:
            if name.startswith("_"):
                continue
            allow_match = any(
                str(rel).endswith(suffix) and thm_name == allow_name
                for suffix, allow_name in ALLOW_LIST
            )
            if allow_match:
                continue
            after_in_decl = binders_text_offset_in_decl + after_binder_in_text
            search_text = decl_block[after_in_decl:]
            if not hypothesis_appears_in_body(name, search_text):
                line = line_of_offset(raw, decl_start)
                findings.append((line, thm_name, name))
    return findings


def main() -> int:
    if not ORBCRYPT.is_dir():
        print(
            f"error: Orbcrypt source directory not found at {ORBCRYPT}",
            file=sys.stderr,
        )
        return 2
    files = sorted(ORBCRYPT.rglob("*.lean"))
    total = 0
    for f in files:
        for line, thm, hyp in audit_file(f):
            rel = f.relative_to(ROOT)
            print(
                f"{rel}:{line}: theorem '{thm}': "
                f"hypothesis '{hyp}' not consumed in proof body"
            )
            total += 1
    if total:
        print(
            f"\nFAIL: {total} theatrical-theorem violation(s) found "
            f"across {len(files)} files.",
            file=sys.stderr,
        )
        print(
            "Either consume the hypothesis in the proof, prefix it "
            "with '_' to mark it intentionally unused, or add it to "
            "ALLOW_LIST in scripts/audit_hypothesis_consumption.py "
            "with an inline justification.",
            file=sys.stderr,
        )
        return 1
    print(f"OK: {len(files)} files audited; zero violations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
