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
#   CTL  a synthetic fixture tree, built in a temp dir ON EVERY RUN, population by
#        construction at every wave. One MUST-FIRE arm per code the validator can emit,
#        plus the specificity arms that tell a correct implementation from a lookalike.
#        A code with no arm is a check indistinguishable from one that CANNOT fire.
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
has_finding() { printf '%s\n' "$1" | grep -q "^FINDING $2 "; }

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
  if printf '%s\n' "$(xc_section_text "$xsec")" | grep -qF -- "$xwar"; then
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
if printf '%s\n' "$(xc_section_text '## 11. What This Document Does Not Define')" | grep -qF -- 'zzz-no-such-exclusion/*.md'; then
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
CV_W=0; CV_N=0
while IFS= read -r sf; do
  [ -n "$sf" ] || continue
  sl="$(va_schema_lines "$ROOT" "$sf" 2>/dev/null | grep -v '^FINDING ')"
  if [ -n "$(va_schema_get "$sl" witness)" ]; then CV_W=$((CV_W+1))
  elif [ -n "$(va_schema_get "$sl" no-witness-because)" ]; then CV_N=$((CV_N+1)); fi
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

# ─────────────────────────────────────────────────────────────────────────────────
echo
echo "CTL — a synthetic fixture tree, population by construction, built fresh every run"
# ─────────────────────────────────────────────────────────────────────────────────
# Every fixture is BUILT from the real corpus copied at runtime, never from a literal in
# this file. A fixture that was never constructed is a green proving nothing, one level
# down — so each mutation is asserted to have changed the tree before the arm it feeds is
# graded.

# mk_root <dir> — a fixture repository: the real architecture document and the real schema
# corpus, plus an empty artifact tree. Copying rather than synthesising is what keeps the
# CTL arms honest: they exercise the corpus this commit actually ships.
mk_root() {
  local d="$1"
  mkdir -p "$d/reference/schemas" "$d/examples/ctl/outputs" "$d/templates"
  cp "$ROOT/$VA_ARCH_DOC" "$d/reference/data-architecture.md"
  cp "$ROOT/$VA_SCHEMA_DIR"/*.md "$d/reference/schemas/"
}
run_fx() { va_main --root "$1" --scope dir . 2>&1; }

CTL_RAN=0

FX="$WORK/clean"; mk_root "$FX"
CLEAN_OUT="$(run_fx "$FX")"; CLEAN_RC=$?
CTL_RAN=1
if [ "$CLEAN_RC" -eq 0 ] && ! printf '%s\n' "$CLEAN_OUT" | grep -q '^FINDING '; then
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
if printf '%s\n' "$B_OUT" | grep -q "^FINDING A3 examples/ctl/outputs/food-list.md field writer "; then
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
if [ "$R" -eq 0 ] && ! has_finding "$O" 'A2' && printf '%s\n' "$O" | grep -q '^SKIP examples/ctl/unclaimed.md'; then
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
if [ "$R" -eq 0 ] && ! printf '%s\n' "$O" | grep -q 'templates/trip-context.template.md'; then
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
if printf '%s\n' "$(xc_section_text '## 11. What This Document Does Not Define')" | grep -qF -- 'templates/*.template.md'; then
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
