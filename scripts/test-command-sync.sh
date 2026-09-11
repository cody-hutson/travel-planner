#!/usr/bin/env bash
#
# test-command-sync.sh — the command-sync guard suite.
#
#   ./scripts/test-command-sync.sh
#
# Grades scripts/sync-commands.sh, which copies the trip commands to a user-scope commands
# directory. It SOURCES that script rather than re-implementing it, the same relation
# scripts/test-artifact-schema.sh has to scripts/validate-artifacts.sh — a suite sources a
# production script, never the reverse.
#
# ── THE VACUITY DOOR THIS SUITE IS BUILT AROUND ──────────────────────────────────
# The script's own default destination is the user-scope commands directory. A suite that
# let that default stand would measure the RUNNER'S home, and on a clean runner that
# directory is empty or absent: every assertion would be universally quantified over the
# empty set — vacuously true, never skipped, silently green. Worse than no check, because
# it reads as proof.
#
# So EVERY arm here drives the script through an INJECTED --root and --dest, into a
# fixture tree built under a temp dir on every invocation. Population is non-zero BY
# CONSTRUCTION, at every run. That is why --dest is a contract requirement of the script
# and not a convenience flag: without it this suite could not exist, and the script would
# be ungradable except against whatever machine happened to run it.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   FX   fixture integrity, graded FIRST in every arm. A control built on a fixture that
#        was never constructed is a green proving nothing, one level down.
#   CK   --check reports each of the three per-file states, and WRITES NOTHING. The
#        no-write claim is measured rather than asserted: the whole destination tree is
#        digested before and after, and the two digests are compared.
#   AP   --apply preserves before overwriting, installs what is absent, and reports what
#        it preserved and where.
#   ID   idempotence. A second --apply over a synced tree copies nothing and creates NO
#        new backup directory — the second half matters more than the first, because a
#        backup per invocation is how a preserve-then-copy design quietly fills a disk.
#   SP   the specificity arms. A clean tree reports zero diverged WHILE THE SAME PROBE
#        reports non-zero on a planted divergence, so the zero is a measurement rather
#        than a broken probe. A zero whose control arm also returns zero is a broken
#        probe, and this suite refuses to report one as a clean result.
#   XR   the source-path resolution failure. A --root whose commands directory does not
#        exist must FAIL rather than report a clean empty sync — the two were otherwise
#        indistinguishable, and a mistyped root would be answered with a green.
#   PF   no verdict in this suite is decided by a pipeline's exit status. The sibling
#        suites carry this arm for a measured reason: a verdict site that pipes into an
#        early-exiting reader dies on SIGPIPE under pipefail and reports failure on a
#        successful match.
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# IN SCOPE — the copy mechanics: which files are selected, what state each is reported in,
# what is written, what is preserved, and what a second run does.
# OUT OF SCOPE, by name:
#   WHETHER A RUNTIME READS THE DESTINATION. This suite asserts that files arrive at a
#   directory. That a command picker reads that directory is a property of the runtime and
#   a green here is not evidence of it.
#   THE CONTENT OF THE COMMAND FILES. Their conformance to the trip-resolution contract is
#   the contract suite's invariant, and their taxonomy bijection is the taxonomy suite's.
#   Three guards, three invariants, no overlap.
#   A REAL USER'S COMMANDS DIRECTORY. Nothing here touches one, by construction.
#
# STRICT SKIP MODE (set by CI — .github/workflows/command-sync.yml).
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# This suite is pure bash with no Node, no gh and no network, so it has NO legitimate skip
# and its expected-skip set is correctly EMPTY.
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Absolute, because group PF reads this file and the script it sources back off disk, and
# this suite runs from whatever directory the runner happens to be in.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
SUBJECT="$HERE/sync-commands.sh"

# shellcheck source=sync-commands.sh
source "$SUBJECT"     # BASH_SOURCE guard prevents dispatch

set +e

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# A content digest of a whole directory tree: every path and every byte. This is what turns
# "--check writes nothing" from a claim into a measurement. Sorted, so two digests of one
# unchanged tree are equal for the right reason rather than by luck of readdir order.
tree_digest() {  # <dir>
  local d="$1"
  [ -d "$d" ] || { printf 'ABSENT'; return 0; }
  find "$d" -type f | LC_ALL=C sort | while IFS= read -r p; do
    printf '%s ' "${p#"$d"}"
    cksum < "$p"
  done
}

has_state() {  # <output> <STATE> <basename>
  grep -q -x -F -- "$2 $3" <<<"$1"
}

# A source tree shaped like the repository's own: a commands directory holding files that
# match the script's pattern, plus one that does not, so selection is exercised rather
# than assumed.
mk_source() {  # <dir>
  local d="$1"
  mkdir -p "$d/.claude/commands"
  printf 'v1 trip\n'              > "$d/.claude/commands/trip.md"
  printf 'v1 trip-new\n'          > "$d/.claude/commands/trip-new.md"
  printf 'v1 trip-record\n'       > "$d/.claude/commands/trip-record.md"
  printf 'not a trip command\n'   > "$d/.claude/commands/other.md"
}

# The script's DEFAULT destination is a real user's commands directory, and this suite's
# claim about it is that no arm ever drove the script there. Snapshotted HERE, before the
# first arm runs, so group RT can report what happened to it as a measurement spanning the
# whole run rather than as the author's recollection. See RT2 for what the comparison does
# and does not establish.
RT_HOME_DEST="$(sc_default_dest)"
RT_HOME_BEFORE="$(tree_digest "$RT_HOME_DEST")"

echo "── Group FX — fixture integrity. Every arm below rests on these."

FX_SRC="$WORK/src"
mk_source "$FX_SRC"
FX_N="$(sc_source_files "$FX_SRC" | wc -l | tr -d ' ')"
if [ "$FX_N" -eq 3 ]; then
  PASS "FX1: the injected source tree yields a population of $FX_N command file(s) — non-zero BY CONSTRUCTION, which is what keeps every assertion below a measurement rather than a vacuous truth over an empty set"
else
  FAIL "FX1: the injected source tree yielded $FX_N command file(s) — the arms below would prove nothing"
fi

FX_SEL="$(sc_source_files "$FX_SRC")"
if ! grep -q -x -F -- 'other.md' <<<"$FX_SEL" && grep -q -x -F -- 'trip.md' <<<"$FX_SEL"; then
  PASS "FX2: selection is by pattern and it discriminates — the non-matching file in the same directory is not selected while the matching ones are, so the population is a filter result and not a directory listing"
else
  FAIL "FX2: selection did not discriminate — either a non-matching file was selected or a matching one was not"
fi

echo
echo "── Group CK — --check reports per-file state and writes nothing."

CK_DEST="$WORK/dest-check"
mkdir -p "$CK_DEST"
cp "$FX_SRC/.claude/commands/trip.md"      "$CK_DEST/trip.md"          # IDENTICAL
printf 'v0 stale\n'                      > "$CK_DEST/trip-new.md"      # DIVERGED
#                                                                        trip-record.md ABSENT

CK_BEFORE="$(tree_digest "$CK_DEST")"
CK_OUT="$(sc_check "$FX_SRC" "$CK_DEST")"; CK_RC=$?
CK_AFTER="$(tree_digest "$CK_DEST")"

if has_state "$CK_OUT" 'IDENTICAL' 'trip.md'; then
  PASS "CK1: a byte-identical destination copy is reported IDENTICAL"
else
  FAIL "CK1: a byte-identical destination copy was not reported IDENTICAL: $(printf '%s' "$CK_OUT" | head -3 | tr '\n' ' ')"
fi
if has_state "$CK_OUT" 'DIVERGED' 'trip-new.md'; then
  PASS "CK2: MUST-FIRE — a destination copy whose bytes differ is reported DIVERGED. This is the state the whole script exists to surface: the copies sit outside the working tree, so nothing else in this repository can observe them drifting"
else
  FAIL "CK2: a diverged destination copy was not reported DIVERGED: $(printf '%s' "$CK_OUT" | head -3 | tr '\n' ' ')"
fi
if has_state "$CK_OUT" 'ABSENT' 'trip-record.md'; then
  PASS "CK3: a missing destination copy is reported ABSENT — its own state, not a kind of DIVERGED, so a first install does not read as drift"
else
  FAIL "CK3: a missing destination copy was not reported ABSENT: $(printf '%s' "$CK_OUT" | head -3 | tr '\n' ' ')"
fi
if [ "$CK_RC" -ne 0 ]; then
  PASS "CK4: --check returned non-zero on a destination carrying a diverged and an absent file, so the verdict is usable by a caller that only reads the exit status"
else
  FAIL "CK4: --check returned 0 on a destination carrying a diverged and an absent file"
fi
if [ "$CK_BEFORE" = "$CK_AFTER" ]; then
  PASS "CK5: --check wrote NOTHING — the whole destination tree digests identically before and after, path by path and byte by byte. Measured, not asserted"
else
  FAIL "CK5: --check modified the destination tree; the report-only mode is not report-only"
fi

echo
echo "── Group SP — specificity. A zero is a measurement only when the same probe fires elsewhere."

SP_DEST="$WORK/dest-clean"
mkdir -p "$SP_DEST"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  cp "$FX_SRC/.claude/commands/$f" "$SP_DEST/$f"
done <<EOF
$FX_SEL
EOF
SP_CLEAN_OUT="$(sc_check "$FX_SRC" "$SP_DEST")"; SP_CLEAN_RC=$?
SP_CLEAN_DIV="$(grep -c -E '^DIVERGED ' <<<"$SP_CLEAN_OUT")"
SP_DIRTY_DIV="$(grep -c -E '^DIVERGED ' <<<"$CK_OUT")"

if [ "$SP_DIRTY_DIV" -gt 0 ] && [ "$SP_CLEAN_DIV" -eq 0 ]; then
  PASS "SP1: the SAME divergence probe reads $SP_DIRTY_DIV on the planted-divergence tree and $SP_CLEAN_DIV on the fully-synced tree — the zero is a measurement of the tree rather than a probe that cannot fire"
else
  FAIL "SP1: the divergence probe did not discriminate (planted=$SP_DIRTY_DIV synced=$SP_CLEAN_DIV) — a zero from it would prove nothing"
fi
if [ "$SP_CLEAN_RC" -eq 0 ]; then
  PASS "SP2: --check returned 0 on a fully-synced destination, so the non-zero in CK4 is attributable to the divergence and not to the mode"
else
  FAIL "SP2: --check returned non-zero on a fully-synced destination"
fi

echo
echo "── Group AP — --apply preserves the version it replaces, then copies."

AP_DEST="$WORK/dest-apply"
AP_BK="$WORK/backups-apply"
mkdir -p "$AP_DEST"
printf 'v0 stale\n' > "$AP_DEST/trip.md"
AP_PRESTATE="$(cat "$AP_DEST/trip.md")"
AP_OUT="$(sc_apply "$FX_SRC" "$AP_DEST" "$AP_BK")"; AP_RC=$?

if [ "$AP_RC" -eq 0 ]; then
  PASS "AP1: --apply returned 0 over a destination holding one stale file and two missing ones"
else
  FAIL "AP1: --apply returned $AP_RC: $(printf '%s' "$AP_OUT" | head -4 | tr '\n' ' ')"
fi
if cmp -s "$FX_SRC/.claude/commands/trip.md" "$AP_DEST/trip.md" \
   && cmp -s "$FX_SRC/.claude/commands/trip-record.md" "$AP_DEST/trip-record.md"; then
  PASS "AP2: after --apply every source file is byte-identical at the destination — the one that was stale and the ones that were absent alike"
else
  FAIL "AP2: the destination does not match the source after --apply"
fi
if [ ! -e "$AP_DEST/other.md" ]; then
  PASS "AP3: the non-matching file in the source commands directory was NOT copied — --apply writes the command files and only those"
else
  FAIL "AP3: a file outside the command pattern was copied to the destination"
fi

AP_BACKUP="$(find "$AP_BK" -type f -name 'trip.md' 2>/dev/null | head -1)"
if [ -n "$AP_BACKUP" ] && [ "$(cat "$AP_BACKUP")" = "$AP_PRESTATE" ]; then
  PASS "AP4: MUST-FIRE — the version being replaced was preserved BEFORE the overwrite, and the preserved bytes equal the pre-state exactly. The order is the whole safety property: a failed copy after a backup leaves both versions, a failed backup after a copy leaves neither"
else
  FAIL "AP4: the replaced version was not preserved, or the preserved bytes are not the pre-state"
fi
if [ -n "$AP_BACKUP" ]; then
  case "$AP_BACKUP" in
    "$AP_DEST"/*) FAIL "AP5: the backup was written INSIDE the destination commands directory, where a markdown file sits among files that are read as commands" ;;
    *)            PASS "AP5: the backup landed outside the destination commands directory, so no preserved copy can sit among files the runtime reads as commands — the design does not rest on an unestablished property of command discovery" ;;
  esac
else
  FAIL "AP5: no backup was produced, so its location cannot be asserted"
fi
if grep -q -F -- 'PRESERVED' <<<"$AP_OUT"; then
  PASS "AP6: --apply reports what it preserved and where, so the user is told where the replaced version went rather than having to find it"
else
  FAIL "AP6: --apply did not report what it preserved"
fi

echo
echo "── Group ID — idempotence, and specifically that a second run creates no new backup."

ID_BK_BEFORE="$(find "$AP_BK" -type d 2>/dev/null | LC_ALL=C sort)"
ID_DEST_BEFORE="$(tree_digest "$AP_DEST")"
ID_OUT="$(sc_apply "$FX_SRC" "$AP_DEST" "$AP_BK")"; ID_RC=$?
ID_BK_AFTER="$(find "$AP_BK" -type d 2>/dev/null | LC_ALL=C sort)"
ID_DEST_AFTER="$(tree_digest "$AP_DEST")"

if [ "$ID_RC" -eq 0 ] && [ "$ID_DEST_BEFORE" = "$ID_DEST_AFTER" ]; then
  PASS "ID1: a second --apply over a synced destination left the whole tree byte-identical — the operation is idempotent"
else
  FAIL "ID1: a second --apply changed the destination tree (rc=$ID_RC)"
fi
if [ "$ID_BK_BEFORE" = "$ID_BK_AFTER" ]; then
  PASS "ID2: MUST-HOLD — the second --apply created NO new backup directory. This is the half that matters: a preserve-then-copy design that backs up unconditionally grows one directory per invocation forever, and the growth is invisible until it is not"
else
  FAIL "ID2: the second --apply created a backup directory although nothing was overwritten"
fi
if grep -q -E '^UNCHANGED ' <<<"$ID_OUT"; then
  PASS "ID3: the second run reports each already-current file as UNCHANGED, so an idempotent run is legible as one rather than looking like a no-op that failed"
else
  FAIL "ID3: the second run did not report any file as UNCHANGED"
fi

echo
echo "── Group XR — a source path that does not resolve FAILS rather than reporting a clean empty sync."

XR_OUT="$(sc_main --root "$WORK/no-such-root" --dest "$WORK/dest-xr" --check 2>&1)"; XR_RC=$?
if [ "$XR_RC" -ne 0 ] && grep -q -F -- 'ERROR' <<<"$XR_OUT"; then
  PASS "XR1: MUST-FIRE — a --root whose commands directory does not exist is an ERROR and a non-zero exit. Without this, a mistyped root yields an empty file list, zero counts and exit 0 — byte-identical to a genuinely clean sync, so the user is told their copies are current for a question that was never asked"
else
  FAIL "XR1: an unresolvable --root produced rc=$XR_RC without an ERROR line — a mistyped root would read as a clean sync"
fi
if [ ! -d "$WORK/dest-xr" ]; then
  PASS "XR2: the failed run created no destination directory — a --check that cannot resolve its source writes nothing at all"
else
  FAIL "XR2: the failed --check created a destination directory"
fi

XV_OUT="$(sc_check "$FX_SRC" "$WORK/dest-never")"
if grep -q -F -- 'ABSENT' <<<"$XV_OUT"; then
  PASS "XR3: --check against a destination that does not exist yet reports every file ABSENT rather than erroring — a check run before the first install answers the question it was asked"
else
  FAIL "XR3: --check against a non-existent destination did not report ABSENT rows"
fi

echo
echo "── Group EX — the export line, printed on every run of both modes."

EX_CHECK="$(sc_main --root "$FX_SRC" --dest "$SP_DEST" --check 2>&1)"
EX_APPLY="$(sc_main --root "$FX_SRC" --dest "$SP_DEST" --backup "$WORK/backups-ex" --apply 2>&1)"
EX_WANT="$(sc_export_line "$FX_SRC")"
if grep -q -F -- "$EX_WANT" <<<"$EX_CHECK" && grep -q -F -- "$EX_WANT" <<<"$EX_APPLY"; then
  PASS "EX1: both modes print the export line carrying the root they were actually run against. --check prints it too, deliberately: the user who ran a read-only check to find out whether their copies are current is exactly the user who has not set the variable"
else
  FAIL "EX1: the export line naming the run's own root was not printed by both modes"
fi
if grep -q -F -- "$FX_SRC" <<<"$EX_CHECK"; then
  PASS "EX2: the printed value is the resolved root of THIS run, not a placeholder — the script is the one surface that knows the correct value, because it was just handed it"
else
  FAIL "EX2: the printed export line does not carry this run's resolved root"
fi

echo
echo "── Group RT — the real repository tree is a population this suite can see, and never writes to."

RT_N="$(sc_source_files "$ROOT" | wc -l | tr -d ' ')"
if [ "$RT_N" -gt 0 ]; then
  PASS "RT1: the repository's own commands directory yields $RT_N command file(s), so the script's selector resolves against the real tree and not only against the fixture"
else
  VACUOUS "RT: the repository's own commands directory yields no command file. Every arm above rests on the injected fixture, which is exactly why the fixture is injected"
fi
# ── RT2 — the real destination, before and after.
#
# This arm previously tested only that sc_default_dest() does not resolve inside this
# suite's temp dir, while its PASS text claimed that no arm drove the script at its default
# destination. The predicate never measured that, and it also INVERTED against the safest
# hardening available here: sandboxing HOME into the fixture — the obvious move for a
# maintainer who wants the default to be harmless — made the arm report a leak. So the
# comparison is the measurement now, and the message says only what the comparison shows.
#
# What it establishes: the default destination is byte-identical to its state before the
# first arm ran. What it does NOT establish, and therefore no longer claims: that nothing
# READ it. A read leaves nothing behind for an arm here to observe.
RT_HOME_AFTER="$(tree_digest "$RT_HOME_DEST")"
if [ -z "$RT_HOME_DEST" ]; then
  PASS "RT2: HOME is unset in this environment, so the script resolves no default destination at all — there was none for an arm to drive the script at, and the property holds by construction rather than by measurement"
elif [ "$RT_HOME_AFTER" = "$RT_HOME_BEFORE" ]; then
  PASS "RT2: the script's default destination ($RT_HOME_DEST) is byte-identical to its state before the first arm of this suite ran — digested at both ends, so a write there would have shown up whether the directory existed beforehand or not. Every arm passed an injected --dest and none of them wrote to a real user's commands directory"
else
  FAIL "RT2: the script's default destination ($RT_HOME_DEST) changed across this run — an arm drove the script without an injected --dest and wrote into a real user's commands directory"
fi

echo
echo "── Group PF — no verdict in this file is decided by a pipeline's exit status."
PF_PIPE_SHAPE='| grep -'"q"
PF_PIPE_TIGHT='|grep -'"q"
PF_BAD=0; PF_GOOD=0
for pfsrc in "$SELF" "$SUBJECT"; do
  if [ ! -r "$pfsrc" ]; then
    FAIL "PF1: $pfsrc is unreadable, so the scan below would cover nothing while reporting a zero"
    PF_GOOD=-1
    break
  fi
  while IFS= read -r pfline || [ -n "$pfline" ]; do
    # An OR-list is not a pipeline, and its two-character operator carries the
    # one-character one as a substring. Neutralise it before the test.
    pfscrub="${pfline//||/  }"
    case "$pfscrub" in
      *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
    esac
    case "$pfline" in
      *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
    esac
  done < "$pfsrc"
done
# Graded in the order that makes the zero mean something: a detector finding no instance of
# the CORRECT form is broken, and its zero on the incorrect form would be a probe failure
# wearing a pass.
if [ "$PF_GOOD" -eq 0 ]; then
  FAIL "PF1: the scan found 0 here-string grep -q sites across this suite and the script it sources, so its zero on the pipeline shape proves nothing"
elif [ "$PF_GOOD" -lt 0 ]; then
  : # already reported above
elif [ "$PF_BAD" -eq 0 ]; then
  PASS "PF1: ${PF_GOOD} grep -q sites across this suite and the script it sources, 0 of them pipelines — no verdict here can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
else
  FAIL "PF1: ${PF_BAD} verdict site(s) pipe into an early-exiting grep under pipefail — it exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead"
fi

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
if [ "$vacuous" -gt 0 ]; then
  printf 'NOTE: %d assertion group(s) had an EMPTY POPULATION and proved nothing about this tree.\n' "$vacuous"
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
