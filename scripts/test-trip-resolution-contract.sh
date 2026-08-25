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
# NOTE: publish-trip-site.sh is deliberately NOT sourced. This suite needs no function
# from it, and sourcing a security-critical script to parse markdown would create shared
# fate — a syntax error there would make the CONTRACT invariant unverifiable for a reason
# with nothing to do with the contract.
set +e

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
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
    if [ "$rows" -eq 0 ]; then
      if [ "$role" = "RESOLVE" ]; then
        printf 'FINDING D2 %s population-role RESOLVE with no per-verb requirement table (no row carries a depth cell reading G0-G8)\n' "$base"; found=1
      fi
    elif [ -n "$depth" ] && [ "$maxd" != "$depth" ]; then
      printf 'FINDING D1 %s contract-depth G%s does not equal the maximum depth in its own verb table (G%s)\n' \
        "$base" "$depth" "$maxd"; found=1
    fi
  done
  return "$found"
}

has_finding() { printf '%s\n' "$1" | grep -qE "^FINDING ($2) "; }
show()        { printf '%s\n' "$1" | grep -E "^FINDING ($2) " | sed 's/^/      /'; }

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
#   nd H2    nr H3    nt D2    dm D1 (max computation)    dd D1 (field-index read)
#   cs code-span depth cells, MUST NOT FIRE      cx D2 (code-span specificity)
# and CTL-e is graded LAST, so its "the repo was never written to" claim covers every
# fixture above it rather than a prefix of them.
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
      [ "$variant" = "nodepth" ]  || printf 'contract-depth: G%s\n' "$depth"
      [ "$variant" = "norole" ]   || printf 'population-role: %s\n' "$role"
      printf '\n'
      if [ "$role" = "RESOLVE" ] && [ "$variant" != "notable" ]; then
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
          codespan)
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
    mkdir -p "$d"
    # `overprefix` is the one variant that must land on the G2/CREATE consumer rather
    # than on `trip`: at depth G8 the required prefix is already the WHOLE list, so
    # `trip` has no room to carry a surplus and could not express the defect at all.
    # `trip-new` is the only member of the tree whose declared depth leaves that room —
    # and it is also the exact consumer whose narrower Bash(ls:*) grant depends on it.
    if [ "$v" = "overprefix" ]; then
      mk_consumer "$d" "trip-new"        2 CREATE  overprefix
      mk_consumer "$d" "trip"            8 RESOLVE ok
    else
      mk_consumer "$d" "trip-new"        2 CREATE  ok
      mk_consumer "$d" "trip"            8 RESOLVE "$v"
    fi
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
  if printf '%s\n' "$DM_OUT" | grep -q -F -- 'verb table (G2)'; then
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
  if printf '%s\n' "$DD_OUT" | grep -q -F -- 'verb table (G1)'; then
    PASS "CTLdd3: the finding names G1 — the depth CELL, read by field index; a row-wide matcher would have read the decoy G8, agreed with the declaration and stayed silent"
  else
    FAIL "CTLdd3: D1 fired but named a maximum the depth column does not contain — the decoy was read as a depth: $(printf '%s' "$DD_OUT" | head -2 | tr '\n' ' ')"
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

  # ── CTL-e: the repo was never mutated. A control that writes into the tree it is
  # meant to be measuring is not a control. Graded LAST, after every fixture above.
  if [ ! -e "$ROOT/.claude/commands/trip-decommission.md" ] || [ "$RP_POP" -gt 0 ]; then
    PASS "CTLe: the control case built its five-file population in a temp dir; the repository tree was never written to"
  else
    FAIL "CTLe: a fixture appears to have been written into the repository tree"
  fi
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
