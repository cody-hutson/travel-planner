#!/usr/bin/env bash
#
# test-trip-resolution-contract.sh — the trip-resolution CONTRACT-CONFORMANCE guard.
#
# The trip-resolution contract has one normative home: CLAUDE.md § "Resolving a trip".
# The `!` pre-execution mechanism fires only inside a command file's own body and there
# is no include directive, so every consuming command file must physically carry the
# evidence blocks. That duplication is forced by the platform, not chosen — and this
# suite is what makes it safe: it EXTRACTS the canonical list from CLAUDE.md and asserts
# every consumer's copy is byte-identical. Copy plus assertion is not the same thing as
# copy; a divergent copy is a red check rather than a latent defect.
#
#   ./scripts/test-trip-resolution-contract.sh
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   PIN  the canonical literals, read FROM CLAUDE.md: the section exists and is
#        uniquely named; the evidence list is a fenced literal whose entries are
#        contiguous from E1, `!`-prefixed and stderr-capturing; the header block
#        yields a citation line. Plus the self-check that gives this suite its
#        reason to exist — THIS SCRIPT HOLDS NO COPY of any canonical entry.
#   RP   the real consumer population under .claude/commands/: citation line present,
#        evidence blocks byte-identical to the canonical at their index, the prefix
#        contiguous from index 1 and EXACTLY the length the declared `contract-depth`
#        requires — no fewer blocks and no more — and `contract-depth` equal to the
#        maximum depth in the file's own verb table.
#   CTL  a synthetic five-file fixture tree, built in a temp dir ON EVERY RUN. Two arms
#        MUST NOT fire — a clean tree, and a table whose depth cells are rendered as
#        code spans; the rest are deliberate defects that MUST, ONE PER FAILURE CODE the
#        checker can emit — H1 H2 H3 P1 P2 P3 D1 D2 — plus the specificity arms, proving
#        the verb-table depth is read by FIELD INDEX and not by a row-wide match, and
#        that normalising the depth cell did not widen it into "any token is a depth".
#        A code with no arm is a check indistinguishable from one that CANNOT
#        fire, which is the precise defect this suite exists to prevent; leaving one
#        unexercised inside the anti-drift guard would be that defect at its own root.
#   Three further groups assert properties of THIS FILE rather than of the contract, and
#   each carries its full reasoning at the group rather than here: PF, that no verdict in
#   this file is decided by a pipeline's exit status; MD, that every PASS here requires
#   evidence its subject could only have produced by RUNNING; and FZ, that no verdict arm
#   in this file reaches PASS through a disjunction — the shape the unable-to-fail arm
#   corrected in group CTL had.
#
# ── WHY CTL IS NOT OPTIONAL DECORATION ───────────────────────────────────────────
# This contract ships in Wave 0, BEFORE any of the five command files exists. At that
# point the real population is ZERO and every RP assertion is a universally-quantified
# statement over the empty set — vacuously true, never skipped, silently green. That is
# "a green that proves less than it looks like", which is worse than no CI because it
# reads as proof. Two mechanisms close it. RP reports its observed population count and
# renders VACUOUS rather than a bare PASS when that count is zero, so an empty run is
# never mistaken for a conformant one. And CTL has population 5 BY CONSTRUCTION on every
# invocation, at every wave — it is what makes this suite gradable at all before the
# consumers exist. A run in which CTL did not execute is a failure, not a pass.
#
# Every CTL fixture is BUILT from the canonical list extracted at runtime, never from a
# literal in this file. The defect arms MUTATE that extracted value, and each mutation
# is asserted to have actually changed the string before the arm it feeds is graded — a
# fixture that was never constructed is a green proving nothing, one level down.
#
# ── ONE CONSTRAINT THIS SUITE CARRIES, WITH ITS REASON ───────────────────────────
# It MUST NOT scan CLAUDE.md for publish-script invocations. Exactly one rendering of
# the archive hand-off conforms — a code span containing the bare script path with flags
# in prose — and the surface renders such hand-offs by POINTING AT CLAUDE.md's
# "Publishing to GitHub Pages" section, which carries the literal delete line. Extending
# an invocation scan to CLAUDE.md would therefore make the conforming hand-off itself
# the violation. The reason is recorded beside the constraint so a later contributor
# does not "complete" the scan. This suite reads CLAUDE.md for two purposes only: to
# assert the section exists and is uniquely named, and to extract the canonical literals
# that section declares (the evidence list and the header citation line). It performs no
# other scan of that file.
#
# ── SCOPE BOUNDARY AGAINST THE TAXONOMY GUARD ────────────────────────────────────
# Two guards, two invariants, no overlap. This one asserts CONTRACT CONFORMANCE (header
# present, evidence byte-identical, depth consistent). scripts/test-command-taxonomy.sh
# asserts TAXONOMY BIJECTION (Step-1 row <-> (command, verb)). Neither re-implements the
# other, which is what lets this one ship without waiting on that one.
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# IN SCOPE — the DECLARATION surface. A green means every consumer DECLARES the contract
# as CLAUDE.md states it. OUT OF SCOPE — CONDUCT: this suite cannot assert that a model
# actually walks the gate ladder, and a green is not evidence that it did. Also out of
# scope — RUNTIME PRIVILEGE: `allowed-tools` is a turn-scoped pre-approval grant, not an
# enforced permission set, so a green here is NOT a privilege guarantee.
#
# STRICT SKIP MODE (set by CI — .github/workflows/trip-resolution-contract.yml).
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# This suite is pure bash with no Node, no gh and no network, so it has NO legitimate
# skip and its expected-skip set is correctly EMPTY. VACUOUS is deliberately a distinct
# verdict from SKIP: a skipped GROUP is a hole in the suite, an empty POPULATION is a
# real measurement of the tree, and collapsing the two would hide one behind the other.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Absolute, because group PF reads this file back off disk and this suite is run from
# whatever directory the runner happens to be in.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
# NOTE: publish-trip-site.sh is deliberately NOT sourced. This suite needs no function
# from it, and sourcing a security-critical script to parse markdown would create shared
# fate — a syntax error there would make the CONTRACT invariant unverifiable for a reason
# with nothing to do with the contract.
set +e

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
# ── THE DISCRIMINATING-EVIDENCE RULE (DER) — helpers, asserted by group MD ─────────
#
# THE RULE. An assertion is MUTATION-DETECTABLE iff every path to its PASS requires
# evidence the subject could only have produced by RUNNING. Equivalently: PASS may never
# be reached on a branch a DEGENERATE outcome also reaches — an absent subject, an empty
# haystack, an unreadable input, an empty population.
#
# expect_rc replaces bare truthiness with an exact expected status. `if f …; then FAIL;
# else PASS` puts the PASS on EVERY non-zero status, so rc=127 — "the function does not
# exist" — is graded identically to rc=1 — "the check correctly rejected". Measured in the
# publish-guard suite: deleting verify_ciphertext outright left four assertions reporting
# PASS against a function that no longer existed, and deleting an entire subcommand left
# the suite exiting 0. The status is the evidence, so the status is what is asserted.
expect_rc() {   # expect_rc <want> <id> <prose> -- <cmd…>
  local want="$1" id="$2" prose="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  local subject="${1:-<no-command>}" got
  "$@" >/dev/null 2>&1; got=$?
  if [ "$got" -eq 127 ] && [ "$want" -ne 127 ]; then
    FAIL "$id: $prose -- rc=127: '$subject' is NOT DEFINED. The subject is ABSENT, not rejecting, so this assertion has no subject to grade"
  elif [ "$got" -eq "$want" ]; then
    PASS "$id: $prose [rc=$got, expected $want]"
  else
    FAIL "$id: $prose -- expected rc=$want, got rc=$got"
  fi
}

# md_probe re-runs an assertion in a subshell with its SUBJECT removed and reports the
# verdict counts it produced. PASS/FAIL are rebound to silent counters inside that
# subshell, so nothing a probe emits reaches the run's counters or its output.
md_probe() {   # md_probe <subject-fn> <assertion-fn> [args…] -> "<pass> <fail>" on stdout
  local victim="$1"; shift
  ( unset -f "$victim" 2>/dev/null
    pass=0; fail=0
    PASS() { pass=$((pass+1)); }
    FAIL() { fail=$((fail+1)); }
    "$@" >/dev/null 2>&1
    printf '%d %d' "$pass" "$fail" )
}

# md_flips is the REGISTRATION primitive named by DER clause 6: for assertion X over
# subject S, removing S must flip X specifically. This suite registers nothing yet — see
# the note at the end of group MD — and it is shipped here so the first remediation calls
# it rather than having to introduce it.
md_flips() {   # md_flips <subject-fn> <id> <assertion-fn> [args…]
  local victim="$1" id="$2"; shift 2
  local out p f
  out="$(md_probe "$victim" "$@")"
  if ! [[ "$out" =~ ^[0-9]+[[:space:]][0-9]+$ ]]; then
    FAIL "MD[$id]: the oracle subshell returned '$out' rather than a '<pass> <fail>' pair — the probe itself failed, so this arm is not a measurement"
    return 0
  fi
  p="${out%% *}"; f="${out##* }"
  if [ "$f" -eq 1 ] && [ "$p" -eq 0 ]; then
    PASS "MD[$id]: with '$victim' removed the assertion reports exactly one FAIL and no PASS — it is mutation-detectable, so its verdict above required '$victim' to have RUN"
  else
    FAIL "MD[$id]: with '$victim' removed the assertion still reports pass=$p fail=$f — it is BLIND to its subject's absence, so its verdict above proves nothing about '$victim'"
  fi
  return 0
}

# A fourth verdict, and the point of it: an assertion whose POPULATION is empty is
# neither a pass nor a failure nor a skipped group. It is a measurement that could not
# say anything, and it must not read as one that did.
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

CLAUDE_MD="$ROOT/CLAUDE.md"
SECTION_HEADING='### Resolving a trip'
EVIDENCE_FENCE='trip-contract-evidence'
HEADER_FENCE='trip-contract-header'

# ─────────────────────────────────────────────────────────────────────────────────
# Extraction primitives. These are the ONLY reads of CLAUDE.md in this file.
# ─────────────────────────────────────────────────────────────────────────────────

# Lines of the first fenced block carrying <info> inside the section headed <heading>.
# Emitted verbatim — byte-identity is the whole point, so nothing is trimmed here.
fence_block() {  # <file> <info> <heading>
  local f="$1" info="$2" heading="$3"
  local in_sec=0 in_fence=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_sec" -eq 0 ]; then
      [ "$line" = "$heading" ] && in_sec=1
      continue
    fi
    if [ "$in_fence" -eq 1 ]; then
      [ "$line" = '```' ] && break
      printf '%s\n' "$line"
      continue
    fi
    # Outside a fence, the next heading of level 1-3 ends the section.
    case "$line" in
      '# '*|'## '*|'### '*) break ;;
    esac
    [ "$line" = '```'"$info" ] && in_fence=1
  done < "$f"
}

# ─────────────────────────────────────────────────────────────────────────────────
# The parameterized conformance checker. RP drives it against the REAL tree and CTL
# drives it against fixtures — the SAME code path, which is what makes CTL's arms
# evidence about RP's verdict rather than about a parallel implementation.
#
#   conformance_check <commands_dir> <canon_file> <citation_line> <canon_count>
#
# Emits `FINDING <id> <file> <detail>` lines; returns 1 if any finding was emitted.
# ─────────────────────────────────────────────────────────────────────────────────
conformance_check() {
  local dir="$1" canon_file="$2" citation="$3" n="$4"
  local found=0 f base line i
  local -a canon
  i=0
  while IFS= read -r line || [ -n "$line" ]; do
    i=$((i+1)); canon[$i]="$line"
  done < "$canon_file"

  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    base="${f##*/}"

    # -- header block: the citation line, byte-identical across every consumer -----
    local has_cite=0
    while IFS= read -r line || [ -n "$line" ]; do
      [ "$line" = "$citation" ] && { has_cite=1; break; }
    done < "$f"
    if [ "$has_cite" -eq 0 ]; then
      printf 'FINDING H1 %s contract header block absent (no citation line)\n' "$base"; found=1
    fi

    # -- contract-depth ------------------------------------------------------------
    local depth="" role=""
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        'contract-depth: G'[0-8]) depth="${line#contract-depth: G}" ;;
        'population-role: RESOLVE'|'population-role: CREATE') role="${line#population-role: }" ;;
      esac
    done < "$f"
    if [ -z "$depth" ]; then
      printf 'FINDING H2 %s contract-depth absent or malformed (want "contract-depth: G0".."G8")\n' "$base"; found=1
    fi
    if [ -z "$role" ]; then
      printf 'FINDING H3 %s population-role absent or malformed (want RESOLVE or CREATE)\n' "$base"; found=1
    fi

    # -- evidence prefix, byte-identical and EXACTLY the length its depth requires --
    # The required prefix length is derived from the declared depth: a file that runs
    # G3 or deeper reads trip-context.md and therefore needs the WHOLE canonical list;
    # G1-G2 needs E1 alone; G0 needs no trip and carries none. Deriving the deep case
    # from n rather than from a literal 2 is deliberate — when a later slice appends E3,
    # every deep consumer goes red until it carries the appended block, which is the
    # mechanism working rather than a defect.
    #
    # The comparison is an EQUALITY, graded in BOTH directions, because the contract
    # states an exact prefix and not a minimum. Carrying MORE of the list than the
    # declared depth requires is its own defect with its own code: every block a file
    # carries is a grant it must hold, so a G1-G2 consumer that quietly acquires E2
    # needs `Bash(grep:*)` for a function it does not have (ADR-007 §2, bound 2) and a
    # minimum-only check stays green while that happens. Equality also makes byte-
    # identity TOTAL: with no remainder past `need`, EVERY block the file carries is
    # compared against the canonical, where a minimum check left the surplus — which
    # may be an arbitrary divergent copy — never examined at all.
    #
    # When the depth is absent, H2 has already fired and the requirement is underivable,
    # so neither direction is graded: reporting a prefix defect against a depth the file
    # never declared would name the wrong thing.
    local need=0 depth_known=0
    if [ -n "$depth" ]; then
      depth_known=1
      if   [ "$depth" -ge 3 ]; then need="$n"
      elif [ "$depth" -ge 1 ]; then need=1
      else need=0
      fi
    fi
    local -a blocks
    local m=0
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        '!`'*) m=$((m+1)); blocks[$m]="$line" ;;
      esac
    done < "$f"
    if [ "$depth_known" -eq 1 ] && [ "$m" -lt "$need" ]; then
      printf 'FINDING P2 %s declares depth G%s (needs exactly %s evidence block(s)) but carries %s\n' \
        "$base" "$depth" "$need" "$m"; found=1
    elif [ "$depth_known" -eq 1 ] && [ "$m" -gt "$need" ]; then
      printf 'FINDING P3 %s declares depth G%s (needs exactly %s evidence block(s)) but carries %s — a surplus block is a tool grant this file has no function for\n' \
        "$base" "$depth" "$need" "$m"; found=1
    fi
    i=1
    while [ "$i" -le "$need" ] && [ "$i" -le "$m" ]; do
      if [ "${blocks[$i]}" != "${canon[$i]}" ]; then
        printf 'FINDING P1 %s evidence block %s is not byte-identical to canonical E%s\n' \
          "$base" "$i" "$i"; found=1
      fi
      i=$((i+1))
    done

    # -- contract-depth equals the maximum depth in the file's own verb table ------
    # Rows are `| verb | lifecycle | mode | destination | depth |`. The depth cell is
    # read by FIELD INDEX, not by a row-wide match: a row-wide matcher would also read
    # a `G8` mentioned in the lifecycle or mode cell and silently agree with itself.
    #
    # The cell is NORMALISED before it is matched, rather than matched with a widened
    # pattern. Padding is stripped, then a code-span rendering is stripped: CLAUDE.md's
    # own consumer table renders every depth value as a code span, so that is the only
    # rendered example a command author has to copy, and `G8` and a backticked `G8` are
    # the same value. Without this, `rows` falls to 0 on a table that is PRESENT and the
    # checker reports it absent — a finding that names the wrong defect entirely.
    # Normalising is deliberately narrower than widening the match: the pattern still
    # admits exactly G0-G8, so a backticked `G9`, `GG1` or `TBD` is still not a depth and
    # a table carrying only those still reads as declaring none.
    local maxd=-1 rows=0 c1 c2 c3 c4 c5 rest d
    local BT='`'
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        '|'*)
          IFS='|' read -r _ c1 c2 c3 c4 c5 rest <<EOF
$line
EOF
          d="${c5// /}"; d="${d//$BT/}"
          case "$d" in
            G[0-8])
              rows=$((rows+1))
              d="${d#G}"
              [ "$d" -gt "$maxd" ] && maxd="$d"
              ;;
          esac
          ;;
      esac
    done < "$f"
    #
    # D2 IS ROLE-NEUTRAL, and that is a repair rather than a preference. It used to fire
    # only for `population-role: RESOLVE`, and the control-fixture builder below made a
    # verb table only for RESOLVE fixtures, so a CREATE consumer carrying no table
    # produced NO FINDING AT ALL. The consequence was not confined to D2: with `rows` at
    # 0 the checker takes this branch and never reaches D1 either, so a CREATE consumer's
    # `contract-depth` was unchecked in BOTH directions — and `contract-depth` is what
    # fixes the evidence prefix a file carries, which is the whole basis of /trip-new's
    # narrower `Bash(ls:*)` grant (ADR-007 §2, bound 2). /trip-new was therefore the one
    # consumer whose depth declaration could not be machine-checked while being the
    # guard's FIRST real population.
    #
    # The contract carries no role qualifier on this requirement: its header block lists
    # the per-verb requirement table as a field every consumer carries, and it states
    # `contract-depth` equals the maximum depth in that file's own verb table for every
    # consumer — G2's `CREATE` exception is bounded to G2's own dispositions and reaches
    # nothing else in the section. The role is reported in the finding for diagnosis and
    # is read by nothing.
    if [ "$rows" -eq 0 ]; then
      printf 'FINDING D2 %s carries no per-verb requirement table (no row carries a depth cell reading G0-G8), so its contract-depth has nothing to be checked against [population-role: %s]\n' \
        "$base" "${role:-absent}"; found=1
    elif [ -n "$depth" ] && [ "$maxd" != "$depth" ]; then
      printf 'FINDING D1 %s contract-depth G%s does not equal the maximum depth in its own verb table (G%s)\n' \
        "$base" "$depth" "$maxd"; found=1
    fi
  done
  return "$found"
}

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
# THIS HELPER IS THE INVERTED POLARITY, AND IT IS THE DANGEROUS HALF. Group RP reads
# `if has_finding "$RP_OUT" 'H1'; then FAIL`, and CTLcs/CTLhs read `if ! has_finding …;
# then PASS`. In BOTH the spurious non-zero resolves toward the quiet answer: a real
# finding goes unreported and the arm records a pass on a state that carries it. Nothing
# announces that, so it cannot be caught by re-running the way a false red can. That is
# why this is closed at the shape rather than at the arms where the defect was first seen
# in the taxonomy suite, which were all `if <test>; then PASS` sites. Group PF keeps it
# closed.
has_finding() { grep -qE "^FINDING ($2) " <<<"$1"; }
# `show` keeps its pipeline deliberately. It also ends in a command that need not read to
# EOF, but its exit status is never consulted — it is called for its OUTPUT, so there is no
# verdict for a spurious status to corrupt. The defect is a pipeline whose STATUS is read,
# not a pipeline.
show()        { printf '%s\n' "$1" | grep -E "^FINDING ($2) " | sed 's/^/      /'; }

# A directory's content-and-layout state, as a file count plus a digest of every file
# under it. Group CTL snapshots the repository's OWN consumer directory with this before
# it builds its first fixture and again after its last, so CTLe's "nothing was written
# into the repository" half is a measured comparison rather than an assertion. An absent
# directory is reported as a distinct state rather than as an empty one, because a write
# that CREATES the directory must register as a change.
tree_state() {  # <dir> -> "<file-count> <digest>"
  local n d
  if [ ! -d "$1" ]; then
    printf '0 absent'
    return
  fi
  n="$(find "$1" -type f | wc -l | tr -d ' ')"
  d="$(find "$1" -type f -exec cksum {} + | LC_ALL=C sort | cksum)"
  printf '%s %s' "$n" "$d"
}

# ═════════════════════════════════════════════════════════════════════════════════
# Group PIN — the canonical literals, read from CLAUDE.md. The guard holds no copy.
# ═════════════════════════════════════════════════════════════════════════════════
echo "── Group PIN — the canonical contract, extracted from CLAUDE.md (never copied into this file)."

PIN_OK=1
if [ ! -r "$CLAUDE_MD" ]; then
  FAIL "PIN0: CLAUDE.md is not readable — the canonical source is absent, so nothing below can be asserted"
  PIN_OK=0
else
  # PIN1 — uniquely named. -x -F: a whole-line fixed-string match, so no regex dialect
  # and no substring can decide this.
  SECN="$(grep -c -x -F -- "$SECTION_HEADING" "$CLAUDE_MD")"
  [ -n "$SECN" ] || SECN=0
  if [ "$SECN" -eq 1 ]; then
    PASS "PIN1: CLAUDE.md carries exactly one \"$SECTION_HEADING\" section — a single normative home"
  else
    FAIL "PIN1: expected exactly one \"$SECTION_HEADING\" heading in CLAUDE.md, found $SECN"
    PIN_OK=0
  fi
fi

CANON_FILE="$WORK/canonical"
: > "$CANON_FILE"
CANON_N=0
CITATION=""
if [ "$PIN_OK" -eq 1 ]; then
  # PIN2 — the evidence list: a fenced literal whose entries are indexed contiguously
  # from E1. The index prefix is stripped here; what a consumer carries is the body.
  idx_ok=1; expect=1
  while IFS= read -r raw || [ -n "$raw" ]; do
    [ -n "$raw" ] || continue
    if [[ "$raw" =~ ^E([0-9]+)\ \ (.*)$ ]]; then
      if [ "${BASH_REMATCH[1]}" != "$expect" ]; then idx_ok=0; fi
      printf '%s\n' "${BASH_REMATCH[2]}" >> "$CANON_FILE"
      CANON_N=$((CANON_N+1)); expect=$((expect+1))
    else
      idx_ok=0
    fi
  done <<EOF
$(fence_block "$CLAUDE_MD" "$EVIDENCE_FENCE" "$SECTION_HEADING")
EOF
  if [ "$CANON_N" -ge 1 ] && [ "$idx_ok" -eq 1 ]; then
    PASS "PIN2: canonical evidence list extracted — $CANON_N entr(y/ies), indexed contiguously from E1"
  else
    FAIL "PIN2: could not extract a contiguously-indexed evidence list from the \`$EVIDENCE_FENCE\` fence (entries=$CANON_N, indexing_ok=$idx_ok)"
    PIN_OK=0
  fi

  # PIN3 — every entry is a `!`-prefixed pre-execution block that captures stderr.
  bad=0; i=0
  while IFS= read -r e || [ -n "$e" ]; do
    i=$((i+1))
    case "$e" in '!`'*) ;; *) bad=$((bad+1)) ;; esac
    case "$e" in *'2>&1'*) ;; *) bad=$((bad+1)) ;; esac
  done < "$CANON_FILE"
  if [ "$CANON_N" -ge 1 ] && [ "$bad" -eq 0 ]; then
    PASS "PIN3: all $CANON_N canonical entries are \`!\`-prefixed pre-execution blocks and every one captures stderr"
  else
    FAIL "PIN3: $bad canonical entr(y/ies) are not \`!\`-prefixed or do not capture stderr"
    PIN_OK=0
  fi

  # PIN4 — the header block's first line is the citation line.
  CITATION="$(fence_block "$CLAUDE_MD" "$HEADER_FENCE" "$SECTION_HEADING" | head -1)"
  if [ -n "$CITATION" ]; then
    PASS "PIN4: contract header citation line extracted — \"$CITATION\""
  else
    FAIL "PIN4: could not extract a citation line from the \`$HEADER_FENCE\` fence"
    PIN_OK=0
  fi
fi

# PIN5 — THE SELF-CHECK THIS SUITE EXISTS FOR. A guard holding its own copy of the
# canonical is a SECOND SOURCE OF TRUTH: it would go green while the documented contract
# drifted away from it. So no canonical entry may appear in this file. The second limb is
# the control arm — the same fixed-string probe MUST fire against CLAUDE.md, or the zero
# on this file is a broken probe rather than a clean result.
if [ "$PIN_OK" -eq 1 ]; then
  self_hits=0; src_hits=0
  while IFS= read -r e || [ -n "$e" ]; do
    [ -n "$e" ] || continue
    h_self="$(grep -c -F -- "$e" "$0")";        [ -n "$h_self" ] || h_self=0
    h_src="$(grep -c -F -- "$e" "$CLAUDE_MD")"; [ -n "$h_src" ]  || h_src=0
    self_hits=$((self_hits+h_self)); src_hits=$((src_hits+h_src))
  done < "$CANON_FILE"
  if [ "$self_hits" -eq 0 ] && [ "$src_hits" -ge "$CANON_N" ]; then
    PASS "PIN5: this script holds NO copy of any canonical entry (0 hits) while the same probe finds all $CANON_N in CLAUDE.md ($src_hits hits) — control arm fires"
  else
    FAIL "PIN5: the one-home seam is gone or the probe is broken (this_file=$self_hits CLAUDE.md=$src_hits of $CANON_N)"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group RP — the real consumer population.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group RP — the real consumer population under .claude/commands/."

CMD_DIR="$ROOT/.claude/commands"
RP_POP=0
if [ -d "$CMD_DIR" ]; then
  for f in "$CMD_DIR"/*.md; do [ -e "$f" ] && RP_POP=$((RP_POP+1)); done
fi

if [ "$PIN_OK" -ne 1 ]; then
  FAIL "RP0: the canonical could not be extracted, so no consumer can be checked against it"
elif [ "$RP_POP" -eq 0 ]; then
  # Not a PASS. The assertions below are universally quantified over an empty set, so
  # they are vacuously true and prove nothing whatsoever about conformance. Saying so
  # is the whole point of this branch — the count is printed so the transition to a
  # real population is visible in the log rather than inferred.
  if [ -d "$CMD_DIR" ]; then why="the directory exists and holds no .md file"; else why="the directory does not exist"; fi
  VACUOUS "RP: observed consumer population = 0 ($why). Every RP assertion is vacuously true and proves NOTHING about conformance. Group CTL below is what makes this run meaningful."
else
  RP_OUT="$(conformance_check "$CMD_DIR" "$CANON_FILE" "$CITATION" "$CANON_N")"; RP_RC=$?
  echo "  observed consumer population = $RP_POP file(s)"
  if has_finding "$RP_OUT" 'H1'; then FAIL "RP1: a consumer is missing the contract header block"; show "$RP_OUT" 'H1'
  else PASS "RP1: all $RP_POP consumer(s) carry the contract header citation line, byte-identical"; fi
  if has_finding "$RP_OUT" 'H2|H3'; then FAIL "RP2: a consumer's contract-depth or population-role is absent or malformed"; show "$RP_OUT" 'H2|H3'
  else PASS "RP2: all $RP_POP consumer(s) declare a well-formed contract-depth and population-role"; fi
  if has_finding "$RP_OUT" 'P1'; then FAIL "RP3: a consumer's evidence block diverges from the canonical"; show "$RP_OUT" 'P1'
  else PASS "RP3: every evidence block in all $RP_POP consumer(s) is byte-identical to the canonical at its index"; fi
  # P2 and P3 are the two directions of ONE rule, so they are surfaced together and the
  # group-level verdict is stated direction-neutrally; the finding line printed by `show`
  # is what names which direction, and each code carries its own message.
  if has_finding "$RP_OUT" 'P2|P3'; then FAIL "RP4: a consumer's evidence prefix is not exactly the one its declared depth requires"; show "$RP_OUT" 'P2|P3'
  else PASS "RP4: every consumer carries exactly the contiguous evidence prefix its declared depth requires — no fewer blocks, and no more"; fi
  if has_finding "$RP_OUT" 'D1|D2'; then FAIL "RP5: a consumer's contract-depth disagrees with its own verb table"; show "$RP_OUT" 'D1|D2'
  else PASS "RP5: every consumer's contract-depth equals the maximum depth in its own verb table"; fi
  # Self-consistency: every finding the checker emitted must have been surfaced above.
  if [ "$RP_RC" -eq 0 ]; then PASS "RP6: the checker returned 0 — no finding of any id went unsurfaced"
  else
    if has_finding "$RP_OUT" 'H1|H2|H3|P1|P2|P3|D1|D2'; then PASS "RP6: the checker returned $RP_RC and every finding it emitted is accounted for above"
    else FAIL "RP6: the checker returned $RP_RC but emitted no finding the assertions above recognise"; fi
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group CTL — the control case. Fixture-driven in $WORK; the repo is NEVER mutated,
# so the control re-proves itself on every push instead of decaying into a one-time
# demonstration. Population 5 by construction, at every wave.
#
# Every arm carries a FIXTURE-INTEGRITY assertion graded FIRST: a control built on a
# fixture that was never constructed is a green proving nothing, one level down.
#
# THE INVARIANT A LATER CONTRIBUTOR MUST HOLD: every failure code `conformance_check`
# can emit has a must-fire arm here. An emitted code with no arm is a check that has
# never been observed to fire, and an unexercised check is indistinguishable from one
# that CANNOT fire — the assertion may already be inert and the suite would stay green
# saying so. When a later slice adds a code, it adds an arm in this group in the same
# change. The arms below are keyed to their code so the correspondence is readable:
#   a  clean tree, MUST NOT FIRE      b  P1     c  H1     d  P2     op P3
#   nd H2    nr H3    nt D2 (RESOLVE)    nc D2 (CREATE)
#   dm D1 (max computation)    dd D1 (field-index read)    dc D1 (CREATE)
#   cs code-span depth cells, MUST NOT FIRE      cx D2 (code-span specificity)
#   hs H2 (code-span HEADER depth — fires, while the same rendering in the CELL passes)
# and CTL-e is graded LAST, so the before/after comparison it makes covers every fixture
# above it rather than a prefix of them.
#
# THE COUNT OF ARMS IS DELIBERATELY NOT RESTATED ANYWHERE ELSE. The keys above are the
# inventory; a number copied into a second file is a copy with no assertion behind it,
# which is the exact failure mode this suite exists to catch. The workflow file therefore
# describes the invariant and points here rather than carrying its own tally.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group CTL — control case: the checker shown PASSING on a correct tree and FAILING on each deliberate defect."

if [ "$PIN_OK" -ne 1 ]; then
  FAIL "CTL0: the canonical could not be extracted, so no fixture can be built from it — the control case did not run, which is a failure and not a pass"
else
  # Every directory mk_tree is asked to build into is RECORDED here, at the point of
  # construction, and CTLe grades the recorded paths. A glob of what happens to exist
  # under the temp dir could not see a fixture built somewhere ELSE, which is the one
  # thing that arm needs to detect — so the list is built from the arguments actually
  # passed rather than discovered afterwards.
  CTL_FIXTURE_DIRS=""
  # The repository's own consumer directory, snapshotted BEFORE the first fixture is
  # built. CTLe compares it against the same measurement taken after the last one.
  CTL_CMD_BEFORE="$(tree_state "$CMD_DIR")"

  # Fixtures are BUILT from the extracted canonical, never sed-patched and never
  # literal: a literal here would be the very second source PIN5 forbids.
  mk_consumer() {  # <dir> <basename> <depth> <role> <variant>
    local d="$1" name="$2" depth="$3" role="$4" variant="$5"
    local i lim
    mkdir -p "$d"
    {
      printf -- '---\ndescription: fixture\n---\n\n# %s\n\n' "$name"
      # evidence prefix
      lim="$depth"
      if [ "$variant" = "shortprefix" ]; then lim=1
      elif [ "$variant" = "overprefix" ]; then lim="$CANON_N"
      elif [ "$depth" -ge 3 ]; then lim="$CANON_N"
      elif [ "$depth" -ge 1 ]; then lim=1
      else lim=0
      fi
      i=1
      while [ "$i" -le "$lim" ]; do
        if [ "$i" -eq 1 ] && [ "$variant" = "nostderr" ]; then
          printf '%s\n\n' "$MUTATED"
        else
          printf '%s\n\n' "$(sed -n "${i}p" "$CANON_FILE")"
        fi
        i=$((i+1))
      done
      # contract header block. Each omission is its own variant so a defect arm removes
      # exactly one field: an arm whose fixture broke several things at once proves the
      # checker fired, not WHICH assertion fired.
      [ "$variant" = "noheader" ] || printf '%s\n' "$CITATION"
      # `spandepth` renders the HEADER's depth as a code span — the rendering the verb
      # table's depth CELL accepts and this line does not. It is its own variant so the
      # arm it feeds changes exactly one thing.
      if   [ "$variant" = "nodepth" ];   then :
      elif [ "$variant" = "spandepth" ]; then printf 'contract-depth: `G%s`\n' "$depth"
      else                                    printf 'contract-depth: G%s\n' "$depth"
      fi
      [ "$variant" = "norole" ]   || printf 'population-role: %s\n' "$role"
      printf '\n'
      # The table is built for EVERY role, not only RESOLVE. Building it only for
      # RESOLVE was the second half of D2's asymmetry: the clean tree's CREATE consumer
      # carried no table, so CTLa2's silence about it was the ROLE EXEMPTION and not a
      # verdict, and no arm could have caught the exemption. `notable` withholds it from
      # the RESOLVE consumer and `notablecreate` from the CREATE one.
      if [ "$variant" != "notable" ] && [ "$variant" != "notablecreate" ]; then
        printf '| verb | lifecycle | mode | destination | depth |\n'
        printf '|---|---|---|---|---|\n'
        case "$variant" in
          depthmismatch)
            # The table tops out at G2 while the file declares G8. Two rows, not one, so
            # the arm exercises the MAXIMUM rather than a single-row equality: a checker
            # that read the first depth cell it met would report G1 and be caught.
            printf '| status | ACTIVE | any | any | G1 |\n'
            printf '| act | ACTIVE | resolved | decided | G2 |\n'
            ;;
          depthdecoy)
            # Every DEPTH cell reads G1, but a decoy `G8` sits in the mode cell of one
            # row and the lifecycle cell of the other — the two cells the checker names.
            # A row-wide matcher reads a decoy, agrees with the declared G8 and stays
            # silent; the field-index read sees G1 and fires. This fixture is the only
            # thing that tells those two implementations apart.
            printf '| status | ACTIVE | G8 | any | G1 |\n'
            printf '| act | G8 | resolved | decided | G1 |\n'
            ;;
          depthmismatchcreate)
            # The CREATE partner of `depthmismatch`: the file declares G2 while its table
            # tops out at G1. Two rows again, so the arm exercises the MAXIMUM for this
            # role rather than a single-row equality.
            printf '| new | ACTIVE | any | any | G0 |\n'
            printf '| new-from | ACTIVE | any | any | G1 |\n'
            ;;
          codespan|spandepth)
            # Every depth cell rendered as a CODE SPAN — which is exactly how CLAUDE.md's
            # own consumer table renders every depth value, and therefore the only
            # rendered example a command author has to copy. The table is PRESENT and its
            # maximum agrees with the declared depth, so this fixture MUST NOT fire.
            printf '| status | ACTIVE | any | any | `G1` |\n'
            printf '| act | ACTIVE | resolved | decided | `G%s` |\n' "$depth"
            ;;
          codespanx)
            # The SPECIFICITY partner of `codespan`. The table is physically present and
            # its depth cells are code spans, but the tokens inside them are not depths.
            # If stripping the backticks had widened the match into "a backticked token is
            # a depth", `rows` would be non-zero here and D2 would fall silent on a table
            # that declares no per-verb depth at all — the repair masking a real absence.
            printf '| status | ACTIVE | any | any | `TBD` |\n'
            printf '| act | ACTIVE | resolved | decided | `TBD` |\n'
            ;;
          *)
            printf '| status | ACTIVE | any | any | G1 |\n'
            printf '| act | ACTIVE | resolved | decided | G%s |\n' "$depth"
            ;;
        esac
      fi
      printf '\nVerb-specific text follows here.\n'
    } > "$d/$name.md"
  }

  # The one mutation the defect arms need, derived from the extracted canonical.
  CANON1="$(sed -n '1p' "$CANON_FILE")"
  MUTATED="${CANON1/ 2>&1/}"

  # Each arm gets its OWN fixture directory, so no arm ever has to clear another's —
  # a control case that deletes a tree is one bad variable away from deleting the wrong
  # one, and it has no reason to.
  mk_tree() {  # <dir> <variant>
    local d="$1" v="$2"
    CTL_FIXTURE_DIRS="$CTL_FIXTURE_DIRS$d
"
    mkdir -p "$d"
    # Three variants must land on the G2/CREATE consumer rather than on `trip`.
    # `overprefix` because at depth G8 the required prefix is already the WHOLE list, so
    # `trip` has no room to carry a surplus and could not express the defect at all —
    # `trip-new` is the only member whose declared depth leaves that room, and it is also
    # the exact consumer whose narrower Bash(ls:*) grant depends on it. `notablecreate`
    # and `depthmismatchcreate` because both are about the CREATE role specifically — the
    # role D2 did not reach and D1 could not be reached through; putting either on a
    # RESOLVE consumer would re-test the branch that already worked.
    case "$v" in
      overprefix)
        mk_consumer "$d" "trip-new"      2 CREATE  overprefix
        mk_consumer "$d" "trip"          8 RESOLVE ok ;;
      notablecreate|depthmismatchcreate)
        mk_consumer "$d" "trip-new"      2 CREATE  "$v"
        mk_consumer "$d" "trip"          8 RESOLVE ok ;;
      *)
        mk_consumer "$d" "trip-new"      2 CREATE  ok
        mk_consumer "$d" "trip"          8 RESOLVE "$v" ;;
    esac
    mk_consumer "$d" "trip-record"       8 RESOLVE ok
    mk_consumer "$d" "trip-publish"      8 RESOLVE ok
    mk_consumer "$d" "trip-decommission" 8 RESOLVE ok
  }

  # ── CTL-a: the MUST-NOT-FIRE arm. It is graded FIRST because without it every
  # negative arm below is satisfied by a checker hard-wired to return 1.
  A="$WORK/ctl_a"; mk_tree "$A" ok
  a_pop=0; for f in "$A"/*.md; do [ -e "$f" ] && a_pop=$((a_pop+1)); done
  if [ "$a_pop" -eq 5 ] && [ -f "$A/trip.md" ] && [ -f "$A/trip-new.md" ]; then
    PASS "CTLa1: fixture integrity — a clean five-file consumer tree was constructed (population $a_pop, built from the extracted canonical)"
  else
    FAIL "CTLa1: the clean fixture tree was not constructed (population $a_pop) — every arm below would prove nothing"
  fi
  # CTLa3 is what gives CTLa2 its meaning for the CREATE role. Until this slice the
  # clean tree's CREATE consumer carried NO verb table and D2 was conditional on RESOLVE,
  # so CTLa2's silence about trip-new was the role exemption rather than a verdict — and
  # no arm in this group could have told those two apart. The clean CREATE consumer now
  # physically carries a readable table whose maximum equals its declared depth, so the
  # MUST-NOT-FIRE arm below is a statement about the widened rule.
  a_new_cells=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *'| G'[0-8]' |'*) a_new_cells=$((a_new_cells+1)) ;; esac
  done < "$A/trip-new.md"
  if [ "$a_new_cells" -gt 0 ] \
     && grep -q -x -F -- 'population-role: CREATE' "$A/trip-new.md" \
     && grep -q -x -F -- 'contract-depth: G2' "$A/trip-new.md" \
     && grep -q -F -- '| G2 |' "$A/trip-new.md"; then
    PASS "CTLa3: fixture integrity — the clean tree's CREATE consumer declares contract-depth G2 and carries $a_new_cells readable depth cell(s) topping out at G2, so CTLa2's silence about it is a verdict on the role-neutral D2 and not the role exemption it used to be"
  else
    FAIL "CTLa3: the clean tree's CREATE consumer carries no readable verb table (depth cells=$a_new_cells) — CTLa2 would be silent for the old reason and the role widening would be untested"
  fi
  A_OUT="$(conformance_check "$A" "$CANON_FILE" "$CITATION" "$CANON_N")"; A_RC=$?
  if [ "$A_RC" -eq 0 ]; then
    PASS "CTLa2: MUST-NOT-FIRE — a conformant five-file tree returns 0; the checker is not hard-wired red"
  else
    FAIL "CTLa2: MUST-NOT-FIRE — a conformant tree was flagged (rc=$A_RC): $(printf '%s' "$A_OUT" | head -3 | tr '\n' ' ')"
  fi

  # ── CTL-b: one evidence block with the stderr redirect dropped MUST fire.
  if [ -n "$MUTATED" ] && [ "$MUTATED" != "$CANON1" ]; then
    PASS "CTLb1: fixture integrity — the mutation actually changed the canonical entry (the stderr redirect was present and was removed)"
  else
    FAIL "CTLb1: the mutation did not change the canonical entry — CTLb2 would be testing an identical string and prove nothing"
  fi
  B="$WORK/ctl_b"; mk_tree "$B" nostderr
  if grep -q -F -- "$MUTATED" "$B/trip.md" && ! grep -q -F -- "$CANON1" "$B/trip.md"; then
    PASS "CTLb2: fixture integrity — the defective consumer carries the mutated block and not the canonical one"
  else
    FAIL "CTLb2: the defective fixture does not carry the mutation — CTLb3 would prove nothing"
  fi
  B_OUT="$(conformance_check "$B" "$CANON_FILE" "$CITATION" "$CANON_N")"; B_RC=$?
  if [ "$B_RC" -ne 0 ] && has_finding "$B_OUT" 'P1'; then
    PASS "CTLb3: MUST-FIRE — a consumer whose evidence block dropped the stderr redirect is caught as a byte-identity divergence (P1)"
  else
    FAIL "CTLb3: MUST-FIRE — a divergent evidence copy passed (rc=$B_RC); the byte-identity assertion is inert"
  fi

  # ── CTL-c: a removed contract header block MUST fire.
  C="$WORK/ctl_c"; mk_tree "$C" noheader
  if ! grep -q -F -- "$CITATION" "$C/trip.md" && grep -q -F -- "$CITATION" "$C/trip-record.md"; then
    PASS "CTLc1: fixture integrity — the header block is absent from exactly the defective consumer and present in its siblings"
  else
    FAIL "CTLc1: the header-removal fixture is not set up as claimed — CTLc2 would prove nothing"
  fi
  C_OUT="$(conformance_check "$C" "$CANON_FILE" "$CITATION" "$CANON_N")"; C_RC=$?
  if [ "$C_RC" -ne 0 ] && has_finding "$C_OUT" 'H1'; then
    PASS "CTLc2: MUST-FIRE — a consumer with no contract header block is caught (H1)"
  else
    FAIL "CTLc2: MUST-FIRE — a consumer with no header block passed (rc=$C_RC)"
  fi

  # ── CTL-d: a declared depth exceeding the evidence prefix carried MUST fire.
  D="$WORK/ctl_d"; mk_tree "$D" shortprefix
  d_blocks=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '!`'*) d_blocks=$((d_blocks+1)) ;; esac
  done < "$D/trip.md"
  if [ "$d_blocks" -lt "$CANON_N" ] && grep -q -x -F -- 'contract-depth: G8' "$D/trip.md"; then
    PASS "CTLd1: fixture integrity — the defective consumer declares depth G8 while carrying only $d_blocks of $CANON_N evidence block(s)"
  else
    FAIL "CTLd1: the short-prefix fixture is not set up as claimed (blocks=$d_blocks of $CANON_N) — CTLd2 would prove nothing"
  fi
  D_OUT="$(conformance_check "$D" "$CANON_FILE" "$CITATION" "$CANON_N")"; D_RC=$?
  if [ "$D_RC" -ne 0 ] && has_finding "$D_OUT" 'P2'; then
    PASS "CTLd2: MUST-FIRE — a consumer declaring a depth deeper than its evidence prefix is caught (P2)"
  else
    FAIL "CTLd2: MUST-FIRE — a declared depth exceeding the carried prefix passed (rc=$D_RC)"
  fi

  # ── CTL-nd: a consumer with no `contract-depth` line MUST fire H2.
  # H2 and H3 are the two header-field codes the shipped control group never reached.
  # An absent depth line also collapses the derived prefix requirement to zero, so this
  # fixture reaches H2 and leaves the prefix assertions untouched.
  ND="$WORK/ctl_nodepth"; mk_tree "$ND" nodepth
  if ! grep -q -x -F -- 'contract-depth: G8' "$ND/trip.md" \
     && grep -q -x -F -- 'population-role: RESOLVE' "$ND/trip.md" \
     && grep -q -x -F -- 'contract-depth: G8' "$ND/trip-record.md"; then
    PASS "CTLnd1: fixture integrity — the contract-depth line is absent from exactly the defective consumer, its population-role is untouched, and the SAME probe finds the line in the sibling — so the zero is a measurement, not a broken probe"
  else
    FAIL "CTLnd1: the depth-removal fixture is not set up as claimed — CTLnd2 would prove nothing"
  fi
  ND_OUT="$(conformance_check "$ND" "$CANON_FILE" "$CITATION" "$CANON_N")"; ND_RC=$?
  if [ "$ND_RC" -ne 0 ] && has_finding "$ND_OUT" 'H2'; then
    PASS "CTLnd2: MUST-FIRE — a consumer that declares no contract-depth is caught (H2)"
  else
    FAIL "CTLnd2: MUST-FIRE — a consumer with no contract-depth passed (rc=$ND_RC); the depth-declaration assertion is inert"
  fi

  # ── CTL-nr: a consumer with no `population-role` line MUST fire H3.
  NR="$WORK/ctl_norole"; mk_tree "$NR" norole
  if ! grep -q -x -F -- 'population-role: RESOLVE' "$NR/trip.md" \
     && grep -q -x -F -- 'contract-depth: G8' "$NR/trip.md" \
     && grep -q -x -F -- 'population-role: RESOLVE' "$NR/trip-record.md"; then
    PASS "CTLnr1: fixture integrity — the population-role line is absent from exactly the defective consumer, its contract-depth is untouched, and the same probe finds the line in the sibling"
  else
    FAIL "CTLnr1: the role-removal fixture is not set up as claimed — CTLnr2 would prove nothing"
  fi
  NR_OUT="$(conformance_check "$NR" "$CANON_FILE" "$CITATION" "$CANON_N")"; NR_RC=$?
  if [ "$NR_RC" -ne 0 ] && has_finding "$NR_OUT" 'H3'; then
    PASS "CTLnr2: MUST-FIRE — a consumer that declares no population-role is caught (H3)"
  else
    FAIL "CTLnr2: MUST-FIRE — a consumer with no population-role passed (rc=$NR_RC); G2's per-command disposition would be improvised per file with nothing to catch it"
  fi

  # ── CTL-nt: a RESOLVE consumer carrying no per-verb requirement table MUST fire D2.
  # The declared role is load-bearing here rather than incidental: D2 is conditional on
  # RESOLVE, so an arm whose fixture also lost the role line would be testing H3.
  NT="$WORK/ctl_notable"; mk_tree "$NT" notable
  nt_rows=0; nt_sib=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) nt_rows=$((nt_rows+1)) ;; esac
  done < "$NT/trip.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) nt_sib=$((nt_sib+1)) ;; esac
  done < "$NT/trip-record.md"
  if [ "$nt_rows" -eq 0 ] && [ "$nt_sib" -gt 0 ] \
     && grep -q -x -F -- 'population-role: RESOLVE' "$NT/trip.md"; then
    PASS "CTLnt1: fixture integrity — the defective consumer declares population-role RESOLVE and carries $nt_rows table line(s), while the identical counter reads $nt_sib next door — a zero with a non-zero control arm"
  else
    FAIL "CTLnt1: the missing-table fixture is not set up as claimed (rows=$nt_rows sibling=$nt_sib) — CTLnt2 would prove nothing"
  fi
  NT_OUT="$(conformance_check "$NT" "$CANON_FILE" "$CITATION" "$CANON_N")"; NT_RC=$?
  if [ "$NT_RC" -ne 0 ] && has_finding "$NT_OUT" 'D2'; then
    PASS "CTLnt2: MUST-FIRE — a RESOLVE consumer with no per-verb requirement table is caught (D2); G7's closed-set default has a table to look in"
  else
    FAIL "CTLnt2: MUST-FIRE — a RESOLVE consumer with no verb table passed (rc=$NT_RC)"
  fi

  # ── CTL-nc: a CREATE consumer carrying no per-verb requirement table MUST fire D2.
  # This is the arm the role condition made unreachable. D2 fired only for RESOLVE and
  # the builder made a table only for RESOLVE fixtures, so the CREATE consumer produced
  # no finding at all — and because `rows` at 0 takes D2's branch, D1 was unreachable for
  # that role too. /trip-new was the single consumer whose contract-depth could not be
  # machine-checked in either direction, while being this guard's FIRST real population.
  # Its designer carries a verb table anyway; the guard should not depend on that.
  NC="$WORK/ctl_notablecreate"; mk_tree "$NC" notablecreate
  nc_rows=0; nc_sib=0; nc_clean=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) nc_rows=$((nc_rows+1)) ;; esac
  done < "$NC/trip-new.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) nc_sib=$((nc_sib+1)) ;; esac
  done < "$NC/trip.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) nc_clean=$((nc_clean+1)) ;; esac
  done < "$A/trip-new.md"
  if [ "$nc_rows" -eq 0 ] && [ "$nc_sib" -gt 0 ] && [ "$nc_clean" -gt 0 ] \
     && grep -q -x -F -- 'population-role: CREATE' "$NC/trip-new.md"; then
    PASS "CTLnc1: fixture integrity — the defective consumer declares population-role CREATE and carries $nc_rows table line(s), while the identical counter reads $nc_sib on its RESOLVE sibling and $nc_clean on the CLEAN tree's own CREATE consumer — two non-zero control arms, so the zero is a measurement and not the builder declining to make a CREATE table"
  else
    FAIL "CTLnc1: the CREATE missing-table fixture is not set up as claimed (rows=$nc_rows sibling=$nc_sib clean=$nc_clean) — CTLnc2 would prove nothing"
  fi
  NC_OUT="$(conformance_check "$NC" "$CANON_FILE" "$CITATION" "$CANON_N")"; NC_RC=$?
  if [ "$NC_RC" -ne 0 ] && has_finding "$NC_OUT" 'D2'; then
    PASS "CTLnc2: MUST-FIRE — a CREATE consumer with no per-verb requirement table is caught (D2); the table requirement is role-neutral, which is how the contract states it"
  else
    FAIL "CTLnc2: MUST-FIRE — a CREATE consumer with no verb table passed (rc=$NC_RC); D2 is still role-asymmetric and /trip-new's contract-depth is checked by nothing"
  fi

  # ── CTL-dm: contract-depth disagreeing with the maximum depth in the file's own verb
  # table MUST fire D1. This is the assertion that had no arm ANYWHERE — RP is VACUOUS
  # until the command files land, so before this arm it had never been observed to fire
  # at any wave, and "inert" and "never exercised" were the same observation.
  DM="$WORK/ctl_depthmismatch"; mk_tree "$DM" depthmismatch
  if grep -q -x -F -- 'contract-depth: G8' "$DM/trip.md" \
     && grep -q -x -F -- '| act | ACTIVE | resolved | decided | G2 |' "$DM/trip.md" \
     && ! grep -q -x -F -- '| act | ACTIVE | resolved | decided | G8 |' "$DM/trip.md" \
     && grep -q -x -F -- '| act | ACTIVE | resolved | decided | G8 |' "$DM/trip-record.md"; then
    PASS "CTLdm1: fixture integrity — the defective consumer declares contract-depth G8 while its verb table tops out at G2; the sibling still carries the matching G8 row, so the absence is observed rather than assumed"
  else
    FAIL "CTLdm1: the depth-mismatch fixture is not set up as claimed — CTLdm2 would prove nothing"
  fi
  DM_OUT="$(conformance_check "$DM" "$CANON_FILE" "$CITATION" "$CANON_N")"; DM_RC=$?
  if [ "$DM_RC" -ne 0 ] && has_finding "$DM_OUT" 'D1'; then
    PASS "CTLdm2: MUST-FIRE — a consumer whose contract-depth disagrees with the maximum depth in its own verb table is caught (D1)"
  else
    FAIL "CTLdm2: MUST-FIRE — a contract-depth disagreeing with its own verb table passed (rc=$DM_RC); the prefix a file carries would no longer be fixed by anything"
  fi
  if grep -q -F -- 'verb table (G2)' <<<"$DM_OUT"; then
    PASS "CTLdm3: the finding names G2 — the MAXIMUM over the table's {G1, G2}, not the first depth cell it met; the max computation is exercised, not merely the inequality"
  else
    FAIL "CTLdm3: D1 fired but did not name G2 as the table maximum, so the reported depth is not the maximum: $(printf '%s' "$DM_OUT" | head -2 | tr '\n' ' ')"
  fi

  # ── CTL-dd: the SPECIFICITY arm for the same assertion. The checker reads the depth
  # cell by FIELD INDEX precisely so a `G8` mentioned in the lifecycle or mode cell does
  # not silently satisfy a declared G8. That reasoning was recorded beside the code and
  # asserted by nothing: a row-wide matcher would have passed every arm above.
  DD="$WORK/ctl_depthdecoy"; mk_tree "$DD" depthdecoy
  if grep -q -x -F -- 'contract-depth: G8' "$DD/trip.md" \
     && grep -q -x -F -- '| status | ACTIVE | G8 | any | G1 |' "$DD/trip.md" \
     && grep -q -x -F -- '| act | G8 | resolved | decided | G1 |' "$DD/trip.md"; then
    PASS "CTLdd1: fixture integrity — the defective consumer declares G8 and plants a decoy G8 in one row's mode cell and the other's lifecycle cell, while EVERY depth cell reads G1"
  else
    FAIL "CTLdd1: the decoy fixture is not set up as claimed — CTLdd2 would prove nothing"
  fi
  DD_OUT="$(conformance_check "$DD" "$CANON_FILE" "$CITATION" "$CANON_N")"; DD_RC=$?
  if [ "$DD_RC" -ne 0 ] && has_finding "$DD_OUT" 'D1'; then
    PASS "CTLdd2: MUST-FIRE — a G8 outside the depth column does not satisfy the declared depth; the disagreement is still caught (D1)"
  else
    FAIL "CTLdd2: MUST-FIRE — a decoy G8 in a non-depth cell silenced the check (rc=$DD_RC); the depth is being read row-wide, so the assertion agrees with itself"
  fi
  if grep -q -F -- 'verb table (G1)' <<<"$DD_OUT"; then
    PASS "CTLdd3: the finding names G1 — the depth CELL, read by field index; a row-wide matcher would have read the decoy G8, agreed with the declaration and stayed silent"
  else
    FAIL "CTLdd3: D1 fired but named a maximum the depth column does not contain — the decoy was read as a depth: $(printf '%s' "$DD_OUT" | head -2 | tr '\n' ' ')"
  fi

  # ── CTL-dc: the CREATE partner of CTL-dm, and the arm that proves the widening closed
  # the defect rather than its symptom. Requiring the table (D2) only makes it PRESENT;
  # this arm is what shows it is then READ for the CREATE role. What rests on it: the
  # declared depth fixes the evidence prefix a file may carry, and /trip-new's narrower
  # `Bash(ls:*)` grant is only true while its prefix is E1 and nothing else (ADR-007 §2,
  # bound 2). Before this, /trip-new could declare any depth it liked.
  DC="$WORK/ctl_depthmismatchcreate"; mk_tree "$DC" depthmismatchcreate
  if grep -q -x -F -- 'contract-depth: G2' "$DC/trip-new.md" \
     && grep -q -x -F -- 'population-role: CREATE' "$DC/trip-new.md" \
     && grep -q -x -F -- '| new-from | ACTIVE | any | any | G1 |' "$DC/trip-new.md" \
     && ! grep -q -F -- '| G2 |' "$DC/trip-new.md" \
     && grep -q -F -- '| G2 |' "$A/trip-new.md"; then
    PASS "CTLdc1: fixture integrity — the defective CREATE consumer declares contract-depth G2 while its verb table tops out at G1, and the SAME probe finds a G2 depth cell on the clean tree's CREATE consumer, so the absence is observed rather than assumed"
  else
    FAIL "CTLdc1: the CREATE depth-mismatch fixture is not set up as claimed — CTLdc2 would prove nothing"
  fi
  DC_OUT="$(conformance_check "$DC" "$CANON_FILE" "$CITATION" "$CANON_N")"; DC_RC=$?
  if [ "$DC_RC" -ne 0 ] && has_finding "$DC_OUT" 'D1'; then
    PASS "CTLdc2: MUST-FIRE — a CREATE consumer whose contract-depth disagrees with its own verb table is caught (D1); the depth equality now reaches the one role that carries a narrower tool grant because of it"
  else
    FAIL "CTLdc2: MUST-FIRE — a CREATE consumer's contract-depth went unchecked against its own verb table (rc=$DC_RC); D2's widening made the table present without making it read"
  fi
  if grep -q -F -- 'verb table (G1)' <<<"$DC_OUT"; then
    PASS "CTLdc3: the finding names G1 — the MAXIMUM over the CREATE table's {G0, G1}, so the max computation runs for this role and not merely a presence check"
  else
    FAIL "CTLdc3: D1 fired on the CREATE consumer but did not name G1 as its table maximum: $(printf '%s' "$DC_OUT" | head -2 | tr '\n' ' ')"
  fi

  # ── CTL-op: a consumer carrying MORE of the canonical list than its declared depth
  # requires MUST fire P3. This is the converse of CTL-d, and until the prefix rule was
  # an equality it had nothing to fire: the checker asserted `m >= need` and never
  # `m == need`, so a G2/CREATE consumer that quietly acquired E2 passed green while
  # needing a `Bash(grep:*)` grant its function does not justify (ADR-007 §2, bound 2).
  # The same one-sided reasoning left a G0 consumer free to carry arbitrary DIVERGENT
  # copies of the canonical blocks with byte-identity never run on them — one defect,
  # two symptoms, and this arm is what holds the closure of both.
  OP="$WORK/ctl_overprefix"; mk_tree "$OP" overprefix
  op_blocks=0; op_clean=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '!`'*) op_blocks=$((op_blocks+1)) ;; esac
  done < "$OP/trip-new.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '!`'*) op_clean=$((op_clean+1)) ;; esac
  done < "$A/trip-new.md"
  if [ "$CANON_N" -gt 1 ] && [ "$op_blocks" -eq "$CANON_N" ] && [ "$op_clean" -eq 1 ] \
     && grep -q -x -F -- 'contract-depth: G2' "$OP/trip-new.md"; then
    PASS "CTLop1: fixture integrity — the defective consumer declares depth G2 (which needs E1 alone) while carrying $op_blocks of $CANON_N block(s); the SAME counter reads $op_clean on the clean tree's trip-new, so the surplus is a measured difference and not an assumed one"
  else
    FAIL "CTLop1: the over-prefix fixture is not set up as claimed (defective=$op_blocks clean=$op_clean canonical=$CANON_N) — CTLop2 would prove nothing"
  fi
  OP_OUT="$(conformance_check "$OP" "$CANON_FILE" "$CITATION" "$CANON_N")"; OP_RC=$?
  if [ "$OP_RC" -ne 0 ] && has_finding "$OP_OUT" 'P3'; then
    PASS "CTLop2: MUST-FIRE — a consumer carrying more of the canonical list than its declared depth requires is caught (P3); the prefix rule is an equality, not a minimum, and an over-provisioned command can no longer ship green with a widened tool grant"
  else
    FAIL "CTLop2: MUST-FIRE — an over-provisioned prefix passed (rc=$OP_RC); the check is a minimum only, so a widened grant and an unexamined divergent copy both ship green"
  fi

  # ── CTL-cs: a per-verb requirement table whose depth cells are rendered as CODE SPANS
  # MUST NOT fire. This is the second MUST-NOT-FIRE arm in the group and it exists for a
  # specific reason: CLAUDE.md's own consumer table renders every depth value as a code
  # span, so it is the only rendered example a command author can copy — and before the
  # cell was normalised, `rows` fell to 0 and a table that is PRESENT was reported absent
  # as D2. A negative arm cannot catch that; only a positive one can.
  CS="$WORK/ctl_codespan"; mk_tree "$CS" codespan
  cs_span=0; cs_bare_def=0; cs_bare_clean=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *'| `G'*'` |'*)   cs_span=$((cs_span+1)) ;;
      *'| G'[0-8]' |'*) cs_bare_def=$((cs_bare_def+1)) ;;
    esac
  done < "$CS/trip.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *'| G'[0-8]' |'*) cs_bare_clean=$((cs_bare_clean+1)) ;; esac
  done < "$A/trip.md"
  if [ "$cs_span" -gt 0 ] && [ "$cs_bare_def" -eq 0 ] && [ "$cs_bare_clean" -gt 0 ] \
     && grep -q -x -F -- 'contract-depth: G8' "$CS/trip.md"; then
    PASS "CTLcs1: fixture integrity — the defective consumer's table carries $cs_span code-span depth cell(s) and $cs_bare_def bare ones, while the identical bare-cell counter reads $cs_bare_clean on the clean tree — so the rendering is the only thing that differs, and the zero is a measurement"
  else
    FAIL "CTLcs1: the code-span fixture is not set up as claimed (span=$cs_span bare_here=$cs_bare_def bare_clean=$cs_bare_clean) — CTLcs2 would prove nothing"
  fi
  CS_OUT="$(conformance_check "$CS" "$CANON_FILE" "$CITATION" "$CANON_N")"; CS_RC=$?
  if [ "$CS_RC" -eq 0 ] && ! has_finding "$CS_OUT" 'D1|D2'; then
    PASS "CTLcs2: MUST-NOT-FIRE — a table whose depth cells are code spans is read as present and its maximum is read correctly; the cell is normalised before it is matched, so the contract's own typography no longer produces a finding that names the wrong defect"
  else
    FAIL "CTLcs2: MUST-NOT-FIRE — a table rendered the way CLAUDE.md renders its own was flagged (rc=$CS_RC): $(printf '%s' "$CS_OUT" | head -3 | tr '\n' ' ')"
  fi

  # ── CTL-cx: the SPECIFICITY arm for that repair. Stripping the backticks must not have
  # widened the match into "a backticked token is a depth" — if it had, a table declaring
  # no depth at all would read as declaring one and D2 would fall silent on a genuinely
  # absent requirement table. CTL-nt covers a table that is not there; this one covers the
  # nastier case of a table that IS there and declares nothing, which is what a widened
  # pattern would swallow.
  CX="$WORK/ctl_codespanx"; mk_tree "$CX" codespanx
  cx_rows=0; cx_depth=0; cx_sib_depth=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '|'*) cx_rows=$((cx_rows+1)) ;; esac
  done < "$CX/trip.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *'| `G'*'` |'*)   cx_depth=$((cx_depth+1)) ;;
      *'| G'[0-8]' |'*) cx_depth=$((cx_depth+1)) ;;
    esac
  done < "$CX/trip.md"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *'| `G'*'` |'*)   cx_sib_depth=$((cx_sib_depth+1)) ;;
      *'| G'[0-8]' |'*) cx_sib_depth=$((cx_sib_depth+1)) ;;
    esac
  done < "$CS/trip.md"
  if [ "$cx_rows" -gt 0 ] && [ "$cx_depth" -eq 0 ] && [ "$cx_sib_depth" -gt 0 ] \
     && grep -q -x -F -- 'population-role: RESOLVE' "$CX/trip.md"; then
    PASS "CTLcx1: fixture integrity — the defective consumer carries $cx_rows table line(s) and declares population-role RESOLVE, yet $cx_depth of its cells are a depth in EITHER rendering, while the same two-rendering counter reads $cx_sib_depth on the code-span fixture next door"
  else
    FAIL "CTLcx1: the code-span specificity fixture is not set up as claimed (rows=$cx_rows depths=$cx_depth sibling=$cx_sib_depth) — CTLcx2 would prove nothing"
  fi
  CX_OUT="$(conformance_check "$CX" "$CANON_FILE" "$CITATION" "$CANON_N")"; CX_RC=$?
  if [ "$CX_RC" -ne 0 ] && has_finding "$CX_OUT" 'D2'; then
    PASS "CTLcx2: MUST-FIRE — a backticked token that is not a depth is still not a depth, so a table declaring none is still caught (D2); normalising the cell did not widen what counts as a depth"
  else
    FAIL "CTLcx2: MUST-FIRE — a table whose only depth cells are backticked non-depths passed (rc=$CX_RC); the normalisation widened the match and now masks a genuinely absent requirement table"
  fi

  # ── CTL-hs: `contract-depth` rendered as a CODE SPAN in the HEADER LINE MUST fire H2,
  # while the SAME rendering in the verb table's depth CELL passes. That asymmetry was
  # measured rather than designed, so it is now STATED in the contract and asserted here
  # instead of being left to be discovered. Why it is kept rather than widened away: each
  # surface accepts exactly the rendering its own worked example shows — the header block
  # is reproduced from the `trip-contract-header` fence, which renders every one of its
  # fields bare, and a verb table from the consumer table, which renders every depth value
  # as a code span. The header block is also the surface whose lines are byte-exact: its
  # citation line is asserted identical across all five files and `population-role` admits
  # RESOLVE or CREATE and no other rendering, so tolerating a second rendering of one
  # field alone would make that block's discipline field-dependent for no gain.
  HS="$WORK/ctl_spandepth"; mk_tree "$HS" spandepth
  if grep -q -x -F -- 'contract-depth: `G8`' "$HS/trip.md" \
     && ! grep -q -x -F -- 'contract-depth: G8' "$HS/trip.md" \
     && grep -q -x -F -- 'contract-depth: G8' "$HS/trip-record.md"; then
    PASS "CTLhs1: fixture integrity — the defective consumer's contract-depth line is PRESENT and code-span rendered, and the same whole-line probe finds the bare form in its sibling, so the zero here is a rendering difference and not a missing line"
  else
    FAIL "CTLhs1: the code-span header fixture is not set up as claimed — CTLhs2 would prove nothing"
  fi
  HS_OUT="$(conformance_check "$HS" "$CANON_FILE" "$CITATION" "$CANON_N")"; HS_RC=$?
  if [ "$HS_RC" -ne 0 ] && has_finding "$HS_OUT" 'H2'; then
    PASS "CTLhs2: MUST-FIRE — a code-span rendering of the HEADER's contract-depth is not a depth declaration and is graded as an absent one (H2)"
  else
    FAIL "CTLhs2: MUST-FIRE — a code-span header depth was accepted (rc=$HS_RC); the header block no longer admits exactly one rendering per field, and the contract says it does"
  fi
  if ! has_finding "$HS_OUT" 'D2'; then
    PASS "CTLhs3: the asymmetry is asserted rather than incidental — the SAME file renders its verb table's depth cells as code spans too, and D2 stayed silent, so the cell accepted precisely the rendering the header rejected"
  else
    FAIL "CTLhs3: D2 fired on a table whose depth cells are code spans, so the two surfaces no longer differ in the direction the contract states: $(printf '%s' "$HS_OUT" | head -2 | tr '\n' ' ')"
  fi

  # ── CTL-e: where this group built, and what it left behind — stated as things it can
  # measure. A control that writes into the tree it is meant to be measuring is not a
  # control. Graded LAST, after every fixture above.
  #
  # ── WHY THIS ARM WAS REWRITTEN, KEPT HERE SO IT IS NOT REINTRODUCED ──────────────
  # It previously read:
  #     if [ ! -e "$ROOT/.claude/commands/trip-decommission.md" ] OR [ "$RP_POP" -gt 0 ]
  # RP_POP counts the *.md files in the very directory the existence test probes. On any
  # tree whose consumer population is non-empty — which is every tree from Wave 1 onwards
  # — the second disjunct is true, so the arm PASSed whatever the first one said. Truth
  # table, executed rather than read: healthy tree PASS; the commands directory moved
  # aside entirely PASS; and a fixture genuinely written into the commands directory
  # PASS — the exact state its own failure text named. A check indistinguishable from one
  # that CANNOT fire is the defect this file's own banner says it exists to prevent, and
  # the review that found this arm found a second one of the identical shape in the same
  # suite. Two instances of one defect is a missing control, not two bugs. Group FZ at the
  # foot of this file is that control: it makes a third one a red check rather than
  # something a reader has to notice by eye.
  #
  # The message overclaimed in the same way the old EVrepo one did: "the repository tree
  # was never written to" was asserted
  # over the whole tree while nothing was watched at all. Three observable things are
  # asserted instead, and the message says only those:
  #   1. this group actually built fixtures, so the path check below has a population;
  #   2. every directory it built into lies under the temp dir, and the temp dir is not
  #      inside the repository — so "under WORK" really does imply "away from ROOT"; and
  #   3. the repository's own .claude/commands/ tree is byte-unchanged across the group,
  #      which is the write half, measured.
  # A READ is not claimed. A read leaves nothing behind for any predicate here to observe,
  # so claiming one did not happen would be the same overclaim in new words.
  #
  # ── WHY AN EMPTY WATCHED SURFACE IS NOT GRADED BROKEN HERE, UNLIKE EVrepo ────────
  # EVrepo fails when the tree it watches held 0 files at snapshot time, because trips/
  # carries a tracked file and a zero there means something is wrong. This surface is
  # different:
  # at Wave 0 the consumer directory is legitimately empty, which is exactly
  # why RP renders VACUOUS rather than FAIL for it. And an empty surface does not blind
  # this comparison — tree_state reports "absent" and a count, so a write that creates the
  # directory, or adds the first file to it, changes the state string either way. The
  # count is carried into the message so a reader sees what was watched.
  CTL_CMD_AFTER="$(tree_state "$CMD_DIR")"
  CTL_CMD_N="${CTL_CMD_BEFORE%% *}"
  CTL_FIXTURE_N=0; CTL_FIXTURE_STRAY=""
  while IFS= read -r ctl_dir || [ -n "$ctl_dir" ]; do
    [ -n "$ctl_dir" ] || continue
    CTL_FIXTURE_N=$((CTL_FIXTURE_N+1))
    case "$ctl_dir" in
      "$WORK"/*) ;;
      *) CTL_FIXTURE_STRAY="$CTL_FIXTURE_STRAY$ctl_dir " ;;
    esac
  done <<<"$CTL_FIXTURE_DIRS"
  CTL_WORK_SANE=1
  case "$WORK" in
    "$ROOT"|"$ROOT"/*) CTL_WORK_SANE=0 ;;
  esac
  if [ "$CTL_FIXTURE_N" -eq 0 ]; then
    FAIL "CTLe: no fixture tree was recorded as built by this group, so the path check below would iterate an empty list and its silence would prove nothing — either the fixtures were not constructed or they were constructed by some route that does not record itself"
  elif [ "$CTL_WORK_SANE" -ne 1 ]; then
    FAIL "CTLe: the temp dir ($WORK) lies inside the repository ($ROOT), so 'this fixture is under the temp dir' would not imply 'this fixture is away from the repository' and the path check below could not say what it claims"
  elif [ -n "$CTL_FIXTURE_STRAY" ]; then
    FAIL "CTLe: a fixture tree this group built does not lie under the temp dir ($WORK) — ${CTL_FIXTURE_STRAY}— so this group cannot say it kept its fixtures out of the repository"
  elif [ "$CTL_CMD_AFTER" != "$CTL_CMD_BEFORE" ]; then
    FAIL "CTLe: the repository's own .claude/commands/ tree changed across this group (was '$CTL_CMD_BEFORE', now '$CTL_CMD_AFTER') — a fixture was written into the tree this suite is measuring"
  else
    PASS "CTLe: all $CTL_FIXTURE_N fixture tree(s) this group built lie under the temp dir ($WORK), which is not inside the repository, and the repository's own .claude/commands/ tree — $CTL_CMD_N file(s), digested before the first fixture was built and again after the last — is byte-unchanged. No fixture was written into the tree this suite measures; a READ is not claimed, because a read leaves nothing here could observe"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PF — no verdict in this suite is decided by a pipeline's exit status.
#
# A verdict site whose writer pipes into an early-exiting `grep -q` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on
# first match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed
# although the match succeeded. Measured on an unchanged tree in the taxonomy suite before
# it was fixed: 10 red runs in 30, across two arms sharing nothing but the shape.
#
# Why a standing arm rather than a comment: this suite routed 21 call sites through one
# has_finding() helper, and its callers are the INVERTED form — group RP reads
# `if has_finding …; then FAIL`, CTLcs and CTLhs read `if ! has_finding …; then PASS`. In
# both, a spurious non-zero resolves toward the quiet answer: the finding goes unreported
# and the arm records a pass on a state that carries it. A false RED costs a re-run and
# announces itself; this direction announces nothing. The shape is therefore what is
# asserted absent, not the arms it happened to surface on elsewhere.
#
# This suite deliberately sources nothing (see the note beside `set +o`), so its scan set
# is correctly this file alone — a scope that follows from the same reasoning that keeps
# the publish script out of this suite's shell.
#
# The needle is assembled from two pieces because this scan reads its own source — a
# literal spelling of the shape in the detector would make the detector match itself and
# report a defect it had just introduced.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group PF — no verdict in this file is decided by a pipeline's exit status."
PF_PIPE_SHAPE='| grep -'"q"
PF_PIPE_TIGHT='|grep -'"q"
PF_BAD=0; PF_GOOD=0
if [ ! -r "$SELF" ]; then
  FAIL "PF1: this file is unreadable at $SELF, so the scan below would cover nothing while reporting a zero"
else
  while IFS= read -r pfline || [ -n "$pfline" ]; do
    # An OR-list is not a pipeline. Its two-character operator carries the one-character
    # one as a substring, so a correct OR-list of two file-reading greps would read as the
    # defect shape. Neutralise the operator before the test rather than teaching both
    # patterns about it: this file carries none today, and the scan must not acquire a
    # false positive the first time one is written.
    pfscrub="${pfline//||/  }"
    case "$pfscrub" in
      *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
    esac
    case "$pfline" in
      *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
    esac
  done < "$SELF"
  # Graded in the order that makes the zero mean something: a detector that finds no
  # instance of the CORRECT form is broken, and its zero on the incorrect form would be a
  # probe failure wearing a pass. An empty input is broken, not clean.
  if [ "$PF_GOOD" -eq 0 ]; then
    FAIL "PF1: the scan found 0 here-string grep -q sites in this file, so its zero on the pipeline shape proves nothing — the convention or the scan has moved, and neither verdict is trustworthy"
  elif [ "$PF_BAD" -eq 0 ]; then
    PASS "PF1: ${PF_GOOD} grep -q sites in this file, 0 of them pipelines — no verdict here, and none of the 21 call sites routed through has_finding, can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
  else
    FAIL "PF1: ${PF_BAD} verdict site(s) in this file pipe into an early-exiting grep under pipefail — it exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead; it is a simple command, so pipefail has nothing to aggregate"
  fi
fi


# ═════════════════════════════════════════════════════════════════════════════════
# Group MD — the Discriminating-Evidence Rule, asserted against this file.
#
# THE RULE. An assertion is MUTATION-DETECTABLE iff every path to its PASS requires
# evidence the subject could only have produced by RUNNING. PASS may never be reached on
# a branch a DEGENERATE outcome also reaches — an absent subject, an empty haystack, an
# unreadable input, an empty population.
#
# WHY THIS GROUP IS HERE AND NOT ONLY IN THE SUITE WHERE THE DEFECT WAS FOUND. The defect
# was measured in the publish-guard suite: deleting verify_ciphertext left four assertions
# PASSing against a function that no longer existed, and deleting an entire subcommand
# left that suite exiting 0. But the population is not concentrated there — 59 sites carry
# the shape across the five suites, and this suite carries 5 of them. A guard installed only where the defect
# was noticed leaves the growth surface unguarded, and the growth is in the other suites:
# two of them gained +499 and +278 lines in a single prior release.
#
# TWO ARMS. The DYNAMIC arm re-runs a REGISTERED assertion with its subject `unset -f`
# and requires exactly one FAIL and no PASS. The STATIC arm scans this file for the
# polarity-negative SHAPE, so an assertion ADDED in that shape is caught even though
# nobody registered it. Registration alone closes today's sites and leaves tomorrow's open.
#
# THE VACUITY GUARD RUNS FIRST, for the same reason PF1's does: a scan that cannot read
# its input, or that finds no instance of the REMEDIATED form, has a zero on the defective
# form that proves nothing. THE CONTROLS ARE STANDING ARMS, not a check performed once at
# authoring time — MD1 proves the scanner discriminates, MD4 that the oracle convicts a
# legacy shape, MD5 that the same oracle certifies a remediated one. Without all three a
# green MD proves only that MD ran.
#
# WHAT THIS GROUP DELIBERATELY DOES NOT DO. It does not grade a Class-2 (zero-population)
# verdict as a defect. `[ "$n" -eq 0 ] && PASS` is CONDITIONAL, not broken: it is sound
# when it states its denominator and carries a sensitivity arm, and many here already do.
# MD3 counts that population with its denominator so the residual rides on every run
# rather than in a comment; it is remediated on touch, not swept in bulk.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group MD — every PASS here must require evidence its subject could only have produced by running."

# ── The three shapes the STATIC arm decides. Written down, because what it matches is an
# ENUMERATION WITH A STATED BOUNDARY and not a closed class.
#
#   Form 1  one line:   if <cond>; then FAIL "<id>: …"; else PASS "<id>: …"; fi
#   Form 2  block:      if|elif <cond>; then / FAIL "<id>: …" / else / PASS "<id>: …"
#   Form 3  trailing:   if|elif <cond>; then FAIL "<id>: …"; <more statements>
#                       else PASS "<id>: …"
#
# in each case ONLY when <cond> is LIVE — a command invocation, a here-string probe or an
# external tool, i.e. something that can exit 127 ("absent") or 2 ("could not read"). A
# condition opening with `[`, `[[`, `test` or `((` is a shell test: it cannot report an
# absent subject, so a PASS on its else limb is not this defect and is NOT flagged.
#
# The condition is read up to the FIRST `;`. What is OUTSIDE this scan, so the next vector
# is a documented exclusion rather than a surprise: a condition carrying an embedded `;`,
# a verdict reached through a `case` arm, a verdict whose id is only known at call time, a
# limb separated from its opener by a non-comment statement, and any verdict inside a
# here-document. It fails open on each.
MD_RE_OPENF='^(if|elif)[[:space:]]+([^;]+);[[:space:]]*then[[:space:]]+FAIL[[:space:]]+"'
MD_RE_OPENB='^(if|elif)[[:space:]]+([^;]+);[[:space:]]*then[[:space:]]*$'
MD_RE_INLE=';[[:space:]]*else[[:space:]]+PASS[[:space:]]+"([^":]*):'
MD_RE_ELSEP='^else[[:space:]]+PASS[[:space:]]+"([^":]*):'
MD_RE_FAILV='^FAIL[[:space:]]+"'
MD_RE_PASSV='^PASS[[:space:]]+"([^":]*):'
MD_RE_ZERO='(-eq|-le|-lt)[[:space:]]+0([[:space:]]|\]|$)|-z[[:space:]]+"'

MD_L=(); MD_N=0; MD_J=-1
MD_C1_IDS=""; MD_C1_N=0; MD_C2_N=0; MD_PASS_N=0; MD_RC_N=0; MD_UNREAD=0
md_reset() { MD_C1_IDS=""; MD_C1_N=0; MD_C2_N=0; MD_PASS_N=0; MD_RC_N=0; MD_UNREAD=0; }

md_live() {   # md_live <condition> -> 0 when the condition can report an ABSENT subject
  local c="$1"
  c="${c#"${c%%[![:space:]]*}"}"
  case "$c" in '!'*) c="${c#!}"; c="${c#"${c%%[![:space:]]*}"}" ;; esac
  case "$c" in ''|'['*|'test '*|'(('*) return 1 ;; esac
  return 0
}

md_next() {   # md_next <index> -> MD_J = next non-blank, non-comment index STRICTLY after it
  local j=$(( $1 + 1 )) t
  while [ "$j" -lt "$MD_N" ]; do
    t="${MD_L[$j]}"; t="${t#"${t%%[![:space:]]*}"}"
    case "$t" in ''|'#'*) j=$((j+1)); continue ;; esac
    MD_J=$j; return 0
  done
  MD_J=-1; return 1
}

md_scan() {   # md_scan <file> -> accumulates MD_C1_IDS MD_C1_N MD_C2_N MD_PASS_N MD_RC_N MD_UNREAD
  local f="$1"
  if [ ! -r "$f" ]; then MD_UNREAD=$((MD_UNREAD+1)); return 0; fi
  MD_L=(); local ln
  while IFS= read -r ln || [ -n "$ln" ]; do MD_L+=("$ln"); done < "$f"
  MD_N=${#MD_L[@]}
  local i s t u c id
  for (( i=0; i<MD_N; i++ )); do
    s="${MD_L[$i]}"; s="${s#"${s%%[![:space:]]*}"}"
    case "$s" in *'PASS "'*)     MD_PASS_N=$((MD_PASS_N+1)) ;; esac
    case "$s" in *'expect_rc '*) MD_RC_N=$((MD_RC_N+1)) ;; esac
    # ── Class 2 — a PASS gated on an empty population. Counted, never failed.
    if [[ "$s" =~ $MD_RE_ZERO ]]; then
      case "$s" in
        *'PASS "'*) MD_C2_N=$((MD_C2_N+1)) ;;
        *) if [[ "$s" =~ $MD_RE_OPENB ]] && md_next "$i"; then
             t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
             [[ "$t" =~ $MD_RE_PASSV ]] && MD_C2_N=$((MD_C2_N+1))
           fi ;;
      esac
    fi
    # ── Class 1 — the polarity-negative shape over a live condition. BASH_REMATCH is
    # clobbered by every [[ =~ ]], so each capture is taken on the line that produced it.
    c=""; id=""
    if [[ "$s" =~ $MD_RE_OPENF ]]; then
      c="${BASH_REMATCH[2]}"
      if [[ "$s" =~ $MD_RE_INLE ]]; then
        id="${BASH_REMATCH[1]}"
      elif md_next "$i"; then
        t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
        if [[ "$t" =~ $MD_RE_ELSEP ]]; then
          id="${BASH_REMATCH[1]}"
        elif [ "$t" = "else" ] && md_next "$MD_J"; then
          u="${MD_L[$MD_J]}"; u="${u#"${u%%[![:space:]]*}"}"
          [[ "$u" =~ $MD_RE_PASSV ]] && id="${BASH_REMATCH[1]}"
        fi
      fi
    elif [[ "$s" =~ $MD_RE_OPENB ]]; then
      c="${BASH_REMATCH[2]}"
      if md_next "$i"; then
        t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
        if [[ "$t" =~ $MD_RE_FAILV ]] && md_next "$MD_J"; then
          t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
          if [[ "$t" =~ $MD_RE_ELSEP ]]; then
            id="${BASH_REMATCH[1]}"
          elif [ "$t" = "else" ] && md_next "$MD_J"; then
            u="${MD_L[$MD_J]}"; u="${u#"${u%%[![:space:]]*}"}"
            [[ "$u" =~ $MD_RE_PASSV ]] && id="${BASH_REMATCH[1]}"
          fi
        fi
      fi
    fi
    if [ -n "$id" ] && md_live "$c"; then
      MD_C1_N=$((MD_C1_N+1)); MD_C1_IDS="$MD_C1_IDS$id "
    fi
  done
  return 0
}

md_diff() {   # md_diff <a-set> <b-set> -> members of a absent from b, deduped
  local x out=" "
  # shellcheck disable=SC2086
  for x in $1; do
    case " $2 " in *" $x "*) continue ;; esac
    case "$out"  in *" $x "*) continue ;; esac
    out="$out$x "
  done
  printf '%s' "${out# }"
}
md_count() { local x n=0; for x in $1; do n=$((n+1)); done; printf '%s' "$n"; }

# ── The control fixture, built here from PIECES. This scan reads its own source, so a
# literal verdict token in the writer below would be read as a real site and the detector
# would convict the fixture it had just written — the same self-matching problem group PF
# solves with a two-piece needle. The fixture carries one site per defective form (ZMDA,
# ZMDB, ZMDF), one shell-test site that must NOT be flagged (ZMDT), one zero-population
# site (ZMDZ), and one remediated site (ZMDR). Sensitivity and specificity in one input.
MD_FIX="$WORK/md-control-fixture.sh"
MD_VP='PASS'; MD_VF='FAIL'
{
  printf 'if zzq_md_subject a; then %s "ZMDA: rejected"; else %s "ZMDA: accepted"; fi\n' "$MD_VF" "$MD_VP"
  printf 'if zzq_md_subject b; then\n  %s "ZMDB: rejected"\nelse\n  %s "ZMDB: accepted"\nfi\n' "$MD_VF" "$MD_VP"
  printf 'if zzq_md_subject c; then %s "ZMDF: rejected"; show zzq\nelse %s "ZMDF: accepted"; fi\n' "$MD_VF" "$MD_VP"
  printf 'if [ "$zzn" -eq 0 ]; then\n  %s "ZMDT: rejected"\nelse\n  %s "ZMDT: accepted"\nfi\n' "$MD_VF" "$MD_VP"
  printf 'if [ "$zzn" -eq 0 ]; then %s "ZMDZ: the population is empty"; else %s "ZMDZ: not empty"; fi\n' "$MD_VP" "$MD_VF"
  printf 'expect_rc 1 "ZMDR" "the remediated form grades an exact status" -- zzq_md_subject d\n'
} > "$MD_FIX"

md_reset; md_scan "$MD_FIX"
MD_FX_C1="${MD_C1_IDS% }"; MD_FX_C2="$MD_C2_N"; MD_FX_RC="$MD_RC_N"; MD_FX_UNREAD="$MD_UNREAD"
md_reset; md_scan "$SELF"
MD_SELF_C1="${MD_C1_IDS% }"

# ── The DECLARED residual. These sites carry the polarity-negative shape and are NOT
# remediated by this change, whose locked scope is the five named assertions in the
# publish-guard suite plus this oracle in all five; a 59-site sweep across five suites is
# exactly the blind bulk edit this repository's own discipline forbids. They are declared
# here rather than left silent, and the diff below runs in BOTH directions — an undeclared
# site FAILS, and a declared site that no longer scans FAILS too, so remediating one
# obliges removing its line. The list can only shrink; it cannot quietly absorb a new
# defect.
#   All five are the same shape over the same subject — `if has_finding …; then FAIL …`
#   with the PASS on the else limb, where an absent has_finding exits 127 and lands on
#   the PASS. This suite's own PF1 already names has_finding as the hinge of 21 arms.
MD_LEGACY='RP1 RP2 RP3 RP4 RP5'

if [ "$MD_UNREAD" -ne 0 ]; then
  FAIL "MD0: this file is unreadable at $SELF, so the scan below would cover nothing while reporting a zero — an unreadable scan set is a finding, never a clean file"
elif [ "$MD_PASS_N" -eq 0 ]; then
  FAIL "MD0: the scan found 0 verdict lines in this file, so its count on the polarity-negative shape proves nothing — either the PASS/FAIL grammar moved or the scan did, and no verdict below is trustworthy"
elif [ "$MD_RC_N" -eq 0 ]; then
  FAIL "MD0: the scan found 0 expect_rc sites — no assertion here is written in the REMEDIATED form, so a clean reading of the defective form is an empty scan rather than a clean file"
else
  PASS "MD0: the scan set is readable and non-degenerate — ${MD_PASS_N} verdict line(s) and ${MD_RC_N} expect_rc site(s) read from this file. Every count below is a measurement rather than an empty scan"

  # MD1 — CONTROL on the scanner, both directions, before any count it produces is read.
  if [ "$MD_FX_UNREAD" -ne 0 ]; then
    FAIL "MD1: CONTROL — the fixture at $MD_FIX was unreadable, so the scanner was never exercised and MD2's count is not a measurement"
  elif [ "$MD_FX_C1" != "ZMDA ZMDB ZMDF" ]; then
    FAIL "MD1: CONTROL on the scanner — over a fixture carrying one site per defective form (ZMDA one-line, ZMDB block, ZMDF trailing-statement), one shell-test site (ZMDT) and one remediated site (ZMDR), the scanner reported '$MD_FX_C1' rather than 'ZMDA ZMDB ZMDF'. MD2's verdict proves nothing until this control fires"
  elif [ "$MD_FX_C2" -ne 1 ]; then
    FAIL "MD1: CONTROL on the Class-2 detector — the fixture carries exactly one zero-population site (ZMDZ) and the detector found $MD_FX_C2, so MD3's inventory is not a measurement"
  elif [ "$MD_FX_RC" -eq 0 ]; then
    FAIL "MD1: CONTROL — the fixture carries one expect_rc site (ZMDR) and the scanner found none, so MD0's non-degeneracy arm is reading something other than what it claims"
  else
    PASS "MD1: CONTROL on the scanner — SENSITIVITY and SPECIFICITY over one fixture: all three defective forms are found (ZMDA, ZMDB, ZMDF), and neither the shell-test site (ZMDT, whose condition cannot report an absent subject) nor the remediated site (ZMDR) is flagged. A detector that flagged everything would be as useless as one that flagged nothing; both arms fired"

    MD_NEW="$(md_diff "$MD_SELF_C1" "$MD_LEGACY")"
    MD_STALE="$(md_diff "$MD_LEGACY" "$MD_SELF_C1")"
    MD_NDEC="$(md_count "$MD_LEGACY")"
    if [ -n "$MD_NEW" ]; then
      FAIL "MD2: assertion(s) carry the polarity-negative shape and are not in the declared residual: ${MD_NEW% } — their PASS limb is reached by rc=127 (the subject is absent) exactly as it is by the rejection they mean to assert. Either grade an exact status with expect_rc, or declare the site in MD_LEGACY above with the reason it stays"
    elif [ -n "$MD_STALE" ]; then
      FAIL "MD2: declared residual site(s) no longer carry the shape: ${MD_STALE% } — the remediation landed but its MD_LEGACY line did not come out. A declaration that outlives its defect is a standing exemption for whatever next takes that id"
    else
      PASS "MD2: every polarity-negative site in this file is accounted for — ${MD_C1_N} found, all ${MD_NDEC} declared, none undeclared and none stale, over a denominator of ${MD_PASS_N} verdict line(s). The declared set is this suite's remediation queue and can only shrink; MD1's control is what makes the accounting a measurement"
    fi

    PASS "MD3: INVENTORY — ${MD_C2_N} of ${MD_PASS_N} verdict line(s) gate a PASS on an empty population ('-eq 0' / '-le 0' / '-z'). That shape is CONDITIONAL rather than defective: it is sound when it states its denominator and carries a sensitivity arm, which many here already do, so it is counted on every run and remediated on touch rather than swept in bulk. The count is a measurement — MD1's Class-2 arm found the one planted site in the fixture"
  fi
fi

# ── MD4 / MD5: the controls on the ORACLE. They do not depend on the static scan, so they
# run outside MD0's guard: a broken scanner must not suppress the oracle's own evidence.
#
# zzq_md_subject exists and returns 1, so BOTH probes below pass while it is present. The
# question each control asks is what happens when it is removed. md_legacy_probe is written
# as a single-line function definition on purpose: the static arm scans THIS file, and a
# bare legacy shape here would be a real finding in its own ledger. Its job is to be
# legacy-shaped for the oracle, not to be a site in the corpus, so it is kept out of the
# scanner's reach by form — and the scanner's own sensitivity is proven on the fixture in
# MD1 instead, where a planted site is exactly what is wanted.
zzq_md_subject()  { return 1; }
md_legacy_probe() { if zzq_md_subject; then FAIL "ZMDL: subject accepted"; else PASS "ZMDL: subject rejected"; fi; }
md_sound_probe()  { expect_rc 1 "ZMDS" "the remediated form grades an exact status" -- zzq_md_subject; }

MD_CL="$(md_probe zzq_md_subject md_legacy_probe)"
if [ "$MD_CL" = "1 0" ]; then
  PASS "MD4: CONTROL on the oracle — a deliberately legacy-shaped assertion still reports pass=1 fail=0 with its subject removed, so the oracle CONVICTS the shape this group exists for. Every MD[...] verdict is therefore a measurement rather than a statement that the oracle ran"
else
  FAIL "MD4: CONTROL on the oracle did not fire — the planted legacy-shaped assertion returned '$MD_CL' rather than '1 0' with its subject removed. Until the oracle convicts a known-blind assertion, an MD[...] pass proves only that md_probe executed"
fi

MD_CS="$(md_probe zzq_md_subject md_sound_probe)"
if [ "$MD_CS" = "0 1" ]; then
  PASS "MD5: CONTROL on the oracle — a remediated assertion over the same subject returns pass=0 fail=1 with that subject removed, so the oracle CERTIFIES the sound shape as well as convicting the defective one. Both directions fired on the same subject in the same process"
else
  FAIL "MD5: CONTROL on the oracle did not fire — the planted remediated assertion returned '$MD_CS' rather than '0 1' with its subject removed. An oracle that convicts everything is as useless as one that convicts nothing"
fi

# ── No assertion in this suite is REGISTERED with md_flips yet, and that is a consequence
# rather than an omission: registration requires the assertion to be remediated first,
# because an oracle asked to certify a still-blind assertion turns the suite red for a
# defect it is reporting rather than causing. The declared residual in MD2 is this suite's
# registration queue, and every entry that leaves it gains an MD[...] arm in the same edit.

# ═════════════════════════════════════════════════════════════════════════════════
# Group FZ — every verdict arm in this file must be able to FAIL.
#
# ── WHY THIS GROUP EXISTS ────────────────────────────────────────────────────────
# This suite's own banner says an unexercised check is indistinguishable from one that
# CANNOT fire, and that leaving one inside the anti-drift guard would be that defect at
# its own root. This suite nevertheless shipped two verdict arms unable to fail — EVrepo,
# corrected on the release branch where that arm lives, and CTLe, corrected in group CTL
# above — and both were found by a human reading predicates at Stage 7, not by a check.
# Two instances of one defect is a missing control, not two bugs. This group is the control.
#
# ── THE RULE IT ENFORCES, AND WHY THAT RULE ──────────────────────────────────────
# Reachability is not decidable in general, so this group does not claim to decide it. It
# enforces a SHAPE, and the shape is the one both instances had:
#
#     a verdict guard that reaches PASS through a DISJUNCTION.
#
# Written `if A or B; then PASS ... else FAIL`, the failure branch requires `not A and
# not B` — a CONJUNCTION the author never wrote down and therefore never checked. That is
# where unsatisfiability hides. Both instances were exactly this, and in both the second
# disjunct was implied by the first's negation:
#   EVrepo  the canary existing implied its parent directory existed;
#   CTLe    the consumer file existing implied the consumer population was non-zero.
# The same disjunction reaching FAIL is the opposite case and is not flagged: `if A or B;
# then FAIL` fires whenever either holds, which is the shape the corrected EVrepo uses.
#
# The shape is not merely suspicious, it is never NECESSARY here. Every arm written that
# way can be written as a chain — one `elif` per condition, one message per branch — which
# is strictly better for a second reason this file already argues elsewhere: a branch that
# can fire for several reasons proves that something was wrong, not WHICH thing. And where
# a disjunct exists to excuse an empty population, this suite already has a verdict for
# that case and it is not PASS: it is VACUOUS. So the rule costs nothing it should keep.
#
# ── COVERAGE BOUNDARY — WHAT THIS GROUP DOES NOT GRADE ───────────────────────────
# Stated plainly, because an overclaiming meta-arm is the same defect one level up.
#   *  It decides a SHAPE, never reachability. A tautological guard — `[ "$n" -ge 0 ]`,
#      or a comparison between two values the suite itself constructs to be equal —
#      reaches PASS without a disjunction and is INVISIBLE here. This group would not
#      have caught such an arm, and does not claim it would.
#   *  It grades the guards whose taken branch BEGINS with a verdict — the first statement
#      after `then`, on that line or on the next non-blank non-comment line. A verdict
#      buried deeper inside a branch is counted as a non-verdict guard and is not graded.
#      The counts are printed, so the ungraded remainder is visible rather than implied.
#   *  The walk is line-oriented and does not track nesting, so it attributes a verdict to
#      the guard it most recently completed. Both controls below run on synthetic sources
#      of known shape precisely because the parser's own correctness cannot be assumed.
#   *  Its scan set is THIS FILE, for the same reason group PF's is: this suite sources
#      nothing, so its own source is the whole of what it can speak for. The sibling guard
#      suites are not scanned and are not covered.
#
# ── THE CONTROLS ARE PERMANENT, NOT A ONE-TIME DEMONSTRATION ─────────────────────
# FZ1 plants an arm carrying the banned shape and requires the detector to flag it. FZ2
# plants the conforming source — the same arm rewritten as a chain, PLUS a conjunctive
# PASS-reaching guard — and requires silence over it; that second guard is not decoration,
# it is the only specimen an over-matching detector can be seen on, and FZ2 asserts its
# presence rather than assuming it. Both sources are built and run on EVERY invocation, the
# way group CTL rebuilds its fixtures, so a detector that stops detecting is caught by the
# next run rather than by the next reader. FZ1 is graded FIRST, and FZ3 reads its result: a
# zero whose sensitivity arm did not fire is a broken probe, not a clean file.
#
# The needle is assembled from two pieces, and the comments above spell it `or` rather than
# literally, for the reason group PF assembles its own: a detector that spells the shape it
# hunts would match itself. The ONE deliberate exception is the plant, which spells the
# operator in full so that it is not built out of the needle it is meant to test — see the
# note at fz_plant, and the probe that forced it.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group FZ — every verdict arm in this file must be able to FAIL."

FZ_OR='|'"|"
FZ_GUARDS=0; FZ_ARMS=0; FZ_PASSARMS=0; FZ_FAILARMS=0; FZ_NONVERDICT=0; FZ_UNRESOLVED=0
FZ_BAD=0; FZ_BAD_AT=""; FZ_LINES=0

# Resolve one located guard against the first statement of its taken branch. Split out so
# the two call sites — the same-line form `if X; then PASS …` and the next-line form —
# classify identically; `fz_rest` and `fz_guard` are the walker's cursor.
fz_resolve() {
  case "$fz_rest" in
    *'PASS "'*)
      FZ_ARMS=$((FZ_ARMS+1)); FZ_PASSARMS=$((FZ_PASSARMS+1))
      case "$fz_guard" in
        *"$FZ_OR"*) FZ_BAD=$((FZ_BAD+1)); FZ_BAD_AT="$FZ_BAD_AT$fz_gline " ;;
      esac ;;
    *'FAIL "'*)
      FZ_ARMS=$((FZ_ARMS+1)); FZ_FAILARMS=$((FZ_FAILARMS+1)) ;;
    *)
      FZ_NONVERDICT=$((FZ_NONVERDICT+1)) ;;
  esac
}

# Walk a shell source and grade every verdict guard it can locate. Sets the FZ_ globals.
fz_scan() {  # <file>
  local f="$1" line t pend=0 want=0
  FZ_GUARDS=0; FZ_ARMS=0; FZ_PASSARMS=0; FZ_FAILARMS=0; FZ_NONVERDICT=0; FZ_UNRESOLVED=0
  FZ_BAD=0; FZ_BAD_AT=""; FZ_LINES=0
  fz_guard=""; fz_gline=0; fz_rest=""
  while IFS= read -r line || [ -n "$line" ]; do
    FZ_LINES=$((FZ_LINES+1))
    t="${line#"${line%%[![:space:]]*}"}"
    case "$t" in ''|'#'*) continue ;; esac
    if [ "$pend" -eq 1 ]; then
      # A continuation of a multi-line guard. Accumulated so a disjunction written on a
      # later line is seen; a guard is a single logical expression however it is wrapped.
      fz_guard="$fz_guard $t"
      case "$t" in
        *' then'*|*';then'*) pend=0; FZ_GUARDS=$((FZ_GUARDS+1)); fz_rest="${t#*then}"; want=1 ;;
        *) continue ;;
      esac
    else
      case "$t" in
        'if '*|'elif '*|'if	'*|'elif	'*)
          # A guard opening while the previous one is still waiting for its branch means
          # that previous branch did not begin with a verdict. Counted, not dropped, so
          # guards = arms + non-verdict + unresolved is an identity a reader can check.
          [ "$want" -eq 1 ] && FZ_UNRESOLVED=$((FZ_UNRESOLVED+1))
          want=0
          fz_guard="$t"; fz_gline="$FZ_LINES"
          case "$t" in
            *' then'*|*';then'*) pend=0; FZ_GUARDS=$((FZ_GUARDS+1)); fz_rest="${t#*then}"; want=1 ;;
            *) pend=1; continue ;;
          esac ;;
        *)
          if [ "$want" -eq 1 ]; then
            fz_rest="$t"; want=0
            case "$t" in 'else'*|'fi'*) FZ_NONVERDICT=$((FZ_NONVERDICT+1)); continue ;; esac
            fz_resolve
          fi
          continue ;;
      esac
    fi
    # A guard completed on this line. When anything follows `then` on the same line, the
    # branch body is there and the arm resolves from it; otherwise the next non-blank,
    # non-comment line is the branch's first statement.
    fz_rest="${fz_rest#"${fz_rest%%[![:space:]]*}"}"
    if [ -n "$fz_rest" ]; then want=0; fz_resolve; fi
  done < "$f"
  [ "$want" -eq 1 ] && FZ_UNRESOLVED=$((FZ_UNRESOLVED+1))
  return 0
}

# The two synthetic sources. Both are written by the SAME emitter differing in one
# argument, so the pair differs in the guard's shape and in nothing else — the property
# that makes FZ2's silence a statement about the shape rather than about the file.
#
# ── THE PLANT SPELLS THE OPERATOR LITERALLY, AND THAT IS LOAD-BEARING ────────────
# It was first written using $FZ_OR, the detector's own needle. That version was probed by
# neutering the needle to a string that matches nothing real — and FZ1 stayed GREEN, because
# the plant had been rebuilt out of the same neutered token and the pair still agreed. A
# control assembled from the thing it validates cannot detect that thing drifting; it is the
# self-referential validation this platform's review discipline names by that word. So the
# specimen is written out in full here, independently of the needle, and the needle stays
# assembled for the reason group PF assembles its own. The literal is safe on this line
# because the walker examines only lines that OPEN a guard, and this one opens a printf.
fz_plant() {  # <path> <banned|conforming>
  local p="$1"
  mkdir -p "${p%/*}"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'p="$1"; n="$2"'
    if [ "$2" = banned ]; then
      printf '%s\n' 'if [ ! -e "$p/canary" ] || [ "$n" -gt 0 ]; then'
      printf '%s\n' '  PASS "PLANT: nothing was written"'
      printf '%s\n' 'else'
      printf '%s\n' '  FAIL "PLANT: something was written"'
      printf '%s\n' 'fi'
    else
      # The same arm as a chain: one condition per branch, one message per branch.
      printf '%s\n' 'if [ ! -e "$p/canary" ]; then'
      printf '%s\n' '  FAIL "PLANT: the canary is absent"'
      printf '%s\n' 'elif [ "$n" -eq 0 ]; then'
      printf '%s\n' '  FAIL "PLANT: the watched surface was empty"'
      printf '%s\n' 'else'
      printf '%s\n' '  PASS "PLANT: measured"'
      printf '%s\n' 'fi'
      # And a plain CONJUNCTIVE guard that reaches PASS. This one carries the whole weight
      # of FZ2: the chain above reaches PASS only through an `else`, which has no guard for
      # a needle to over-match, so a detector widened until it flagged every test in sight
      # would have left the chain untouched and FZ2 would have passed while the detector
      # was useless — measured, and it did exactly that before this arm was added. A
      # conforming PASS-reaching guard is the only specimen an over-match can be seen on.
      printf '%s\n' 'if [ -e "$p/canary" ] && [ "$n" -gt 0 ]; then'
      printf '%s\n' '  PASS "PLANT: the surface was watched and is unchanged"'
      printf '%s\n' 'else'
      printf '%s\n' '  FAIL "PLANT: the surface changed"'
      printf '%s\n' 'fi'
    fi
  } > "$p"
}

FZ_BANNED="$WORK/fz/banned.sh"
FZ_CLEAN="$WORK/fz/conforming.sh"
fz_plant "$FZ_BANNED" banned
fz_plant "$FZ_CLEAN" conforming

# ── FZ1 — SENSITIVITY, graded FIRST. A planted arm carrying the banned shape must be
# flagged, and flagged at its own guard line. Without this, FZ3's zero is a probe that
# never fired rather than a file that carries nothing.
fz_scan "$FZ_BANNED"
FZ1_BAD="$FZ_BAD"; FZ1_AT="$FZ_BAD_AT"; FZ1_PASSARMS="$FZ_PASSARMS"
if [ "$FZ1_BAD" -eq 1 ] && [ "$FZ1_PASSARMS" -eq 1 ]; then
  PASS "FZ1: SENSITIVITY — a planted arm whose PASS is guarded by a disjunction is detected (1 finding, at line ${FZ1_AT% } of the plant), so the detector fires on the shape both shipped instances had"
else
  FAIL "FZ1: SENSITIVITY — the planted unfirable arm was NOT detected as expected (findings=$FZ1_BAD, PASS-reaching arms located=$FZ1_PASSARMS, expected 1 and 1). Every verdict below rests on this arm, so none of them is trustworthy"
fi

# ── FZ2 — SPECIFICITY. The conforming source must be silent, over a population the walker
# actually located AND one that includes a PASS-reaching guard. A detector that flags
# everything is as useless as one that flags nothing; the PASS-reaching arm is the only
# specimen on which over-matching is observable, so its presence is asserted rather than
# assumed — a zero measured over a population with nothing to over-match on is not a
# specificity result.
fz_scan "$FZ_CLEAN"
FZ2_BAD="$FZ_BAD"; FZ2_ARMS="$FZ_ARMS"; FZ2_FAILARMS="$FZ_FAILARMS"; FZ2_PASSARMS="$FZ_PASSARMS"
if [ "$FZ2_BAD" -eq 0 ] && [ "$FZ2_ARMS" -ge 3 ] && [ "$FZ2_FAILARMS" -ge 2 ] && [ "$FZ2_PASSARMS" -ge 1 ]; then
  PASS "FZ2: SPECIFICITY — the conforming source is NOT flagged, over $FZ2_ARMS located verdict arm(s): $FZ2_FAILARMS reaching FAIL and $FZ2_PASSARMS reaching PASS through a conjunction, which is the specimen a widened detector would over-match. The detector discriminates the shape rather than rejecting every guard"
else
  FAIL "FZ2: SPECIFICITY — the conforming source was flagged, or the walker located too little of it to say (findings=$FZ2_BAD, arms=$FZ2_ARMS, FAIL-reaching=$FZ2_FAILARMS, PASS-reaching=$FZ2_PASSARMS; want 0 findings over >=3 arms with >=2 FAIL-reaching and >=1 PASS-reaching). The detector cannot tell the shapes apart, or there is nothing in the sample for an over-match to show on, and FZ3's verdict means nothing either way"
fi

# ── FZ3 — THIS FILE. The claim, and its denominator with it.
#
# Graded in the order that makes the zero mean something, the same ordering PF1 uses. The
# sensitivity result is READ here rather than merely reported above it: a clean verdict on
# this file whose own control arm did not fire is a probe failure wearing a pass, and a
# message that says "the sensitivity arm fired" while nothing checked whether it did would
# be the overclaim this whole group exists to catch, one level up. FZ2 needs no such gate —
# a detector that flags everything cannot produce a zero here to begin with.
fz_scan "$SELF"
FZ_WC="$(wc -l < "$SELF" | tr -d ' ')"
if [ "$FZ1_BAD" -ne 1 ]; then
  FAIL "FZ3: the sensitivity arm did not fire on the plant (FZ1 above), so whatever this scan found or did not find in this file is untrustworthy — a zero from a detector never shown to detect anything is a broken probe, not a clean result"
elif [ "$FZ_ARMS" -eq 0 ]; then
  FAIL "FZ3: the walker located 0 verdict arms in this file, so its zero on the banned shape is an empty scan and not a clean result — the file's shape or this walker has moved"
elif [ "$FZ_BAD" -eq 0 ]; then
  PASS "FZ3: $FZ_GUARDS guard(s) in this file — $FZ_ARMS located verdict arm(s) ($FZ_PASSARMS reaching PASS, $FZ_FAILARMS reaching FAIL), $FZ_NONVERDICT non-verdict, $FZ_UNRESOLVED unresolved — and 0 of the $FZ_PASSARMS PASS-reaching guards is a disjunction. The sensitivity arm fired on the plant, so this zero is a measurement. It grades a shape, not reachability: see this group's coverage boundary for what it cannot see"
else
  FAIL "FZ3: $FZ_BAD verdict arm(s) in this file reach PASS through a disjunction, at line(s) ${FZ_BAD_AT% }. The failure branch then needs every disjunct false at once — a conjunction nobody wrote down — which is how both previously shipped arms became unable to fail. Rewrite as a chain: one condition per branch, one message per branch"
fi

# ── FZ4 — the walk covered the file, measured by a differently-shaped counter. A state
# machine that stopped early would report a small, clean population and look identical to
# a clean file. `wc -l` counts newlines, so the walker's count is that or one more when a
# final line carries no newline; anything outside that window means the walk was partial.
if [ "$FZ_LINES" -ge "$FZ_WC" ] && [ "$FZ_LINES" -le "$((FZ_WC+1))" ] && [ "$FZ_WC" -gt 0 ]; then
  PASS "FZ4: the walker read $FZ_LINES line(s) of this file against $FZ_WC counted independently — the scan covered the whole source, so FZ3's population is the file's and not a prefix of it"
else
  FAIL "FZ4: the walker read $FZ_LINES line(s) of this file while an independent count reads $FZ_WC — the walk did not cover the source, so FZ3 graded a prefix and its verdict does not describe this file"
fi

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
if [ "$vacuous" -gt 0 ]; then
  printf 'NOTE: %d assertion group(s) had an EMPTY POPULATION and proved nothing. This run rests on group CTL.\n' "$vacuous"
fi
rc=0
[ "$fail" -eq 0 ] || rc=1
# STRICT SKIP MODE — a skipped group is a failure unless it is declared. This suite has
# no dependency-gated group, so its declared set is correctly EMPTY and every skip fails.
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
