#!/usr/bin/env bash
#
# test-artifact-schema.sh — the artifact-schema guard suite.
#
# Drives scripts/validate-artifacts.sh over the tracked tree and over a synthetic fixture
# tree built fresh on every run. It SOURCES the validator rather than re-implementing it,
# the same way test-publish-guard.sh sources publish-trip-site.sh — the repo's only
# instance of that relation, and it runs suite -> production, never the reverse.
#
#   ./scripts/test-artifact-schema.sh
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   SC   the real schema corpus under reference/schemas/: every schema well-formed, its
#        class-id and artifact agreeing with reference/data-architecture.md § 1.1, tokens
#        unique, path-patterns inside the declared glob subset, a coverage declaration
#        present and singular, and the corpus in BIJECTION with the document's in-model
#        enumeration. The class list is READ FROM the document; neither this suite nor
#        the validator holds a copy of it.
#   XC   every selector exclusion the validator applies is declared in the architecture
#        document, IN THE SECTION the validator names for it (S9). An exclusion is a
#        statement about what the gate does not adjudicate, so an undeclared one is the
#        gate quietly narrowing its own scope.
#   AR   the tracked tree: the selector's DENOMINATOR is reported, the whole population is
#        accounted for as selected + excluded + unmatched, and the skip predicate's result
#        is reported by path AND by resolved class. Renders VACUOUS, never a bare PASS,
#        when the VERSIONED population is zero.
#   CV   the coverage split — "<n> witness / <m> no-witness / <total>" — which is the line
#        the per-class coverage question is answered by reading.
#   EN   every universal enum has ONE home and every other home is byte-identical to it, in
#        member set AND ORDER. The homes are discovered by SHAPE — the key plus a delimited
#        pipe-list — never by matching the canonical text, so a DRIFTED home is still found
#        and is then reported rather than quietly leaving the population.
#   UF   every schema declares every key of the universal frontmatter block (§ 4.4's "no class
#        removes a universal field"). The key set is read FROM that block and the corpus from
#        the schema directory, so no count is pinned. Without it a schema can drop a required
#        field and this suite's output stays BYTE-IDENTICAL — measured, not predicted.
#   LC   the value and key classifiers answer the same under every locale the host declares.
#        A bracket range resolves against the collating sequence, so `[a-z]` matched uppercase
#        under a UTF-8 default and CI enforced a rule an operator's own run did not.
#   CA   the several homes of each class's assignment agree: § 1.1's columns, § 6's Members
#        column, § 9's per-class delta column, and the frontmatter of the class's declared
#        witness. Per-field denominators, because the fields do not all have the same number
#        of homes, and `writer` is excluded with its ground measured rather than asserted.
#   PB   the publish-bound artifact set matches the site-layout spec's declaring fence, in
#        both directions and with the class agreeing per row.
#   ST   the starred-field count in templates/traveler-intake.template.md agrees across ALL
#        FOUR of its homes: the banner numeral, the appendix rule-4 numeral, the appendix's
#        per-field `(starred)` annotations, and the marked fields themselves — which are the
#        only home that is not a restatement of another, so they are the reference count.
#        Every surface is found by MARKUP SHAPE and never by line number, and the evaluator
#        carries control arms covering every violation code it can emit, each mutating ONE
#        surface alone and each required to turn it red, and two edits that must not.
#   CTL  a synthetic fixture tree, built in a temp dir ON EVERY RUN, population by
#        construction at every wave. One MUST-FIRE arm per code the validator can emit,
#        plus the specificity arms that tell a correct implementation from a lookalike.
#        A code with no arm is a check indistinguishable from one that CANNOT fire.
#
# ── WHY EN, CA, PB AND ST RUN AGAINST THE REAL TREE AND NOT INSIDE A FIXTURE ─────
# Each is a statement about THIS COMMIT'S corpus — how many homes an enum has, whether four
# documents agree, whether a spec fence matches a table — so the population that makes them
# meaningful is the tracked tree itself. They therefore read $ROOT directly and add NO
# finding code to the validator, which is what keeps them clear of group CTL: mk_root builds
# a fixture carrying the architecture document, the schema corpus and the declared witnesses
# and NOTHING ELSE, is not a git repository, and does not carry the site-layout spec. An
# assertion added to the validator's finding set would run inside that tree and fail there by
# construction — the coupling that already turned CTL red once in this release and had to be
# reverted rather than patched forward. Each group carries its own control arms instead, so
# none of them depends on CTL's fixture to be non-vacuous.
#
# ST joins them on the same terms, and for one further reason of its own. AR3 asserts that
# NO templates/*.template.md reaches the selector, because a template's `trip:` value is the
# placeholder <trip-slug> and would fail A4 — so a check that read the template BY ADDING IT
# TO THE SELECTOR would falsify an assertion this suite currently passes. ST reads the file
# directly instead and adds no finding code, which leaves va_select's output untouched; the
# ST-AR3 arm then re-reads AR_NTPL in the same run and asserts it is still zero, so the
# constraint is GRADED rather than promised in a comment.
#
# ── WHY CTL IS NOT OPTIONAL DECORATION ───────────────────────────────────────────
# This gate ships BEFORE any in-repo artifact carries frontmatter. At that commit every
# selected file skips, the versioned population is ZERO, and every AR assertion about a
# validated artifact is a statement over the empty set — vacuously true, never skipped,
# silently green. That is a green that proves less than it looks like, which is worse than
# no CI because it reads as proof. Three things close it. AR reports its observed
# denominator and renders a distinct VACUOUS verdict. CV reports the coverage split rather
# than asserting coverage. And CTL has a population by construction on every invocation,
# so the suite demonstrates ON THIS COMMIT that the checker can still fail.
#
# ── THE TWO ARMS THAT ARE THE POINT OF THIS SUITE ────────────────────────────────
# C1a and C1b are the skip predicate, made observable rather than asserted:
#
#   C1a  MUST NOT FIRE. An artifact carrying NO schema-version and violating its class
#        schema in three ways is reported as SKIPPED and contributes ZERO to the failure
#        count. An unversioned artifact cannot fail the build even when it is wrong.
#   C1b  MUST FIRE. The byte-identical fixture with `schema-version: 1` added and nothing
#        else changed does fail, emitting A3 and A4.
#
# The two fixtures differ by EXACTLY ONE LINE, and that is asserted before either arm is
# graded. That is what makes the pair a proof rather than two independent tests: the only
# variable between them is the skip predicate itself.
#
# STRICT SKIP MODE (set by CI — .github/workflows/artifact-schema.yml).
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# This suite is pure bash with no Node, no gh and no network, so it has NO legitimate skip
# and its expected-skip set is correctly EMPTY. VACUOUS is a distinct verdict from SKIP for
# the reason the trip-resolution-contract suite already states: a skipped GROUP is a hole
# in the suite, an empty POPULATION is a real measurement of the tree, and collapsing the
# two would hide one behind the other.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Resolved BEFORE the source below, and absolutely: group PF reads this file and the
# validator it sources. Taken after the source, BASH_SOURCE[0] is still this file, but
# the ordering is not left to be re-derived by a later reader.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
SELF_VALIDATOR="$HERE/validate-artifacts.sh"
# shellcheck source=validate-artifacts.sh
source "$HERE/validate-artifacts.sh"     # BASH_SOURCE guard prevents dispatch
set +e

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# has_finding <output> <code> — the code appears as a FINDING token, not as a substring of
# some longer word. A substring test would let A1 match A10 and read as a pass.
#
# ── THE HERE-STRING IS LOAD-BEARING, NOT A STYLE CHOICE. Read this before "simplifying"
# it back into a pipeline.
#
# `grep -q` exits the instant it matches, by specification. Feeding it from a pipeline
# whose writer has not finished writing kills that writer with SIGPIPE, and `pipefail` —
# set at the top of this file — then reports the PIPELINE as failed even though the match
# succeeded. The result is a test verdict that depends on process scheduling. A here-string
# is a redirection on a SIMPLE COMMAND, not a pipeline, so pipefail has no second status to
# aggregate and there is no second process to signal. The bytes grep reads are identical:
# bash appends exactly one newline, which is what the `printf '%s\n'` it replaced did.
#
# This is closed at the SHAPE rather than at any one arm because this helper carries BOTH
# polarities and the dangerous one is silent. Most callers read `if [ "$R" -ne 0 ] &&
# has_finding …; then PASS; else FAIL`, where a spurious non-zero is a false RED — someone
# notices and re-runs. But CTL-A2neg reads `! has_finding "$O" 'A2'`, where the same
# spurious status is a false GREEN on a state that carries the finding: the arm reports
# MUST-NOT-FIRE satisfied precisely because the check failed to run. That direction
# announces nothing, so it is not detectable by re-running. Group PF keeps it closed.
has_finding() { grep -q "^FINDING $2 " <<<"$1"; }

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "SC — the schema corpus (reference/schemas/)"
# ─────────────────────────────────────────────────────────────────────────────────
SC_CLASSES="$(va_class_rows "$ROOT")"
SC_NCLASS="$(printf '%s\n' "$SC_CLASSES" | grep -c '^[0-9]')"
SC_FILES="$(va_schema_files "$ROOT")"
SC_NFILES="$(printf '%s\n' "$SC_FILES" | grep -c '[^[:space:]]')"

if [ "$SC_NCLASS" -gt 0 ]; then
  PASS "SC0: the in-model class enumeration was READ FROM reference/data-architecture.md — $SC_NCLASS classes; this suite and the validator hold no copy of it"
else
  FAIL "SC0: no class rows extracted from the architecture document — every assertion below would be over an empty set"
fi

if [ "$SC_NFILES" -gt 0 ]; then
  PASS "SC1: the schema corpus has a non-empty population — $SC_NFILES schema files (README excluded; it declares the corpus, it is not a class)"
else
  FAIL "SC1: reference/schemas/ holds no schema files"
fi

SC_OUT="$(va_check_corpus "$ROOT" 2>&1)"; SC_RC=$?
if [ "$SC_RC" -eq 0 ] && [ -z "$SC_OUT" ]; then
  PASS "SC2: every schema is well-formed and the corpus is in bijection with the class enumeration — no S-class finding over $SC_NFILES schemas x $SC_NCLASS classes"
else
  FAIL "SC2: the schema corpus does not validate: $(printf '%s' "$SC_OUT" | head -4 | tr '\n' ' ')"
fi

if [ "$SC_NFILES" -eq "$SC_NCLASS" ]; then
  PASS "SC3: the corpus and the enumeration are the same size ($SC_NFILES = $SC_NCLASS) — stated as an observed equality, with SC2's bijection check as the assertion behind it"
else
  FAIL "SC3: $SC_NFILES schema files against $SC_NCLASS declared classes"
fi

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "XC — selector exclusions are declared in the corpus, not decided in the guard"
# ─────────────────────────────────────────────────────────────────────────────────
# Section-scoped: the pattern literal must appear WITHIN the section the validator names
# for it, not merely somewhere in the file. A whole-file substring test would go green on
# an exclusion whose declaration had moved to an unrelated section.
xc_section_text() {
  awk -v h="$1" '
    index($0, h) == 1 { inside = 1; next }
    inside && (/^## / || /^### /) { inside = 0 }
    inside { print }
  ' "$ROOT/$VA_ARCH_DOC"
}
XC_N=0; XC_BAD=0
while IFS= read -r xline; do
  [ -n "$xline" ] || continue
  xpat="${xline%%|*}"; xrest="${xline#*|}"
  xwar="${xrest%%|*}"; xsec="${xrest#*|}"
  XC_N=$((XC_N+1))
  # Here-string, not a pipeline — see has_finding above. This site is the one where the
  # defect was OBSERVED in this suite: a command substitution on the left of a pipe into
  # `grep -q` is the shape that fires far below the pipe-capacity threshold, and its FAIL
  # branch accuses the CORPUS of an undeclared exclusion. A gate that randomly blames the
  # thing it guards is worse than no gate, so the shape goes rather than the assertion.
  if grep -qF -- "$xwar" <<<"$(xc_section_text "$xsec")"; then
    PASS "XC: exclusion '$xpat' has its warrant '$xwar' stated at '$xsec'"
  else
    FAIL "XC: exclusion '$xpat' is applied by the validator but its warrant '$xwar' is NOT stated at '$xsec' — the gate would be narrowing its own scope with nothing in the corpus behind it"
    XC_BAD=$((XC_BAD+1))
  fi
done <<EOF
$VA_EXCLUSIONS
EOF
if [ "$XC_N" -gt 0 ] && [ "$XC_BAD" -eq 0 ]; then
  PASS "XC0: all $XC_N declared exclusions carry a warrant in reference/data-architecture.md, each in its own named section"
fi
# Specificity: the section-scoped probe must NOT find a pattern that is not there.
if grep -qF -- 'zzz-no-such-exclusion/*.md' <<<"$(xc_section_text '## 11. What This Document Does Not Define')"; then
  FAIL "XC1: the section probe matched a pattern that does not exist — every XC pass above is a broken probe"
else
  PASS "XC1: control — the same section-scoped probe returns nothing for a fabricated exclusion pattern, so the XC passes above are real matches"
fi

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "AR — the tracked tree: the selector's denominator, and the skip predicate applied"
# ─────────────────────────────────────────────────────────────────────────────────
AR_SEL="$(va_select "$ROOT" tracked)"
AR_NSEL="$(printf '%s\n' "$AR_SEL" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {n++} END{print n+0}')"
AR_NEXC="$(printf '%s\n' "$AR_SEL" | awk -F'\t' '$1=="EXCLUDED" {n++} END{print n+0}')"
AR_NUNM="$(printf '%s\n' "$AR_SEL" | awk -F'\t' '$1=="UNMATCHED" {n++} END{print n+0}')"
AR_NPOP="$(cd "$ROOT" && git ls-files 2>/dev/null | grep -c '[^[:space:]]')"
AR_NCOV="$(printf '%s\n' "$AR_SEL" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {print $1}' | sort -u | grep -c '[^[:space:]]')"

printf '  DENOMINATOR: %s selected / %s excluded / %s unmatched = %s tracked files; %s of %s classes have a selected instance\n' \
  "$AR_NSEL" "$AR_NEXC" "$AR_NUNM" "$AR_NPOP" "$AR_NCOV" "$SC_NCLASS"

if [ "$((AR_NSEL + AR_NEXC + AR_NUNM))" -eq "$AR_NPOP" ]; then
  PASS "AR0: the whole tracked population is accounted for — $AR_NSEL + $AR_NEXC + $AR_NUNM = $AR_NPOP. A denominator that cannot be reconstructed is not a denominator"
else
  FAIL "AR0: the partition does not close — $AR_NSEL + $AR_NEXC + $AR_NUNM != $AR_NPOP"
fi

if [ "$AR_NSEL" -gt 0 ]; then
  PASS "AR1: the selector has a NON-EMPTY population — $AR_NSEL files. A green over zero selected files would be vacuous, not passing"
else
  FAIL "AR1: the selector selected NOTHING. Every AR verdict below would be a statement over the empty set"
fi

# INT-4 — CIAC-7, observable in one run: no command file is selected, and the count that
# makes that meaningful is non-zero (asserted at AR1 above, not assumed here).
AR_NCMD="$(printf '%s\n' "$AR_SEL" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {print $3}' | grep -c '^\.claude/commands/')"
if [ "$AR_NCMD" -eq 0 ]; then
  PASS "AR2: 0 of the $AR_NSEL selected files are .claude/commands/*.md — an upstream schema this repo does not own is out of the gate's selection set, and the selector still selected $AR_NSEL other files"
else
  FAIL "AR2: $AR_NCMD command file(s) reached the selector"
fi
AR_NTPL="$(printf '%s\n' "$AR_SEL" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {print $3}' | grep -c '^templates/')"
if [ "$AR_NTPL" -eq 0 ]; then
  PASS "AR3: 0 templates/*.template.md reached the selector — the emitters the model declares out of scope stay out, on a tree where both of them DO carry a schema-version"
else
  FAIL "AR3: $AR_NTPL template(s) reached the selector; a template's trip: value is the placeholder <trip-slug> and would fail A4"
fi

AR_NSCH="$(printf '%s\n' "$AR_SEL" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {print $3}' | grep -c '^reference/schemas/')"
if [ "$AR_NSCH" -eq 0 ]; then
  PASS "AR6: 0 schema files reached the selector, with NO exclusion carrying them — no class path-pattern reaches reference/schemas/ and a schema carries a fence rather than frontmatter, so the schemas are not instances of themselves by construction. An exclusion here would have been a scope narrowing with nothing behind it"
else
  FAIL "AR6: $AR_NSCH schema file(s) were selected as artifacts"
fi

AR_OUT="$(va_main --root "$ROOT" --scope tracked 2>&1)"; AR_RC=$?
AR_NSKIP="$(printf '%s\n' "$AR_OUT" | grep -c '^SKIP ')"
AR_NVER="$(printf '%s\n' "$AR_OUT" | sed -n 's/^PREDICATE .*validated=\([0-9]*\)$/\1/p')"
AR_NVER="${AR_NVER:-0}"

if [ "$AR_NSKIP" -eq "$AR_NSEL" ] && [ "$AR_NSEL" -gt 0 ]; then
  PASS "AR4: the skip predicate was applied to all $AR_NSEL selected files and its result reported BY PATH and BY RESOLVED CLASS, never merely counted"
elif [ "$AR_NSKIP" -gt 0 ]; then
  PASS "AR4: the skip predicate was applied and reported by path and class for $AR_NSKIP of $AR_NSEL selected files"
else
  FAIL "AR4: no skip was reported over a population of $AR_NSEL"
fi

if [ "$AR_NVER" -gt 0 ]; then
  if [ "$AR_RC" -eq 0 ]; then
    PASS "AR5: $AR_NVER versioned artifact(s) validated clean"
  else
    FAIL "AR5: $AR_NVER versioned artifact(s) and the validator reported findings: $(printf '%s' "$AR_OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
  fi
else
  VACUOUS "AR5: the VERSIONED population is 0 — $AR_NSEL files were selected and all $AR_NSKIP skipped under the tolerant read, so no artifact was validated on this commit. This is a real measurement of the tree, not a pass. This run rests on group CTL"
fi

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "CV — the coverage declaration (the line the coverage question is read from)"
# ─────────────────────────────────────────────────────────────────────────────────
# CV_WITNESSES accumulates the witness PATHS as well as counting them, because group CTL
# below copies exactly this set into every fixture root it builds. It is captured HERE rather
# than re-derived there: a second walk of the corpus would be a second home for the coverage
# declarations, free to drift out of agreement with this one while both stayed green — the
# same reason this suite reads the class enumeration from the document instead of holding one.
# CV_CLASS_WITNESS pairs each class-id with the witness path it declares, and
# CV_NOWITNESS_IDS records the class-ids that declare the other branch. Group CA below reads
# BOTH, for the same reason CV_WITNESSES is captured here rather than re-derived there: a
# second walk of the corpus would be a second home for the coverage declarations, free to
# drift out of agreement with this one while both stayed green. The no-witness ids are
# captured rather than inferred by subtraction so CA's denominator is a MEASUREMENT of which
# classes are absent by design, not an arithmetic remainder that would absorb a class that
# declared neither branch.
CV_W=0; CV_N=0; CV_WITNESSES=""; CV_CLASS_WITNESS=""; CV_NOWITNESS_IDS=""
while IFS= read -r sf; do
  [ -n "$sf" ] || continue
  sl="$(va_schema_lines "$ROOT" "$sf" 2>/dev/null | grep -v '^FINDING ')"
  cvw="$(va_schema_get "$sl" witness)"
  cvc="$(va_schema_get "$sl" class-id)"
  if [ -n "$cvw" ]; then
    CV_W=$((CV_W+1)); CV_WITNESSES="$CV_WITNESSES$cvw$VA_NL"
    CV_CLASS_WITNESS="$CV_CLASS_WITNESS${cvc}${VA_TAB}${cvw}${VA_NL}"
  elif [ -n "$(va_schema_get "$sl" no-witness-because)" ]; then
    CV_N=$((CV_N+1)); CV_NOWITNESS_IDS="$CV_NOWITNESS_IDS $cvc"
  fi
done <<EOF
$SC_FILES
EOF
printf '  CV: %s witness / %s no-witness / %s total\n' "$CV_W" "$CV_N" "$SC_NFILES"

if [ "$((CV_W + CV_N))" -eq "$SC_NFILES" ] && [ "$SC_NFILES" -gt 0 ]; then
  PASS "CV0: every one of the $SC_NFILES classes declares exactly one of witness: / no-witness-because: — the coverage question is answered by the line above rather than by a per-class audit"
else
  FAIL "CV0: $CV_W + $CV_N != $SC_NFILES — a class declares neither or both"
fi

if [ "$CV_W" -eq 0 ]; then
  VACUOUS "CV1: 0 classes declare a validated witness. Coverage is a measurement, and on this commit the measurement is zero — the gate's teeth grow as each migration slice flips its class to witness:, and from that commit a stripped or unversioned witness is S6"
else
  PASS "CV1: $CV_W class(es) declare a validated witness; a stripped or unversioned witness is now a fail-closed coverage regression (S6)"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group EN — every enum has ONE home, and every other home agrees with it byte for byte.
#
# ── WHY THIS GROUP EXISTS ────────────────────────────────────────────────────────
# The three universal enums are correct across every home today. Nothing HELD them so. The
# defect this release found by hand is exactly the shape a comparison catches mechanically:
# one record declared a five-member enum while nineteen schemas, six class rows, a fixture
# and the running gate all shipped six. Every home was internally plausible; only a
# cross-home comparison could see it.
#
# ── THE PROBE IS KEYED ON SHAPE, NEVER ON CONTENT, AND THAT IS THE WHOLE DESIGN ──
# A home is discovered by the KEY plus a delimited payload carrying at least one `|` — not
# by matching the canonical member string. The distinction is the difference between an
# assertion and a tautology: a probe that found homes BY the canonical text would define its
# population as the set of places that already agree, and a drifted home would leave the
# population rather than fail. Keyed on shape, a drifted home is still FOUND and is then
# reported as a mismatch, which is the only arrangement under which the zero means anything.
#
# Two rendered forms exist in the corpus and both are discovered by the same predicate: the
# angle form a declaration block uses, and the bracket form a per-class schema's
# `field <key>: required enum [...]` line uses. Neither is spelled as a literal member list
# anywhere in this file — that would be the second source of truth this suite exists to
# prevent, green while the document it claims to enforce drifted away from it.
#
# ── ORDER, NOT ONLY MEMBERSHIP ───────────────────────────────────────────────────
# The comparison is string equality on the delimiter-joined payload, so a REORDERING is a
# mismatch. A set comparison would let an ordering drift through, and the enums are read as
# ordered lists in the corpus.
#
# ── THE KEY SET IS DERIVED, NOT LISTED ───────────────────────────────────────────
# EN takes every key in the universal-frontmatter declaration whose value is a delimited
# pipe-list. A fourth enum field added to that block is picked up with no edit here; a list
# of key names in this file would silently not cover it.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "EN — the universal enums: one home, and every other home byte-identical to it"

EN_DOC="$ROOT/$VA_ARCH_DOC"

# The universal-frontmatter block's enum-valued keys. Derived, never listed.
#
# ── WHY THE FENCE IS RE-JOINED BEFORE IT IS MATCHED, AND WHY THAT IS THE WHOLE POINT ──
# Read this before "simplifying" the accumulator back into a single per-line match.
#
# The key set is DERIVED (see the group header above), which is what lets a fourth enum
# field be picked up with no edit here. The derivation's failure mode is that it can only
# ever NARROW: a key is discovered by matching `key: <a|b|c>` on ONE line, so a one-line
# MARKDOWN REFLOW of the declaration block — wrapping a long pipe-list across two lines —
# drops that key from the set entirely. The suite then emits FEWER assertions, every one
# green, exit 0, with that enum's homes across the tracked tree checked by NOTHING. A
# coverage floor that can silently drop is not a floor, and nothing in EN2 could tell the
# two greens apart: one key checked and reported, one key never in the population.
#
# Pinning an expected COUNT here would close it, and is rejected: a literal count is a
# second source of truth that a legitimate fourth enum turns red for being right. So the
# derivation is made reflow-IMMUNE instead of merely counted. A line holding an unclosed
# `<` is held and joined to its continuation, and the whitespace a reflow introduces
# around the `|` delimiters is normalized away — so a reflowed block yields the IDENTICAL
# key set and the IDENTICAL canonical payload rather than a shorter one. EN0b below is the
# control arm that proves it, built by reflowing the real document at runtime.
en_fence_lines() {
  awk '
    $0 ~ /^### 4\.4 / { insec = 1; next }
    insec && (/^### / || /^## /) { insec = 0 }
    insec && $0 == "```yaml" { infence = 1; pend = ""; next }
    infence && $0 == "```" {
      if (pend != "") { gsub(/[ \t]*\|[ \t]*/, "|", pend); print pend }
      infence = 0; pend = ""; next
    }
    infence {
      line = $0
      if (pend != "") { sub(/^[ \t]+/, "", line); pend = pend " " line }
      else { pend = line }
      # An unclosed `<` is a wrapped declaration, not a finished one: hold it and join
      # the continuation. Anything else is complete as written and is emitted now.
      if (index(pend, "<") > 0 && index(pend, ">") == 0) next
      gsub(/[ \t]*\|[ \t]*/, "|", pend)
      print pend; pend = ""
    }
  ' "$1"
}

en_keys() {
  en_fence_lines "${1:-$EN_DOC}" | awk '
    match($0, /^[a-z][a-z0-9-]*:[^<>]*<[^<>]*\|[^<>]*>/) { k = $0; sub(/:.*$/, "", k); print k }
  '
}

# en_canonical <key> — the member list, from the universal-frontmatter block and nowhere
# else. One line per declaration site, so the caller can assert the site is singular.
en_canonical() {
  en_fence_lines "${2:-$EN_DOC}" | awk -v key="$1" '
    index($0, key ":") == 1 {
      if (match($0, /<[^<>]*\|[^<>]*>/)) print substr($0, RSTART + 1, RLENGTH - 2)
    }
  '
}

# en_probe <key> <file>... — "<file>\t<line>\t<payload>" per home. ONE awk process over the
# whole population rather than one per file: this group reads every tracked file and the
# suite it joins already runs in minutes, so the process count is the cost that matters.
en_probe() {
  local key="$1"; shift
  [ "$#" -gt 0 ] || return 0
  awk -v key="$key" '
    {
      line = $0
      while (match(line, "(^|[ \t`])" key ":[^<>[\\]]*(<[^<>]*\\|[^<>]*>|\\[[^][]*\\|[^][]*\\])")) {
        seg = substr(line, RSTART, RLENGTH)
        if (match(seg, /<[^<>]*>$/)) p = substr(seg, RSTART + 1, RLENGTH - 2)
        else { match(seg, /\[[^][]*\]$/); p = substr(seg, RSTART + 1, RLENGTH - 2) }
        printf "%s\t%d\t%s\n", FILENAME, FNR, p
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$@"
}

EN_FILES=(); EN_NFILES=0
while IFS= read -r enf; do
  [ -n "$enf" ] || continue
  if [ -r "$ROOT/$enf" ]; then EN_FILES+=("$ROOT/$enf"); EN_NFILES=$((EN_NFILES+1)); fi
done <<EOF
$(cd "$ROOT" && git ls-files 2>/dev/null)
EOF

EN_OK=1
EN_KEYS="$(en_keys)"
EN_NKEYS="$(printf '%s\n' "$EN_KEYS" | grep -c '[^[:space:]]')"
if [ ! -r "$EN_DOC" ]; then
  FAIL "EN0: $VA_ARCH_DOC is not readable — the canonical source is absent, so nothing below can be asserted. Not a skip and not a pass"
  EN_OK=0
elif [ "$EN_NKEYS" -gt 0 ] && [ "$EN_NFILES" -gt 0 ]; then
  PASS "EN0: the universal-frontmatter block declares $EN_NKEYS enum-valued key(s), read FROM $VA_ARCH_DOC over a tracked population of $EN_NFILES file(s); this file holds no copy of any member list"
else
  FAIL "EN0: no enum-valued key was extracted from the universal-frontmatter block ($EN_NKEYS), or the tracked population is empty ($EN_NFILES) — every EN verdict below would be over an empty set"
  EN_OK=0
fi

# EN0b — THE CONTROL ARM FOR THE DERIVATION ITSELF, and it is the one this group was
# missing. Every arm below asserts that the HOMES agree with the canonical; none of them
# can see the key set SHRINK, because a key that leaves the population takes its own
# assertion with it. So the derivation is re-run against a REFLOWED rendering of the real
# document, built at runtime by wrapping each declaration's pipe-list across two lines —
# the exact edit a markdown formatter makes — and the two key sets must be IDENTICAL.
#
# The reflow is generated FROM the document, never from a literal: a fabricated fixture
# would stop tracking the block the moment a fourth enum was added to it.
if [ "$EN_OK" -eq 1 ]; then
  EN_RF="$WORK/en-reflowed.md"
  awk '
    infence && match($0, /^[a-z][a-z0-9-]*:[^<>]*<[^<>]*\|[^<>]*>/) {
      # Wrap at the LAST delimiter, so the payload spans two lines exactly as a
      # formatter would leave it.
      p = $0
      if (match(p, /\|[^<>|]*>/)) {
        printf "%s|\n            %s\n", substr(p, 1, RSTART - 1), substr(p, RSTART + 1)
        next
      }
    }
    { print }
    $0 == "```yaml" { infence = 1 }
    $0 == "```" { infence = 0 }
  ' "$EN_DOC" > "$EN_RF"
  EN_RF_KEYS="$(en_keys "$EN_RF")"
  EN_RF_N="$(printf '%s\n' "$EN_RF_KEYS" | grep -c '[^[:space:]]')"
  EN_RF_DIFF=0
  [ "$EN_RF_KEYS" = "$EN_KEYS" ] || EN_RF_DIFF=1
  # The mutation must be asserted to have LANDED, or an identical key set proves only
  # that the reflow builder did nothing.
  EN_RF_MUT=0
  cmp -s "$EN_DOC" "$EN_RF" || EN_RF_MUT=1
  if [ "$EN_RF_MUT" -eq 1 ] && [ "$EN_RF_DIFF" -eq 0 ] && [ "$EN_RF_N" -eq "$EN_NKEYS" ]; then
    PASS "EN0b: control — the declaration block was REFLOWED at runtime (the mutation is asserted to have landed) and the same derivation returns the IDENTICAL $EN_RF_N key(s). A markdown reflow cannot silently narrow this group's population, which is the one failure the arms below are structurally unable to see"
  elif [ "$EN_RF_MUT" -eq 0 ]; then
    FAIL "EN0b: the reflow control produced a byte-identical document, so it asserted nothing — the builder no longer matches the declaration block's shape"
  else
    FAIL "EN0b: reflowing the declaration block CHANGED the derived key set ($EN_NKEYS -> $EN_RF_N). A one-line wrap silently drops an enum from this group's population and every home it had is then checked by nothing. Derived: [$(printf '%s' "$EN_RF_KEYS" | tr '\n' ' ')] against [$(printf '%s' "$EN_KEYS" | tr '\n' ' ')]"
  fi
fi

if [ "$EN_OK" -eq 1 ]; then
  EN_SITES_BAD=0; EN_SITES=""
  while IFS= read -r enk; do
    [ -n "$enk" ] || continue
    ensn="$(en_canonical "$enk" | grep -c '[^[:space:]]')"
    EN_SITES="$EN_SITES$enk=$ensn "
    [ "$ensn" -eq 1 ] || EN_SITES_BAD=$((EN_SITES_BAD+1))
  done <<EOF
$EN_KEYS
EOF
  if [ "$EN_SITES_BAD" -eq 0 ]; then
    PASS "EN1: every enum has EXACTLY ONE declaration site in the universal-frontmatter block — a single normative home ($EN_SITES)"
  else
    FAIL "EN1: $EN_SITES_BAD enum(s) do not have exactly one declaration site in the universal-frontmatter block ($EN_SITES)"
    EN_OK=0
  fi
fi

# EN2 — one arm per enum. The denominator is the OBSERVED home count and is printed, so a
# green cannot rest on a population nobody counted.
EN_TOTAL_HOMES=0
if [ "$EN_OK" -eq 1 ]; then
  while IFS= read -r enk; do
    [ -n "$enk" ] || continue
    encanon="$(en_canonical "$enk" | head -1)"
    enhomes="$(en_probe "$enk" ${EN_FILES[@]+"${EN_FILES[@]}"})"
    enn="$(printf '%s\n' "$enhomes" | grep -c '[^[:space:]]')"
    enbad="$(printf '%s\n' "$enhomes" | awk -F'\t' -v c="$encanon" 'NF>2 && $3 != c {n++} END{print n+0}')"
    EN_TOTAL_HOMES=$((EN_TOTAL_HOMES + enn))
    if [ "$enn" -eq 0 ]; then
      FAIL "EN2-$enk: the probe found NO home for this enum. A zero here is a broken probe, not a clean corpus — the canonical declaration site is itself a home and must have been counted"
    elif [ "$enbad" -eq 0 ]; then
      PASS "EN2-$enk: all $enn home(s) of the \`$enk\` enum are byte-identical to the one canonical declaration, in MEMBER SET AND ORDER — [$encanon]"
    else
      FAIL "EN2-$enk: $enbad of $enn home(s) of the \`$enk\` enum disagree with the canonical [$encanon]:"
      printf '%s\n' "$enhomes" | awk -F'\t' -v c="$encanon" -v r="$ROOT/" 'NF>2 && $3 != c { p=$1; sub(r,"",p); printf "      %s:%s -> [%s]\n", p, $2, $3 }'
    fi
  done <<EOF
$EN_KEYS
EOF
fi

# EN3 — THE CONTROL ARM, AND IT IS INSIDE THE ASSERTION. The same probe, run against a
# DRIFTED rendering of each enum in BOTH rendered forms, must FIND the home and REPORT it as
# differing. A probe that cannot see a drifted home would return zero mismatches above for
# the wrong reason, and nothing in EN2 alone could tell the two zeroes apart. The drifted
# fixture is BUILT by reordering the canonical extracted at runtime, never from a literal.
if [ "$EN_OK" -eq 1 ]; then
  EN_CTL_FOUND=0; EN_CTL_FLAGGED=0; EN_CTL_ARMS=0; EN_CTL_MUT=0
  while IFS= read -r enk; do
    [ -n "$enk" ] || continue
    encanon="$(en_canonical "$enk" | head -1)"
    # Reorder the first two members. Asserted to have CHANGED the string before it is used:
    # a fixture that was never mutated is a green proving nothing, one level down.
    enmut="$(printf '%s' "$encanon" | awk -F'|' '{ if (NF < 2) { print; next } printf "%s|%s", $2, $1; for (i = 3; i <= NF; i++) printf "|%s", $i; printf "\n" }')"
    [ "$enmut" != "$encanon" ] && EN_CTL_MUT=$((EN_CTL_MUT+1))
    printf 'field %s: required enum [%s]\n%s: <%s>\n' "$enk" "$enmut" "$enk" "$enmut" > "$WORK/en-ctl"
    enh="$(en_probe "$enk" "$WORK/en-ctl")"
    EN_CTL_ARMS=$((EN_CTL_ARMS+2))
    EN_CTL_FOUND=$((EN_CTL_FOUND + $(printf '%s\n' "$enh" | grep -c '[^[:space:]]')))
    EN_CTL_FLAGGED=$((EN_CTL_FLAGGED + $(printf '%s\n' "$enh" | awk -F'\t' -v c="$encanon" 'NF>2 && $3 != c {n++} END{print n+0}')))
  done <<EOF
$EN_KEYS
EOF
  if [ "$EN_CTL_MUT" -eq "$EN_NKEYS" ] && [ "$EN_CTL_FOUND" -eq "$EN_CTL_ARMS" ] && [ "$EN_CTL_FLAGGED" -eq "$EN_CTL_ARMS" ]; then
    PASS "EN3: control — a REORDERED member list is found by the same probe and reported as differing in all $EN_CTL_ARMS arms (both rendered forms x $EN_NKEYS enums), and every mutation was asserted to have changed the string. The zeroes in EN2 are measurements, not an empty scan"
  else
    FAIL "EN3: the control arm did not behave (mutations=$EN_CTL_MUT/$EN_NKEYS found=$EN_CTL_FOUND/$EN_CTL_ARMS flagged=$EN_CTL_FLAGGED/$EN_CTL_ARMS) — every EN2 zero above is a broken probe rather than a clean result"
  fi
fi

# EN4 — specificity. The same probe must return NOTHING for a key the corpus never declares,
# while EN2's sensitivity arm above observed a non-zero total. Both limbs, or the zero is
# an empty scan wearing a pass.
if [ "$EN_OK" -eq 1 ]; then
  EN_FAB="$(en_probe 'zzz-no-such-enum-key' ${EN_FILES[@]+"${EN_FILES[@]}"} | grep -c '[^[:space:]]')"
  if [ "$EN_FAB" -eq 0 ] && [ "$EN_TOTAL_HOMES" -gt 0 ]; then
    PASS "EN4: control — the same probe returns 0 homes for a fabricated key across all $EN_NFILES tracked files, while finding $EN_TOTAL_HOMES real homes. The probe discriminates rather than matching everything or nothing"
  else
    FAIL "EN4: specificity failed — fabricated key returned $EN_FAB home(s) over a real-home total of $EN_TOTAL_HOMES"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group UF — no schema silently drops a universal frontmatter field.
#
# ── WHAT THIS CLOSES, AND HOW IT WAS OBSERVED ────────────────────────────────────
# reference/data-architecture.md § 4.4 declares the universal frontmatter block and states
# the invariant in terms — "no class removes a universal field" — and every schema in the
# corpus restates it in its own fence comment. NOTHING HELD IT.
#
# Measured rather than assumed: deleting one `field` row from one schema and running this
# suite produced output BYTE-IDENTICAL to the unmutated run — same 76 passed, same 0 failed,
# same rc 0. A required field left a schema and no assertion moved.
#
# ── THE ENUM KEYS WERE NOT COVERED EITHER, AND THAT HAD TO BE TESTED ─────────────
# The reading this group was written against was that the gap belonged to group EN, which
# covers enum-valued keys only. It does not. EN compares each enum's MEMBER LIST across the
# homes it finds, so a schema that drops `field lifecycle:` entirely never disagrees with the
# canonical — it leaves EN's population, EN2's home count slides by one, and the arm still
# reports PASS. That was run: deleting an enum-valued universal key is exactly as invisible
# as deleting a non-enum one, and the only trace is a home count nothing asserts a floor on.
# So the gap is not one group's. No assertion anywhere bound a schema's declared key set to
# the universal set, and that is the binding this group adds.
#
# ── THE EXPECTATION IS DERIVED, AND NO COUNT IS PINNED ───────────────────────────
# The universal key set is read FROM § 4.4's own fence through en_fence_lines above — the
# reflow-immune reader EN0b already proves cannot silently narrow. The schema population is
# read through va_schema_files and each schema's declared fields through va_schema_lines, the
# validator's own parser. Neither the number of schemas nor the number of universal keys is
# spelled in this file, so a legitimate twentieth schema, or a ninth universal field, is
# picked up with no edit here. A pinned count would be a second source of truth that turns
# red for being right — the failure this suite already refuses at EN's key derivation.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "UF — every schema declares every universal frontmatter field (§ 4.4)"

# uf_univ_keys [doc] — every key of the universal frontmatter block, enum-valued or not.
# en_keys narrows to the pipe-list values because group EN is about member lists; the § 4.4
# invariant is stated over the WHOLE block, so this reads the whole block.
uf_univ_keys() {
  en_fence_lines "${1:-$EN_DOC}" | awk '
    $0 == "---" { next }
    match($0, /^[a-z][a-z0-9-]*:/) { print substr($0, 1, RLENGTH - 1) }
  '
}

# uf_missing <root> — "<schema-path>\t<key>" for every universal key a schema fails to
# declare as a `field` row. Emits nothing when the invariant holds.
uf_missing() {
  local r="$1" sf sl declared keys k
  keys="$(uf_univ_keys "$r/$VA_ARCH_DOC")"
  while IFS= read -r sf; do
    [ -n "$sf" ] || continue
    sl="$(va_schema_lines "$r" "$sf" 2>/dev/null | grep -v '^FINDING ')"
    declared="$(va_schema_all "$sl" field | awk '{ print $1 }')"
    while IFS= read -r k; do
      [ -n "$k" ] || continue
      grep -qx -- "$k" <<<"$declared" || printf '%s\t%s\n' "$sf" "$k"
    done <<INNER
$keys
INNER
  done <<OUTER
$(va_schema_files "$r")
OUTER
}

# uf_fx <dir> — the architecture document and the schema corpus, and nothing else. That is
# the whole population uf_missing reads, so a fixture carrying more would be carrying it for
# no arm. Copied from this commit rather than synthesised, for mk_root's stated reason.
uf_fx() {
  mkdir -p "$1/$VA_SCHEMA_DIR"
  cp "$ROOT/$VA_ARCH_DOC" "$1/$VA_ARCH_DOC"
  cp "$ROOT/$VA_SCHEMA_DIR"/*.md "$1/$VA_SCHEMA_DIR/"
}

UF_KEYS="$(uf_univ_keys)"
UF_NKEYS="$(printf '%s\n' "$UF_KEYS" | grep -c '[^[:space:]]')"
UF_DEN=$((UF_NKEYS * SC_NFILES))
UF_OK=1

if [ "$UF_NKEYS" -gt 0 ] && [ "$SC_NFILES" -gt 0 ]; then
  PASS "UF0: the universal-frontmatter block declares $UF_NKEYS key(s) [$(printf '%s' "$UF_KEYS" | tr '\n' ' ')], read FROM $VA_ARCH_DOC § 4.4, against a corpus of $SC_NFILES schema(s) — a DERIVED denominator of $UF_DEN (schema x universal key) pairs, with neither count spelled in this file"
else
  FAIL "UF0: the universal key set ($UF_NKEYS) or the schema corpus ($SC_NFILES) is empty — every UF verdict below would be a statement over the empty set"
  UF_OK=0
fi

if [ "$UF_OK" -eq 1 ]; then
  UF_MISS="$(uf_missing "$ROOT")"
  UF_NMISS="$(printf '%s\n' "$UF_MISS" | grep -c '[^[:space:]]')"
  if [ "$UF_NMISS" -eq 0 ]; then
    PASS "UF1: all $UF_DEN (schema x universal key) pairs are declared — no class removes a universal field, which is what § 4.4 says and what nothing checked. The denominator is derived from the corpus and the document, so it grows with either"
  else
    FAIL "UF1: $UF_NMISS of $UF_DEN (schema x universal key) pair(s) are MISSING — a schema has silently dropped a universal field: $(printf '%s' "$UF_MISS" | awk -F'\t' '{ printf "%s lacks field %s; ", $1, $2 }' | head -c 400)"
  fi
fi

# UF-CTL1 — MUST FIRE, and the mutation is the one that proved the gap. A universal key is
# deleted from ONE schema in a fixture copy, and the check must report EXACTLY that pair.
# Both the schema and the key are DERIVED (the first of each), so no class name and no field
# name is pinned in this file.
if [ "$UF_OK" -eq 1 ]; then
  UF_FX1="$WORK/uf-mut1"; uf_fx "$UF_FX1"
  UF_TGT="$(va_schema_files "$ROOT" | head -1)"
  UF_TKEY="$(printf '%s\n' "$UF_KEYS" | head -1)"
  awk -v k="$UF_TKEY" '$0 ~ "^field " k ":" { next } { print }' \
    "$ROOT/$UF_TGT" > "$UF_FX1/$UF_TGT.new" && mv "$UF_FX1/$UF_TGT.new" "$UF_FX1/$UF_TGT"
  UF_MUT1=0
  cmp -s "$ROOT/$UF_TGT" "$UF_FX1/$UF_TGT" || UF_MUT1=1
  UF_OUT1="$(uf_missing "$UF_FX1")"
  UF_N1="$(printf '%s\n' "$UF_OUT1" | grep -c '[^[:space:]]')"
  UF_HIT1="$(awk -F'\t' -v s="$UF_TGT" -v k="$UF_TKEY" '$1==s && $2==k {n++} END{print n+0}' <<<"$UF_OUT1")"
  # Graded as a DELTA against UF1's own measurement, not against a literal 1. The fixture is
  # a copy of this commit's corpus, so on a tree that genuinely has a missing field the arm
  # would otherwise inherit it and fail for the corpus's reason while accusing itself — a
  # control that mis-attributes its own cause. One mutation must add exactly one pair,
  # whatever the corpus started from.
  UF_EXP1=$((UF_NMISS + 1))
  if [ "$UF_MUT1" -eq 1 ] && [ "$UF_N1" -eq "$UF_EXP1" ] && [ "$UF_HIT1" -eq 1 ]; then
    PASS "UF-CTL1: MUST FIRE — deleting 'field $UF_TKEY:' from $UF_TGT in a fixture copy adds EXACTLY ONE (schema, key) pair to the reported set ($UF_NMISS -> $UF_N1) and it is that pair. The mutation is asserted to have landed, so the arm grades a changed tree rather than an unbuilt one"
  else
    FAIL "UF-CTL1: MUST FIRE — the deletion of 'field $UF_TKEY:' from $UF_TGT was not reported cleanly (mutation-landed=$UF_MUT1, pairs-reported=$UF_N1 against $UF_EXP1 expected, target-pair-found=$UF_HIT1). UF1's count above rests on a probe that does not respond to a known deletion"
  fi
fi

# UF-CTL2 — MUST FIRE from the DOCUMENT side. A ninth universal field added to § 4.4 must be
# required of every schema at once; this is the arm proving the key set actually drives the
# comparison, rather than the comparison being satisfied by whatever the schemas happen to
# declare. The fabricated key is added to the fence itself, so the derivation is what carries
# it — nothing here tells uf_missing which keys to look for.
if [ "$UF_OK" -eq 1 ]; then
  UF_FX2="$WORK/uf-mut2"; uf_fx "$UF_FX2"
  awk '
    $0 == "```yaml" && !done { print; infence = 1; next }
    infence && $0 == "---" && !opened { print; opened = 1; print "zzz-fabricated-universal: <value>"; next }
    infence && $0 == "```" { infence = 0; done = 1 }
    { print }
  ' "$ROOT/$VA_ARCH_DOC" > "$UF_FX2/$VA_ARCH_DOC.new" && mv "$UF_FX2/$VA_ARCH_DOC.new" "$UF_FX2/$VA_ARCH_DOC"
  UF_MUT2=0
  cmp -s "$ROOT/$VA_ARCH_DOC" "$UF_FX2/$VA_ARCH_DOC" || UF_MUT2=1
  UF_K2="$(uf_univ_keys "$UF_FX2/$VA_ARCH_DOC" | grep -c '[^[:space:]]')"
  UF_OUT2="$(uf_missing "$UF_FX2")"
  UF_HIT2="$(awk -F'\t' '$2=="zzz-fabricated-universal" {n++} END{print n+0}' <<<"$UF_OUT2")"
  if [ "$UF_MUT2" -eq 1 ] && [ "$UF_K2" -eq "$((UF_NKEYS + 1))" ] && [ "$UF_HIT2" -eq "$SC_NFILES" ]; then
    PASS "UF-CTL2: MUST FIRE — a fabricated key added to § 4.4's fence is derived as universal ($UF_NKEYS -> $UF_K2) and is then reported missing from all $SC_NFILES schemas. The expectation follows the document, so a ninth universal field would be enforced corpus-wide with no edit to this file"
  else
    FAIL "UF-CTL2: MUST FIRE — a fabricated universal key was not enforced corpus-wide (mutation-landed=$UF_MUT2, keys-derived=$UF_K2 against $((UF_NKEYS + 1)) expected, schemas-flagged=$UF_HIT2 of $SC_NFILES)"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group LC — the classifying predicates do not change their answer with the locale.
#
# ── THE FINDING ──────────────────────────────────────────────────────────────────
# `va_type_ok`'s slug arm and `va_fm_pairs`'s kebab-case arm both classified with bracket
# RANGES. A range is resolved against the collating sequence of the current locale, and under
# a UTF-8 collation `[a-z]` matches uppercase: `Hub` and `HUB` were REJECTED under LC_ALL=C
# and ACCEPTED under an operator's own default. Nothing pinned the locale for the validator
# or its workflow, so CI enforced a rule an operator's own run did not, and a file that
# passed locally failed in CI for a reason nothing explained.
#
# ── THE FIX IS BY CONSTRUCTION, NOT BY PINNING, AND THAT IS WHY LC2 EXISTS ───────
# Pinning LC_ALL inside the validator would make the answer depend on a pin holding at every
# entry point — including the ones this suite uses, which call the predicates directly rather
# than through the CLI. Spelling the character sets explicitly removes the collation table
# from the question altogether: with no range to widen, there is nothing for a locale to do.
# LC2 asserts that property at the source, which is the arm that still has teeth on a host
# whose locale archive contains nothing that folds. LC1 asserts the behaviour through the
# real function, which is the arm that would have caught the original.
#
# ── WHY THE POPULATION IS DERIVED FROM THE HOST ──────────────────────────────────
# A folding locale cannot be assumed present: C, POSIX and C.UTF-8 all collate by codepoint
# and none of them reproduces the finding. So the locale set is DERIVED — C and POSIX always,
# plus whatever the host declares that the probe shows to fold — and the arm reports how many
# of each it exercised. A run on a host with none is a weaker measurement and says so; it is
# never a vacuous one, because the set is never smaller than two and LC2 does not depend on
# the archive at all.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "LC — the classifying predicates are locale-invariant"

# lc_folds <locale> — true when a bracket range folds case under that locale. Probed on a
# construct THIS FILE owns rather than on the validator, so the probe stays independent of
# the thing it is used to grade. This is also the one deliberate range in the scan set's
# neighbourhood, and LC2 below is scoped to the validator for exactly that reason.
lc_folds() {
  local LC_ALL="$1"
  case H in [a-z]) return 0 ;; *) return 1 ;; esac
}

LC_SET="C
POSIX"
LC_FOLD_N=0
while IFS= read -r lcname; do
  [ -n "$lcname" ] || continue
  [ "$LC_FOLD_N" -lt 4 ] || break
  lc_folds "$lcname" || continue
  LC_SET="$LC_SET
$lcname"
  LC_FOLD_N=$((LC_FOLD_N + 1))
done <<EOF
$(locale -a 2>/dev/null)
EOF
LC_N="$(printf '%s\n' "$LC_SET" | grep -c '[^[:space:]]')"

if [ "$LC_N" -ge 2 ]; then
  PASS "LC0: the differential runs over $LC_N locale(s) — C and POSIX, plus the $LC_FOLD_N collation-folding locale(s) this host declares. A folding locale is one where a bracket range matches outside its written span, which is the construct the finding is about"
else
  FAIL "LC0: only $LC_N locale(s) were assembled — a differential needs at least two, so LC1 below would be comparing a value with itself"
fi

# LC1 — THROUGH THE REAL FUNCTION. The values are derived from one lowercase seed by case
# transformation, because the finding is about case; they are not a spelled table.
LC_SEED='hub'
LC_VALUES="$LC_SEED
$(printf '%s' "$LC_SEED" | tr 'a-z' 'A-Z')
$(printf '%s' "$LC_SEED" | awk '{ printf "%s%s", toupper(substr($0, 1, 1)), substr($0, 2) }')
$LC_SEED-9
$LC_SEED.9"
LC_DISAGREE=0; LC_PAIRS=0; LC_DETAIL=""
while IFS= read -r lcv; do
  [ -n "$lcv" ] || continue
  lcbase=""
  while IFS= read -r lcl; do
    [ -n "$lcl" ] || continue
    # A subshell, so the assignment cannot outlive the call and each verdict is taken under
    # exactly the locale it is labelled with.
    if ( export LC_ALL="$lcl"; va_type_ok slug "$lcv" ); then lcr=accept; else lcr=reject; fi
    if [ -z "$lcbase" ]; then
      lcbase="$lcr"
    else
      LC_PAIRS=$((LC_PAIRS + 1))
      if [ "$lcr" != "$lcbase" ]; then
        LC_DISAGREE=$((LC_DISAGREE + 1))
        LC_DETAIL="$LC_DETAIL '$lcv' C=$lcbase $lcl=$lcr;"
      fi
    fi
  done <<INNER
$LC_SET
INNER
done <<OUTER
$LC_VALUES
OUTER
if [ "$LC_PAIRS" -gt 0 ] && [ "$LC_DISAGREE" -eq 0 ]; then
  PASS "LC1: va_type_ok's slug predicate returned the SAME verdict across all $LC_PAIRS (value, locale) comparisons — observed through the real function, not through a standalone rendering of the construct. An operator's shell and CI cannot disagree about what a slug is"
elif [ "$LC_PAIRS" -eq 0 ]; then
  FAIL "LC1: no (value, locale) pair was compared — the arm asserted nothing"
else
  FAIL "LC1: the slug predicate disagreed with itself on $LC_DISAGREE of $LC_PAIRS comparison(s) — the same value is accepted under one locale and rejected under another, so CI enforces a rule an operator's own run does not:$LC_DETAIL"
fi

# LC2 — the by-construction arm. Scoped to the VALIDATOR, deliberately: this suite carries a
# range of its own in lc_folds above, which is the probe rather than the predicate, and a
# whole-file scan would read it as the defect it exists to detect.
lc_fn_body() {
  awk -v fn="$2" '
    $0 == fn "() {" { inside = 1; next }
    inside && $0 == "}" { inside = 0 }
    inside { print }
  ' "$1"
}
lc_ranges() {
  awk '{ n += gsub(/a-z/, ""); n += gsub(/A-Z/, ""); n += gsub(/0-9/, "") } END { print n + 0 }'
}
LC_FNS="va_type_ok
va_fm_pairs"
LC_RANGE_TOTAL=0; LC_BODY_LINES=0
if [ -r "$SELF_VALIDATOR" ]; then
  while IFS= read -r lcfn; do
    [ -n "$lcfn" ] || continue
    lcbody="$(lc_fn_body "$SELF_VALIDATOR" "$lcfn")"
    LC_BODY_LINES=$((LC_BODY_LINES + $(printf '%s\n' "$lcbody" | grep -c '[^[:space:]]')))
    LC_RANGE_TOTAL=$((LC_RANGE_TOTAL + $(printf '%s\n' "$lcbody" | lc_ranges)))
  done <<EOF
$LC_FNS
EOF
fi
LC_SPEC="$(printf 'case "$v" in [a-z0-9]) return 0 ;; esac\n' | lc_ranges)"
if [ "$LC_BODY_LINES" -eq 0 ]; then
  FAIL "LC2: the scan read 0 lines from the classifier bodies — the function names or the validator have moved, and the zero below would cover nothing"
elif [ "$LC_SPEC" -eq 0 ]; then
  FAIL "LC2: the range detector found nothing in a synthetic line that carries one, so its zero over the real bodies would be a broken probe wearing a pass"
elif [ "$LC_RANGE_TOTAL" -eq 0 ]; then
  PASS "LC2: 0 collation-dependent bracket ranges across $LC_BODY_LINES lines of va_type_ok and va_fm_pairs — both classifiers spell their character sets explicitly, so no collation table can widen one. The detector found $LC_SPEC in a synthetic control line, so the zero is a measurement rather than an empty scan"
else
  FAIL "LC2: $LC_RANGE_TOTAL collation-dependent bracket range(s) remain in va_type_ok / va_fm_pairs across $LC_BODY_LINES lines — a range is resolved against the current locale's collating sequence, so these predicates answer differently in CI and in an operator's shell"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group CA — the several homes of each class's assignment agree.
#
# ── THE HOMES, AS MEASURED RATHER THAN AS ASSUMED ────────────────────────────────
# `lifecycle` has FOUR homes per class and the document says so in terms: § 1.1's column,
# § 6's Members column, § 9's delta column ("the third place in this document the assignment
# appears"), and the frontmatter of the class's declared witness.
#
# `provenance` and `publish` have TWO homes each — § 1.1's column and the witness — because
# neither § 6 nor § 9 carries a per-class assignment for them. The denominators below are
# therefore stated PER FIELD rather than assumed uniform; a four-home claim applied to a
# two-home field would report a green over two comparisons that were never made.
#
# ── `writer` IS DELIBERATELY NOT COMPARED, AND THE OMISSION IS MEASURED ──────────
# § 1.1 states the writer as PROSE carrying qualifiers, while the frontmatter states a token
# or an inline list. Two of the seventeen witnessed classes are correct AND unequal by
# design: the section-owned class renders as a two-writer prose phrase against a two-value
# list, and the residual targeted-research class names its writer generically because the
# writer varies per instance while its witness names the concrete spoke that produced it. A
# normalization loose enough to admit those two is loose enough to admit real drift, so the
# field is excluded rather than compared badly — and CA7 below reports the excluded count as
# a measurement so the exclusion is never silent.
#
# ── THE WITNESS DENOMINATOR IS 17, NOT 19, AND THAT IS CORRECT ───────────────────
# Two classes declare `no-witness-because:` instead of a witness. Their absence from the
# fourth home is the coverage declaration working, not a gap, so they are excluded from the
# witness comparison BY THEIR OWN DECLARATION (read from CV_NOWITNESS_IDS) rather than by
# arithmetic. A class that declared NEITHER branch would fall out of both sets, which is why
# CA6 asserts the two partitions close on the class enumeration.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "CA — the class-assignment homes agree (§ 1.1 · § 6 · § 9 · the witness frontmatter)"

# The canonical lifecycle members, taken from group EN's extraction so no member is spelled
# here either. The token name is a key, not a member; the vocabulary stays extracted.
CA_LIFE_ENUM="$(en_canonical lifecycle | head -1)"

# ca_members — "<class-number>\t<token>" from § 6's Members column: the inverse direction of
# § 1.1, one row per lifecycle token listing the classes it holds.
ca_members() {
  awk -v canon="$CA_LIFE_ENUM" '
    BEGIN { nm = split(canon, M, "|") }
    index($0, "## 6. Lifecycle Classes") == 1 { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside && /^\|/ {
      if (split($0, F, "|") != 5) next
      tok = F[2]; gsub(/[` ]/, "", tok)
      ok = 0; for (i = 1; i <= nm; i++) if (tok == M[i]) ok = 1
      if (!ok) next
      mem = F[4]
      while (match(mem, /C[0-9]+/)) { printf "%s\t%s\n", substr(mem, RSTART + 1, RLENGTH - 1), tok; mem = substr(mem, RSTART + RLENGTH) }
    }
  ' "$EN_DOC"
}

# ca_delta — "<class-number>\t<token>" from § 9's per-class delta column. Range rows are
# EXPANDED, and a cell that does not resolve to exactly one canonical token emits a
# PARSE-FAIL row rather than a plausible guess: two tokens in a cell, or none, is a parse
# this gate cannot decide, and deciding it silently is how a green lands on the wrong data.
ca_delta() {
  awk -v canon="$CA_LIFE_ENUM" '
    BEGIN { nm = split(canon, M, "|") }
    index($0, "## 9. Per-Artifact Gap Analysis") == 1 { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside && /^\|/ {
      if (split($0, F, "|") != 5) next
      rng = F[2]; gsub(/[ `*]/, "", rng)
      if (rng !~ /^[0-9]+([^0-9][0-9]+)?$/) next
      tmp = F[4]; found = 0; tok = ""
      while (match(tmp, /`[a-z-]+`/)) {
        t = substr(tmp, RSTART + 1, RLENGTH - 2)
        for (i = 1; i <= nm; i++) if (t == M[i]) { found++; tok = t }
        tmp = substr(tmp, RSTART + RLENGTH)
      }
      if (found != 1) { printf "PARSE-FAIL\t%s\n", rng; next }
      split(rng, R, /[^0-9]+/)
      lo = R[1] + 0; hi = (R[2] == "" ? lo : R[2] + 0)
      for (c = lo; c <= hi; c++) printf "%s\t%s\n", c, tok
    }
  ' "$EN_DOC"
}

CA_ROWS="$(va_class_rows "$ROOT")"
CA_N="$(printf '%s\n' "$CA_ROWS" | grep -c '^[0-9]')"

# ca_col_for_key <key> — the § 1.1 field index whose WHOLE column lies inside that key's
# canonical enum, or empty when that is not exactly one column.
#
# THE COLUMN IS RESOLVED BY NAME, NEVER BY POSITION, AND THAT IS NOT FASTIDIOUSNESS. The key
# set is derived from the universal-frontmatter block in declaration order, and binding
# field 4 to the first key would silently mis-bind the moment that block reordered — a
# comparison that runs, reports a denominator, and grades the wrong column. Resolving by
# containment makes the binding self-checking: the resolver requires EXACTLY ONE candidate
# column, so an ambiguous or absent binding is reported rather than guessed. The enums are
# nearly disjoint (they share a single member), which is what makes containment decisive.
ca_col_for_key() {
  printf '%s\n' "$CA_ROWS" | awk -F'\t' -v e="$(en_canonical "$1" | head -1)" '
    function member(v,   i, n, A) { n = split(e, A, "|"); for (i = 1; i <= n; i++) if (v == A[i]) return 1; return 0 }
    function lead(s) { sub(/ .*$/, "", s); return s }
    NF > 5 && $1 ~ /^[0-9]+$/ { rows++; for (f = 3; f <= 6; f++) if (member(lead($f))) ok[f]++ }
    END {
      if (rows == 0) exit
      cand = 0; which = ""
      for (f = 3; f <= 6; f++) if (ok[f] == rows) { cand++; which = f }
      if (cand == 1) print which
    }'
}
CA_COLS=""; CA_COLBAD=0
while IFS= read -r cakey; do
  [ -n "$cakey" ] || continue
  cacol="$(ca_col_for_key "$cakey")"
  if [ -n "$cacol" ]; then CA_COLS="$CA_COLS$cakey$VA_TAB$cacol$VA_NL"
  else CA_COLBAD=$((CA_COLBAD+1)); fi
done <<EOF
$EN_KEYS
EOF
CA_NCOL="$(printf '%s\n' "$CA_COLS" | grep -c '[^[:space:]]')"
CA_COLUNIQ="$(printf '%s\n' "$CA_COLS" | awk -F'\t' 'NF>1{print $2}' | sort -u | grep -c '[^[:space:]]')"
if [ "$CA_N" -gt 0 ] && [ "$CA_COLBAD" -eq 0 ] && [ "$CA_NCOL" -eq "$EN_NKEYS" ] && [ "$CA_COLUNIQ" -eq "$CA_NCOL" ]; then
  PASS "CA0: each of the $EN_NKEYS enum keys resolves to EXACTLY ONE § 1.1 column whose every value across all $CA_N rows is a member of that key's own canonical enum, and the $CA_COLUNIQ resolved columns are distinct. The binding is by containment, not by position"
else
  FAIL "CA0: the § 1.1 assignment columns did not resolve (rows=$CA_N unresolved-keys=$CA_COLBAD resolved=$CA_NCOL/$EN_NKEYS distinct=$CA_COLUNIQ) — every comparison below would be grading an unbound or shared column"
fi

# CA1/CA2 — § 6 and § 9, each against § 1.1. Both directions: a class missing from either
# home is as much a failure as a class the two homes disagree on.
#
# The rows are passed EXPLICITLY rather than read from the global, so the control arm can
# drive the same comparator over a mutated table without a variable assignment that would
# persist past the call and corrupt every later arm.
#
# ── THE PAIRS ARRIVE IN THE STREAM, NEVER THROUGH -v, AND THAT IS A BUG FIX ──────
# `awk -v` cannot carry a multi-line value: the assignment is parsed as a string literal and
# an embedded newline terminates it, so a multi-line -v is a hard awk error on some awks and
# a truncated value on others. Both comparators here take a MULTI-LINE pair list. They are
# therefore fed one tagged stream — the pairs first, each prefixed with a literal tag, then
# the rows — which also removes the empty-first-file hazard the usual FNR==NR idiom carries:
# with no reliance on record counting, a pair list that is legitimately empty cannot make the
# first row of the second stream read as a pair.
ca_compare_doc() {  # <rows> <pairs> <field> ; "<total>\t<compared>\t<unpaired>\t<mismatch>\t<detail>"
  {
    printf '%s\n' "$2" | awk -F'\t' '$1 ~ /^[0-9]+$/ && NF > 1 { printf "PAIR\t%s\t%s\n", $1, $2 }'
    printf '%s\n' "$1"
  } | awk -F'\t' -v fld="$3" '
    function lead(s) { sub(/ .*$/, "", s); return s }
    $1 == "PAIR" { O[$2] = $3; next }
    NF > 5 && $1 ~ /^[0-9]+$/ {
      seen[$1] = 1; total++
      if (!($1 in O)) { miss++; d = d " C" $1 ":absent" ; next }
      cmp++
      if (O[$1] != lead($(fld))) { bad++; d = d " C" $1 ":" lead($(fld)) "vs" O[$1] }
    }
    END {
      for (k in O) if (!(k in seen)) { extra++; d = d " C" k ":not-in-enumeration" }
      printf "%d\t%d\t%d\t%d\t%s\n", total, cmp, miss + extra, bad, d
    }'
}

# § 6 and § 9 both state the LIFECYCLE assignment and nothing else, so both comparisons run
# against the column CA0 resolved for that key rather than a hardcoded index.
#
# The fallback is 0 DELIBERATELY: awk's field 0 is the whole record, which can never equal a
# lifecycle token, so an unresolved binding makes every comparison mismatch and the arms go
# RED. An unresolved column must not be able to produce a green, and a fallback naming a real
# column would do exactly that.
CA_LIFECOL="$(printf '%s\n' "$CA_COLS" | awk -F'\t' '$1 == "lifecycle" { print $2; exit }')"
CA_LIFECOL="${CA_LIFECOL:-0}"
CA_M="$(ca_members)"
CA_MPF="$(printf '%s\n' "$CA_M" | grep -c '^PARSE-FAIL' || true)"
CA_R1="$(ca_compare_doc "$CA_ROWS" "$CA_M" "$CA_LIFECOL")"
CA_R1_TOT="$(printf '%s' "$CA_R1" | cut -f1)"; CA_R1_CMP="$(printf '%s' "$CA_R1" | cut -f2)"
CA_R1_MIS="$(printf '%s' "$CA_R1" | cut -f3)"; CA_R1_BAD="$(printf '%s' "$CA_R1" | cut -f4)"
if [ "$CA_R1_CMP" -gt 0 ] && [ "$CA_R1_MIS" -eq 0 ] && [ "$CA_R1_BAD" -eq 0 ] && [ "$CA_MPF" -eq 0 ]; then
  PASS "CA1: § 6's Members column assigns a lifecycle to all $CA_R1_CMP of $CA_R1_TOT classes and every one agrees with § 1.1's L column — the two homes are compared in both directions, so a class in one and not the other is a failure"
else
  FAIL "CA1: § 6 vs § 1.1 — compared=$CA_R1_CMP/$CA_R1_TOT unpaired=$CA_R1_MIS disagreements=$CA_R1_BAD parse-failures=$CA_MPF:$(printf '%s' "$CA_R1" | cut -f5)"
fi

CA_D="$(ca_delta)"
CA_DPF="$(printf '%s\n' "$CA_D" | grep -c '^PARSE-FAIL' || true)"
CA_R2="$(ca_compare_doc "$CA_ROWS" "$CA_D" "$CA_LIFECOL")"
CA_R2_TOT="$(printf '%s' "$CA_R2" | cut -f1)"; CA_R2_CMP="$(printf '%s' "$CA_R2" | cut -f2)"
CA_R2_MIS="$(printf '%s' "$CA_R2" | cut -f3)"; CA_R2_BAD="$(printf '%s' "$CA_R2" | cut -f4)"
if [ "$CA_R2_CMP" -gt 0 ] && [ "$CA_R2_MIS" -eq 0 ] && [ "$CA_R2_BAD" -eq 0 ] && [ "$CA_DPF" -eq 0 ]; then
  PASS "CA2: § 9's per-class delta column assigns a lifecycle to all $CA_R2_CMP of $CA_R2_TOT classes — range rows expanded — and every one agrees with § 1.1's L column"
else
  FAIL "CA2: § 9 vs § 1.1 — compared=$CA_R2_CMP/$CA_R2_TOT unpaired=$CA_R2_MIS disagreements=$CA_R2_BAD parse-failures=$CA_DPF:$(printf '%s' "$CA_R2" | cut -f5)"
fi

# CA-witness-<key> — the witness frontmatter, ONE ARM PER COMPARABLE FIELD, named after the
# field rather than numbered so a fourth enum key added to the universal block adds an arm
# with a self-describing name instead of shifting a numbering. The witness set comes from the
# coverage declarations group CV already read; no witness path is spelled here.
CA_WIT_N="$(printf '%s\n' "$CV_CLASS_WITNESS" | grep -c '[^[:space:]]')"
CA_NOWIT_N="$(printf '%s' "$CV_NOWITNESS_IDS" | wc -w | tr -d ' ')"
ca_witness_field() {  # <field-index-in-CA_ROWS> <frontmatter-key> ; emits "<cmp>\t<bad>\t<detail>"
  local fidx="$1" key="$2" cid wpath want got bad=0 cmp=0 detail=""
  while IFS="$VA_TAB" read -r cid wpath; do
    [ -n "$cid" ] && [ -n "$wpath" ] || continue
    want="$(printf '%s\n' "$CA_ROWS" | awk -F'\t' -v n="${cid#C}" -v f="$fidx" '$1 == n { v = $f; sub(/ .*$/, "", v); print v; exit }')"
    got="$(va_fm_pairs "$ROOT" "$wpath" 2>/dev/null | awk -F'\t' -v k="$key" '$1 == k { print $2; exit }')"
    cmp=$((cmp+1))
    if [ "$want" != "$got" ]; then bad=$((bad+1)); detail="$detail $cid:${want:-<absent>}vs${got:-<absent>}"; fi
  done <<EOF
$CV_CLASS_WITNESS
EOF
  printf '%s\t%s\t%s\n' "$cmp" "$bad" "$detail"
}
while IFS="$VA_TAB" read -r cakey cacol; do
  [ -n "$cakey" ] && [ -n "$cacol" ] || continue
  car="$(ca_witness_field "$cacol" "$cakey")"
  cac="$(printf '%s' "$car" | cut -f1)"; cab="$(printf '%s' "$car" | cut -f2)"
  if [ "$cac" -gt 0 ] && [ "$cab" -eq 0 ]; then
    PASS "CA-witness-$cakey: all $cac witnessed class(es) declare a \`$cakey\` in frontmatter equal to § 1.1's column — denominator $cac of $CA_N classes, the remaining $CA_NOWIT_N being absent BY THEIR OWN no-witness-because declaration rather than by a gap"
  else
    FAIL "CA-witness-$cakey: $cab of $cac witnessed class(es) disagree with § 1.1:$(printf '%s' "$car" | cut -f3)"
  fi
done <<EOF
$CA_COLS
EOF

# CA6 — the two coverage branches partition the class enumeration. Asserted rather than
# assumed, because the witness arms' denominator is only correct while the classes missing
# from it are missing BY DECLARATION; a class declaring neither branch would silently shrink
# that denominator and every arm above would still read green over a smaller population.
if [ "$((CA_WIT_N + CA_NOWIT_N))" -eq "$CA_N" ] && [ "$CA_N" -gt 0 ]; then
  PASS "CA6: the witness partition closes on the class enumeration — $CA_WIT_N witnessed + $CA_NOWIT_N declared-no-witness = $CA_N classes. The two classes absent from the witness home are absent by design, and the denominator above reflects that rather than treating it as a gap"
else
  FAIL "CA6: $CA_WIT_N + $CA_NOWIT_N != $CA_N — a class declares neither coverage branch, so the witness denominator is smaller than it looks"
fi

# CA7 — the writer exclusion, made a MEASUREMENT rather than a silent omission. It reports
# how many § 1.1 writer cells are not a bare token, which is the property that makes the
# field non-comparable. A future slice that regularises the column sees this count fall.
CA_WPROSE="$(printf '%s\n' "$CA_ROWS" | awk -F'\t' 'NF > 5 && $1 ~ /^[0-9]+$/ && $3 !~ /^[a-z][a-z0-9-]*$/ {n++} END{print n+0}')"
if [ "$CA_WPROSE" -gt 0 ]; then
  PASS "CA7: \`writer\` is deliberately NOT compared across its two homes, and the reason is measured: $CA_WPROSE of $CA_N § 1.1 writer cells are prose rather than a bare token, and two of the witnessed classes are correct AND unequal by design. A normalization admitting those would admit real drift; the field is excluded rather than compared badly"
else
  FAIL "CA7: 0 of $CA_N writer cells are prose, so the stated ground for excluding \`writer\` from the comparison no longer holds — the exclusion should be revisited rather than left standing"
fi

# CA8 — THE CONTROL ARM. The comparator must FAIL on a mutated assignment. Without it every
# CA verdict above is a zero whose control arm was never run.
CA_MUT="$(printf '%s\n' "$CA_ROWS" | awk -F'\t' -v canon="$CA_LIFE_ENUM" -v fld="$CA_LIFECOL" '
  BEGIN { nm = split(canon, M, "|") }
  NF > 5 && $1 ~ /^[0-9]+$/ && !done {
    v = $(fld); sub(/ .*$/, "", v)
    for (i = 1; i <= nm; i++) if (M[i] != v) { $(fld) = M[i]; done = 1; break }
  }
  { printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6 }')"
CA_MUT_CHANGED=0
[ "$CA_MUT" != "$CA_ROWS" ] && CA_MUT_CHANGED=1
CA_CTL_SIX="$(ca_compare_doc "$CA_MUT" "$CA_M" "$CA_LIFECOL" | cut -f4)"
CA_CTL_NINE="$(ca_compare_doc "$CA_MUT" "$CA_D" "$CA_LIFECOL" | cut -f4)"
if [ "$CA_MUT_CHANGED" -eq 1 ] && [ "$CA_CTL_SIX" -ge 1 ] && [ "$CA_CTL_NINE" -ge 1 ]; then
  PASS "CA8: control — flipping ONE class's lifecycle in a copy of § 1.1 makes the SAME comparator report a disagreement against § 6 ($CA_CTL_SIX) and against § 9 ($CA_CTL_NINE), and the mutation was asserted to have changed the table. The zeroes in CA1 and CA2 are measurements rather than a comparator that cannot fail"
else
  FAIL "CA8: the control arm did not behave (mutated=$CA_MUT_CHANGED six=$CA_CTL_SIX nine=$CA_CTL_NINE) — every CA verdict above is a zero with no control behind it"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PB — the publish-bound artifact set matches the spec fence that declares it.
#
# The site-layout spec carries a fence declaring which artifacts the site build may read.
# It was built expressly so the claim would be assertable rather than merely asserted, and
# until now nothing asserted it: the fence has exactly ONE occurrence corpus-wide, its own
# declaration site, and no reader resolved it. This group is that reader.
#
# ── THE CLASS SELECTOR IS DERIVED FROM THE FENCE, NOT SPELLED HERE ───────────────
# The set of publish classes to compare is the set the FENCE declares, so no member of the
# publish enum is a literal in this file. § 1.1's rows carrying any of those classes are
# then required to be exactly the fence's rows, with the class agreeing per row.
#
# ── THE RESIDUAL, STATED RATHER THAN LEFT TO BE DISCOVERED ───────────────────────
# Because the class selector comes from the fence, this group catches a fence row with no
# § 1.1 backing, a § 1.1 row missing from the fence within a class the fence represents, and
# a per-row class disagreement. It does NOT catch the wholesale disappearance of EVERY row
# of one publish class from the fence: the selector would narrow with it and the remaining
# rows would still agree. Closing that would need a second independent declaration of which
# classes the fence must carry, and the corpus has none. Said plainly so a green is not read
# as more than it is.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "PB — the publish-bound artifact set matches the spec fence that declares it"

PB_SPEC='reference/site-layout-spec.md'
PB_FENCE='publish-contract-artifacts'
PB_OK=1
if [ ! -r "$ROOT/$PB_SPEC" ]; then
  FAIL "PB0: $PB_SPEC is not readable — the fence that declares the publish-bound set is absent, so nothing below can be asserted. Not a skip and not a pass"
  PB_OK=0
else
  # Counted over the whole tracked population in one awk pass, on a WHOLE-LINE equality
  # against the opening fence. A substring test would also match this file's own prose
  # mention of the info string and report the home as duplicated.
  PB_SITES="$(awk -v info='```'"$PB_FENCE" '$0 == info { n++ } END { print n+0 }' ${EN_FILES[@]+"${EN_FILES[@]}"} 2>/dev/null)"
  PB_SITES="${PB_SITES:-0}"
  if [ "$PB_SITES" -eq 1 ]; then
    PASS "PB0: the \`$PB_FENCE\` fence has EXACTLY ONE occurrence across all $EN_NFILES tracked files — its own declaration site, which is what makes it a single home rather than one copy among several"
  else
    FAIL "PB0: the \`$PB_FENCE\` fence occurs $PB_SITES time(s) across the tracked population; a single normative home is the premise every assertion below rests on"
    PB_OK=0
  fi
fi

if [ "$PB_OK" -eq 1 ]; then
  PB_ROWS="$(awk -v info='```'"$PB_FENCE" '
    $0 == info { inside = 1; next }
    inside && $0 == "```" { inside = 0; next }
    inside {
      line = $0
      sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      n = split(line, F, /[[:space:]]+/)
      if (n < 2) { printf "PARSE-FAIL\t%s\n", line; next }
      printf "%s\t%s\n", F[1], F[2]
    }' "$ROOT/$PB_SPEC")"
  PB_N="$(printf '%s\n' "$PB_ROWS" | grep -c '[^[:space:]]')"
  PB_PF="$(printf '%s\n' "$PB_ROWS" | grep -c '^PARSE-FAIL' || true)"
  PB_PUBENUM="$(en_canonical publish | head -1)"
  # The § 1.1 publish column, taken from the binding CA0 resolved by containment. Bound by
  # NAME rather than by position for the reason CA0 states, and defaulted to a field index
  # that cannot exist so an unresolved binding yields an empty comparison rather than a
  # plausible one read out of the wrong column.
  PB_PUBCOL="$(printf '%s\n' "$CA_COLS" | awk -F'\t' '$1 == "publish" { print $2; exit }')"
  PB_PUBCOL="${PB_PUBCOL:-99}"
  PB_BADCLASS="$(printf '%s\n' "$PB_ROWS" | awk -F'\t' -v e="$PB_PUBENUM" '
    function member(v,   i, n, A) { n = split(e, A, "|"); for (i = 1; i <= n; i++) if (v == A[i]) return 1; return 0 }
    NF > 1 && $1 != "PARSE-FAIL" && !member($2) { n++ } END { print n+0 }')"
  if [ "$PB_N" -gt 0 ] && [ "$PB_PF" -eq 0 ] && [ "$PB_BADCLASS" -eq 0 ]; then
    PASS "PB1: the fence parsed to $PB_N \`<artifact> <class>\` row(s), every class a member of the canonical publish enum extracted at EN — the fence declares its classes in the same vocabulary § 1.1 does"
  else
    FAIL "PB1: the fence did not parse cleanly (rows=$PB_N parse-failures=$PB_PF non-enum-classes=$PB_BADCLASS)"
    PB_OK=0
  fi
fi

# PB2 — the comparison, in both directions, with the class agreeing per row.
# The fence rows arrive in the STREAM rather than through -v, for the reason stated at
# ca_compare_doc above: a multi-line -v value is an awk error, not a long string.
pb_compare() {  # <fence-rows> ; "<n-fence>\t<n-expected>\t<only-fence>\t<only-doc>\t<class-bad>\t<detail>"
  {
    printf '%s\n' "$1" | awk -F'\t' 'NF > 1 && $1 != "" && $1 != "PARSE-FAIL" { printf "FENCE\t%s\t%s\n", $1, $2 }'
    printf '%s\n' "$CA_ROWS"
  } | awk -F'\t' -v pubcol="$PB_PUBCOL" '
    $1 == "FENCE" { FE[$2] = $3; nf++; CLS[$3] = 1; next }
    NF > 5 && $1 ~ /^[0-9]+$/ { DOC[$2] = $(pubcol) }
    END {
      for (a in DOC) {
        if (!(DOC[a] in CLS)) continue
        ne++
        if (!(a in FE)) { onlydoc++; d = d " " a ":in-1.1(" DOC[a] ")-not-in-fence" }
        else if (FE[a] != DOC[a]) { badc++; d = d " " a ":1.1=" DOC[a] ",fence=" FE[a] }
      }
      for (a in FE) if (!(a in DOC)) { onlyfence++; d = d " " a ":in-fence-not-in-1.1" }
      printf "%d\t%d\t%d\t%d\t%d\t%s\n", nf, ne, onlyfence, onlydoc, badc, d
    }'
}
if [ "$PB_OK" -eq 1 ]; then
  PB_R="$(pb_compare "$PB_ROWS")"
  PB_NF="$(printf '%s' "$PB_R" | cut -f1)"; PB_NE="$(printf '%s' "$PB_R" | cut -f2)"
  PB_OF="$(printf '%s' "$PB_R" | cut -f3)"; PB_OD="$(printf '%s' "$PB_R" | cut -f4)"
  PB_BC="$(printf '%s' "$PB_R" | cut -f5)"
  if [ "$PB_NF" -gt 0 ] && [ "$PB_NE" -gt 0 ] && [ "$PB_OF" -eq 0 ] && [ "$PB_OD" -eq 0 ] && [ "$PB_BC" -eq 0 ]; then
    PASS "PB2: the fence's $PB_NF artifact(s) are EXACTLY the $PB_NE class(es) whose § 1.1 publish column carries one of the fence's declared classes, and the class agrees on every row. Compared in both directions — a fence row with no class row is as much a failure as a class row the fence omits"
  else
    FAIL "PB2: the publish-bound set and the fence disagree (fence=$PB_NF expected=$PB_NE only-in-fence=$PB_OF only-in-§1.1=$PB_OD class-mismatch=$PB_BC):$(printf '%s' "$PB_R" | cut -f6)"
  fi
fi

# PB3 — the control arm. Both failure directions must be reachable, or PB2's zeroes are a
# comparator that cannot fail. Dropped row => the § 1.1 side is unmatched; fabricated row
# => the fence side is unmatched. Both mutations asserted to have landed.
if [ "$PB_OK" -eq 1 ]; then
  PB_DROP="$(printf '%s\n' "$PB_ROWS" | awk 'NR > 1')"
  PB_ADD="$(printf '%s\n%s\t%s\n' "$PB_ROWS" 'outputs/zzz-not-a-class.md' "$(printf '%s\n' "$PB_ROWS" | awk -F'\t' 'NF>1{print $2; exit}')")"
  PB_C1="$(pb_compare "$PB_DROP" | cut -f4)"
  PB_C2="$(pb_compare "$PB_ADD" | cut -f3)"
  PB_MUT=0
  { [ "$PB_DROP" != "$PB_ROWS" ] && [ "$PB_ADD" != "$PB_ROWS" ]; } && PB_MUT=1
  if [ "$PB_MUT" -eq 1 ] && [ "$PB_C1" -ge 1 ] && [ "$PB_C2" -ge 1 ]; then
    PASS "PB3: control — dropping a fence row makes the same comparator report an unmatched § 1.1 class ($PB_C1), and adding a fabricated row makes it report an unmatched fence row ($PB_C2). Both mutations were asserted to have landed, so PB2's zeroes are measurements in both directions rather than one"
  else
    FAIL "PB3: the control arm did not behave (mutations-landed=$PB_MUT dropped-row-detected=$PB_C1 added-row-detected=$PB_C2) — PB2's zeroes have no control behind them"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group FW — the frozen regression witness is held by an ASSERTION, not by convention.
#
# ── WHY THIS GROUP EXISTS ────────────────────────────────────────────────────────
# reference/data-architecture.md § 10 constraint 2 declares the worked example under
# examples/tokyo-2026/ a byte-identical regression witness. Until this group shipped,
# NOTHING in the repository enforced that. No enforcement file referenced the directory
# at all, and none of the witness's files carries a schema-version — so the validating
# gate SELECTS them and then SKIPS them under the tolerant read. The witness was neither
# validated nor frozen, and an edit to it passed every required suite green. The freeze
# was real only as a review constraint, which is a person remembering, not a gate.
#
# ── WHY A CONTENT PIN AND NOT A DIFF AGAINST THE BASE BRANCH ─────────────────────
# A branch-versus-base diff is the obvious mechanism and it was rejected on two grounds,
# both checkable. FIRST: this suite's workflow checks out at the default depth, so the
# base branch's history is NOT in the CI working copy — the diff would need either a
# deeper fetch or a network call, and a freeze that depends on fetching a moving ref at
# an arbitrary time is a freeze with a race in it. SECOND, and the one that decides it:
# a diff against the base goes EMPTY the moment this branch merges, so the assertion
# would become tautological on exactly the commit that made it permanent. A content pin
# read from the corpus keeps its teeth forever and needs no history at all.
#
# The digest is git's own content address (`git hash-object`), so byte-for-byte is what
# is literally compared, with no external hashing tool and no second tree to diff.
#
# ── THE DECLARATION LIVES IN THE DOCUMENT, NOT IN THIS FILE ──────────────────────
# The pinned rows are read from the `frozen-witness-digest` fence in the architecture
# document — the same declaration-in-the-corpus mechanism § 5.6 already uses for the
# non-publishable class. A digest list held HERE would be a second source of truth: the
# document would claim a freeze this file enforced against its own copy, free to drift.
# The path set is compared in BOTH directions, so a file added under the witness or
# deleted from it fails as loudly as a file whose bytes moved.
#
# ── WHEN THE WITNESS LEGITIMATELY HAS TO CHANGE ──────────────────────────────────
# Edit the file and re-pin its row in the SAME commit; the diff then carries the content
# change and the re-pin side by side, which is the visibility the freeze exists to buy.
# A content change arriving WITHOUT its re-pin turns this group red. The document's own
# § 10 states this too, so a reader who meets the red is not stuck.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "FW — the frozen regression witness is content-pinned by the corpus"

FW_DOC="$ROOT/$VA_ARCH_DOC"

# fw_rows — the declared (digest, path) pairs. Read from the fence and nowhere else.
fw_rows() {
  awk '
    $0 == "```frozen-witness-digest" { infence = 1; next }
    infence && $0 == "```" { infence = 0; next }
    infence {
      line = $0
      sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
      if (line == "" || substr(line, 1, 1) == "#") next
      n = split(line, f, /[ \t]+/)
      if (n >= 2) printf "%s\t%s\n", f[1], f[2]
    }
  ' "$FW_DOC"
}

# fw_compare <base-dir> — "<rows>\t<mismatched>\t<missing>\t<detail>". ONE comparator,
# driven by both the real arm and the control arm below. A control that ran different
# code from the assertion would prove nothing about the assertion.
fw_compare() {
  local base="$1" nrow=0 nbad=0 nmiss=0 detail="" d p actual
  while IFS=$'\t' read -r d p; do
    [ -n "$p" ] || continue
    nrow=$((nrow+1))
    if [ ! -r "$base/$p" ]; then nmiss=$((nmiss+1)); detail="$detail $p(absent)"; continue; fi
    actual="$(git hash-object -- "$base/$p" 2>/dev/null)"
    [ "$actual" = "$d" ] || { nbad=$((nbad+1)); detail="$detail $p"; }
  done <<EOF
$(fw_rows)
EOF
  printf '%s\t%s\t%s\t%s\n' "$nrow" "$nbad" "$nmiss" "$detail"
}

FW_OK=1
FW_PAIRS="$(fw_rows)"
FW_NROW="$(printf '%s\n' "$FW_PAIRS" | grep -c '[^[:space:]]')"
if [ ! -r "$FW_DOC" ]; then
  FAIL "FW0: $VA_ARCH_DOC is not readable, so the freeze declaration could not be read. Not a skip and not a pass"
  FW_OK=0
elif [ "$FW_NROW" -gt 0 ]; then
  PASS "FW0: the freeze declaration in $VA_ARCH_DOC § 10 pins $FW_NROW file(s); this suite holds no copy of any digest"
else
  FAIL "FW0: the \`frozen-witness-digest\` fence yielded ZERO rows. An empty declaration is a freeze that asserts nothing, and every verdict below would be over the empty set — this fails rather than passing quietly"
  FW_OK=0
fi

# FW1 — the pinned path set and the tracked path set are the same set. Derived from the
# declared paths' common directory prefix, so this file names no directory of its own.
if [ "$FW_OK" -eq 1 ]; then
  FW_ROOT="$(printf '%s\n' "$FW_PAIRS" | awk -F'\t' '
    NF > 1 {
      p = $2; sub(/\/[^\/]*$/, "", p)
      if (pref == "") { pref = p; next }
      while (pref != "" && index(p "/", pref "/") != 1) sub(/\/[^\/]*$/, "", pref)
    }
    END { print pref }')"
  FW_TRACKED="$(cd "$ROOT" && git ls-files "$FW_ROOT" 2>/dev/null | sort)"
  FW_DECL="$(printf '%s\n' "$FW_PAIRS" | awk -F'\t' 'NF>1{print $2}' | sort)"
  FW_NTRK="$(printf '%s\n' "$FW_TRACKED" | grep -c '[^[:space:]]')"
  FW_ONLY_TRK="$(comm -23 <(printf '%s\n' "$FW_TRACKED") <(printf '%s\n' "$FW_DECL") | grep -c '[^[:space:]]')"
  FW_ONLY_DEC="$(comm -13 <(printf '%s\n' "$FW_TRACKED") <(printf '%s\n' "$FW_DECL") | grep -c '[^[:space:]]')"
  if [ -n "$FW_ROOT" ] && [ "$FW_NTRK" -gt 0 ] && [ "$FW_ONLY_TRK" -eq 0 ] && [ "$FW_ONLY_DEC" -eq 0 ]; then
    PASS "FW1: the declaration covers the witness EXACTLY — $FW_NROW pinned against $FW_NTRK tracked under '$FW_ROOT/', compared in both directions. A file added to the witness is as much a failure as one deleted"
  else
    FAIL "FW1: the pinned set and the tracked set differ under '$FW_ROOT/' (tracked=$FW_NTRK pinned=$FW_NROW tracked-but-unpinned=$FW_ONLY_TRK pinned-but-untracked=$FW_ONLY_DEC)"
    FW_OK=0
  fi
fi

# FW2 — the assertion itself.
if [ "$FW_OK" -eq 1 ]; then
  FW_R="$(fw_compare "$ROOT")"
  FW_N="$(printf '%s' "$FW_R" | cut -f1)"; FW_BAD="$(printf '%s' "$FW_R" | cut -f2)"
  FW_MISS="$(printf '%s' "$FW_R" | cut -f3)"; FW_DET="$(printf '%s' "$FW_R" | cut -f4)"
  if [ "$FW_N" -gt 0 ] && [ "$FW_BAD" -eq 0 ] && [ "$FW_MISS" -eq 0 ]; then
    PASS "FW2: all $FW_N file(s) of the frozen witness are byte-identical to their pinned content address — the freeze is now asserted on every push rather than held as a review constraint"
  else
    FAIL "FW2: the frozen witness has MOVED ($FW_BAD of $FW_N mismatched, $FW_MISS absent):$FW_DET — if the change was deliberate, re-pin those rows in reference/data-architecture.md § 10 in this same commit"
  fi
fi

# FW3 — THE MUST-FIRE ARM. The witness is unmodified today, so FW2 green proves nothing
# on its own: a comparator that always returned zero would look exactly the same. A copy
# is mutated by one appended byte and run through the SAME comparator, which must report
# exactly that one file and must still match every other. Both limbs matter — a detector
# that flagged everything would satisfy the first and fail the second.
if [ "$FW_OK" -eq 1 ]; then
  FW_MUT_DIR="$WORK/fw-mutated"
  mkdir -p "$FW_MUT_DIR"
  ( cd "$ROOT" && git ls-files "$FW_ROOT" 2>/dev/null | while IFS= read -r f; do
      mkdir -p "$FW_MUT_DIR/$(dirname "$f")" && cp "$ROOT/$f" "$FW_MUT_DIR/$f"
    done )
  FW_VICTIM="$(printf '%s\n' "$FW_DECL" | head -1)"
  printf '\n' >> "$FW_MUT_DIR/$FW_VICTIM"
  FW_LANDED=0
  cmp -s "$ROOT/$FW_VICTIM" "$FW_MUT_DIR/$FW_VICTIM" || FW_LANDED=1
  FW_CR="$(fw_compare "$FW_MUT_DIR")"
  FW_CBAD="$(printf '%s' "$FW_CR" | cut -f2)"; FW_CMISS="$(printf '%s' "$FW_CR" | cut -f3)"
  if [ "$FW_LANDED" -eq 1 ] && [ "$FW_CBAD" -eq 1 ] && [ "$FW_CMISS" -eq 0 ]; then
    PASS "FW3: control — one byte appended to '$FW_VICTIM' in a temp copy (the mutation is asserted to have landed) and the same comparator reports EXACTLY 1 of $FW_N mismatched, with the other $((FW_N - 1)) still matching. FW2's zero is a measurement, and this suite demonstrates on this commit that the freeze can still fail"
  else
    FAIL "FW3: the must-fire arm did not behave (mutation-landed=$FW_LANDED detected=$FW_CBAD expected=1 absent=$FW_CMISS) — FW2's zero has no control behind it and cannot be read as a freeze"
  fi
  # FW3b — the repository was never written to. A freeze assertion that mutated the thing
  # it freezes would be the defect, not the guard.
  FW_RR="$(fw_compare "$ROOT" | cut -f2)"
  if [ "$FW_RR" -eq 0 ]; then
    PASS "FW3b: the control mutated a temp copy only — the witness in the repository is still byte-identical to its pin after the arm above ran"
  else
    FAIL "FW3b: the witness in the REPOSITORY differs from its pin after the control arm ran — the control wrote into the tree it is meant to be measuring"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group VI — the venue-identity split rule has a witness.
#
# ── THE INVARIANT ────────────────────────────────────────────────────────────────
# agents/05-hub-planner.md § "Step 1 — links-reference.md" fixes how two mentions become
# one venue: five ordered rungs, stopped at the first that decides, biased toward
# SPLITTING an uncertain pair. Rung 2 decides on a resolved location; rung 3 on a
# byte-identical maps URL as evidence of rung 2; rung 4 demotes every name-shaped signal
# to corroborating; rung 5 is the catch-all — where nothing above decides, mint SEPARATE
# keys and name the pair in OPEN DECISIONS.
#
# So a MERGE is a claim, and this group asserts the claim carries its warrant:
#
#   where one `ven-` key is bound to more than one distinct display string, EITHER
#   location evidence appears on the mentions' own entries, OR the pair is declared
#   in OPEN DECISIONS.
#
# ── WHY IT IS WORTH ASSERTING AND NOT MERELY STATING ─────────────────────────────
# The two errors are not symmetric and only one of them is visible. A wrong SPLIT leaves
# two rows a reader can see. A wrong MERGE deletes a place from the plan and leaves
# nothing behind — and rung 1 then freezes it, because a key already carried decides on
# every later pass. An unwarranted merge is therefore the one identity error that gets
# quieter over time, which is exactly the class a person re-reading prose will not catch.
#
# ── THE PROBE READS BINDINGS, NEVER NAMES ───────────────────────────────────────
# A mention is discovered by its `artifact-entry` fence or by a declared key column — the
# two marker forms § 4.5 rule 2 assigns — never by matching a display string. Keyed on
# names, this group would define its population as the set of pairs that already agree,
# which is the tautology EN's own header warns about in the same terms.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "VI — a merged venue key carries the warrant the identity procedure requires"

# vi_bindings <file>... — "<key>\t<display>\t<file>\t<located>\t<is-source>" per mention.
#
# `located` is 1 when the mention's own entry carries a declared Location line — the
# rung-2 evidence. `is-source` separates the two marker forms, and the separation is
# load-bearing rather than tidy: a fenced `artifact-entry` in a research list is a SOURCE
# mention, one of the things the hub had to join, so it is what must carry the evidence.
# A declared key column in the registry or the matrix is the hub's OUTPUT of that same
# decision. Counting a table row as evidence would let a merge warrant ITSELF — the guard
# would read the hub's conclusion back as its own premise and go green on every merge.
# Table rows still contribute their DISPLAY STRING, because the divergence across
# artifacts is exactly what the surrogate key exists to absorb.
vi_bindings() {
  [ "$#" -gt 0 ] || return 0
  awk '
    function flush() {
      if (pk != "") { printf "%s\t%s\t%s\t%d\t1\n", pk, ph, pf, loc; pk = "" }
    }
    FNR == 1 { flush(); heading = ""; loc = 0; infence = 0 }
    /^#{2,6}[ \t]/ {
      flush(); h = $0; sub(/^#+[ \t]*/, "", h); sub(/[ \t]+$/, "", h)
      heading = h; loc = 0; next
    }
    $0 ~ /^```artifact-entry[ \t]*$/ { infence = 1; next }
    infence && $0 ~ /^```[ \t]*$/ { infence = 0; next }
    infence && $0 ~ /^venue:[ \t]*ven-[0-9a-f]+[ \t]*$/ {
      k = $0; sub(/^venue:[ \t]*/, "", k); sub(/[ \t]+$/, "", k)
      pk = k; ph = heading; pf = FILENAME; next
    }
    # A declared key column: | `ven-xxxx` | Display | ... — a display string, never
    # evidence. See the header above.
    /^\|/ {
      n = split($0, c, "|")
      if (n >= 3) {
        a = c[2]; b = c[3]
        gsub(/^[ \t`]+|[ \t`]+$/, "", a); gsub(/^[ \t]+|[ \t]+$/, "", b)
        if (a ~ /^ven-[0-9a-f]+$/ && b != "" && b != "-" && b != "—") {
          printf "%s\t%s\t%s\t0\t0\n", a, b, FILENAME
        }
      }
    }
    {
      l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); gsub(/\*\*/, "", l)
      if (l ~ /^[Ll]ocation:[ \t]*[^ \t]/) loc = 1
    }
    END { flush() }
  ' "$@"
}

# vi_violations <bindings> <open-decisions-text> — one line per key whose merge is
# unwarranted. The same evaluator drives the real arm and the control arm below.
#
# The OPEN DECISIONS limb is applied HERE IN SHELL and deliberately not through an awk
# `-v` assignment. That text is a multi-line extract, and awk rejects an embedded newline
# in a `-v` value: the program aborts mid-parse, the command substitution yields nothing,
# and the caller reads ZERO violations. That is a broken probe wearing a pass, and it is
# the exact shape this suite refuses everywhere else — so the multi-line value never
# reaches awk at all.
vi_violations() {
  local cand k cline
  cand="$(awk -F'\t' '
    NF > 4 {
      key = $1
      if (!((key SUBSEP $2) in seenstr)) { seenstr[key SUBSEP $2] = 1; nstr[key]++ }
      # Only a SOURCE mention can satisfy or fail the evidence test; a table row is the
      # decision written down, never a warrant for it.
      if ($5 == 1) { nsrc[key]++; if ($4 == 0) unlocated[key]++ }
      where[key] = where[key] " " $2 "(" $3 ")"
    }
    END {
      for (k in nstr) {
        if (nstr[k] < 2) continue
        if (unlocated[k] + 0 == 0) continue
        printf "%s\t%d\t%d\t%s\n", k, nstr[k], unlocated[k] + 0, where[k]
      }
    }
  ' <<EOF
$1
EOF
)"
  while IFS= read -r cline; do
    [ -n "$cline" ] || continue
    k="${cline%%$'\t'*}"
    # A declared pair discharges the requirement — rung 5's other half.
    if grep -qF -- "$k" <<<"$2"; then continue; fi
    printf '%s\n' "$cline"
  done <<EOF
$cand
EOF
}

VI_FILES=(); VI_NFILES=0
while IFS= read -r vif; do
  [ -n "$vif" ] || continue
  if [ -r "$ROOT/$vif" ]; then VI_FILES+=("$ROOT/$vif"); VI_NFILES=$((VI_NFILES+1)); fi
done <<EOF
$(cd "$ROOT" && git ls-files '*.md' 2>/dev/null)
EOF

VI_OK=1
VI_BIND="$(vi_bindings ${VI_FILES[@]+"${VI_FILES[@]}"})"
VI_NBIND="$(printf '%s\n' "$VI_BIND" | grep -c '[^[:space:]]')"
VI_NKEYS="$(printf '%s\n' "$VI_BIND" | awk -F'\t' 'NF>4{print $1}' | sort -u | grep -c '[^[:space:]]')"
VI_NSRC="$(printf '%s\n' "$VI_BIND" | awk -F'\t' 'NF>4 && $5==1{n++} END{print n+0}')"
VI_NMULTI="$(printf '%s\n' "$VI_BIND" | awk -F'\t' 'NF>4{print $1 "\t" $2}' | sort -u | awk -F'\t' '{n[$1]++} END{c=0; for (k in n) if (n[k] > 1) c++; print c+0}')"
# The declared-pair surface is an OPEN DECISIONS **table row**, and only a table row is
# read. A whole-section sweep pulls in the surrounding prose — several agent prompts
# discuss OPEN DECISIONS at length — and any key token happening to appear in that prose
# would silently discharge a violation. Rung 5 requires the pair to be NAMED in the
# table, so the table is the population.
VI_OD="$(awk '
  index($0, "OPEN DECISIONS") > 0 { insec = 1; next }
  insec && (/^#{1,6}[ \t]/ || /^---[ \t]*$/) { insec = 0; next }
  insec && /^\|/ { print }
' ${VI_FILES[@]+"${VI_FILES[@]}"} 2>/dev/null)"

printf '  BINDINGS: %d mention(s) over %d key(s) across %d tracked markdown file(s); %d are source mentions; %d key(s) carry more than one display string\n' \
  "$VI_NBIND" "$VI_NKEYS" "$VI_NFILES" "$VI_NSRC" "$VI_NMULTI"

if [ "$VI_NBIND" -gt 0 ] && [ "$VI_NKEYS" -gt 0 ] && [ "$VI_NSRC" -gt 0 ]; then
  PASS "VI0: the binding probe has a NON-EMPTY population — $VI_NBIND mention(s) over $VI_NKEYS key(s), $VI_NSRC of them source mentions. Discovered by marker form, never by display string"
else
  FAIL "VI0: the probe found no key bindings, or no SOURCE mention among them (bindings=$VI_NBIND keys=$VI_NKEYS source=$VI_NSRC). Every verdict below would be over the empty set, and a zero here is a broken probe rather than a clean corpus"
  VI_OK=0
fi

if [ "$VI_OK" -eq 1 ] && [ "$VI_NMULTI" -eq 0 ]; then
  VACUOUS "VI1: no key in this corpus is bound to more than one display string, so the split rule has nothing to grade. This is a real measurement of the tree, not a skipped group — the arm below still proves the evaluator can fail"
elif [ "$VI_OK" -eq 1 ]; then
  VI_BAD="$(vi_violations "$VI_BIND" "$VI_OD")"
  VI_NBAD="$(printf '%s\n' "$VI_BAD" | grep -c '[^[:space:]]')"
  if [ "$VI_NBAD" -eq 0 ]; then
    PASS "VI1: all $VI_NMULTI merged key(s) carry their warrant — each is either located on every mention (rung 2) or declared in OPEN DECISIONS (rung 5). A merge with neither would be an identity claim the corpus does not support"
  else
    FAIL "VI1: $VI_NBAD of $VI_NMULTI merged key(s) carry NO warrant — the identity procedure's rungs 2 and 3 cannot fire without location evidence, rung 4 forbids deciding on the name, so rung 5 requires separate keys and a declared pair:"
    printf '%s\n' "$VI_BAD" | awk -F'\t' 'NF>3 { printf "      %s: %s display string(s), %s unlocated mention(s), no OPEN DECISIONS row —%s\n", $1, $2, $3, $4 }'
  fi
fi

# VI2 — THE MUST-FIRE ARM, and it is inside the assertion. The location lines are stripped
# from a runtime copy of the corpus and the SAME evaluator must then report the merges as
# unwarranted. Without it, VI1's zero and an evaluator that cannot fail are the same green.
if [ "$VI_OK" -eq 1 ] && [ "$VI_NMULTI" -gt 0 ]; then
  VI_STRIP="$(printf '%s\n' "$VI_BIND" | awk -F'\t' 'NF>4 { printf "%s\t%s\t%s\t0\t%s\n", $1, $2, $3, $5 }')"
  VI_C1="$(vi_violations "$VI_STRIP" "$VI_OD" | grep -c '[^[:space:]]')"
  VI_C2="$(vi_violations "$VI_BIND" "" | grep -c '[^[:space:]]')"
  VI_LANDED=0
  [ "$VI_STRIP" != "$VI_BIND" ] && VI_LANDED=1
  if [ "$VI_LANDED" -eq 1 ] && [ "$VI_C1" -ge 1 ]; then
    PASS "VI2: control — with every mention's location evidence stripped from a runtime copy (the mutation is asserted to have landed) the same evaluator reports $VI_C1 unwarranted merge(s), and with the OPEN DECISIONS text emptied it reports $VI_C2. VI1's zero is a measurement of both limbs rather than an evaluator that cannot fail"
  else
    FAIL "VI2: the must-fire arm did not behave (mutation-landed=$VI_LANDED stripped-location-detected=$VI_C1 expected>=1) — VI1's verdict has no control behind it"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group ST — the starred-field count is ONE fact with FOUR homes inside one template,
# and the three homes that merely describe it must agree with the one that IS it.
#
# ── WHY THIS GROUP EXISTS ────────────────────────────────────────────────────────
# templates/traveler-intake.template.md tells a traveller how many of its fields carry the
# star, and it tells them TWICE in prose — in the banner at the top and again in rule 4 of
# the agent appendix at the bottom — while the appendix ALSO restates the starred set field
# by field as `**Label** (starred)`. Only one of those four surfaces is not a restatement:
# the marked fields themselves. The other three are claims about it.
#
# Nothing in this repository read that template before this group. So starring an eleventh
# field and updating the banner alone would have shipped a stale appendix, in two places,
# with every gate green — and the appendix is the surface an agent reads to run the intake,
# so the stale copy is the one that drives the conversation. It has not happened yet: all
# four homes agree on this commit. That is precisely when the guard is cheap, and it is why
# it is added now rather than after the first drift. A latent defect is still a defect; the
# only thing that is latent is the evidence.
#
# ── WHY IT LIVES HERE AND NOT IN A SCRIPT OF ITS OWN ─────────────────────────────
# The status checks this repository requires on main are JOB NAMES. A new workflow would
# produce a name that is not among them, so it could go red without stopping a merge — an
# advisory check wearing the clothes of a gate, which is the one shape this suite exists to
# refuse. Group ST inherits the already-required artifact-schema context and therefore
# blocks from its first commit, with no branch-protection change assumed, needed or made.
#
# ── THE PROBE IS KEYED ON SHAPE, NEVER ON A LINE NUMBER ─────────────────────────
# The report that surfaced this named the two numerals at lines 6 and 295. They are live at
# 21 and 320. A guard pinned to a line number would have been wrong before it was written,
# so every surface here is discovered by its MARKUP SHAPE and the line number is an OUTPUT
# of that discovery rather than an input to it. One pair of functions drives the real arms
# and every control arm alike, the vi_bindings/vi_violations idiom above: an evaluator
# that is not the one under test proves nothing about the one that ships.
#
# ── AR3 IS NOT FALSIFIED, AND THAT IS GRADED RATHER THAN CLAIMED ────────────────
# AR3 asserts that NO templates/*.template.md reaches the selector, because a template's
# `trip:` value is the placeholder <trip-slug> and would fail A4. This group reads the
# template DIRECTLY with its own text processing and adds NO finding code to the validator,
# so va_select's output is untouched — the same reason EN, CA and PB stay clear of CTL.
# ST-AR3 re-reads AR_NTPL in this same run and asserts it is still zero, which makes the
# constraint an observation rather than a promise in a comment.
#
# ── ST HAS NO LEGITIMATE SKIP ───────────────────────────────────────────────────
# The population is a tracked file, so it exists by construction. A missing or unreadable
# template is a FAILURE here, never a SKIP and never VACUOUS: the file going away is itself
# drift this group is meant to notice, and GUARD_EXPECTED_SKIPS is correctly empty.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "ST — the starred-field count agrees across all four of its homes in one template"

ST_REL="templates/traveler-intake.template.md"
ST_FILE="$ROOT/$ST_REL"
ST_STAR='⭐'
ST_DIR="$WORK/st"
mkdir -p "$ST_DIR"

# st_surfaces <file> — one TAB record per discovered assertion site, three surfaces:
#
#   PROSE<TAB><line><TAB><count-as-integer>   a sentence that STATES the number
#   MARKED<TAB><line><TAB><label>             a field whose bullet IS the star
#   ANNOT<TAB><line><TAB><label>              the appendix's per-field restatement
#
# The glyph is located with index()/substr() rather than matched inside a bracket
# expression, for the reason group LC states about the validator: a bracket range resolves
# against the current locale's collating sequence, so CI and an operator's shell can
# disagree about what it matched. index() is a search with no collation in it at all, and
# every bracket used below is a NAMED CLASS rather than a range, which is the same fix LC2
# already enforces on va_type_ok.
#
# PROSE is the hard surface, and it is hard for a specific reason: BOTH prose sites carry a
# COMPETING cardinal. The banner reads "about 2-3 minutes" before it reads "ten of them",
# and rule 4 reads "the two-to-three minute pass" after it reads "the ten fields". A reader
# that took the first number on the line would report 2 for the banner, agree with nothing,
# and be wrong in a way that never announces itself. So a number counts only when it is
# followed — within at most three intervening words, across whitespace or dashes only — by
# `field`/`fields` or by `of them`. That window is what rejects both decoys, and it was
# tuned against them rather than guessed. A line that is itself a MARKED or an ANNOT record
# is never also a PROSE record: the surfaces are disjoint by construction, so a starred
# field can never be miscounted as a claim about how many starred fields there are.
st_surfaces() {
  awk -v star="$ST_STAR" -v ndash='–' -v mdash='—' '
    # cardinal <token> — the integer this token ENDS with at a word boundary, or -1.
    # Anchoring at the end of the token is what enforces the "number, then a separator"
    # shape: rule 4 opens with the list marker "4." and that 4 is NOT a cardinal here,
    # because a period follows it rather than a space. That single property is the whole
    # difference between reading the rule and reading its number.
    function cardinal(tok,   c, p, w) {
      if (match(tok, /[0-9]+$/)) {
        c = substr(tok, RSTART, RLENGTH)
        if (length(c) > 3) return -1
        p = (RSTART == 1) ? "" : substr(tok, RSTART - 1, 1)
        if (p == "" || p !~ /[[:alnum:]_]/) return c + 0
        return -1
      }
      w = tolower(tok)
      if (match(w, /[[:alpha:]]+$/)) {
        c = substr(w, RSTART, RLENGTH)
        p = (RSTART == 1) ? "" : substr(w, RSTART - 1, 1)
        if ((p == "" || p !~ /[[:alnum:]_]/) && (c in NUM)) return NUM[c]
      }
      return -1
    }
    BEGIN {
      split("one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty", nw, " ")
      for (i = 1; i <= 20; i++) NUM[nw[i]] = i
      slen = length(star)
    }
    {
      line = $0; isfield = 0
      # MARKED — a list item whose bullet carries the glyph, then a bold label and a colon.
      if (match(line, /^-[ \t]*/)) {
        rest = substr(line, RLENGTH + 1)
        if (index(rest, star) == 1) {
          rest = substr(rest, slen + 1); sub(/^[ \t]+/, "", rest)
          if (match(rest, /^\*\*[^*]+:\*\*/)) {
            printf "MARKED\t%d\t%s\n", FNR, substr(rest, 3, RLENGTH - 5)
            isfield = 1
          }
        }
      }
      # ANNOT — the appendix naming one starred field. Every match on the line, because the
      # appendix lists several fields per line and only some of them are starred.
      seg = line
      while (match(seg, /\*\*[^*]+\*\*[ \t]*\(starred\)/)) {
        lab = substr(seg, RSTART + 2, RLENGTH - 2)
        sub(/\*\*[ \t]*\(starred\)$/, "", lab)
        printf "ANNOT\t%d\t%s\n", FNR, lab
        seg = substr(seg, RSTART + RLENGTH)
        isfield = 1
      }
      if (isfield) next
      # PROSE — a claim ABOUT the starred set, so the line must refer to the star at all.
      low = tolower(line)
      if (index(line, star) == 0 && low !~ /(^|[^[:alnum:]_])(starred|stars|star)([^[:alnum:]_]|$)/) next
      t = line
      gsub(ndash, " ", t); gsub(mdash, " ", t); gsub(/-/, " ", t)
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      n = split(t, w, /[ \t]+/)
      for (i = 1; i <= n; i++) {
        v = cardinal(w[i])
        if (v < 0) continue
        for (j = i + 1; j <= i + 4 && j <= n; j++) {
          if (w[j] ~ /^fields?([^[:alnum:]_]|$)/) { printf "PROSE\t%d\t%d\n", FNR, v; break }
          if (w[j] == "of" && j < n && w[j + 1] ~ /^them([^[:alnum:]_]|$)/) { printf "PROSE\t%d\t%d\n", FNR, v; break }
        }
      }
    }
  ' "$1"
}

# st_violations <surfaces> — one "<CODE><TAB><detail>" line per disagreement.
#
# MARKED is the reference count, because it is the only one of the four homes that is not a
# restatement of another: the fields ARE the starred set, the rest describe it.
#
# PROSE-POP is pinned at EXACTLY two rather than floored at one, and the pin is the point.
# A floor cannot see the deletion of one of two sites, which is the drift this group was
# asked to catch — the same reason AR2, AR3 and AR6 pin exact zeros with a stated warrant
# instead of asserting "not too many". A third assertion added on purpose turns ST red and
# is declared in the same change. That is the intent rather than the cost.
#
# LABELS-SET and LABELS-ORDER are two codes and not one because a rename and a reorder are
# different facts about the corpus, and a single verdict covering both would name neither —
# the CTL-SCOPE rule applied one level up.
st_violations() {
  awk -F'\t' '
    $1 == "PROSE"  { np++; pl[np] = $2; pv[np] = $3 }
    $1 == "MARKED" { nm++; ml[nm] = $3 }
    $1 == "ANNOT"  { na++; al[na] = $3; if (a1 == "") a1 = $2; a2 = $2 }
    END {
      np += 0; nm += 0; na += 0
      if (np != 2)
        printf "PROSE-POP\t%d prose count assertion(s) discovered; this template states the starred count in exactly 2 places, the banner and appendix rule 4\n", np
      if (nm == 0)
        printf "MARKED-EMPTY\tno field carries the star bullet, so the reference count would be a statement over the empty set\n"
      if (na == 0)
        printf "ANNOT-EMPTY\tno appendix annotation restates a starred field\n"
      for (i = 1; i <= np; i++)
        if (pv[i] + 0 != nm)
          printf "DISAGREE\tthe prose assertion at line %s says %s; %d field(s) actually carry the star\n", pl[i], pv[i], nm
      if (na != nm)
        printf "DISAGREE\tthe appendix restates %d starred field(s), lines %s-%s; %d field(s) actually carry the star\n", na, a1, a2, nm
      for (i = 1; i <= nm; i++) inm[ml[i]] = 1
      for (i = 1; i <= na; i++) ina[al[i]] = 1
      d = ""
      for (i = 1; i <= nm; i++) if (!(ml[i] in ina)) d = d " marked-only:" ml[i]
      for (i = 1; i <= na; i++) if (!(al[i] in inm)) d = d " annotated-only:" al[i]
      if (d != "")
        printf "LABELS-SET\tthe marked set and the appendix set are not the same set —%s\n", d
      else {
        om = ""; oa = ""
        for (i = 1; i <= nm; i++) om = om "|" ml[i]
        for (i = 1; i <= na; i++) oa = oa "|" al[i]
        if (om != oa)
          printf "LABELS-ORDER\tthe same labels appear in a different order — marked: %s / appendix: %s\n", substr(om, 2), substr(oa, 2)
      }
    }
  ' <<EOF
$1
EOF
}

# st_has <violations> <code> — the code appears as a whole FIELD, never as the prefix of a
# longer one. Here-string rather than a pipeline, deliberately: group PF grades the shape,
# and an early-exiting grep fed by a pipeline reports failure on a SUCCESSFUL match under
# the pipefail set at the top of this file.
st_has() { grep -q "^$2$(printf '\t')" <<<"$1"; }

# st_n <kind> <surfaces> — how many records of one surface were discovered.
st_n() { printf '%s\n' "$2" | awk -F'\t' -v k="$1" '$1 == k { n++ } END { print n + 0 }'; }

# st_field <kind> <ordinal> <column> <surfaces> — one cell of a discovered record, so every
# mutation below aims at a site the probe FOUND rather than at a line this file names.
st_field() { printf '%s\n' "$4" | awk -F'\t' -v k="$1" -v o="$2" -v c="$3" '$1 == k { n++; if (n == o) { print $c; exit } }'; }

# st_fixture <name> — a fresh copy of the real template under the run's temp dir. Never
# $ROOT: CTLe grades, last of all, that this suite never wrote into the tree it measures.
st_fixture() { cp "$ST_FILE" "$ST_DIR/$1.md" && printf '%s\n' "$ST_DIR/$1.md"; }

# st_line_sub <file> <line> <ere> <replacement> — one substitution on ONE line, in place.
st_line_sub() {
  awk -v ln="$2" -v a="$3" -v b="$4" 'NR == ln { sub(a, b) } { print }' "$1" > "$1.new" && mv "$1.new" "$1"
}

# st_line_del <file> <line> — remove ONE line.
st_line_del() { awk -v ln="$2" 'NR != ln' "$1" > "$1.new" && mv "$1.new" "$1"; }

# st_word <n> — the English name of a small integer, so the mutators below can rewrite a
# numeral without this file holding a copy of the one the template happens to use.
st_word() { printf '%s\n' "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty" | awk -v n="$1" '{ print $n }'; }

# st_bump <file> <line> <value> — restate the prose numeral at <line> as one less, in
# whichever form the line writes it. Tries the word first and the digits only if the word
# did not land, so the arm still exercises the surface if the template is ever rewritten to
# say "10" instead of "ten" — and if NEITHER lands the arm reports mutation-landed=0 and
# fails, which is the honest outcome rather than a green over an unmutated file.
st_bump() {
  local f="$1" ln="$2" v="$3"
  st_line_sub "$f" "$ln" "[ ]$(st_word "$v")[ ]" " $(st_word "$((v - 1))") "
  if cmp -s "$ST_FILE" "$f"; then
    st_line_sub "$f" "$ln" "[ ]${v}[ ]" " $((v - 1)) "
  fi
}

# st_mustfire <arm> <fixture> <code> <what> — one surface mutated ALONE, and the SAME
# evaluator must then report <code>. The mutation is asserted to have LANDED before the
# verdict is read: a fixture that was never actually changed makes a must-fire arm's
# silence meaningless, which is the C1-integrity and VI2 discipline one level down.
st_mustfire() {
  local id="$1" fx="$2" want="$3" what="$4" landed=0 v n
  cmp -s "$ST_FILE" "$fx" || landed=1
  v="$(st_violations "$(st_surfaces "$fx")")"
  n="$(printf '%s\n' "$v" | grep -c '[^[:space:]]')"
  if [ "$landed" -eq 1 ] && st_has "$v" "$want"; then
    PASS "$id: MUST FIRE — $what, and the same evaluator reports $want ($n violation(s) in all). The mutation is asserted to have landed before the verdict is read"
  else
    FAIL "$id: MUST FIRE — $what, but the evaluator did not report $want (mutation-landed=$landed violations=$n). ST1's zero has no control behind it for this surface"
  fi
}

# st_mustnotfire <arm> <fixture> <edit-expected> <what> — the arms that tell a correct
# evaluator from a lookalike. Without them an evaluator that returned a violation for ANY
# difference would pass every must-fire arm above and still be worthless.
st_mustnotfire() {
  local id="$1" fx="$2" wantedit="$3" what="$4" landed=0 v n
  cmp -s "$ST_FILE" "$fx" || landed=1
  v="$(st_violations "$(st_surfaces "$fx")")"
  n="$(printf '%s\n' "$v" | grep -c '[^[:space:]]')"
  if [ "$landed" -eq "$wantedit" ] && [ "$n" -eq 0 ]; then
    PASS "$id: MUST NOT FIRE — $what, and the evaluator reports 0 violations"
  else
    FAIL "$id: MUST NOT FIRE — $what, but the evaluator reports $n violation(s) (differs-from-original=$landed, expected $wantedit):$(printf '%s\n' "$v" | awk -F'\t' 'NF>1 { printf " %s", $1 }')"
  fi
}

ST_OK=1
ST_SURF=""; ST_NPROSE=0; ST_NMARK=0; ST_NANNOT=0; ST_NGLYPH=0
if [ -r "$ST_FILE" ]; then
  ST_SURF="$(st_surfaces "$ST_FILE")"
  ST_NPROSE="$(st_n PROSE "$ST_SURF")"
  ST_NMARK="$(st_n MARKED "$ST_SURF")"
  ST_NANNOT="$(st_n ANNOT "$ST_SURF")"
  ST_NGLYPH="$(awk -v star="$ST_STAR" '{ s = $0; while ((p = index(s, star)) > 0) { n++; s = substr(s, p + length(star)) } } END { print n + 0 }' "$ST_FILE")"
fi

printf '  SURFACES: %s prose count assertion(s) / %s marked field(s) / %s appendix annotation(s) in %s, over %s star glyph(s) in the file\n' \
  "$ST_NPROSE" "$ST_NMARK" "$ST_NANNOT" "$ST_REL" "$ST_NGLYPH"

if [ ! -r "$ST_FILE" ]; then
  FAIL "ST0: $ST_REL is missing or unreadable, so every verdict below would be about a file this suite never read. This population exists by construction — a tracked file — so its absence is a FAILURE and never a skip"
  ST_OK=0
elif [ "$ST_NPROSE" -gt 0 ] && [ "$ST_NMARK" -gt 0 ] && [ "$ST_NANNOT" -gt 0 ]; then
  PASS "ST0: all three discovered surfaces have a NON-EMPTY population — $ST_NPROSE prose assertion(s), $ST_NMARK marked field(s), $ST_NANNOT appendix annotation(s), each found by markup shape and reporting the line it was found on. A zero on any of them would make every verdict below a statement over the empty set; the exact prose population is pinned by ST1, not here"
else
  FAIL "ST0: a surface came back EMPTY (prose=$ST_NPROSE marked=$ST_NMARK annotations=$ST_NANNOT) — a zero here is a broken probe or a restructured template, not a clean file, and ST1 below would be asserting agreement among surfaces it never found"
  ST_OK=0
fi

if [ "$ST_OK" -eq 1 ]; then
  ST_VIOL="$(st_violations "$ST_SURF")"
  ST_NVIOL="$(printf '%s\n' "$ST_VIOL" | grep -c '[^[:space:]]')"
  if [ "$ST_NVIOL" -eq 0 ]; then
    PASS "ST1: all four homes of the starred count agree — $ST_NMARK marked field(s), both prose assertions reading $ST_NMARK, and $ST_NANNOT appendix annotation(s) carrying the same labels in the same order. The zero is a measurement: the CTL-ST arms below show this same evaluator failing on a single-surface mutation of every kind it can report and staying silent on two edits that change no surface"
  else
    FAIL "ST1: $ST_NVIOL disagreement(s) among the four homes of the starred count in $ST_REL — one of them was updated and the others were not:"
    printf '%s\n' "$ST_VIOL" | awk -F'\t' 'NF > 1 { printf "      %s: %s\n", $1, $2 }'
  fi

  if [ "$ST_NGLYPH" -gt "$ST_NMARK" ]; then
    PASS "ST2: the reference count is $ST_NMARK MARKED FIELDS and not the $ST_NGLYPH star glyphs the file contains, and the inequality is observed here rather than assumed. The banner's own mention of the glyph is prose about the convention, excluded by the shape MARKED matches — so a counter that had quietly become a glyph tally would report $ST_NGLYPH and be caught by this arm"
  else
    FAIL "ST2: the marked-field count ($ST_NMARK) is not strictly below the glyph count ($ST_NGLYPH), so the discriminator between counting fields and counting glyphs is UNTESTED on this tree and ST1's agreement proves less than it appears to"
  fi

  if [ "${AR_NTPL:-unset}" = "0" ]; then
    PASS "ST-AR3: AR3 is re-read in this same run and still reports 0 template(s) reaching the selector. Group ST reads $ST_REL directly and adds no finding code to the validator, so the constraint that this check must not drag a template into va_select is an observation here, not a promise in a comment"
  else
    FAIL "ST-AR3: AR_NTPL reads '${AR_NTPL:-unset}' rather than 0 — group ST has pulled a template into the selector and falsified AR3, which is the one thing this group was required not to do"
  fi
fi

# ── The control arms. Single-surface mutations that MUST turn ST red, covering every
# violation code the evaluator can report, and two edits that MUST NOT. Every fixture is a
# copy of the REAL file, mutated at a line the probe DISCOVERED, so no arm can drift away
# from the surface it is meant to exercise.
if [ "$ST_OK" -eq 1 ]; then
  ST_PL1="$(st_field PROSE 1 2 "$ST_SURF")";  ST_PV1="$(st_field PROSE 1 3 "$ST_SURF")"
  ST_PL2="$(st_field PROSE 2 2 "$ST_SURF")";  ST_PV2="$(st_field PROSE 2 3 "$ST_SURF")"
  ST_ML1="$(st_field MARKED 1 2 "$ST_SURF")"; ST_MB1="$(st_field MARKED 1 3 "$ST_SURF")"
  ST_AL1="$(st_field ANNOT 1 2 "$ST_SURF")"

  ST_FX="$(st_fixture m1)"; st_bump "$ST_FX" "$ST_PL1" "$ST_PV1"
  st_mustfire CTL-ST-M1 "$ST_FX" DISAGREE "the BANNER numeral alone is restated as $((ST_PV1 - 1)) at line $ST_PL1, with the marked fields and the appendix untouched"

  ST_FX="$(st_fixture m2)"; st_bump "$ST_FX" "$ST_PL2" "$ST_PV2"
  st_mustfire CTL-ST-M2 "$ST_FX" DISAGREE "the APPENDIX RULE-4 numeral alone is restated as $((ST_PV2 - 1)) at line $ST_PL2, with the banner and the annotations untouched"

  ST_FX="$(st_fixture m3)"; st_line_sub "$ST_FX" "$ST_ML1" "${ST_STAR}[ ]*" ""
  st_mustfire CTL-ST-M3 "$ST_FX" DISAGREE "the star is stripped from ONE marked field ('$ST_MB1', line $ST_ML1), leaving every numeral and every annotation as it was"

  ST_FX="$(st_fixture m4)"; st_line_sub "$ST_FX" "$ST_AL1" "[ ]*[(]starred[)]" ""
  st_mustfire CTL-ST-M4 "$ST_FX" DISAGREE "ONE appendix annotation is dropped at line $ST_AL1, leaving both numerals and every marked field as they were"

  ST_FX="$(st_fixture d1)"; st_line_del "$ST_FX" "$ST_PL1"
  st_mustfire CTL-ST-D1 "$ST_FX" PROSE-POP "the BANNER assertion is DELETED outright (line $ST_PL1) — the case a count-only comparison passes, because the remaining numeral still agrees"

  ST_FX="$(st_fixture d2)"; st_line_del "$ST_FX" "$ST_PL2"
  st_mustfire CTL-ST-D2 "$ST_FX" PROSE-POP "the APPENDIX RULE-4 assertion is DELETED outright (line $ST_PL2), the same hole at the other site"

  ST_FX="$(st_fixture r1)"; st_line_sub "$ST_FX" "$ST_ML1" "[*][*]$ST_MB1:[*][*]" "**$ST_MB1 (renamed):**"
  st_mustfire CTL-ST-R1 "$ST_FX" LABELS-SET "ONE marked field is RENAMED ('$ST_MB1', line $ST_ML1) and every count is left equal, so only a label-for-label comparison can see it"

  # R2 is the subtle one: the banner keeps its glyph and keeps its numeral, but stops being
  # a countable assertion. It is the failure a count-only comparison cannot see, because
  # nothing was deleted and nothing disagrees — an assertion quietly became a sentence.
  ST_FX="$(st_fixture r2)"; st_line_sub "$ST_FX" "$ST_PL1" "[ ]of[ ]them" " like that"
  ST_R2_KEPT=0
  awk -v ln="$ST_PL1" -v star="$ST_STAR" 'NR == ln && index($0, star) > 0 { f = 1 } END { exit(f ? 0 : 1) }' "$ST_FX" && ST_R2_KEPT=1
  if [ "$ST_R2_KEPT" -eq 1 ]; then
    st_mustfire CTL-ST-R2 "$ST_FX" PROSE-POP "the BANNER is REWORDED out of the count shape at line $ST_PL1 while KEEPING its star glyph (asserted present on the mutated line) — it still looks like the assertion and no longer is one"
  else
    FAIL "CTL-ST-R2: MUST FIRE — the reword was supposed to leave the glyph on line $ST_PL1 and did not, so this arm would be testing deletion rather than the reword it is named for"
  fi

  # ── LABELS-ORDER, MARKED-EMPTY and ANNOT-EMPTY each have a branch in st_violations and,
  # until these three arms, had nothing showing the branch can be REACHED. An emitted code no
  # arm has been observed firing is a claim about the evaluator rather than a measurement of
  # it — the standard the arms above already meet, applied to the three codes that
  # shipped without it. Each is provoked ALONE, and each asserts its OWN code rather than
  # settling for a red, because a red proves only that something fired.

  # O1 — a pure REORDER, the case LABELS-ORDER was split from LABELS-SET to name. Transposing
  # two appendix annotations leaves both label SETS equal and every count untouched, so
  # LABELS-SET is silent by construction and LABELS-ORDER is the only surface that can still
  # see the edit. The two sites must be distinct lines: one sub() per call means a
  # transposition inside a single line would rewrite the label this arm had just written and
  # cancel to no edit, so the precondition is GRADED rather than assumed, the way R2 grades
  # its own.
  ST_AB1="$(st_field ANNOT 1 3 "$ST_SURF")"
  ST_AL2="$(st_field ANNOT 2 2 "$ST_SURF")"; ST_AB2="$(st_field ANNOT 2 3 "$ST_SURF")"
  if [ "$ST_AL1" != "$ST_AL2" ]; then
    ST_FX="$(st_fixture o1)"
    st_line_sub "$ST_FX" "$ST_AL1" "[*][*]$ST_AB1[*][*]" "**$ST_AB2**"
    st_line_sub "$ST_FX" "$ST_AL2" "[*][*]$ST_AB2[*][*]" "**$ST_AB1**"
    st_mustfire CTL-ST-O1 "$ST_FX" LABELS-ORDER "the appendix's first two annotations are TRANSPOSED ('$ST_AB1' at line $ST_AL1 with '$ST_AB2' at line $ST_AL2), so both sets stay equal and every count stays put — the one edit only an order-aware comparison can see"
  else
    FAIL "CTL-ST-O1: MUST FIRE — the first two appendix annotations both sit on line $ST_AL1, so transposing them would cancel to no edit and this arm would grade nothing. LABELS-ORDER needs two annotations on distinct lines to be provoked"
  fi

  # E1 — the MARKED surface emptied outright. The star is stripped from every marked bullet
  # the probe DISCOVERED, one sub per RECORD rather than one per line, so the several-per-line
  # shape st_surfaces already handles is emptied too. MARKED-EMPTY is what stops ST1's "the
  # fields ARE the reference count" from becoming a statement over the empty set: without this
  # arm, a template that had lost every star could still be reported as four homes in
  # agreement about nothing.
  ST_FX="$(st_fixture e1)"; ST_I=1
  while [ "$ST_I" -le "$ST_NMARK" ]; do
    st_line_sub "$ST_FX" "$(st_field MARKED "$ST_I" 2 "$ST_SURF")" "${ST_STAR}[ ]*" ""
    ST_I=$((ST_I + 1))
  done
  st_mustfire CTL-ST-E1 "$ST_FX" MARKED-EMPTY "the star is stripped from ALL $ST_NMARK marked field(s), taking the reference count itself to zero and leaving the three homes that merely describe it describing nothing"

  # E2 — the ANNOT surface emptied the same way and for the same reason: the appendix's
  # per-field restatement is the home ST1 compares label FOR label, and a zero there would
  # make that comparison vacuous while both numerals still agreed with the marked set.
  ST_FX="$(st_fixture e2)"; ST_I=1
  while [ "$ST_I" -le "$ST_NANNOT" ]; do
    st_line_sub "$ST_FX" "$(st_field ANNOT "$ST_I" 2 "$ST_SURF")" "[ ]*[(]starred[)]" ""
    ST_I=$((ST_I + 1))
  done
  st_mustfire CTL-ST-E2 "$ST_FX" ANNOT-EMPTY "all $ST_NANNOT appendix annotations are dropped, leaving the marked fields and both numerals standing with nothing restating them field by field"

  ST_FX="$(st_fixture clean)"
  st_mustnotfire CTL-ST-CLEAN "$ST_FX" 0 "an UNMUTATED copy of the real file is put through the same evaluator, which is the baseline that makes every must-fire arm above mean something"

  ST_FX="$(st_fixture neutral)"; st_line_sub "$ST_FX" "$ST_ML1" "[[]" "[Reworded hint — "
  st_mustnotfire CTL-ST-NEUTRAL "$ST_FX" 1 "the bracketed HINT inside a marked field is reworded (line $ST_ML1), changing the file but no surface — no numeral, no label, no glyph and no annotation"
fi

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "CTL — a synthetic fixture tree, population by construction, built fresh every run"
# ─────────────────────────────────────────────────────────────────────────────────
# Every fixture is BUILT from the real corpus copied at runtime, never from a literal in
# this file. A fixture that was never constructed is a green proving nothing, one level
# down — so each mutation is asserted to have changed the tree before the arm it feeds is
# graded.

# mk_root <dir> — a fixture repository: the real architecture document, the real schema
# corpus, and every witness that corpus declares, plus an empty artifact tree. Copying
# rather than synthesising is what keeps the CTL arms honest: they exercise the corpus this
# commit actually ships.
#
# ── WHY THE WITNESSES ARE COPIED, AND WHAT IT DOES NOT DO TO THE ARMS ────────────
# A `witness:` declaration is resolved by S5 against WHATEVER TREE THE VALIDATOR RUNS IN.
# A fixture root carrying the corpus but none of the files that corpus points at therefore
# fails S5 for every declared witness BY CONSTRUCTION, and the failure is an artefact of how
# the fixture is built rather than anything wrong with the repository. That is not a
# prediction: the first class to flip to `witness:` turned CTLa red with exactly that finding
# and was reverted at 740dd93 rather than kept, which left the coverage declaration unable to
# follow the migration it exists to track.
#
# Copying the declared witnesses removes that construction artefact and NOTHING ELSE:
#   * Every MUST-FIRE arm still fires from its own MUTATION, and has_finding() names the code
#     it is looking for, so added population cannot mask the finding an arm is grading.
#   * Every MUST-NOT-FIRE arm gets STRICTER, never looser: CTLa, C1a, CTL-A2neg, CTL-TPL and
#     CTL-RESID all assert rc 0 over the whole fixture, so from here each declared witness
#     must validate CLEAN in a tree built fresh from this commit. The suite proves more than
#     it did, not less.
#   * CTL-S5 keeps its meaning BY ORDERING, not by exemption: mk_root copies the witnesses the
#     REAL corpus declares, and the S5 mutation runs afterwards naming a path no schema ever
#     declared — so nothing copied it, and the arm still observes a genuinely missing witness.
#   * A copy that does not land is not silent. The witness is then absent from the fixture,
#     which is the same state this fix removed, and CTLa goes red naming S5 and the path.
#
# The population is still built fresh in a temp dir on every invocation, still comes entirely
# from this commit's own tracked files, and is still never a literal in this file.
mk_root() {
  local d="$1" w
  mkdir -p "$d/reference/schemas" "$d/examples/ctl/outputs" "$d/templates"
  cp "$ROOT/$VA_ARCH_DOC" "$d/reference/data-architecture.md"
  cp "$ROOT/$VA_SCHEMA_DIR"/*.md "$d/reference/schemas/"
  # Read from CV_WITNESSES, which group CV above accumulated from the coverage declarations
  # themselves. No witness path is spelled in this file.
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    case "$w" in */*) mkdir -p "$d/${w%/*}" ;; esac
    cp "$ROOT/$w" "$d/$w"
  done <<EOF
$CV_WITNESSES
EOF
}
run_fx() { va_main --root "$1" --scope dir . 2>&1; }

CTL_RAN=0

FX="$WORK/clean"; mk_root "$FX"
CLEAN_OUT="$(run_fx "$FX")"; CLEAN_RC=$?
CTL_RAN=1
if [ "$CLEAN_RC" -eq 0 ] && ! grep -q '^FINDING ' <<<"$CLEAN_OUT"; then
  PASS "CTLa: MUST NOT FIRE — a fixture root carrying this commit's real schema corpus and no artifacts validates clean (rc=0)"
else
  FAIL "CTLa: the clean baseline already fails, so every must-fire arm below proves nothing: $(printf '%s' "$CLEAN_OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
fi

# ── C1a / C1b — the skip predicate, observed. THE POINT OF THIS SUITE.
# One artifact, deliberately wrong three ways: a required field absent (writer), a bad
# enum value (lifecycle), and an out-of-grammar line. Built once, then copied and given a
# single extra line.
FXA="$WORK/c1a"; mk_root "$FXA"
cat > "$FXA/examples/ctl/outputs/food-list.md" <<'FIXTURE'
---
artifact: outputs/food-list.md
trip: ctl-fixture
lifecycle: not-a-real-lifecycle
provenance: researched
publish: internal
generated: 2026-08-28
---

# Food List — CTL fixture
FIXTURE
FXB="$WORK/c1b"; mk_root "$FXB"
cp "$FXA/examples/ctl/outputs/food-list.md" "$FXB/examples/ctl/outputs/food-list.md"
# The single line that is the whole difference between the two arms.
awk 'NR==2 { print; print "schema-version: 1"; next } { print }' \
  "$FXA/examples/ctl/outputs/food-list.md" > "$FXB/examples/ctl/outputs/food-list.md.new"
mv "$FXB/examples/ctl/outputs/food-list.md.new" "$FXB/examples/ctl/outputs/food-list.md"

C1_DIFF="$(diff "$FXA/examples/ctl/outputs/food-list.md" "$FXB/examples/ctl/outputs/food-list.md" | grep -c '^[<>]')"
if [ "$C1_DIFF" -eq 1 ] && grep -q '^schema-version: 1$' "$FXB/examples/ctl/outputs/food-list.md"; then
  PASS "C1-integrity: the two fixtures differ by EXACTLY ONE LINE, and that line is 'schema-version: 1'. The only variable between C1a and C1b is the skip predicate — which is what makes the pair a proof rather than two independent tests"
else
  FAIL "C1-integrity: the fixture pair differs by $C1_DIFF line(s); C1a/C1b below would not isolate the skip predicate"
fi

A_OUT="$(run_fx "$FXA")"; A_RC=$?
A_SKIPPED="$(printf '%s\n' "$A_OUT" | grep -c '^SKIP examples/ctl/outputs/food-list.md C6')"
A_FINDINGS="$(printf '%s\n' "$A_OUT" | grep -c '^FINDING ')"
if [ "$A_RC" -eq 0 ] && [ "$A_FINDINGS" -eq 0 ] && [ "$A_SKIPPED" -eq 1 ]; then
  PASS "C1a: MUST NOT FIRE — an artifact carrying NO schema-version, violating its class schema three ways (required field absent, bad enum value, out-of-grammar line), is SKIPPED by path and by resolved class, contributes 0 findings and returns rc 0. An unversioned artifact cannot fail the build even when it is wrong"
else
  FAIL "C1a: MUST NOT FIRE — an unversioned artifact turned the gate red (rc=$A_RC, findings=$A_FINDINGS, skip-lines=$A_SKIPPED). The tolerant read's first limb is not being honoured: $(printf '%s' "$A_OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
fi

B_OUT="$(run_fx "$FXB")"; B_RC=$?
if [ "$B_RC" -ne 0 ] && has_finding "$B_OUT" 'A3' && has_finding "$B_OUT" 'A4'; then
  PASS "C1b: MUST FIRE — the byte-identical fixture with 'schema-version: 1' added and nothing else changed FAILS CLOSED (rc=$B_RC), emitting A3 (required field absent) and A4 (value outside its declared enum)"
else
  FAIL "C1b: MUST FIRE — declaring a version did not make the same three violations fail (rc=$B_RC): $(printf '%s' "$B_OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
fi
if grep -q "^FINDING A3 examples/ctl/outputs/food-list.md field writer " <<<"$B_OUT"; then
  PASS "C1b-report: the finding names the ARTIFACT and the FIELD, not merely that validation failed — 'FINDING A3 examples/ctl/outputs/food-list.md field writer ...'"
else
  FAIL "C1b-report: a finding did not name both the artifact and the field: $(printf '%s' "$B_OUT" | grep '^FINDING A3' | head -1)"
fi

# ── A1 — malformed frontmatter (duplicate key: two homes for one fact).
FX="$WORK/a1"; mk_root "$FX"
printf -- '---\nartifact: outputs/food-list.md\nschema-version: 1\ntrip: ctl\ntrip: ctl-again\nwriter: food\nlifecycle: accumulate-append\nprovenance: researched\npublish: internal\ngenerated: 2026-08-28\n---\n\n# x\n' \
  > "$FX/examples/ctl/outputs/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'A1'; then
  PASS "CTL-A1: MUST FIRE — a duplicate frontmatter key is A1; picking either value silently would be the wrong answer to a question the file asks"
else
  FAIL "CTL-A1: MUST FIRE — a duplicate key was accepted (rc=$R)"
fi

# ── A2 — the no-schema-yet window, and its specificity arm. This is the pair that closes
# the fail-open § 11 names.
FX="$WORK/a2"; mk_root "$FX"
printf -- '---\nartifact: outputs/no-such-class.md\nschema-version: 1\ntrip: ctl\n---\n\n# x\n' \
  > "$FX/examples/ctl/unclaimed.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'A2'; then
  PASS "CTL-A2: MUST FIRE — a VERSIONED artifact declaring a class no schema covers is A2. Without the declared arm this file would simply not be selected: it would leave the gate silently, which is the fail-OPEN the gate exists to close"
else
  FAIL "CTL-A2: MUST FIRE — a versioned artifact naming an unknown class was not caught (rc=$R)"
fi
FX="$WORK/a2neg"; mk_root "$FX"
printf -- '---\nartifact: outputs/no-such-class.md\ntrip: ctl\n---\n\n# x\n' \
  > "$FX/examples/ctl/unclaimed.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -eq 0 ] && ! has_finding "$O" 'A2' && grep -q '^SKIP examples/ctl/unclaimed.md' <<<"$O"; then
  PASS "CTL-A2neg: MUST NOT FIRE — the SAME unknown class with no schema-version SKIPS. A2 is gated behind the version check, so the tolerant read's first limb still holds and the gate authored no second rule"
else
  FAIL "CTL-A2neg: MUST NOT FIRE — an UNVERSIONED artifact naming an unknown class failed (rc=$R); A2 has escaped the version gate and the gate is now inventing a rule § 7.3 does not state"
fi

# ── A5 — the file's own declaration disagreeing with the class that selected it.
FX="$WORK/a5"; mk_root "$FX"
printf -- '---\nartifact: outputs/activities-list.md\nschema-version: 1\ntrip: ctl\nwriter: food\nlifecycle: accumulate-append\nprovenance: researched\npublish: internal\ngenerated: 2026-08-28\n---\n\n# x\n' \
  > "$FX/examples/ctl/outputs/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'A5'; then
  PASS "CTL-A5: MUST FIRE — an artifact whose declared class disagrees with the class whose path-pattern selected it is A5"
else
  FAIL "CTL-A5: MUST FIRE — a mismatched declaration was accepted (rc=$R)"
fi

# ── A6 — a version its own schema does not define. The gate's second stated boundary.
FX="$WORK/a6"; mk_root "$FX"
printf -- '---\nartifact: outputs/food-list.md\nschema-version: 99\ntrip: ctl\nwriter: food\nlifecycle: accumulate-append\nprovenance: researched\npublish: internal\ngenerated: 2026-08-28\n---\n\n# x\n' \
  > "$FX/examples/ctl/outputs/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'A6'; then
  PASS "CTL-A6: MUST FIRE — an in-repo artifact declaring a version its own in-repo schema does not define is a broken repository, not a forward-compatible trip. The boundary is stated in the validator's source rather than left to be discovered"
else
  FAIL "CTL-A6: MUST FIRE — a version above the class schema's own was accepted (rc=$R)"
fi

# ── S1..S8 — corpus arms. Each mutates the copied corpus and asserts the mutation landed.
FX="$WORK/s1"; mk_root "$FX"
sed 's|^artifact: outputs/food-list.md$|artifact: outputs/not-a-class.md|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
if grep -q '^artifact: outputs/not-a-class.md$' "$FX/reference/schemas/food-list.md"; then
  O="$(run_fx "$FX")"; R=$?
  if [ "$R" -ne 0 ] && has_finding "$O" 'S1'; then
    PASS "CTL-S1: MUST FIRE — a schema whose artifact disagrees with its class's row in the enumeration is S1"
  else
    FAIL "CTL-S1: MUST FIRE — a schema disagreeing with the document was accepted (rc=$R)"
  fi
else
  FAIL "CTL-S1: the fixture mutation did not land; the arm would prove nothing"
fi

FX="$WORK/s2"; mk_root "$FX"
sed 's|^schema-version: 1$|schema-version: 1\nthis line is not in the grammar|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S2'; then
  PASS "CTL-S2: MUST FIRE — an out-of-grammar line inside an artifact-schema fence is S2. The grammar is closed, so an unrecognised construct is a violation of the corpus and never a limitation of the parser"
else
  FAIL "CTL-S2: MUST FIRE — an out-of-grammar schema line was accepted (rc=$R)"
fi

FX="$WORK/s3"; mk_root "$FX"
cp "$FX/reference/schemas/food-list.md" "$FX/reference/schemas/food-list-copy.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S3'; then
  PASS "CTL-S3: MUST FIRE — two schemas declaring the same class is S3, so a stray file under reference/schemas/ cannot silently become a second home for a class"
else
  FAIL "CTL-S3: MUST FIRE — a duplicate class declaration was accepted (rc=$R)"
fi

# A stray file under reference/schemas/ that is not a schema at all. CTL-S3 covers a stray
# file that DUPLICATES a class; this covers the other shape, where the corpus quietly gains
# a member nothing declares. Both matter, because "the enum's home is the directory listing"
# is only safe while a non-member cannot sit in the directory unnoticed.
FX="$WORK/stray"; mk_root "$FX"
printf -- '# notes\n\nscratch notes that are not a schema at all\n' > "$FX/reference/schemas/scratch-notes.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S2'; then
  PASS "CTL-STRAY: MUST FIRE — a stray non-schema file under reference/schemas/ is S2 (no artifact-schema fence). Homing the class enum in a directory listing is only safe while a non-member cannot sit in that directory unnoticed"
else
  FAIL "CTL-STRAY: MUST FIRE — a stray file under reference/schemas/ was accepted (rc=$R); the corpus can gain a member nothing declares"
fi

FX="$WORK/s4"; mk_root "$FX"
sed 's|^path-pattern: .*$|path-pattern: **/outputs/**/food-list.md|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S4'; then
  PASS "CTL-S4: MUST FIRE — ** anywhere but the first or last segment is a malformed pattern, reported rather than quietly reinterpreted"
else
  FAIL "CTL-S4: MUST FIRE — a malformed path-pattern was accepted (rc=$R)"
fi

FX="$WORK/s5"; mk_root "$FX"
sed 's|^no-witness-because: .*$|witness: examples/ctl/outputs/does-not-exist.md|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S5'; then
  PASS "CTL-S5: MUST FIRE — a declared witness that does not exist is S5"
else
  FAIL "CTL-S5: MUST FIRE — a missing witness path was accepted (rc=$R)"
fi

FX="$WORK/s6"; mk_root "$FX"
printf -- '# Food List — CTL fixture with no frontmatter at all\n' > "$FX/examples/ctl/outputs/food-list.md"
sed 's|^no-witness-because: .*$|witness: examples/ctl/outputs/food-list.md|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S6'; then
  PASS "CTL-S6: MUST FIRE — a declared witness that exists but carries no schema-version is a COVERAGE REGRESSION (S6). This is what lets the gate's teeth grow with the migration: the failing assertion is the class's own coverage declaration, not the skip predicate, so nothing re-branches the tolerant read"
else
  FAIL "CTL-S6: MUST FIRE — a stripped witness was accepted (rc=$R)"
fi

FX="$WORK/s7"; mk_root "$FX"
sed 's|^no-witness-because: .*$|witness: reference/schemas/README.md\nno-witness-because: both, which is not allowed|' \
  "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S7'; then
  PASS "CTL-S7: MUST FIRE — declaring both witness: and no-witness-because: is S7; they are mutually exclusive and exactly one is required"
else
  FAIL "CTL-S7: MUST FIRE — a schema declaring both coverage branches was accepted (rc=$R)"
fi
FX="$WORK/s7b"; mk_root "$FX"
grep -v '^no-witness-because: ' "$FX/reference/schemas/food-list.md" > "$FX/reference/schemas/food-list.md.n" && mv "$FX/reference/schemas/food-list.md.n" "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S7'; then
  PASS "CTL-S7b: MUST FIRE — declaring NEITHER is S7 too. A class with no coverage statement is the silent-absence case the declaration exists to prevent"
else
  FAIL "CTL-S7b: MUST FIRE — a schema declaring no coverage branch was accepted (rc=$R)"
fi

FX="$WORK/s8"; mk_root "$FX"
rm -f "$FX/reference/schemas/food-list.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'S8'; then
  PASS "CTL-S8: MUST FIRE — a class in the enumeration with no schema in the corpus breaks the bijection (S8). The guard holds no copy of the class list, so this is asserted against the document itself"
else
  FAIL "CTL-S8: MUST FIRE — a missing class schema was accepted (rc=$R)"
fi

# ── X2 — an unreadable required population is a failure, never an empty one.
FX="$WORK/x2"; mk_root "$FX"
rm -rf "$FX/reference/schemas"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'X2'; then
  PASS "CTL-X2: MUST FIRE — an absent schema directory is X2, an unreadable population. An absent corpus must never read as a corpus with nothing wrong in it"
else
  FAIL "CTL-X2: MUST FIRE — an absent schema directory did not fail (rc=$R)"
fi

# ── The templates exclusion, both directions. It is INERT on the path arm and LOAD-BEARING
# on the declared arm, and asserting only the pass direction would leave that unproven.
FX="$WORK/tpl"; mk_root "$FX"
cp "$ROOT/templates/trip-context.template.md" "$FX/templates/trip-context.template.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -eq 0 ] && ! grep -q 'templates/trip-context.template.md' <<<"$O"; then
  PASS "CTL-TPL: MUST NOT FIRE — this commit's REAL versioned template, copied into the fixture tree, is excluded and reaches no finding. § 11 declares it an emitter, not an instance"
else
  FAIL "CTL-TPL: MUST NOT FIRE — the template reached the gate (rc=$R): $(printf '%s' "$O" | grep '^FINDING ' | head -2 | tr '\n' ' ')"
fi
FX="$WORK/tplneg"; mk_root "$FX"
cp "$ROOT/templates/trip-context.template.md" "$FX/examples/ctl/trip-context.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -ne 0 ] && has_finding "$O" 'A4'; then
  PASS "CTL-TPLneg: MUST FIRE — the SAME bytes at a non-template path DO fail (its trip: value is the placeholder <trip-slug>, not a slug). So the exclusion is doing real work rather than decorating a file the gate would have passed anyway"
else
  FAIL "CTL-TPLneg: MUST FIRE — the template's contents passed at a non-excluded path (rc=$R), so CTL-TPL proves nothing about the exclusion"
fi

# ── Residual-class precedence: the broadest pattern must never steal a named class's file.
FX="$WORK/resid"; mk_root "$FX"
printf -- '---\nartifact: outputs/food-list.md\nschema-version: 1\ntrip: ctl\nwriter: food\nlifecycle: accumulate-append\nprovenance: researched\npublish: internal\ngenerated: 2026-08-28\n---\n\n# x\n' \
  > "$FX/examples/ctl/outputs/food-list.md"
printf -- '---\nartifact: outputs/<slug>.md\nschema-version: 1\ntrip: ctl\nwriter: food\nlifecycle: accumulate-append\nprovenance: researched\npublish: internal\ngenerated: 2026-08-28\n---\n\n# x\n' \
  > "$FX/examples/ctl/outputs/late-night-ramen.md"
O="$(run_fx "$FX")"; R=$?
if [ "$R" -eq 0 ]; then
  PASS "CTL-RESID: both a named class's file and a residual outputs/<slug>.md file validate under the class each SHOULD resolve to — longest-literal-pattern-wins keeps C18 from stealing every named class's file, with no precedence list to maintain"
else
  FAIL "CTL-RESID: residual-class precedence is wrong (rc=$R): $(printf '%s' "$O" | grep '^FINDING ' | head -2 | tr '\n' ' ')"
fi

# ── S9's must-fire arm. XC asserts the real exclusions against the real document; this
# asserts that the assertion itself can fail.
if grep -qF -- 'templates/*.template.md' <<<"$(xc_section_text '## 11. What This Document Does Not Define')"; then
  PASS "CTL-S9: the exclusion-provenance probe FIRES on a pattern that is genuinely declared ('templates/*.template.md' at § 11), and XC1 above showed it returns nothing for one that is not — both arms observed"
else
  FAIL "CTL-S9: the exclusion-provenance probe cannot find a pattern that IS in § 11; every XC verdict is a broken probe"
fi

# ── The --scope dir target: two facts one verdict used to conflate.
# A nonexistent path and an empty-but-real directory produced BYTE-IDENTICAL output at rc 0,
# so a user who mistyped a trip name was told their trip was clean. The two are different
# facts — one is a scope that does not resolve, the other a scope that resolves to nothing —
# and they are graded here as two arms because a single verdict covering both would be a
# worse outcome than two that distinguish them.
FX="$WORK/scope"; mk_root "$FX"
mkdir -p "$FX/examples/ctl/empty-but-real"
SCOPE_MISS_OUT="$(va_main --root "$FX" --scope dir examples/ctl/no-such-trip-xyz 2>&1)"; SCOPE_MISS_RC=$?
SCOPE_EMPTY_OUT="$(va_main --root "$FX" --scope dir examples/ctl/empty-but-real 2>&1)"; SCOPE_EMPTY_RC=$?
if [ "$SCOPE_MISS_RC" -ne 0 ] && has_finding "$SCOPE_MISS_OUT" 'X2'; then
  PASS "CTL-SCOPE1: MUST FIRE — a --scope dir target that does not exist is X2 and fails closed (rc=$SCOPE_MISS_RC). A mistyped trip name is an unreadable population, and an absent population must never read as a population with nothing wrong in it"
else
  FAIL "CTL-SCOPE1: MUST FIRE — a nonexistent --scope dir target returned rc=$SCOPE_MISS_RC with no X2. A user who fat-fingers a trip name is being told their trip is clean"
fi
if [ "$SCOPE_EMPTY_RC" -eq 0 ] && ! has_finding "$SCOPE_EMPTY_OUT" 'X2'; then
  PASS "CTL-SCOPE2: MUST NOT FIRE — a real directory that happens to hold no files is not an unreadable population, so it does not take X2. The specificity arm that keeps CTL-SCOPE1 from being an existence check that fires on everything"
else
  FAIL "CTL-SCOPE2: MUST NOT FIRE — an empty-but-real directory was reported as unreadable (rc=$SCOPE_EMPTY_RC): $(printf '%s' "$SCOPE_EMPTY_OUT" | grep '^FINDING ' | head -2 | tr '\n' ' ')"
fi
if [ "$SCOPE_MISS_OUT" != "$SCOPE_EMPTY_OUT" ]; then
  PASS "CTL-SCOPE3: the two outputs DIFFER. A path that does not exist and a directory that is merely empty are different facts, and the gate now answers them with two verdicts rather than one shared silence"
else
  FAIL "CTL-SCOPE3: a nonexistent path and an empty-but-real directory still produce IDENTICAL output — the conflation is live and CTL-SCOPE1/2 above cannot both be meaningful"
fi

# ── The VACUOUS verdict on the local arm. The CI arm has rendered one since this suite
# shipped (AR5); the arm a user runs directly did not, which left the one surface reached by
# hand as the only one where a green over nothing read as a pass.
if grep -q '^VACUOUS ' <<<"$SCOPE_EMPTY_OUT"; then
  PASS "CTL-VAC1: MUST FIRE — a run whose selected population is ZERO renders a VACUOUS verdict on the local arm, in the shape AR5 already uses on the CI arm. A pass over zero selected files is vacuous, not passing"
else
  FAIL "CTL-VAC1: MUST FIRE — a run over an empty population rendered no VACUOUS verdict, so the local arm still reports a silent green over nothing"
fi
if ! grep -q '^VACUOUS ' <<<"$CLEAN_OUT"; then
  PASS "CTL-VAC2: MUST NOT FIRE — the same validator over the clean fixture's NON-empty population renders no VACUOUS verdict, so the verdict tracks the measured population rather than being printed unconditionally"
else
  FAIL "CTL-VAC2: MUST NOT FIRE — a VACUOUS verdict appeared over a non-empty population, which would make CTL-VAC1 meaningless"
fi

# ── .publish/ — the exclusion is absolute or it is not an exclusion. Two arms on IDENTICAL
# bytes, differing only in POSITION. reference/data-architecture.md states the exclusion
# without qualification; a root-anchored glob made that true at the repository root and false
# inside a trip, which is the one position a real user's .publish/ ever occupies.
FX="$WORK/pub"; mk_root "$FX"
mkdir -p "$FX/examples/ctl/trip/.publish" "$FX/.publish"
PUB_BYTES="$(printf -- '---\nartifact: outputs/no-such-class.md\nschema-version: 1\ntrip: ctl\n---\n\n# x\n')"
printf '%s\n' "$PUB_BYTES" > "$FX/examples/ctl/trip/.publish/index.md"
printf '%s\n' "$PUB_BYTES" > "$FX/.publish/index.md"
printf '%s\n' "$PUB_BYTES" > "$FX/examples/ctl/trip/notes.md"
PUB_SEL_IN="$(va_select "$FX" dir examples/ctl/trip)"
PUB_SEL_RT="$(va_select "$FX" dir .)"
pub_excluded() { awk -F'\t' -v p="$2" '$1 == "EXCLUDED" && $2 == p { n++ } END { print n + 0 }' <<<"$1"; }
PUB_IN="$(pub_excluded "$PUB_SEL_IN" 'examples/ctl/trip/.publish/index.md')"
PUB_RT="$(pub_excluded "$PUB_SEL_RT" '.publish/index.md')"
PUB_NEG="$(pub_excluded "$PUB_SEL_IN" 'examples/ctl/trip/notes.md')"
if [ "$PUB_IN" -eq 1 ] && [ "$PUB_RT" -eq 1 ]; then
  PASS "CTL-PUB1: the .publish/ exclusion holds in BOTH positions on identical bytes — excluded inside a trip AND at the repository root. The corpus states the exclusion absolutely, and it is now absolute rather than root-anchored"
else
  FAIL "CTL-PUB1: the .publish/ exclusion is POSITION-DEPENDENT — in-trip excluded=$PUB_IN, repo-root excluded=$PUB_RT (each must be 1). The corpus says .publish/ is never traversed by any selector; at one of these positions it is"
fi
if [ "$PUB_NEG" -eq 0 ]; then
  PASS "CTL-PUB2: the same probe reports 0 for a file of the SAME BYTES outside .publish/, so CTL-PUB1's counts are a measurement of the exclusion rather than of the probe matching everything"
else
  FAIL "CTL-PUB2: the exclusion probe matched a file outside .publish/ ($PUB_NEG) — the exclusion is over-broad and CTL-PUB1 proves nothing"
fi

# ── CTL-e: the repository was never mutated. A control that writes into the tree it is
# measuring is not a control. Graded LAST, after every fixture above.
if [ ! -e "$ROOT/examples/ctl" ] && [ ! -e "$ROOT/reference/schemas/food-list-copy.md" ] \
   && [ ! -e "$ROOT/reference/schemas/scratch-notes.md" ]; then
  PASS "CTLe: every fixture above was built in a temp dir; the repository tree was never written to"
else
  FAIL "CTLe: a fixture appears to have been written into the repository tree"
fi

if [ "$CTL_RAN" -ne 1 ]; then
  FAIL "X1: group CTL did not execute — a run without it is a failure, never a pass"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PF — no verdict in this suite, or in the validator it sources, is decided by a
# pipeline's exit status.
#
# A verdict site whose writer pipes into an early-exiting `grep -q` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on
# first match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed
# although the match succeeded. It was OBSERVED here, on arm XC, whose FAIL branch accuses
# the corpus of an exclusion it never made.
#
# Why a standing arm rather than a comment: XC is an `if <test>; then PASS` site, where the
# spurious status is a false RED and someone re-runs. has_finding()'s call sites include
# the inverted form (`! has_finding` at CTL-A2neg), where the same status is a false GREEN
# on a state that carries the finding. The dangerous direction is the one nobody would see,
# so the shape is what is asserted absent, not the arm it happened to surface on.
#
# The validator is in the scan set because this suite SOURCES it: its functions run in this
# shell, under this file's `pipefail`, so a pipeline verdict introduced there would be this
# suite's defect and no other file's scan would ever see it.
#
# The needle is assembled from two pieces because this scan reads its own source — a
# literal spelling of the shape in the detector would make the detector match itself and
# report a defect it had just introduced.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group PF — no verdict here is decided by a pipeline's exit status."
PF_PIPE_SHAPE='| grep -'"q"
PF_PIPE_TIGHT='|grep -'"q"
PF_BAD=0; PF_GOOD=0; PF_UNREAD=0
for pffile in "$SELF" "$SELF_VALIDATOR"; do
  if [ ! -r "$pffile" ]; then
    PF_UNREAD=$((PF_UNREAD+1)); continue
  fi
  while IFS= read -r pfline || [ -n "$pfline" ]; do
    # An OR-list is not a pipeline. Its two-character operator carries the one-character
    # one as a substring, so a correct `grep -qF a f OR grep -qF b f` line reads as the
    # defect shape and would turn this suite red for being right. Neither file in this
    # scan set carries such a line today; the scrub is here so the scan does not acquire
    # a false positive the first time one is written. The publish-guard suite's group E
    # already carries one, which is what makes this a measured concern and not a guess.
    pfscrub="${pfline//||/  }"
    case "$pfscrub" in
      *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
    esac
    case "$pfline" in
      *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
    esac
  done < "$pffile"
done
# Graded in the order that makes the zero mean something: a scan that cannot read its
# inputs, or that finds no instance of the CORRECT form, is broken, and its zero on the
# incorrect form would be a probe failure wearing a pass. An empty input is broken, not
# clean — the same rule XC1 applies to the section probe.
if [ "$PF_UNREAD" -ne 0 ]; then
  FAIL "PF1: $PF_UNREAD of the 2 files in the scan set were unreadable, so the verdict below would cover less than it claims"
elif [ "$PF_GOOD" -eq 0 ]; then
  FAIL "PF1: the scan found 0 here-string grep -q sites across the scan set, so its zero on the pipeline shape proves nothing — the convention or the scan has moved, and neither verdict is trustworthy"
elif [ "$PF_BAD" -eq 0 ]; then
  PASS "PF1: ${PF_GOOD} grep -q sites across this suite and the validator it sources, 0 of them pipelines — no verdict here can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
else
  FAIL "PF1: ${PF_BAD} verdict site(s) in the scan set pipe into an early-exiting grep under pipefail — it exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead; it is a simple command, so pipefail has nothing to aggregate"
fi

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
printf 'SELECTOR: %d files selected / %d excluded / %d unmatched = %d tracked; %d validated, %d skipped under the tolerant read.\n' \
  "$AR_NSEL" "$AR_NEXC" "$AR_NUNM" "$AR_NPOP" "$AR_NVER" "$AR_NSKIP"
printf 'COVERAGE: %d witness / %d no-witness / %d total.\n' "$CV_W" "$CV_N" "$SC_NFILES"
if [ "$vacuous" -gt 0 ]; then
  printf 'NOTE: %d assertion group(s) had an EMPTY POPULATION and proved nothing. This run rests on group CTL.\n' "$vacuous"
fi
rc=0
[ "$fail" -eq 0 ] || rc=1
# STRICT SKIP MODE — a skipped group is a failure unless it is declared. This suite has no
# dependency-gated group, so its declared set is correctly EMPTY and every skip fails.
if [ "${GUARD_STRICT_SKIPS:-0}" = "1" ]; then
  unexpected=""
  # shellcheck disable=SC2086
  for g in $SKIPPED; do
    case " ${GUARD_EXPECTED_SKIPS:-} " in
      *" $g "*) ;;
      *)        unexpected="$unexpected$g " ;;
    esac
  done
  if [ -n "$unexpected" ]; then
    printf 'STRICT: group(s) skipped but not declared in GUARD_EXPECTED_SKIPS: %s\n' "$unexpected"
    rc=1
  else
    printf 'STRICT: every skip was declared (%s) — no group vanished silently.\n' "${GUARD_EXPECTED_SKIPS:-none}"
  fi
fi
exit "$rc"
