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
#   CA   the several homes of each class's assignment agree: § 1.1's columns, § 6's Members
#        column, § 9's per-class delta column, and the frontmatter of the class's declared
#        witness. Per-field denominators, because the fields do not all have the same number
#        of homes, and `writer` is excluded with its ground measured rather than asserted.
#   PB   the publish-bound artifact set matches the site-layout spec's declaring fence, in
#        both directions and with the class agreeing per row.
#   CTL  a synthetic fixture tree, built in a temp dir ON EVERY RUN, population by
#        construction at every wave. One MUST-FIRE arm per code the validator can emit,
#        plus the specificity arms that tell a correct implementation from a lookalike.
#        A code with no arm is a check indistinguishable from one that CANNOT fire.
#
# ── WHY EN, CA AND PB RUN AGAINST THE REAL TREE AND NOT INSIDE A FIXTURE ─────────
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
en_keys() {
  awk '
    $0 ~ /^### 4\.4 / { insec = 1; next }
    insec && (/^### / || /^## /) { insec = 0 }
    insec && $0 == "```yaml" { infence = 1; next }
    infence && $0 == "```" { infence = 0; next }
    infence && match($0, /^[a-z][a-z0-9-]*:[^<>]*<[^<>]*\|[^<>]*>/) { k = $0; sub(/:.*$/, "", k); print k }
  ' "$EN_DOC"
}

# en_canonical <key> — the member list, from the universal-frontmatter block and nowhere
# else. One line per declaration site, so the caller can assert the site is singular.
en_canonical() {
  awk -v key="$1" '
    $0 ~ /^### 4\.4 / { insec = 1; next }
    insec && (/^### / || /^## /) { insec = 0 }
    insec && $0 == "```yaml" { infence = 1; next }
    infence && $0 == "```" { infence = 0; next }
    infence && index($0, key ":") == 1 {
      if (match($0, /<[^<>]*\|[^<>]*>/)) print substr($0, RSTART + 1, RLENGTH - 2)
    }
  ' "$EN_DOC"
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
