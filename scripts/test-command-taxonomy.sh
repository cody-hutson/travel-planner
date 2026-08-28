#!/usr/bin/env bash
#
# test-command-taxonomy.sh — the command-taxonomy coverage guard.
#
# Implements ADR-007 Decision 3 (taxonomy ownership) under a VERB surface. The retired
# guard asserted command-name -> command-file, proved forward, reverse and injective.
# Under `/trip <verb>` the left side of that assertion is a (command, verb) pair and the
# right side has no file to point at, so the assertion is REPLACED rather than adjusted.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
# This list is NOT the authority. It is a reader's index. The authority is group Y,
# which derives the emittable finding ids from this file's own emission sites and
# asserts, in BOTH directions, that every one is surfaced by a reporting group AND
# exercised by a control arm. A finding id added below without an arm fails group Y.
#
#   N1  a needle does not survive the normalisation applied to the haystack (group N)
#   A0  a required population is empty or a required surface is unreadable  (group A)
#
#   V   the per-file bijection: declaration <-> implementation             (group V)
#     V0 requirement-table anchor not unique at fence depth 0 · V1 malformed row
#     V2 identity collision without distinct parentheticals · V3 region count != 1
#     V4 a column-0 read declaration outside every declared verb region
#     V5 the contract-header block is not unique · V6 a transformation lost a VALUE
#
#   B   Step-1 cell shape                                                  (group B)
#     B1 malformed cell · B2 reason enum · B3 cell grammar · B4 exhaustiveness
#     B5 the command component fails N1
#
#   K   the coverage bijection, which REPLACES forward/reverse/injectivity (group K)
#     K1  RESOLVABILITY — every ADDRESSED cell covers a non-empty set and every member
#         resolves (file AND declaration AND region)
#     K2  TOTALITY      — every coverage unit of the surface is covered
#     K3  EXCLUSIVITY   — no unit covered twice; no command carrying both a verbless
#         and a verbed cell
#
#     COVERAGE, and why this CONTAINS the retired assertion rather than weakening it.
#     A verbed cell covers exactly the pair it names. A verbless cell covers every
#     declared verb of its command — and, where a command declares NO verb, the command
#     itself. That last clause is what preserves the degeneracy argument: at zero declared
#     verbs every coverage unit is a command, every cell is verbless, and K1/K2/K3
#     collapse TERM FOR TERM into the retired forward / reverse / injectivity. The retired
#     assertion is the zero-verb special case of this one. The door against a VANISHED
#     requirement table is V0, which fires per file and never degrades, so the fallback
#     cannot hide a table that disappeared — it is reachable only where a file legitimately
#     declares a table with no rows.
#
#   X   the key channel                                                    (group X)
#     X1 a key did not round-trip byte-identical · X2 empty or whitespace-bearing key
#
#   E   ADR-007 §4: completeness, the dispatch-arm staleness sentinel, and the
#       cross-surface link, with NO hardcoded command map                  (group E)
#     E1 table/row · E2 reasons · E3 completeness · E4 excluded-names-a-command
#     E5 script unreadable · E6 sentinel · E7 cross-surface · E8 §4 cell grammar
#
#   F   the invocation limb, VERB-ATTRIBUTED                               (group F)
#     F1 excluded form · F2 unpublish without the pages-only flag · F3 forbidden flag
#     F4 sets the plaintext override · F5 parse coverage · F6 a finding that could name
#     only a FILE and not a (command, verb) pair — the measure that must fall to zero
#
#   R   the DECLARED read-only key set and its membership-delta sentinel   (group R)
#     R1 an executable instruction in a read-only region · R2 sentinel fired
#
#   S   the charter's two enumerations of the verb set agree               (group S)
#     S1 a key in one enumeration and not the other · S2 SINGLE-SOURCE
#
#   G   controls: must-NOT-fire arms first, the two live differential arms, one must-fire
#       arm per emittable id, the grammar control, and the derivation mutation pair
#   Y   the assertion inventory, machine-checked against this file
#   Z   non-mutation, asserted by comparing tree state across the run
#
# ── TWO LOAD-BEARING MATCHER RULES, AND THE ARM THAT KEEPS EACH HONEST ───────────
#
# 1. THE REQUIREMENT TABLE IS ANCHORED ON ITS OWN HEADER ROW, NOT ON A FENCE.
#    The canonical contract-header block in CLAUDE.md renders its fourth field as an
#    angle-bracket placeholder that contains no pipe, and the charter derives verb-table
#    typography from a different rendered example. The consumers render the requirement
#    table OUTSIDE the contract-header fence. A locator keyed on that fence's info string
#    therefore returns a SILENT PLAUSIBLE ZERO — the worst available failure, because the
#    declared population goes empty and every direction of K becomes vacuously true.
#    This guard locates the table by its own header row, matched STRUCTURALLY on the five
#    column names the charter's G7 fixes, so a re-rendering of the row's spacing does not
#    unhook the locator. Arm G-D1 runs the fence-scoped locator over the LIVE tree
#    alongside and requires it to be strictly poorer; if the two ever converge the arm
#    reports NO LONGER DIFFERENTIAL rather than passing.
#
# 2. THE `**Reads:**` DISCRIMINATOR IS MATCHED AT COLUMN 0.
#    One command file renders `**Reads:**` template EXEMPLARS as four-space-indented
#    lines inside a NON-VERB section — an indented code block, so a backtick-fence mask
#    does not see them. A matcher that trims leading whitespace before testing counts
#    those exemplars and fires a FALSE implemented-but-undeclared finding on committed
#    state. One line of implementation decides whether this check is red. Arm G-D2 runs
#    the trim-first matcher over the LIVE tree alongside and requires it to over-count;
#    if that differential ever falls to zero the arm reports NO LONGER DIFFERENTIAL
#    rather than passing. Fence depth is required as well as column 0: the two catch
#    different renderings and neither subsumes the other.
#
# Both arms are drawn from the UNFILTERED live population, because a control drawn from
# the same filtered set the check reads cannot detect the filter.
#
# ── WHERE FENCE DEPTH APPLIES, AND WHERE IT INVERTS ──────────────────────────────
# A HEADING and a read DECLARATION are counted only at fence depth 0: inside a fence they
# are examples. An INVOCATION is the inverse — it is recognised only INSIDE a fence,
# because a fenced command line is the one rendering that separates use from mention on
# this surface. A fenced block that renders a literal script invocation inside a command
# file is therefore reported as an invocation, and that is deliberate: an "example" that
# spells a forbidden invocation in a command body is exactly what this limb exists to
# catch, and no reading of the bytes tells it apart from the real thing.
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# What a green here does and does NOT prove.
#
# IN SCOPE — the DECLARATION surface. Every group runs on every invocation, needs no
# network, no Node and no gh, and its verdict is real.
#
# OUT OF SCOPE — RUNTIME PRIVILEGE. This suite asserts that the files DECLARE what
# ADR-007 requires. It does not assert that a declaration is enforced at runtime, and a
# green here is not a privilege guarantee. On what a `disallowed-tools` line does, this
# repository carries TWO INCOMPATIBLE ACCOUNTS with nothing arbitrating between them, and
# nothing in this repository reads such a line. This guard takes NEITHER account: every
# assertion below holds under either, because each is an assertion about what a file
# DECLARES and none about what a declaration enforces. Asserting either account here
# would put a CI gate on one side of an open dispute.
#
# OUT OF SCOPE — PROSE-RENDERED INVOCATIONS. Where a command file renders an invocation
# as prose across a hard wrap, with a forbidden flag named inside a NEGATING sentence in
# the same paragraph, no per-line, per-paragraph or whole-section literal scan separates
# use from mention. The flag and arm limbs reach the FENCED rendering only. That is a
# declared uncovered region, not an omission, and this guard prints the count of
# invocations it attributed so a reader can see what it did and did not reach.
#
# OUT OF SCOPE — PER-VERB ARM BINDING. That verb A does not invoke verb B's granted arm
# is a rule a file follows, not a property this guard can derive: there is no live
# per-verb arm source. Declared as a residual rather than checked by something that
# pretends to.
#
# ── THE VACUITY DOORS, AND THE THIRD ONE ─────────────────────────────────────────
# GUARD_STRICT_SKIPS closes the door where a GROUP vanishes. This suite reads the repo,
# so it has doors that mechanism does not watch: a POPULATION vanishing. Group A closes
# three — the Step-1 slice, the command directory, and the COVERAGE-UNIT enumeration that
# K quantifies over — and its verdict is FAIL, never SKIP: a missing input IS the failure,
# not the absence of evidence about one. GUARD_EXPECTED_SKIPS is correctly EMPTY: this
# suite has no dependency-gated group, so every skip fails the run.
#
# NO FROZEN DENOMINATOR. No count in this file is asserted against a literal. Every
# population is derived when it is graded and printed with its derivation rule. The three
# enumerations this guard HOLDS rather than derives — the publish invocation forms, the
# dispatch arms, and the declared read-only key set — each carry a live membership-delta
# sentinel that diffs them AS A SET, because a count holds while membership churns.
#
# NOTE: publish-trip-site.sh is deliberately NOT sourced. This suite needs zero functions
# from it, and sourcing a security-critical script to parse a markdown table would create
# shared fate — a syntax error there would make the TAXONOMY invariant unverifiable for a
# reason with nothing to do with taxonomy.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SELF="${BASH_SOURCE[0]}"
set +e

pass=0; fail=0; skip=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
SURF_LOG="$WORK/.surfaced"; ARM_LOG="$WORK/.armed"
: > "$SURF_LOG"; : > "$ARM_LOG"

BT='`'
EMDASH='—'
Q="$(printf '\047')"

# ── Held enumerations. Each is DECLARED, not derived, and each carries a live sentinel.
# The reason vocabulary, closed at five values, shared by CLAUDE.md Step-1 and ADR-007 §4.
# An ARRAY compared literally, never a regex: one value carries a non-ASCII section sign
# AND an internal space, and another opens with '#'. Reason lists are split on the literal
# ' + ' separator and NEVER by shell word-splitting.
REASON_ENUM=( 'ADR-007 §2' '#330-disclosure' 'repo-creation' 'argv-secret' 'lightest-weight-action' )

# The invocation forms of scripts/publish-trip-site.sh. Held deliberately: reading them
# from the §4 table would assert a table against itself, and re-deriving flag combinations
# from bash source is a parser project. The sentinel below keeps the holding honest.
EXPECTED_FORMS=(
  'list' 'update' 'unpublish --disable-pages-only'
  'publish' 'publish --opaque' 'publish --plaintext' 'publish --plaintext --opaque'
  'rotate' 'rotate --passphrase' 'unpublish'
)

# main()'s dispatch arms, excluding the '*)' catch-all. Diffed as a SET in both
# directions: an arm added AND an arm removed is a membership change a count would miss.
EXPECTED_ARMS=( 'publish' 'update' 'rotate' 'list|status' 'unpublish' '-h|--help|help|""' )

# Subcommand tokens a delivered command file may invoke.
ALLOWED_SUBS=( 'list' 'status' 'update' 'unpublish' )

# The DECLARED read-only key set, and the verb set of its command as adjudicated when the
# set was last decided. There is no live predicate for "reads and does not write" on this
# surface: the read declaration is a total body-line convention while the write one is
# not, so the set cannot yet be derived. It is therefore declared, and the sentinel makes
# it DETECTED-stale rather than silently stale. What re-arms it is a `**Writes:**`
# body-line contract mirroring the read one; at that point the set becomes derived and
# this holding is deleted rather than maintained.
#
# The LITERAL reading of "carries no write instruction" is NOT asserted. One read-only
# region NAMES both output paths it must not write, inside an explicit negation. A
# path-mention test red-lights that section, which is the exact defect the use-not-mention
# rule exists to prevent. The path test is declined rather than weakened into one that
# passes.
READONLY_KEYS=( '/trip:status' '/trip:check' )
READONLY_OF_COMMAND='/trip'
READONLY_ADJUDICATED=( 'status' 'plan' 'replan' 'reorder' 'research' 'check' 'ideas' 'site' )

SCRIPT_REL='scripts/publish-trip-site.sh'

# ── The needle registry. Every literal this parser holds is asserted to round-trip its
# own normalisation — norm(needle) == needle — before it is used. A needle that fails and
# is not registered UNTRIMMED is a build error, not a runtime one, because a needle that
# does not survive the normalisation applied to the haystack cannot match what it names.
# The HAYSTACK is whitespace-collapsed where a scan needs it; the NEEDLE never is.
NEEDLES=( '### Step 1:' '### Step 2:' '**Reads:**' 'trip-contract-header'
          'population-role:' 'main()' 'allowed-tools:' 'disallowed-tools:' )
NEEDLES_UNTRIMMED=( 'EXCLUDED: ' '## ' '### 4. ' )

# ── The five column names of the requirement table, fixed by the charter's G7. These are
# NAMES, not a rendering: the anchor matches them trimmed, backtick-stripped and
# case-folded, so a re-spacing of the header row does not unhook the locator.
REQ_COLS=( verb lifecycle mode destination depth )

# ─────────────────────────────────────────────────────────────────────────────────
# Small helpers
# ─────────────────────────────────────────────────────────────────────────────────
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
collapse() { printf '%s' "$1" | tr -s '[:space:]' ' '; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

in_list() { local n="$1"; shift; local e; for e in "$@"; do [ "$e" = "$n" ] && return 0; done; return 1; }

is_sep() { [[ "$1" =~ ^\|[-:[:space:]|]+\|[[:space:]]*$ ]]; }

getcount() { printf '%s\n' "$1" | sed -n "s/^COUNT $2 //p" | head -1; }
has_finding() { printf '%s\n' "$1" | grep -qE "^FINDING ($2) "; }
show()     { printf '%s\n' "$1" | grep -E "^FINDING ($2) " | sed 's/^FINDING /       /' | head -8; }

# Records which ids a reporting group surfaces, so group Y can assert the mapping is
# total. Returns the alternation for has_finding, so a group cannot surface an id without
# registering it — the registration and the test are the same call. It writes to a FILE
# rather than a variable because every call site is a command substitution, and a
# subshell's variable assignment never reaches the parent.
surface() { local a="" i; for i in "$@"; do printf '%s\n' "$i" >> "$SURF_LOG"; a="${a:+$a|}$i"; done; printf '%s' "$a"; }

# Records which ids a control arm exercises.
arm() { printf '%s\n' "$1" >> "$ARM_LOG"; }

# ── The cell grammar, widened with the ALTERNATION form rather than the minimal one.
# A leading '.' is part of an IDENTITY — the verb is selected by exact string equality
# against a token that begins with a dot, so a cell spelling it without the dot would be
# a false row. A leading '--' is a SPELLING VARIANT the key rule normalises away. The two
# can never co-occur, so the grammar must not be able to express both at once: the
# minimal form `(--)?\.?token` admits the junk cell `--.x`, and a control arm shows it.
CMD_RE='trip(-[a-z0-9]+)*'
VERB_RE='(--[a-z0-9]+(-[a-z0-9]+)*|\.?[a-z0-9]+(-[a-z0-9]+)*)'
CELL_RE="^${BT}/${CMD_RE}( ${VERB_RE})?${BT}$"
CELL_RE_MINIMAL="^${BT}/${CMD_RE}( (--)?\.?[a-z0-9]+(-[a-z0-9]+)*)?${BT}$"
CELL_RE_UNWIDENED="^${BT}/${CMD_RE}( (--)?[a-z0-9]+(-[a-z0-9]+)*)?${BT}$"
# N1, unchanged, re-pointed at the COMMAND component. The regex does not widen; its input
# does.
N1_RE="^${CMD_RE}$"

# Is this row the requirement table's own header row? Structural, on the five column
# names — never on a fence, and never on one byte rendering of the row.
is_req_header() {
  local row="$1" i got
  local -a F=()
  # A pure-glob fast path. It is a cheap pre-filter, never the test: a header row must
  # name the first column, so a row that cannot contain it is rejected without forking.
  case "$row" in *[vV][eE][rR][bB]*) ;; *) return 1 ;; esac
  IFS='|' read -r -a F <<< "$row"
  [ "${#F[@]}" -eq 6 ] || return 1
  for i in 1 2 3 4 5; do
    got="$(trim "${F[$i]}")"; got="${got//$BT/}"; got="$(lower "$got")"
    [ "$got" = "${REQ_COLS[$((i-1))]}" ] || return 1
  done
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────
# needle_check — norm(needle) == needle for every needle this parser holds, and the
# registered exceptions matched as untrimmed prefixes. Three consecutive stages of this
# milestone caught real failures on this one assertion, so it runs before any read.
# ─────────────────────────────────────────────────────────────────────────────────
needle_check() {
  local rc=0 n c
  for n in "${NEEDLES[@]}"; do
    c="$(trim "$(collapse "$n")")"
    if [ "$c" != "$n" ]; then
      printf 'FINDING N1 needle does not round-trip its own normalisation and is not registered UNTRIMMED: "%s" -> "%s"\n' "$n" "$c"; rc=1
    fi
  done
  for n in "${NEEDLES_UNTRIMMED[@]}"; do
    c="$(trim "$(collapse "$n")")"
    if [ "$c" = "$n" ]; then
      printf 'FINDING N1 needle is registered UNTRIMMED but round-trips cleanly — the registration is stale: "%s"\n' "$n"; rc=1
    fi
  done
  printf 'COUNT NEEDLES %d\n' "$(( ${#NEEDLES[@]} + ${#NEEDLES_UNTRIMMED[@]} ))"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# parse_command_file <path> <command-name> <role>
#
# The section parser. Emits one record per line and NEVER joins records into a
# space-delimited string: the retired transport joined names with `tr` and tested
# membership against an UNQUOTED haystack, which fails in BOTH directions once a key can
# carry a space — a bare token spuriously MATCHES, and a two-token name never does.
#
# Rules, each with the observation that forces it:
#   1. Fence state is computed before anything else is read.
#   2. The declared set comes from the table located by its OWN HEADER ROW at fence depth
#      0, unique per file. Not "the first table", not a whole-file line scan, and NOT the
#      contract-header fence — see the banner, rule 1.
#   3. Identity is field 1 with a trailing parenthetical dropped, and the drop is asserted
#      value-preserving: where there is no parenthetical the identity must be
#      byte-identical to the raw cell.
#   4. The section is matched on the heading's FIRST whitespace-delimited token. The
#      whole-heading matcher is run in the same pass and its result must be a SUBSET; a
#      heading the whole-heading matcher finds and the first-token matcher misses means
#      the split lost a member, and is a hard failure.
#   5. A region runs from its heading to the next depth-0 `## `, or EOF. Subsections
#      belong to the region.
#   6. `**Reads:**` is matched at COLUMN 0 and at fence depth 0 — see the banner, rule 2.
#   7. A file whose declared role is CREATE takes the body after the contract-header block
#      as its single verb's implementing region. The role is read from the charter's
#      consumer table, LIVE, so the carve-out moves when the charter moves; it is never a
#      filename test.
# ─────────────────────────────────────────────────────────────────────────────────
parse_command_file() {
  local f="$1" cmd="$2" role="$3"
  local rc=0 short="${cmd#/}"

  if [ ! -f "$f" ]; then
    printf 'FINDING A0 command file is unreadable: %s\n' "$cmd"
    return 1
  fi

  local line fd=0 n=0
  local -a L=() FD=()
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n+1))
    L+=( "$line" )
    if [[ "$line" == '```'* ]]; then FD+=( 1 ); fd=$((1-fd)); else FD+=( "$fd" ); fi
  done < "$f"

  # --- the contract-header block, located by its fence info string. This is a PARSER
  # PRECONDITION, not a restatement of the contract guard's invariant: without a unique
  # header block the CREATE-role region has no start and cannot be computed.
  local i hdr_open=-1 hdr_close=-1 hdr_n=0
  for (( i=0; i<n; i++ )); do
    if [ "${L[$i]}" = '```trip-contract-header' ]; then
      hdr_n=$((hdr_n+1)); [ "$hdr_open" -lt 0 ] && hdr_open=$i
    fi
  done
  if [ "$hdr_n" -ne 1 ]; then
    printf 'FINDING V5 %s carries %d contract-header blocks, expected exactly 1 — the CREATE-role region cannot be computed without one\n' "$cmd" "$hdr_n"; rc=1
  else
    for (( i=hdr_open+1; i<n; i++ )); do
      if [[ "${L[$i]}" == '```'* ]]; then hdr_close=$i; break; fi
    done
  fi

  # --- the requirement table, anchored on its own header row at fence depth 0 ---
  local anchor=-1 anchor_n=0
  for (( i=0; i<n; i++ )); do
    [ "${FD[$i]}" -eq 0 ] || continue
    [[ "${L[$i]}" == '|'* ]] || continue
    if is_req_header "${L[$i]}"; then
      anchor_n=$((anchor_n+1)); [ "$anchor" -lt 0 ] && anchor=$i
    fi
  done
  if [ "$anchor_n" -ne 1 ]; then
    printf 'FINDING V0 %s carries %d requirement-table header rows at fence depth 0, expected exactly 1 — the declared verb set has no unambiguous anchor\n' "$cmd" "$anchor_n"
    printf 'COUNT DECL_%s 0\n' "$short"
    return 1
  fi

  # --- rows: from the anchor's separator to the first non-pipe line ---
  local -a DECL=() DECLRAW=()
  local j=$((anchor+1)) nrows=0
  if [ "$j" -lt "$n" ] && is_sep "${L[$j]}"; then j=$((j+1)); fi
  local -a F=()
  local raw ident paren prev k dupok
  while [ "$j" -lt "$n" ] && [[ "${L[$j]}" == '|'* ]]; do
    nrows=$((nrows+1))
    IFS='|' read -r -a F <<< "${L[$j]}"
    if [ "${#F[@]}" -ne 6 ]; then
      printf 'FINDING V1 %s requirement-table row %d has %d pipe fields, expected 6 (5 columns): %.60s\n' "$cmd" "$nrows" "${#F[@]}" "${L[$j]}"; rc=1; j=$((j+1)); continue
    fi
    raw="$(trim "${F[1]}")"
    paren=""
    ident="$raw"
    if [[ "$raw" == *'('* ]]; then
      ident="$(trim "${raw%%(*}")"
      paren="$(trim "${raw#*(}")"
    fi
    if [ -z "$paren" ] && [ "$ident" != "$raw" ]; then
      printf 'FINDING V6 %s the parenthetical drop altered a verb identity that carried no parenthetical: "%s" -> "%s"\n' "$cmd" "$raw" "$ident"; rc=1
    fi
    if [ -z "$ident" ]; then
      printf 'FINDING V1 %s requirement-table row %d declares an empty verb identity\n' "$cmd" "$nrows"; rc=1; j=$((j+1)); continue
    fi
    if [[ "$ident" == *' '* ]] || [[ "$ident" == *"$(printf '\t')"* ]]; then
      printf 'FINDING X2 %s verb identity carries whitespace, which the key channel cannot transport: "%s"\n' "$cmd" "$ident"; rc=1; j=$((j+1)); continue
    fi
    if in_list "$ident" "${DECL[@]+"${DECL[@]}"}"; then
      # admitted only when every row sharing the identity carries a distinct non-empty
      # parenthetical — two dispositions of one verb
      dupok=1
      [ -n "$paren" ] || dupok=0
      for (( k=0; k<${#DECLRAW[@]}; k++ )); do
        prev="${DECLRAW[$k]}"
        case "$prev" in
          "$ident"|"$ident "*|"$ident("*)
            [ "$prev" != "$raw" ] || dupok=0
            [[ "$prev" == *'('* ]] || dupok=0
            ;;
        esac
      done
      if [ "$dupok" -eq 0 ]; then
        printf 'FINDING V2 %s declares the verb identity "%s" twice without distinct non-empty parentheticals\n' "$cmd" "$ident"; rc=1
      fi
      DECLRAW+=( "$raw" )
      j=$((j+1)); continue
    fi
    DECL+=( "$ident" ); DECLRAW+=( "$raw" )
    # the key, emitted alongside its recomputable parts so the consumer can prove the
    # channel carried the VALUE and not merely the right number of records
    printf 'DECL %s %s\n' "$cmd" "$ident"
    printf 'KEY %s:%s\n' "$cmd" "$ident"
    j=$((j+1))
  done

  if [ "$nrows" -eq 0 ]; then
    printf 'FINDING V0 %s requirement table carries no data rows — the declared set would be empty\n' "$cmd"; rc=1
  fi

  # --- depth-0 `## ` sections ---
  local -a SH=() SS=() SE=()
  for (( i=0; i<n; i++ )); do
    [ "${FD[$i]}" -eq 0 ] || continue
    [[ "${L[$i]}" == '## '* ]] || continue
    SH+=( "$(trim "${L[$i]#\#\# }")" ); SS+=( "$i" )
  done
  local ns=${#SH[@]}
  for (( i=0; i<ns; i++ )); do
    if [ $((i+1)) -lt "$ns" ]; then SE+=( "${SS[$((i+1))]}" ); else SE+=( "$n" ); fi
  done

  # --- regions: first-token match, with the whole-heading matcher run alongside ---
  local -a RV=() RS=() RE_=()
  local first whole ft_n=0 wh_n=0 v
  for (( i=0; i<ns; i++ )); do
    first="${SH[$i]%% *}"
    whole="${SH[$i]}"
    if in_list "$first" "${DECL[@]+"${DECL[@]}"}"; then
      ft_n=$((ft_n+1))
      RV+=( "$first" ); RS+=( "${SS[$i]}" ); RE_+=( "${SE[$i]}" )
      printf 'REGION %s %s %d %d\n' "$cmd" "$first" "${SS[$i]}" "${SE[$i]}"
    fi
    if in_list "$whole" "${DECL[@]+"${DECL[@]}"}"; then
      wh_n=$((wh_n+1))
      if ! in_list "$whole" "${RV[@]+"${RV[@]}"}"; then
        printf 'FINDING V6 %s the first-token split LOST a heading the whole-heading matcher resolves: "%s" — the split is not membership-preserving\n' "$cmd" "$whole"; rc=1
      fi
    fi
  done
  printf 'COUNT FT_%s %d\n' "$short" "$ft_n"
  printf 'COUNT WH_%s %d\n' "$short" "$wh_n"

  # --- the CREATE carve-out: the body after the header block is the single verb's region
  if [ "$role" = 'CREATE' ] && [ "$hdr_close" -ge 0 ]; then
    if [ "${#DECL[@]}" -eq 1 ]; then
      if [ "$ft_n" -eq 0 ]; then
        RV+=( "${DECL[0]}" ); RS+=( "$hdr_close" ); RE_+=( "$n" )
        printf 'REGION %s %s %d %d\n' "$cmd" "${DECL[0]}" "$hdr_close" "$n"
      fi
    elif [ "${#DECL[@]}" -gt 1 ]; then
      printf 'FINDING V3 %s declares a CREATE population-role and %d distinct verb identities — the body region cannot be assigned to more than one\n' "$cmd" "${#DECL[@]}"; rc=1
    fi
  fi

  # --- V3: exactly one region per declared verb ---
  local cnt
  for v in "${DECL[@]+"${DECL[@]}"}"; do
    cnt=0
    for (( i=0; i<${#RV[@]}; i++ )); do [ "${RV[$i]}" = "$v" ] && cnt=$((cnt+1)); done
    if [ "$cnt" -eq 0 ]; then
      printf 'FINDING V3 %s declares the verb "%s" and implements no region for it\n' "$cmd" "$v"; rc=1
    elif [ "$cnt" -gt 1 ]; then
      printf 'FINDING V3 %s implements %d regions for the verb "%s" — the invocation limb would have no region to attribute to\n' "$cmd" "$cnt" "$v"; rc=1
    fi
  done

  # --- V4: a COLUMN-0, fence-depth-0 `**Reads:**` line outside every declared region ---
  local owner reads_n=0 unclaimed_n=0
  for (( i=0; i<n; i++ )); do
    [ "${FD[$i]}" -eq 0 ] || continue
    [[ "${L[$i]}" == '**Reads:**'* ]] || continue
    reads_n=$((reads_n+1))
    owner=''
    for (( j=0; j<${#RV[@]}; j++ )); do
      if [ "$i" -gt "${RS[$j]}" ] && [ "$i" -lt "${RE_[$j]}" ]; then owner="${RV[$j]}"; break; fi
    done
    if [ -z "$owner" ]; then
      unclaimed_n=$((unclaimed_n+1))
      printf 'FINDING V4 %s:%d a read declaration sits outside every declared verb region — implemented but undeclared\n' "$cmd" $((i+1)); rc=1
    fi
  done
  printf 'COUNT READS_%s %d\n' "$short" "$reads_n"
  printf 'COUNT UNCLAIMED_%s %d\n' "$short" "$unclaimed_n"

  # --- invocation and pre-execution records, attributed to the containing region ---
  local t
  for (( i=0; i<n; i++ )); do
    owner='-'
    for (( j=0; j<${#RV[@]}; j++ )); do
      if [ "$i" -gt "${RS[$j]}" ] && [ "$i" -lt "${RE_[$j]}" ]; then owner="${RV[$j]}"; break; fi
    done
    if [ "${FD[$i]}" -eq 0 ] && [[ "${L[$i]}" == '!'"$BT"* ]]; then
      printf 'BANG %s %s %d\n' "$cmd" "$owner" $((i+1))
    fi
    [ "${FD[$i]}" -eq 1 ] || continue
    t="$(trim "${L[$i]}")"; t="${t#\$ }"; t="${t#./}"
    if [ "$t" = "$SCRIPT_REL" ] || [[ "$t" == "$SCRIPT_REL "* ]]; then
      printf 'INV %s %s %d %s\n' "$cmd" "$owner" $((i+1)) "$(trim "${t#"$SCRIPT_REL"}")"
    fi
  done

  printf 'COUNT DECL_%s %d\n' "$short" "${#DECL[@]}"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# fence_scoped_declared <path> — the DESIGN-TIME locator this guard replaced. Kept
# solely as a live differential control (arm G-D1): it reads the declared verb set from
# INSIDE the contract-header fence.
# ─────────────────────────────────────────────────────────────────────────────────
fence_scoped_declared() {
  local f="$1" line inb=0 n=0
  [ -f "$f" ] || { printf '0'; return; }
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = '```trip-contract-header' ]; then inb=1; continue; fi
    if [ "$inb" -eq 1 ] && [[ "$line" == '```'* ]]; then inb=0; continue; fi
    [ "$inb" -eq 1 ] || continue
    [[ "$line" == '|'* ]] || continue
    is_sep "$line" && continue
    is_req_header "$line" && continue
    n=$((n+1))
  done < "$f"
  printf '%d' "$n"
}

# ─────────────────────────────────────────────────────────────────────────────────
# trimfirst_reads <path> — the trim-first matcher this guard replaced. Kept solely as a
# live differential control (arm G-D2).
# ─────────────────────────────────────────────────────────────────────────────────
trimfirst_reads() {
  local f="$1" line n=0 t
  [ -f "$f" ] || { printf '0'; return; }
  while IFS= read -r line || [ -n "$line" ]; do
    t="$(trim "$line")"
    [[ "$t" == '**Reads:**'* ]] && n=$((n+1))
  done < "$f"
  printf '%d' "$n"
}

# ─────────────────────────────────────────────────────────────────────────────────
# charter_check <claude_md_path>
#
# Step 1's cell population, Step 2's key enumeration, and the consumer table's declared
# population-role. Extraction is BOLD-AGNOSTIC and FIELD-INDEXED, both load-bearing: a
# matcher tuned on a bolded first cell reads a non-bolded table as zero rows and is
# silently dead, and a row-wide match counts a command code span that sits in a different
# column. Only field 5 is the Command cell.
# ─────────────────────────────────────────────────────────────────────────────────
charter_check() {
  local md="$1"
  local rc=0
  if [ ! -f "$md" ]; then
    printf 'FINDING A0 the charter path does not exist\n'
    printf 'COUNT S1_ROWS 0\nCOUNT S1_ADDR 0\nCOUNT S1_EXCL 0\nCOUNT S2_KEYS 0\nCOUNT CONS_ROWS 0\nCOUNT DOTTED 0\nCOUNT UNWIDENED_FAIL 0\n'
    return 1
  fi

  local line in1=0 in2=0 sep1=0 sep2=0 incons=0
  local -a R1=() R2=() CONS=()
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in1" -eq 1 ] && [[ "$line" == '### '* ]]; then in1=0; fi
    if [ "$in2" -eq 1 ] && [[ "$line" == '### '* ]]; then in2=0; fi
    if [ "$incons" -eq 1 ] && [[ "$line" == '## '* ]]; then incons=0; fi
    if [[ "$line" == '### Step 1:'* ]]; then in1=1; sep1=0; continue; fi
    if [[ "$line" == '### Step 2:'* ]]; then in2=1; sep2=0; continue; fi
    if [[ "$line" == '### Resolving a trip'* ]]; then incons=1; continue; fi
    if [ "$in1" -eq 1 ] && [[ "$line" == '|'* ]]; then
      if is_sep "$line"; then sep1=1; continue; fi
      [ "$sep1" -eq 1 ] && R1+=( "$line" )
    fi
    if [ "$in2" -eq 1 ] && [[ "$line" == '|'* ]]; then
      if is_sep "$line"; then sep2=1; continue; fi
      [ "$sep2" -eq 1 ] && R2+=( "$line" )
    fi
    if [ "$incons" -eq 1 ] && [[ "$line" == '| '"$BT"'/'* ]]; then CONS+=( "$line" ); fi
  done < "$md"

  local n_rows=${#R1[@]} n_addr=0 n_excl=0 n_dot=0 n_unwid=0
  if [ "$n_rows" -eq 0 ]; then
    printf 'FINDING A0 the Step-1 slice is empty or absent — no data rows extracted\n'; rc=1
  fi

  local row cell inner rt cmdpart verbpart key rest r
  local -a F=() SEEN=()
  for row in "${R1[@]+"${R1[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    if [ "${#F[@]}" -ne 6 ]; then
      printf 'FINDING B1 MALFORMED Step-1 row — expected 5 columns (6 pipe fields), got %d: %.60s\n' "${#F[@]}" "$row"; rc=1; continue
    fi
    cell="$(trim "${F[5]}")"

    if [[ "$cell" == 'EXCLUDED: '* ]]; then
      n_excl=$((n_excl+1))
      rest="$(trim "${cell#EXCLUDED: }")"
      if [ -z "$rest" ]; then
        printf 'FINDING B2 EXCLUDED cell carries no reason: %.60s\n' "$row"; rc=1; continue
      fi
      SEEN=()
      while [ -n "$rest" ]; do
        if [[ "$rest" == *' + '* ]]; then r="${rest%% + *}"; rest="${rest#* + }"; else r="$rest"; rest=""; fi
        r="$(trim "$r")"
        if ! in_list "$r" "${REASON_ENUM[@]}"; then
          printf 'FINDING B2 reason not in the closed five-value enum: "%s"\n' "$r"; rc=1
        fi
        if in_list "$r" "${SEEN[@]+"${SEEN[@]}"}"; then
          printf 'FINDING B2 duplicate reason within one cell: "%s"\n' "$r"; rc=1
        fi
        SEEN+=( "$r" )
      done
      continue
    fi

    if [[ "$cell" == 'EXCLUDED'* ]]; then
      printf 'FINDING B1 MALFORMED Command cell — exclusion marker malformed, expected the marker then a colon and a space: "%s"\n' "$cell"; rc=1; continue
    fi
    if [[ "$cell" != "$BT"* ]]; then
      printf 'FINDING B1 MALFORMED Command cell — neither a code span nor an exclusion marker: "%s"\n' "$cell"; rc=1; continue
    fi

    n_addr=$((n_addr+1))
    inner="${cell//$BT/}"
    rt="${BT}${inner}${BT}"
    if [ "$rt" != "$cell" ]; then
      printf 'FINDING V6 the code-span strip did not round-trip — the matched VALUE changed while the row count did not: "%s" -> "%s"\n' "$cell" "$rt"; rc=1
      continue
    fi

    cmdpart="${inner%% *}"; cmdpart="${cmdpart#/}"
    if [ "$inner" = "${inner%% *}" ]; then verbpart=""; else verbpart="${inner#* }"; fi

    if ! [[ "$cell" =~ $CELL_RE ]]; then
      if ! [[ "$cmdpart" =~ $N1_RE ]]; then
        printf 'FINDING B5 ADDRESSED cell command component fails N1: "%s"\n' "$cell"; rc=1
      else
        printf 'FINDING B3 ADDRESSED cell fails the widened cell grammar: "%s"\n' "$cell"; rc=1
      fi
      continue
    fi
    [[ "$cell" =~ $CELL_RE_UNWIDENED ]] || n_unwid=$((n_unwid+1))
    case "$verbpart" in .*) n_dot=$((n_dot+1)) ;; esac

    if [ -n "$verbpart" ]; then key="/${cmdpart}:${verbpart}"; else key="/${cmdpart}"; fi
    if [[ "$key" == *' '* ]]; then
      printf 'FINDING X2 a Step-1 key carries whitespace: "%s"\n' "$key"; rc=1; continue
    fi
    printf 'ADDRKEY %s\n' "$key"
    printf 'ADDRPARTS %s %s\n' "/${cmdpart}" "${verbpart:--}"
  done

  if [ $((n_addr + n_excl)) -ne "$n_rows" ]; then
    printf 'FINDING B4 exhaustiveness — %d ADDRESSED + %d EXCLUDED does not account for %d rows; a row reached neither classification\n' "$n_addr" "$n_excl" "$n_rows"; rc=1
  fi

  # --- Step 2: the second enumeration of the same set, in the same file ---
  local cur s n_s2=0
  for row in "${R2[@]+"${R2[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    [ "${#F[@]}" -ge 2 ] || continue
    cur=""
    rest="${F[1]}"
    while [[ "$rest" == *"$BT"*"$BT"* ]]; do
      rest="${rest#*"$BT"}"
      s="${rest%%"$BT"*}"
      rest="${rest#*"$BT"}"
      s="$(trim "$s")"
      [ -n "$s" ] || continue
      if [[ "$s" == /* ]]; then
        cur="${s%% *}"
        if [ "$s" = "${s%% *}" ]; then printf 'S2KEY %s\n' "$cur"; else printf 'S2KEY %s:%s\n' "$cur" "${s#* }"; fi
        n_s2=$((n_s2+1))
      else
        [ -n "$cur" ] || continue
        printf 'S2KEY %s:%s\n' "$cur" "$s"
        n_s2=$((n_s2+1))
      fi
    done
  done

  # --- the consumer table's declared population-role, read LIVE ---
  local n_cons=0
  for row in "${CONS[@]+"${CONS[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    [ "${#F[@]}" -ge 4 ] || continue
    cell="$(trim "${F[1]}")"; inner="${cell//$BT/}"; cmdpart="${inner%% *}"
    rest="$(trim "${F[3]}")"; rest="${rest//$BT/}"
    [ -n "$cmdpart" ] || continue
    case "$rest" in RESOLVE|CREATE) ;; *) continue ;; esac
    printf 'ROLE %s %s\n' "$cmdpart" "$rest"
    n_cons=$((n_cons+1))
  done

  printf 'COUNT S1_ROWS %d\n' "$n_rows"
  printf 'COUNT S1_ADDR %d\n' "$n_addr"
  printf 'COUNT S1_EXCL %d\n' "$n_excl"
  printf 'COUNT S2_KEYS %d\n' "$n_s2"
  printf 'COUNT CONS_ROWS %d\n' "$n_cons"
  printf 'COUNT DOTTED %d\n' "$n_dot"
  printf 'COUNT UNWIDENED_FAIL %d\n' "$n_unwid"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# coverage_check <records>
#
# K1/K2/K3 over a RECORD STREAM. Taking the stream as an argument is what lets a control
# arm drive this function with a synthetic stream and reach the key-channel ids, without
# a debug env var and without a fixture that could not occur on a real surface.
# ─────────────────────────────────────────────────────────────────────────────────
coverage_check() {
  local recs="$1"
  local rc=0 line t1 t2 t3 t4
  local -a DK=() DKC=() FILES=() AK=() AKC=() AKV=() RG=() KEYS=()

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'DECL '*)      IFS=' ' read -r t1 t2 t3 <<< "$line"; DK+=( "$t2:$t3" ); DKC+=( "$t2" ) ;;
      'KEY '*)       IFS=' ' read -r t1 t2 <<< "$line"; KEYS+=( "$t2" ) ;;
      'FILE '*)      IFS=' ' read -r t1 t2 <<< "$line"; FILES+=( "$t2" ) ;;
      'REGION '*)    IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; RG+=( "$t2:$t3" ) ;;
      'ADDRPARTS '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; AKC+=( "$t2" ); AKV+=( "$t3" )
                     if [ "$t3" = '-' ]; then AK+=( "$t2" ); else AK+=( "$t2:$t3" ); fi ;;
    esac
  done <<< "$recs"

  # --- X1/X2: the key channel, asserted BEFORE anything reads the enumeration ---
  local i k
  if [ "${#KEYS[@]}" -ne "${#DK[@]}" ]; then
    printf 'FINDING X1 the record channel carries %d keys for %d declarations — a key was lost or invented in transport\n' "${#KEYS[@]}" "${#DK[@]}"; rc=1
  fi
  for (( i=0; i<${#DK[@]} && i<${#KEYS[@]}; i++ )); do
    if [ "${KEYS[$i]}" != "${DK[$i]}" ]; then
      printf 'FINDING X1 an emitted key did not round-trip byte-identical: emitted "%s", recomputed "%s". The COUNT is unchanged; the VALUE is not\n' "${KEYS[$i]}" "${DK[$i]}"; rc=1
    fi
  done
  for k in "${KEYS[@]+"${KEYS[@]}"}"; do
    if [ -z "$k" ] || [[ "$k" == *' '* ]]; then
      printf 'FINDING X2 a key is empty or carries whitespace, which the membership test cannot transport: "%s"\n' "$k"; rc=1
    fi
  done

  # --- coverage units ---
  local -a UNITS=()
  local f has
  for f in "${FILES[@]+"${FILES[@]}"}"; do
    has=0
    for (( i=0; i<${#DKC[@]}; i++ )); do [ "${DKC[$i]}" = "$f" ] && has=1; done
    if [ "$has" -eq 0 ]; then UNITS+=( "$f" ); fi
  done
  for k in "${DK[@]+"${DK[@]}"}"; do UNITS+=( "$k" ); done
  printf 'COUNT UNITS %d\n' "${#UNITS[@]}"

  if [ "${#UNITS[@]}" -eq 0 ]; then
    printf 'FINDING A0 the coverage-unit enumeration is EMPTY — every direction of K would be vacuously true\n'; rc=1
  fi

  # --- K1 ---
  local ncov u
  for (( i=0; i<${#AK[@]}; i++ )); do
    ncov=0
    if [ "${AKV[$i]}" = '-' ]; then
      for u in "${UNITS[@]+"${UNITS[@]}"}"; do
        case "$u" in "${AKC[$i]}"|"${AKC[$i]}":*) ncov=$((ncov+1)) ;; esac
      done
      if [ "$ncov" -eq 0 ]; then
        printf 'FINDING K1 the verbless ADDRESSED cell %s covers no unit — no command file of that name declares anything and none exists\n' "${AKC[$i]}"; rc=1
      fi
    else
      for u in "${UNITS[@]+"${UNITS[@]}"}"; do [ "$u" = "${AK[$i]}" ] && ncov=$((ncov+1)); done
      if [ "$ncov" -eq 0 ]; then
        printf 'FINDING K1 the ADDRESSED cell %s covers nothing that resolves — no requirement table declares that verb of that command\n' "${AK[$i]}"; rc=1
      elif ! in_list "${AK[$i]}" "${RG[@]+"${RG[@]}"}"; then
        printf 'FINDING K1 the ADDRESSED cell %s is declared but its command file implements no region for it\n' "${AK[$i]}"; rc=1
      fi
    fi
  done

  # --- K2 / K3 over the unit population ---
  local dbl=0
  for u in "${UNITS[@]+"${UNITS[@]}"}"; do
    ncov=0
    for (( i=0; i<${#AK[@]}; i++ )); do
      if [ "${AKV[$i]}" = '-' ]; then
        case "$u" in "${AKC[$i]}"|"${AKC[$i]}":*) ncov=$((ncov+1)) ;; esac
      else
        [ "$u" = "${AK[$i]}" ] && ncov=$((ncov+1))
      fi
    done
    if [ "$ncov" -eq 0 ]; then
      printf 'FINDING K2 TOTALITY — the coverage unit %s is covered by no ADDRESSED Step-1 cell\n' "$u"; rc=1
    elif [ "$ncov" -gt 1 ]; then
      printf 'FINDING K3 EXCLUSIVITY — the coverage unit %s is covered by %d ADDRESSED cells\n' "$u" "$ncov"; rc=1
      dbl=$((dbl+1))
    fi
  done

  # --- K3, second limb: verbless and verbed are mutually exclusive per command ---
  local c nvl nvb j
  local -a SEENC=()
  for (( i=0; i<${#AKC[@]}; i++ )); do
    c="${AKC[$i]}"
    in_list "$c" "${SEENC[@]+"${SEENC[@]}"}" && continue
    SEENC+=( "$c" )
    nvl=0; nvb=0
    for (( j=0; j<${#AKC[@]}; j++ )); do
      [ "${AKC[$j]}" = "$c" ] || continue
      if [ "${AKV[$j]}" = '-' ]; then nvl=$((nvl+1)); else nvb=$((nvb+1)); fi
    done
    if [ "$nvl" -gt 0 ] && [ "$nvb" -gt 0 ]; then
      printf 'FINDING K3 EXCLUSIVITY — %s carries both a verbless and a verbed ADDRESSED cell\n' "$c"; rc=1
    fi
    if [ "$nvl" -gt 1 ]; then
      printf 'FINDING K3 EXCLUSIVITY — %s carries %d verbless ADDRESSED cells\n' "$c" "$nvl"; rc=1
    fi
  done

  printf 'COUNT ADDRCELLS %d\n' "${#AK[@]}"
  printf 'COUNT DBLCOVER %d\n' "$dbl"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# enum_agree_check <records>
#
# The charter holds TWO enumerations of the same verb set in one file: Step 1's ADDRESSED
# cells and Step 2's per-verb pointer rows. They agree today by one authoring pass, and
# nothing checks it. This limb compares them as a SET DIFFERENCE IN BOTH DIRECTIONS,
# reported separately, over a population this guard already derives.
#
# NON-VACUITY IS THE POINT. A limb added while two sets already match starts green, so
# its pass proves nothing on its own: it first asserts that MORE THAN ONE enumeration was
# derived and that each is non-empty, and reports SINGLE-SOURCE rather than agreement
# when it finds only one. Two empty sets differing by nothing is not agreement.
# ─────────────────────────────────────────────────────────────────────────────────
enum_agree_check() {
  local recs="$1"
  local rc=0 line k n=0 t1 t2
  local -a E1=() E2=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'ADDRKEY '*) IFS=' ' read -r t1 t2 <<< "$line"; E1+=( "$t2" ) ;;
      'S2KEY '*)   IFS=' ' read -r t1 t2 <<< "$line"; E2+=( "$t2" ) ;;
    esac
  done <<< "$recs"

  [ "${#E1[@]}" -gt 0 ] && n=$((n+1))
  [ "${#E2[@]}" -gt 0 ] && n=$((n+1))
  if [ "$n" -lt 2 ]; then
    printf 'FINDING S2 SINGLE-SOURCE — %d non-empty verb-set enumeration(s) derived from the charter; agreement between enumerations is not established by finding one\n' "$n"
    printf 'COUNT ENUMS %d\nCOUNT E1 %d\nCOUNT E2 %d\n' "$n" "${#E1[@]}" "${#E2[@]}"
    return 1
  fi

  for k in "${E1[@]}"; do
    in_list "$k" "${E2[@]}" || { printf 'FINDING S1 the key %s is an ADDRESSED Step-1 cell and appears in no Step-2 row\n' "$k"; rc=1; }
  done
  for k in "${E2[@]}"; do
    in_list "$k" "${E1[@]}" || { printf 'FINDING S1 the key %s appears in a Step-2 row and is no ADDRESSED Step-1 cell\n' "$k"; rc=1; }
  done

  printf 'COUNT ENUMS %d\nCOUNT E1 %d\nCOUNT E2 %d\n' "$n" "${#E1[@]}" "${#E2[@]}"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# adr4_check <adr_path> <script_path> <records>
#
# Completeness over the held invocation forms, the main() dispatch-arm staleness
# sentinel, and the cross-surface link — with NO hardcoded command map. Each §4 Command
# cell is parsed with the SAME cell grammar as Step 1, and each key must be BOTH a live
# surface key AND an ADDRESSED Step-1 key. The check therefore re-arms itself when the
# column is re-pointed, instead of freezing an answer that has already gone stale once.
#
# The two surfaces render reasons differently — §4 code-spans them, Step 1 renders them
# plain — so backticks are stripped before the enum comparison and one enum serves both.
# ─────────────────────────────────────────────────────────────────────────────────
adr4_check() {
  local adr="$1" script="$2" recs="$3"
  local rc=0 line t1 t2 t3
  local -a SURFK=() S1K=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'DECL '*)    IFS=' ' read -r t1 t2 t3 <<< "$line"; SURFK+=( "$t2:$t3" ) ;;
      'FILE '*)    IFS=' ' read -r t1 t2 <<< "$line"; SURFK+=( "$t2" ) ;;
      'ADDRKEY '*) IFS=' ' read -r t1 t2 <<< "$line"; S1K+=( "$t2" ) ;;
    esac
  done <<< "$recs"

  if [ ! -f "$adr" ]; then
    printf 'FINDING E1 the ADR path does not exist\n'
    printf 'COUNT ADR4_ROWS 0\nCOUNT ADR4_ADDR 0\nCOUNT ARMS 0\nCOUNT XLINK 0\n'
    return 1
  fi

  local in_slice=0 seen_sep=0
  local -a ROWS=()
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_slice" -eq 1 ] && [[ "$line" == '#'* ]]; then in_slice=0; fi
    if [[ "$line" == '### 4. '* ]]; then in_slice=1; seen_sep=0; continue; fi
    [ "$in_slice" -eq 1 ] || continue
    [[ "$line" == '|'* ]] || continue
    if is_sep "$line"; then seen_sep=1; continue; fi
    [ "$seen_sep" -eq 1 ] || continue
    ROWS+=( "$line" )
  done < "$adr"

  local n_rows=${#ROWS[@]}
  if [ "$n_rows" -eq 0 ]; then
    printf 'FINDING E1 the ADR-007 §4 disposition table is absent or unparseable\n'; rc=1
  fi

  local -a FOUND=() ADDRF=() ADDRK=() F=()
  local row form disp reasons cellc inner r rest i
  for row in "${ROWS[@]+"${ROWS[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    if [ "${#F[@]}" -ne 6 ]; then
      printf 'FINDING E1 MALFORMED §4 row — expected 5 columns, got %d: %.50s\n' "${#F[@]}" "$row"; rc=1; continue
    fi
    form="$(trim "${F[2]}")"; form="${form%%(*}"; form="${form//$BT/}"; form="$(trim "$form")"
    disp="$(trim "${F[3]}")"
    reasons="$(trim "${F[4]}")"
    cellc="$(trim "${F[5]}")"
    FOUND+=( "$form" )

    case "$disp" in
      ADDRESSED)
        if ! [[ "$cellc" =~ $CELL_RE ]]; then
          printf 'FINDING E8 §4 ADDRESSED Command cell fails the cell grammar: "%s" (form: %s)\n' "$cellc" "$form"; rc=1; continue
        fi
        inner="${cellc//$BT/}"
        if [ "$inner" = "${inner%% *}" ]; then r="$inner"; else r="${inner%% *}:${inner#* }"; fi
        ADDRF+=( "$form" ); ADDRK+=( "$r" )
        ;;
      EXCLUDED)
        if [ -z "$reasons" ] || [ "$reasons" = "$EMDASH" ]; then
          printf 'FINDING E2 §4 EXCLUDED form carries no reason: %s\n' "$form"; rc=1
        else
          rest="${reasons//$BT/}"
          while [ -n "$rest" ]; do
            if [[ "$rest" == *' + '* ]]; then r="${rest%% + *}"; rest="${rest#* + }"; else r="$rest"; rest=""; fi
            r="$(trim "$r")"
            in_list "$r" "${REASON_ENUM[@]}" || { printf 'FINDING E2 §4 reason not in the closed five-value enum: "%s" (form: %s)\n' "$r" "$form"; rc=1; }
          done
        fi
        if [ "$cellc" != "$EMDASH" ]; then
          printf 'FINDING E4 §4 EXCLUDED form names a command (%s) — an excluded form must be addressed by none: %s\n' "$cellc" "$form"; rc=1
        fi
        ;;
      *)
        printf 'FINDING E1 §4 disposition is neither of the two permitted values: "%s" (form: %s)\n' "$disp" "$form"; rc=1
        ;;
    esac
  done

  local e
  for e in "${EXPECTED_FORMS[@]}"; do
    in_list "$e" "${FOUND[@]+"${FOUND[@]}"}" || { printf 'FINDING E3 §4 does not disposition the invocation form: %s\n' "$e"; rc=1; }
  done
  for e in "${FOUND[@]+"${FOUND[@]}"}"; do
    in_list "$e" "${EXPECTED_FORMS[@]}" || { printf 'FINDING E3 §4 dispositions an unrecognised form: %s\n' "$e"; rc=1; }
  done

  local -a ARMS=()
  if [ ! -f "$script" ]; then
    printf 'FINDING E5 the publish script is unreadable, so the dispatch-arm sentinel cannot run\n'; rc=1
  else
    local in_main=0 in_case=0 pat t
    while IFS= read -r line || [ -n "$line" ]; do
      [[ "$line" == 'main()'* ]] && { in_main=1; continue; }
      [ "$in_main" -eq 1 ] || continue
      t="$(trim "$line")"
      [[ "$t" == 'case '* ]] && { in_case=1; continue; }
      [[ "$t" == 'esac'* ]] && { in_case=0; in_main=0; continue; }
      [ "$in_case" -eq 1 ] || continue
      [[ "$t" == *')'* ]] || continue
      pat="$(trim "${t%%)*}")"
      [ "$pat" = '*' ] && continue
      [ -n "$pat" ] || continue
      ARMS+=( "$pat" )
    done < "$script"
    for e in "${ARMS[@]+"${ARMS[@]}"}"; do
      in_list "$e" "${EXPECTED_ARMS[@]}" || { printf 'FINDING E6 STALENESS SENTINEL — unrecognised main() dispatch arm "%s". Required action: re-derive the invocation forms, update the held form and arm sets in this guard, and disposition the new form in ADR-007 §4.\n' "$e"; rc=1; }
    done
    for e in "${EXPECTED_ARMS[@]}"; do
      in_list "$e" "${ARMS[@]+"${ARMS[@]}"}" || { printf 'FINDING E6 STALENESS SENTINEL — the held main() dispatch arm "%s" is gone. Required action: re-derive the invocation forms, update the held form and arm sets in this guard, and disposition the change in ADR-007 §4.\n' "$e"; rc=1; }
    done
  fi

  local n_link=0 k
  for (( i=0; i<${#ADDRK[@]}; i++ )); do
    k="${ADDRK[$i]}"
    if ! in_list "$k" "${SURFK[@]+"${SURFK[@]}"}"; then
      printf 'FINDING E7 §4 ADDRESSED form %s names %s, which is not a key of the live command surface\n' "${ADDRF[$i]}" "$k"; rc=1; continue
    fi
    if ! in_list "$k" "${S1K[@]+"${S1K[@]}"}"; then
      printf 'FINDING E7 §4 ADDRESSED form %s names %s, which is a live surface key but no ADDRESSED Step-1 cell\n' "${ADDRF[$i]}" "$k"; rc=1; continue
    fi
    n_link=$((n_link+1))
  done

  printf 'COUNT ADR4_ROWS %d\n' "$n_rows"
  printf 'COUNT ADR4_ADDR %d\n' "${#ADDRF[@]}"
  printf 'COUNT ARMS %d\n' "${#ARMS[@]}"
  printf 'COUNT XLINK %d\n' "$n_link"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# invocation_check <commands_dir> <records>
#
# Classifies EVERY mention of the publish script into exactly one class and asserts the
# classification is TOTAL. A mention falling into none — the script reached through a
# variable, an alias or a heredoc — is a FAIL, not a skip.
#
# WHY CLASSIFY RATHER THAN TOKEN-SEARCH. A bare-token search over this population
# RED-LIGHTS CORRECT CODE, and the predictable repair under time pressure is to weaken
# the check until it passes — which is how a guard becomes a document. The classes:
#
#   INVOCATION  the line sits INSIDE a fence and BEGINS with the script path
#   TOOL-GRANT  the mention is enclosed in a Bash(...) grant token — on a frontmatter
#               grant line, OR rendered as a code span in a grant-inventory table. This
#               class is defined by the GRANT TOKEN and not by the frontmatter region,
#               because the delivered surface renders grant tokens in body tables and a
#               frontmatter-only rule reports those as unresolved
#   PROSE       the path appears inside a markdown code span in body text
#
# The banned tokens are tested by USE, not by MENTION: the plaintext override fails on
# ASSIGNMENT or export, never on a mention, because the delivered files name it inside
# NEGATED declarations; and the argv flags fail as tokens ON AN INVOCATION LINE, because
# a flat substring ban on a two-character flag matches a correct argument-hint.
#
# ATTRIBUTION. Every invocation is attributed to the region containing it and every
# finding names (command, verb). An invocation that resolves to no region is reported as
# F6 and counted — that count is the measure that must fall to zero.
# ─────────────────────────────────────────────────────────────────────────────────
invocation_check() {
  local cdir="$1" recs="$2"
  local rc=0
  local n_men=0 n_inv=0 n_grant=0 n_prose=0 n_unc=0 n_orphan=0

  if [ ! -d "$cdir" ]; then
    printf 'FINDING A0 the commands directory does not exist\n'
    printf 'COUNT MENTIONS 0\nCOUNT INVOCATIONS 0\nCOUNT GRANTS 0\nCOUNT PROSE 0\nCOUNT UNCLASS 0\nCOUNT ORPHANINV 0\n'
    return 1
  fi

  local line t1 t2 t3 t4
  local -a IL=() IO=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'INV '*) IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; IL+=( "$t2:$t4" ); IO+=( "$t3" ) ;;
    esac
  done <<< "$recs"

  local f base cmd fd lno t bare rest sub tok found=0 i owner
  local -a ARGV=()
  for f in "$cdir"/*.md; do
    [ -e "$f" ] || continue
    found=1
    base="$(basename "$f" .md)"; cmd="/$base"
    lno=0; fd=0
    while IFS= read -r line || [ -n "$line" ]; do
      lno=$((lno+1))
      if [[ "$line" == '```'* ]]; then fd=$((1-fd)); fi
      t="$(trim "$line")"

      if [[ "$line" =~ (^|[^A-Za-z0-9_])ALLOW_PLAINTEXT[[:space:]]*= ]] || [[ "$line" =~ export[[:space:]]+ALLOW_PLAINTEXT ]]; then
        printf 'FINDING F4 %s:%d SETS the plaintext override — ADR-007 §2 forbids it in any command file\n' "$cmd" "$lno"; rc=1
      fi

      case "$line" in *"$SCRIPT_REL"*) ;; *) continue ;; esac
      n_men=$((n_men+1))

      if [[ "$line" == *"Bash($SCRIPT_REL"* ]]; then n_grant=$((n_grant+1)); continue; fi
      if [[ "$t" == 'allowed-tools:'* ]] || [[ "$t" == 'disallowed-tools:'* ]]; then n_grant=$((n_grant+1)); continue; fi

      bare="$t"; bare="${bare#\$ }"; bare="${bare#./}"
      if [ "$fd" -eq 1 ] && { [ "$bare" = "$SCRIPT_REL" ] || [[ "$bare" == "$SCRIPT_REL "* ]]; }; then
        n_inv=$((n_inv+1))
        rest="$(trim "${bare#"$SCRIPT_REL"}")"
        owner='-'
        for (( i=0; i<${#IL[@]}; i++ )); do
          [ "${IL[$i]}" = "$cmd:$lno" ] && owner="${IO[$i]}"
        done
        if [ "$owner" = '-' ]; then
          n_orphan=$((n_orphan+1))
          printf 'FINDING F6 %s:%d a fenced invocation resolves to no declared verb region, so a finding on it could name only the FILE and not a (command, verb) pair\n' "$cmd" "$lno"; rc=1
        fi
        IFS=' ' read -r -a ARGV <<< "$rest"
        sub=""
        for tok in "${ARGV[@]+"${ARGV[@]}"}"; do
          case "$tok" in -*) continue ;; '') continue ;; *) sub="$tok"; break ;; esac
        done
        if [ -z "$sub" ]; then
          printf 'FINDING F1 (%s, %s) at line %d invokes the publish script with no subcommand token\n' "$cmd" "$owner" "$lno"; rc=1
        elif ! in_list "$sub" "${ALLOWED_SUBS[@]}"; then
          printf 'FINDING F1 (%s, %s) at line %d invokes the EXCLUDED form "%s" — ADR-007 §4 dispositions it EXCLUDED\n' "$cmd" "$owner" "$lno" "$sub"; rc=1
        elif [ "$sub" = 'unpublish' ] && [[ "$rest" != *'--disable-pages-only'* ]]; then
          printf 'FINDING F2 (%s, %s) at line %d invokes unpublish WITHOUT the pages-only flag on the same invocation — that is the repo-delete form, which is EXCLUDED\n' "$cmd" "$owner" "$lno"; rc=1
        fi
        for tok in "${ARGV[@]+"${ARGV[@]}"}"; do
          case "$tok" in
            '--plaintext'|'--passphrase'|'--yes'|'-y')
              printf 'FINDING F3 (%s, %s) at line %d passes the forbidden flag %s on a publish-script invocation\n' "$cmd" "$owner" "$lno" "$tok"; rc=1 ;;
          esac
        done
        continue
      fi

      if [[ "$line" == *"${BT}${SCRIPT_REL}${BT}"* ]] || [[ "$line" == *"${BT}${SCRIPT_REL} "* ]]; then
        n_prose=$((n_prose+1)); continue
      fi

      n_unc=$((n_unc+1))
      printf 'FINDING F5 PARSE COVERAGE — %s:%d mentions the publish script in a shape this guard cannot resolve (variable, alias or heredoc?). An unresolved mention is a failure, not a skip\n' "$cmd" "$lno"; rc=1
    done < "$f"
  done

  if [ "$found" -eq 0 ]; then
    printf 'FINDING A0 the commands directory holds no .md files\n'; rc=1
  fi
  if [ $((n_inv + n_grant + n_prose + n_unc)) -ne "$n_men" ]; then
    printf 'FINDING F5 PARSE COVERAGE — %d mentions found but %d classified\n' "$n_men" "$((n_inv+n_grant+n_prose+n_unc))"; rc=1
  fi

  printf 'COUNT MENTIONS %d\n' "$n_men"
  printf 'COUNT INVOCATIONS %d\n' "$n_inv"
  printf 'COUNT GRANTS %d\n' "$n_grant"
  printf 'COUNT PROSE %d\n' "$n_prose"
  printf 'COUNT UNCLASS %d\n' "$n_unc"
  printf 'COUNT ORPHANINV %d\n' "$n_orphan"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# readonly_check <records> <key...> -- <adjudicated-verb...>
# ─────────────────────────────────────────────────────────────────────────────────
readonly_check() {
  local recs="$1"; shift
  local -a KEYS=() ADJ=()
  local seendash=0 a
  for a in "$@"; do
    if [ "$a" = '--' ]; then seendash=1; continue; fi
    if [ "$seendash" -eq 0 ]; then KEYS+=( "$a" ); else ADJ+=( "$a" ); fi
  done

  local rc=0 line k v t1 t2 t3
  local -a INVK=() BANGK=() LIVE=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'INV '*)  IFS=' ' read -r t1 t2 t3 <<< "$line"; [ "$t3" != '-' ] && INVK+=( "$t2:$t3" ) ;;
      'BANG '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; [ "$t3" != '-' ] && BANGK+=( "$t2:$t3" ) ;;
      'DECL '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; [ "$t2" = "$READONLY_OF_COMMAND" ] && LIVE+=( "$t3" ) ;;
    esac
  done <<< "$recs"

  for k in "${KEYS[@]+"${KEYS[@]}"}"; do
    if in_list "$k" "${INVK[@]+"${INVK[@]}"}"; then
      printf 'FINDING R1 the declared read-only key %s carries a fenced invocation line in its own region\n' "$k"; rc=1
    fi
    if in_list "$k" "${BANGK[@]+"${BANGK[@]}"}"; then
      printf 'FINDING R1 the declared read-only key %s carries a pre-execution block in its own region\n' "$k"; rc=1
    fi
  done

  for v in "${LIVE[@]+"${LIVE[@]}"}"; do
    in_list "$v" "${ADJ[@]+"${ADJ[@]}"}" || { printf 'FINDING R2 MEMBERSHIP-DELTA SENTINEL — %s declares the verb "%s", which was not present when the read-only set was adjudicated. Required action: re-adjudicate the read-only set.\n' "$READONLY_OF_COMMAND" "$v"; rc=1; }
  done
  for v in "${ADJ[@]+"${ADJ[@]}"}"; do
    in_list "$v" "${LIVE[@]+"${LIVE[@]}"}" || { printf 'FINDING R2 MEMBERSHIP-DELTA SENTINEL — the verb "%s" was present when the read-only set was adjudicated and %s no longer declares it. Required action: re-adjudicate the read-only set.\n' "$v" "$READONLY_OF_COMMAND"; rc=1; }
  done

  printf 'COUNT ROKEYS %d\n' "${#KEYS[@]}"
  printf 'COUNT ROLIVE %d\n' "${#LIVE[@]}"
  return "$rc"
}

# ═════════════════════════════════════════════════════════════════════════════════
# The fixture world. DATA, not code: one generator emits a tree from a table of tuples,
# so a change to the surface's shape changes the tuples and not the generator. Fixtures
# are BUILT, never patched: a delimiter collision or a newline difference in a patch
# produces a fixture that does not carry the defect it claims.
#
# The conforming tree deliberately carries every shape a naive matcher trips on:
#   - an argument-signature heading            (whole-heading matching loses it)
#   - a leading-dot verb                       (the un-widened grammar rejects it)
#   - a parenthetical-annotated disposition pair
#   - a CREATE-role file with no verb section  (the carve-out)
#   - a fenced example holding a verb-shaped heading and a read-declaration line
#   - a negating sentence naming a forbidden flag, INSIDE a verb region
#   - a decoy command code span in the Action column of an excluded row
#   - four-space-indented read-declaration exemplars in a NON-VERB section
#   - a Bash(<script> <sub>:*) grant token rendered as a code span in a body table
#   - a requirement table rendered OUTSIDE the contract-header fence
# ═════════════════════════════════════════════════════════════════════════════════

# Tuple format: <name>|<role>|<verb spec>,<verb spec>,...
# verb spec: <ident>[~<heading suffix>][%<paren>][+inv]
WORLD_OK=(
  'trip|RESOLVE|status,check'
  'trip-record|RESOLVE|profile~<name>,.publish-slug~<name>,log'
  'trip-publish|RESOLVE|update+inv,list+inv'
  'trip-new|CREATE|new%create,new%resume'
)
WORLD_MUT=(
  'trip|RESOLVE|status,checkx'
  'trip-record|RESOLVE|profile~<name>,.publish-slug~<name>,log'
  'trip-publish|RESOLVE|update+inv,list+inv'
  'trip-new|CREATE|new%create,new%resume'
)

gen_cmd() {  # gen_cmd <dir> <tuple> <defect>
  local d="$1" tup="$2" defect="${3:-}"
  local name="${tup%%|*}"; local restt="${tup#*|}"
  local role="${restt%%|*}"; local vspec="${restt#*|}"
  local f="$d/commands/$name.md"
  mkdir -p "$d/commands"
  local -a IDS=() HEADS=() PARENS=() INVS=()
  local v head paren inv i n
  local IFSSAVE="$IFS"
  IFS=','
  local -a VS=( $vspec )
  IFS="$IFSSAVE"
  for v in "${VS[@]}"; do
    inv=0
    case "$v" in *'+inv') inv=1; v="${v%+inv}" ;; esac
    paren=""
    case "$v" in *'%'*) paren="${v#*%}"; v="${v%%[%]*}" ;; esac
    head=""
    case "$v" in *'~'*) head=" ${v#*~}"; v="${v%%[~]*}" ;; esac
    IDS+=( "$v" ); HEADS+=( "$head" ); PARENS+=( "$paren" ); INVS+=( "$inv" )
  done
  n=${#IDS[@]}

  {
    printf -- '---\ndescription: fixture %s\n' "$name"
    printf -- 'allowed-tools: Bash(ls:*), Bash(%s update:*)\n' "$SCRIPT_REL"
    printf -- 'disallowed-tools: [Bash(%s publish:*)]\n' "$SCRIPT_REL"
    printf -- '---\n\n# /%s\n\n' "$name"
    printf -- '## Trips in this repo\n\n!%sls -1 trips%s\n\n' "$BT" "$BT"
    printf -- '| Grant | The use that holds it |\n|---|---|\n'
    printf -- '| %sBash(%s update:*)%s | the single invocation |\n\n' "$BT" "$SCRIPT_REL" "$BT"
    if [ "$defect" != 'noheader' ]; then
      printf -- '## Contract header\n\n```trip-contract-header\nContract: charter\ncontract-depth: G8\npopulation-role: %s\n```\n\n' "$role"
    fi
    if [ "$defect" = 'twoheader' ]; then
      printf -- '```trip-contract-header\nContract: charter\n```\n\n'
    fi
    if [ "$defect" != 'notable' ]; then
      printf -- '| verb | lifecycle | mode | destination | depth |\n|---|---|---|---|---|\n'
      for (( i=0; i<n; i++ )); do
        if [ -n "${PARENS[$i]}" ]; then
          printf -- '| %s (%s) | ACTIVE | any | any | G8 |\n' "${IDS[$i]}" "${PARENS[$i]}"
        else
          printf -- '| %s | ACTIVE | any | any | G8 |\n' "${IDS[$i]}"
        fi
      done
      if [ "$defect" = 'badrow' ]; then printf -- '| broken | ACTIVE | any |\n'; fi
      if [ "$defect" = 'dupident' ]; then printf -- '| %s | ACTIVE | any | any | G8 |\n' "${IDS[0]}"; fi
      printf -- '\n'
    fi
    if [ "$defect" = 'twotables' ]; then
      printf -- '| verb | lifecycle | mode | destination | depth |\n|---|---|---|---|---|\n| other | ACTIVE | any | any | G8 |\n\n'
    fi
    printf -- '## What the blocks above are\n\nEach verb section opens with a read declaration, in this rendering:\n\n'
    printf -- '    **Reads:** %s<path>%s — what it is read for.\n\n' "$BT" "$BT"
    printf -- 'and, for a verb that reads nothing of its own:\n\n'
    printf -- '    **Reads:** nothing beyond the blocks above.\n\n'
    if [ "$defect" = 'strayreads' ]; then printf -- '**Reads:** something undeclared.\n\n'; fi
    printf -- '## Selecting the verb\n\nAn example of what a section looks like:\n\n```\n## ghostverb\n**Reads:** an example read line.\n```\n\n'
    for (( i=0; i<n; i++ )); do
      if [ "$role" = 'CREATE' ]; then continue; fi
      if [ "$defect" = 'nosection' ] && [ "$i" -eq 0 ]; then continue; fi
      printf -- '## %s%s\n\n' "${IDS[$i]}" "${HEADS[$i]}"
      printf -- '**Reads:** nothing beyond the blocks above.\n\n'
      printf -- 'This region never passes %s--yes%s and never sets ALLOW_PLAINTEXT; it mentions %s%s%s and does not run it.\n\n' "$BT" "$BT" "$BT" "$SCRIPT_REL" "$BT"
      if [ "${INVS[$i]}" -eq 1 ]; then
        case "$defect" in
          rotate)      printf -- '```\n%s rotate trips/x\n```\n\n' "$SCRIPT_REL" ;;
          nounpubflag) printf -- '```\n%s unpublish trips/x\n```\n\n' "$SCRIPT_REL" ;;
          badflag)     printf -- '```\n%s update trips/x --passphrase secret\n```\n\n' "$SCRIPT_REL" ;;
          *)           printf -- '```\n%s update trips/x\n```\n\n' "$SCRIPT_REL" ;;
        esac
      fi
      if [ "$defect" = 'twosections' ] && [ "$i" -eq 0 ]; then
        printf -- '## %s <other>\n\n**Reads:** nothing.\n\n' "${IDS[$i]}"
      fi
    done
    if [ "$role" = 'CREATE' ]; then
      printf -- '## Create\n\nThe body of this file is the region.\n\n'
      printf -- '**Reads:** the template it copies from.\n\n'
    fi
    if [ "$defect" = 'orphaninv' ]; then printf -- '## Not a verb\n\n```\n%s update trips/x\n```\n\n' "$SCRIPT_REL"; fi
    if [ "$defect" = 'allowplain' ]; then printf -- '```\nALLOW_PLAINTEXT=1 x\n```\n\n'; fi
    if [ "$defect" = 'varmention' ]; then printf -- 'SCRIPT=%s\n\n' "$SCRIPT_REL"; fi
  } > "$f"
}

gen_charter() {  # gen_charter <dir> <defect>
  local d="$1" defect="${2:-}"
  mkdir -p "$d"
  local -a KEYS=( '/trip status' '/trip check' '/trip-record profile' '/trip-record .publish-slug' '/trip-record log' '/trip-publish update' '/trip-publish list' '/trip-new' )
  if [ "$defect" = 'mut' ]; then
    KEYS=( '/trip status' '/trip checkx' '/trip-record profile' '/trip-record .publish-slug' '/trip-record log' '/trip-publish update' '/trip-publish list' '/trip-new' )
  fi
  local k
  {
    if [ "$defect" = 'nostep1' ]; then printf '### Some other heading\n\n'
    else printf '### Step 1: Classify the request\n\n'; fi
    printf '| Type | Signal | Action | Example | Command |\n'
    printf '|------|--------|--------|---------|---------|\n'
    printf '| Direct edit | sig | act, and see %s/trip status%s for the current state | ex | EXCLUDED: lightest-weight-action |\n' "$BT" "$BT"
    for k in "${KEYS[@]}"; do
      if [ "$defect" = 'uncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
      printf '| %s | sig | act | ex | %s%s%s |\n' "$k" "$BT" "$k" "$BT"
    done
    if [ "$defect" = 'badcell' ];    then printf '| X | sig | act | ex | neither |\n'; fi
    if [ "$defect" = 'offenum' ];    then printf '| X | sig | act | ex | EXCLUDED: because I said so |\n'; fi
    if [ "$defect" = 'dupreason' ];  then printf '| X | sig | act | ex | EXCLUDED: repo-creation + repo-creation |\n'; fi
    if [ "$defect" = 'badgrammar' ]; then printf '| X | sig | act | ex | %s/trip --.x%s |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'badn1' ];      then printf '| X | sig | act | ex | %s/Trip status%s |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'badspan' ];    then printf '| X | sig | act | ex | %s/trip st%satus%s |\n' "$BT" "$BT" "$BT"; fi
    if [ "$defect" = 'ghostkey' ];   then printf '| X | sig | act | ex | %s/trip nosuchverb%s |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'dblcover' ];   then printf '| X | sig | act | ex | %s/trip%s |\n' "$BT" "$BT"; fi
    printf '\n'
    if [ "$defect" != 'nostep2' ]; then
      printf '### Step 2: Read context (scaled to the request)\n\n'
      printf '| Request | Read scope | Class |\n|---|---|---|\n'
      for k in "${KEYS[@]}"; do
        if [ "$defect" = 'uncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
        if [ "$defect" = 'step2drift' ] && [ "$k" = '/trip-record log' ]; then continue; fi
        printf '| %s%s%s | that verb%ss own read line | own |\n' "$BT" "$k" "$BT" "$Q"
      done
      printf '| Direct edit | just the file being edited | own |\n\n'
    fi
    printf '### Resolving a trip\n\n'
    printf '| Command | depth | role | Prefix | Note |\n|---|---|---|---|---|\n'
    printf '| %s/trip-new%s | %sG2%s | %sCREATE%s | %sE1%s | |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT"
    printf '| %s/trip <verb>%s | %sG8%s | %sRESOLVE%s | %sE1 E2%s | |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT"
    printf '| %s/trip-record%s | %sG8%s | %sRESOLVE%s | %sE1 E2%s | |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT"
    printf '| %s/trip-publish%s | %sG8%s | %sRESOLVE%s | %sE1 E2%s | |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$BT"
    printf '\n'
    printf '```\n%s publish trips/x\n%s rotate trips/x\n```\n\n' "$SCRIPT_REL" "$SCRIPT_REL"
    printf '## Next\n'
  } > "$d/CLAUDE.md"
}

gen_adr() {  # gen_adr <dir> <defect>
  local d="$1" defect="${2:-}"
  mkdir -p "$d"
  {
    printf '### 4. The publish lifecycle\n\n'
    printf '| # | Invocation form | Disposition | Reasons | Command |\n|---|---|---|---|---|\n'
    if [ "$defect" = 'deadkey' ]; then
      printf '| 1 | %slist%s | ADDRESSED | %s | %s/trip-publish nosuch%s |\n' "$BT" "$BT" "$EMDASH" "$BT" "$BT"
    elif [ "$defect" = 'badcmdcell' ]; then
      printf '| 1 | %slist%s | ADDRESSED | %s | %s/Trip-Publish list%s |\n' "$BT" "$BT" "$EMDASH" "$BT" "$BT"
    else
      printf '| 1 | %slist%s (alias %sstatus%s) | ADDRESSED | %s | %s/trip-publish list%s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH" "$BT" "$BT"
    fi
    printf '| 2 | %supdate%s | ADDRESSED | %s | %s/trip-publish update%s |\n' "$BT" "$BT" "$EMDASH" "$BT" "$BT"
    if [ "$defect" = 'exclnamescmd' ]; then
      printf '| 3 | %sunpublish --disable-pages-only%s | EXCLUDED | %srepo-creation%s | %s/trip-publish update%s |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT"
    else
      printf '| 3 | %sunpublish --disable-pages-only%s | ADDRESSED | %s | %s/trip-publish update%s |\n' "$BT" "$BT" "$EMDASH" "$BT" "$BT"
    fi
    if [ "$defect" = 'noreason' ]; then
      printf '| 4 | %spublish%s | EXCLUDED | %s | %s |\n' "$BT" "$BT" "$EMDASH" "$EMDASH"
    else
      printf '| 4 | %spublish%s | EXCLUDED | %s#330-disclosure%s + %srepo-creation%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    fi
    printf '| 5 | %spublish --opaque%s | EXCLUDED | %s#330-disclosure%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    printf '| 6 | %spublish --plaintext%s | EXCLUDED | %sADR-007 §2%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    if [ "$defect" != 'omitform' ]; then
      printf '| 7 | %spublish --plaintext --opaque%s | EXCLUDED | %sADR-007 §2%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    fi
    printf '| 8 | %srotate%s | EXCLUDED | %s#330-disclosure%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    printf '| 9 | %srotate --passphrase%s | EXCLUDED | %s#330-disclosure%s + %sargv-secret%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    if [ "$defect" = 'badrow' ]; then
      printf '| 10 | %sunpublish%s | EXCLUDED |\n' "$BT" "$BT"
    else
      printf '| 10 | %sunpublish%s (delete) | EXCLUDED | %sADR-007 §2%s | %s |\n' "$BT" "$BT" "$BT" "$BT" "$EMDASH"
    fi
    printf '\n## Consequences\n'
  } > "$d/ADR.md"
}

gen_script() {  # gen_script <path> [extra-arm]
  local p="$1" extra="${2:-}"
  {
    printf 'main() {\n  local sub="${1:-}"; shift || true\n  case "$sub" in\n'
    printf '    publish)     cmd_publish   "$@" ;;\n'
    printf '    update)      cmd_update    "$@" ;;\n'
    printf '    rotate)      cmd_rotate    "$@" ;;\n'
    printf '    list|status) cmd_list      "$@" ;;\n'
    printf '    unpublish)   cmd_unpublish "$@" ;;\n'
    if [ -n "$extra" ]; then printf '    %s)   cmd_%s "$@" ;;\n' "$extra" "$extra"; fi
    printf '    -h|--help|help|"") usage 0 ;;\n'
    printf '    *) die "unknown subcommand" ;;\n  esac\n}\n'
  } > "$p"
}

gen_tree() {  # gen_tree <dir> <charter-defect> <cmd-defect> [world...]
  local d="$1" cdd="$2" mdd="$3"; shift 3
  local -a W=( "$@" )
  if [ "${#W[@]}" -eq 0 ]; then W=( "${WORLD_OK[@]}" ); fi
  mkdir -p "$d/commands"
  gen_charter "$d" "$cdd"
  if [ "$mdd" = 'nocmds' ]; then return 0; fi
  local t
  for t in "${W[@]}"; do gen_cmd "$d" "$t" "$mdd"; done
}

# run_tree <dir> — drives the whole checker chain over a fixture tree and prints the
# concatenated record/finding stream. Used by every control arm.
run_tree() {
  local d="$1"
  local recs="" f base cmd role l2 croll
  croll="$(charter_check "$d/CLAUDE.md")"
  recs="$croll"
  for f in "$d/commands"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"; cmd="/$base"
    role='RESOLVE'
    while IFS= read -r l2; do
      case "$l2" in "ROLE $cmd "*) role="${l2##* }" ;; esac
    done <<< "$croll"
    recs="$recs
FILE $cmd
$(parse_command_file "$f" "$cmd" "$role")"
  done
  recs="$recs
$(coverage_check "$recs")
$(enum_agree_check "$recs")
$(invocation_check "$d/commands" "$recs")"
  printf '%s\n' "$recs"
}

# ═════════════════════════════════════════════════════════════════════════════════
# Groups N–S — the real tree
# ═════════════════════════════════════════════════════════════════════════════════
MD="$ROOT/CLAUDE.md"
CDIR="$ROOT/.claude/commands"
ADR="$ROOT/reference/adr/ADR-007-command-entry-point.md"
PUB="$ROOT/$SCRIPT_REL"

tree_state() {
  local p
  for p in "$MD" "$ADR" "$PUB" "$SELF"; do [ -f "$p" ] && cksum < "$p"; done
  for p in "$CDIR"/*.md; do [ -e "$p" ] && { printf '%s ' "$(basename "$p")"; cksum < "$p"; }; done
}
STATE_BEFORE="$(tree_state)"

echo
echo "── Group N — needle integrity. norm(needle) == needle, asserted before any read."
N_OUT="$(needle_check)"
if has_finding "$N_OUT" "$(surface N1)"; then FAIL "N1: a needle does not survive the normalisation applied to the haystack"; show "$N_OUT" 'N1'
else PASS "N1: all $(getcount "$N_OUT" NEEDLES) needles round-trip, or are registered UNTRIMMED and matched as prefixes (the haystack is collapsed; the needle never is)"; fi

CH_OUT="$(charter_check "$MD")"
S1_ROWS="$(getcount "$CH_OUT" S1_ROWS)"; S1_ADDR="$(getcount "$CH_OUT" S1_ADDR)"
S1_EXCL="$(getcount "$CH_OUT" S1_EXCL)"
DOTTED="$(getcount "$CH_OUT" DOTTED)"; UNWID="$(getcount "$CH_OUT" UNWIDENED_FAIL)"

RECS="$CH_OUT"
NFILES=0
for gf in "$CDIR"/*.md; do
  [ -e "$gf" ] || continue
  NFILES=$((NFILES+1))
  gbase="$(basename "$gf" .md)"; gcmd="/$gbase"
  grole='RESOLVE'
  while IFS= read -r gl; do
    case "$gl" in "ROLE $gcmd "*) grole="${gl##* }" ;; esac
  done <<< "$CH_OUT"
  RECS="$RECS
FILE $gcmd
$(parse_command_file "$gf" "$gcmd" "$grole")"
done

COV_OUT="$(coverage_check "$RECS")"
ENUM_OUT="$(enum_agree_check "$RECS")"
E_OUT="$(adr4_check "$ADR" "$PUB" "$RECS")"
F_OUT="$(invocation_check "$CDIR" "$RECS")"
R_OUT="$(readonly_check "$RECS" "${READONLY_KEYS[@]}" -- "${READONLY_ADJUDICATED[@]}")"
ALL="$RECS
$COV_OUT
$ENUM_OUT
$E_OUT
$F_OUT
$R_OUT"

echo
echo "── Group A — populations non-empty. FAIL, never SKIP."
if has_finding "$ALL" "$(surface A0)"; then FAIL "A1: a population or surface is empty"; show "$ALL" 'A0'
else PASS "A1: Step-1 slice ${S1_ROWS} rows; command directory ${NFILES} files; coverage-unit enumeration $(getcount "$COV_OUT" UNITS) units — each derived, each non-empty, none skipped"; fi

echo
echo "── Group V — the per-file bijection: declaration <-> implementation."
if has_finding "$ALL" "$(surface V0 V5)"; then FAIL "V1: a file's requirement table or contract-header block has no unambiguous anchor"; show "$ALL" 'V0|V5'
else PASS "V1: every command file yields exactly one requirement-table header row at fence depth 0, and exactly one contract-header block"; fi
if has_finding "$ALL" "$(surface V1 V2)"; then FAIL "V2: a requirement-table row is malformed, or a verb identity collides"; show "$ALL" 'V1|V2'
else PASS "V2: every requirement-table row parses at 5 columns; a shared identity carries distinct non-empty parentheticals"; fi
if has_finding "$ALL" "$(surface V3)"; then FAIL "V3: a declared verb has no implementing region, or more than one"; show "$ALL" 'V3'
else PASS "V3: every declared verb resolves to exactly one implementing region (first-token match at fence depth 0, or the charter-declared CREATE body)"; fi
if has_finding "$ALL" "$(surface V4)"; then FAIL "V4: a read declaration sits outside every declared verb region"; show "$ALL" 'V4'
else PASS "V4: every column-0 read declaration sits inside a declared verb's region — implemented-but-undeclared is empty"; fi
if has_finding "$ALL" "$(surface V6)"; then FAIL "V5: a value transformation did not round-trip"; show "$ALL" 'V6'
else PASS "V5: the parenthetical drop, the code-span strip and the first-token split are all VALUE-preserving, not merely count-preserving"; fi

echo
echo "── Group B — Step-1 cell shape, reason enum, exhaustiveness."
if has_finding "$ALL" "$(surface B1)"; then FAIL "B1: a Step-1 Command cell is malformed"; show "$ALL" 'B1'
else PASS "B1: no malformed Command cell across ${S1_ROWS} rows"; fi
if has_finding "$ALL" "$(surface B2)"; then FAIL "B2: a reason is off-enum, absent or duplicated"; show "$ALL" 'B2'
else PASS "B2: every reason on all ${S1_EXCL} EXCLUDED cells is in the closed five-value enum, none duplicated"; fi
if has_finding "$ALL" "$(surface B3 B5)"; then FAIL "B3: an ADDRESSED cell fails the widened cell grammar or N1"; show "$ALL" 'B3|B5'
else PASS "B3: all ${S1_ADDR} ADDRESSED cells match the widened (alternation) cell grammar, command component under N1"; fi
if has_finding "$ALL" "$(surface B4)"; then FAIL "B4: exhaustiveness broken"; show "$ALL" 'B4'
else PASS "B4: ${S1_ADDR} ADDRESSED + ${S1_EXCL} EXCLUDED accounts for ${S1_ROWS} rows, no silent gap"; fi
if [ "${DOTTED:-0}" -gt 0 ]; then
  PASS "B5: DOTTED-CELL COUNT ${DOTTED:-0} — the leading-dot widening is exercised by LIVE data; ${UNWID:-0} live cell(s) fail the un-widened grammar, so the widened and un-widened forms are DISTINGUISHABLE on this population"
else
  PASS "B5: DOTTED-CELL COUNT 0 — READ THIS AS VACUOUS, NOT AS PASSING. No live cell exercises the leading-dot widening, so a green on this arm is evidence about the fixture only, and it must not be read as closure of the widening obligation. ${UNWID:-0} live cell(s) fail the un-widened grammar"
fi

echo
echo "── Group K — the coverage bijection. K1 resolvability, K2 totality, K3 exclusivity."
if has_finding "$ALL" "$(surface X1 X2)"; then FAIL "K0: the key channel is lossy"; show "$ALL" 'X1|X2'
else PASS "K0: every emitted key round-trips byte-identical through the record channel; no key is empty or carries whitespace; every membership test passes its haystack quoted"; fi
if has_finding "$ALL" "$(surface K1)"; then FAIL "K1: an ADDRESSED cell covers nothing, or a covered member does not resolve"; show "$ALL" 'K1'
else PASS "K1: RESOLVABILITY — each of $(getcount "$COV_OUT" ADDRCELLS) ADDRESSED cells covers a non-empty set and every member resolves (file AND declaration AND region)"; fi
if has_finding "$ALL" "$(surface K2)"; then FAIL "K2: a coverage unit is covered by no ADDRESSED cell"; show "$ALL" 'K2'
else PASS "K2: TOTALITY — all $(getcount "$COV_OUT" UNITS) coverage units are covered; the uncovered set is empty, graded as a set difference and reported member by member"; fi
if has_finding "$ALL" "$(surface K3)"; then FAIL "K3: exclusivity violated"; show "$ALL" 'K3'
else PASS "K3: EXCLUSIVITY — no unit covered twice; no command carrying both a verbless and a verbed cell. K2 AND K3 give exactly one"; fi

echo
echo "── Group S — the charter's two enumerations of the verb set agree."
if has_finding "$ALL" "$(surface S2)"; then FAIL "S1: SINGLE-SOURCE — fewer than two enumerations were derived, so agreement is not established"; show "$ALL" 'S2'
elif has_finding "$ALL" "$(surface S1)"; then FAIL "S2: the two charter enumerations disagree"; show "$ALL" 'S1'
else PASS "S1: $(getcount "$ENUM_OUT" ENUMS) enumerations derived, each non-empty ($(getcount "$ENUM_OUT" E1) / $(getcount "$ENUM_OUT" E2)); the set difference is empty in BOTH directions, reported separately"; fi

echo
echo "── Group E — ADR-007 §4: completeness, staleness sentinel, cross-surface link."
if has_finding "$ALL" "$(surface E1)"; then FAIL "E1: the §4 table is absent or a row is malformed"; show "$ALL" 'E1'
else PASS "E1: §4 parsed — $(getcount "$E_OUT" ADR4_ROWS) disposition rows, each carrying exactly one disposition"; fi
if has_finding "$ALL" "$(surface E2 E4)"; then FAIL "E2: a §4 disposition is unreasoned, off-enum, or an EXCLUDED form names a command"; show "$ALL" 'E2|E4'
else PASS "E2: every §4 EXCLUDED form carries at least one enum reason and names no command"; fi
if has_finding "$ALL" "$(surface E3)"; then FAIL "E3: COMPLETENESS — the held invocation-form denominator is not covered in both directions"; show "$ALL" 'E3'
else PASS "E3: completeness — every held invocation form is dispositioned and §4 dispositions no unrecognised form"; fi
if has_finding "$ALL" "$(surface E5 E6)"; then FAIL "E4: the dispatch-arm STALENESS SENTINEL fired"; show "$ALL" 'E5|E6'
else PASS "E4: staleness sentinel — main() carries $(getcount "$E_OUT" ARMS) dispatch arms, diffed as a SET against the held enumeration in both directions"; fi
if has_finding "$ALL" "$(surface E7 E8)"; then FAIL "E5: a §4 ADDRESSED Command cell fails the grammar, or its key does not link"; show "$ALL" 'E7|E8'
else PASS "E5: cross-surface — all $(getcount "$E_OUT" XLINK) of $(getcount "$E_OUT" ADR4_ADDR) §4 ADDRESSED keys parse under the same cell grammar and are BOTH live surface keys AND ADDRESSED Step-1 keys. No command map is held"; fi

echo
echo "── Group F — the invocation limb, verb-attributed."
if has_finding "$ALL" "$(surface F1)"; then FAIL "F1: a command file invokes an EXCLUDED form"; show "$ALL" 'F1'
else PASS "F1: all $(getcount "$F_OUT" INVOCATIONS) fenced invocations carry a subcommand in the allowed set"; fi
if has_finding "$ALL" "$(surface F2)"; then FAIL "F2: an unpublish invocation lacks the pages-only flag"; show "$ALL" 'F2'
else PASS "F2: every unpublish invocation carries the pages-only flag on the same invocation"; fi
if has_finding "$ALL" "$(surface F3 F4)"; then FAIL "F3: a forbidden flag is passed, or the plaintext override is set"; show "$ALL" 'F3|F4'
else PASS "F3: no invocation passes a forbidden flag, and no file SETS the plaintext override — the test is USE, not MENTION"; fi
if has_finding "$ALL" "$(surface F5)"; then FAIL "F4: PARSE COVERAGE — a script mention is unresolved"; show "$ALL" 'F5'
else PASS "F4: parse coverage TOTAL — $(getcount "$F_OUT" MENTIONS) mentions = $(getcount "$F_OUT" INVOCATIONS) invocations + $(getcount "$F_OUT" GRANTS) tool-grants + $(getcount "$F_OUT" PROSE) prose, $(getcount "$F_OUT" UNCLASS) unresolved"; fi
if has_finding "$ALL" "$(surface F6)"; then FAIL "F5: an invocation finding could name only a file, not a (command, verb) pair"; show "$ALL" 'F6'
else PASS "F5: FILE-GRANULAR FINDINGS $(getcount "$F_OUT" ORPHANINV) — the measure that must FALL TO ZERO. Every attributed invocation names (command, verb)"; fi

echo
echo "── Group R — the DECLARED read-only key set and its membership-delta sentinel."
if has_finding "$ALL" "$(surface R1)"; then FAIL "R1: a read-only region carries an executable instruction"; show "$ALL" 'R1'
else PASS "R1: each of $(getcount "$R_OUT" ROKEYS) declared read-only regions carries no fenced invocation line and no pre-execution block of its own"; fi
if has_finding "$ALL" "$(surface R2)"; then FAIL "R2: the MEMBERSHIP-DELTA SENTINEL fired — the read-only set needs re-adjudication"; show "$ALL" 'R2'
else PASS "R2: sentinel — ${READONLY_OF_COMMAND}'s $(getcount "$R_OUT" ROLIVE) live declared verbs match the adjudicated set as a SET, in both directions. A count would hold while membership churned"; fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group G — controls. Fixture-driven under a temp directory, NEVER repo-mutating, so
# every arm re-proves on each push instead of decaying into a one-time demonstration.
# Every arm asserts FIXTURE INTEGRITY FIRST: a control built on a fixture that was never
# constructed is a green proving nothing, one level down.
# The must-NOT-fire arms come FIRST, because without them the negative arms prove nothing
# — a checker hard-wired to return 1 passes every one of them.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group G — controls: the guard shown FAILING on deliberate defects, PASSING on a correct tree, and DERIVING rather than remembering."

G0="$WORK/g0"; gen_tree "$G0" ok ok
if [ -f "$G0/CLAUDE.md" ] && [ -f "$G0/commands/trip.md" ] && [ -f "$G0/commands/trip-new.md" ] && [ -f "$G0/commands/trip-record.md" ] && [ -f "$G0/commands/trip-publish.md" ]; then
  PASS "G0a: fixture integrity — the conforming tree was constructed"
  G0OUT="$(run_tree "$G0")"
  if printf '%s\n' "$G0OUT" | grep -q '^FINDING '; then
    FAIL "G0b: MUST-NOT-FIRE — the conforming tree was flagged: $(printf '%s' "$G0OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
  else
    PASS "G0b: MUST-NOT-FIRE — a correct tree returns no finding of any id; the guard is not hard-wired red"
    PASS "G0c: MUST-NOT-FIRE — an argument-signature heading, a leading-dot verb and a parenthetical disposition pair all resolve"
    PASS "G0d: MUST-NOT-FIRE — four-space-indented read-declaration EXEMPLARS in a non-verb section produce no undeclared-verb finding (the column-0 rule), and a read-declaration line inside a fenced example produces none either (fence depth)"
    PASS "G0e: MUST-NOT-FIRE — a verb-shaped heading inside a fenced example produces no section, so the file with no real verb sections is not given an invented one"
    PASS "G0f: MUST-NOT-FIRE — a negating sentence naming a forbidden flag INSIDE a verb region, a grant token rendered as a code span in a body table, and a decoy command span in the Action column all PASS: the test is USE and FIELD-INDEXED, not MENTION and row-wide"
    PASS "G0g: MUST-NOT-FIRE — a CREATE-role file implementing no verb section resolves through the charter-declared carve-out, and a read declaration in its body is claimed"
    PASS "G0h: MUST-NOT-FIRE — the fixture charter carries literal EXCLUDED invocations in a fenced block and the invocation limb reports zero: its input set is the command directory and nothing else"
  fi
else
  FAIL "G0a: fixture integrity — the conforming tree was not constructed; G0b-h would prove nothing"
fi

# ── the two live differential arms. Drawn from the UNFILTERED live population.
D1_FENCE=0
for gf in "$CDIR"/*.md; do
  [ -e "$gf" ] || continue
  D1_FENCE=$(( D1_FENCE + $(fence_scoped_declared "$gf") ))
done
D1_ANCH="$(printf '%s\n' "$RECS" | grep -c '^DECL ')"
if [ "${D1_ANCH:-0}" -gt "$D1_FENCE" ]; then
  PASS "G-D1: LIVE DIFFERENTIAL — the header-row anchor recovers ${D1_ANCH} declared verbs where the fence-scoped locator this guard replaced recovers ${D1_FENCE}. On committed state the fence-based reading returns a SILENT PLAUSIBLE ZERO, and every direction of K over it would be vacuously true"
elif [ "${D1_ANCH:-0}" -eq "$D1_FENCE" ] && [ "${D1_ANCH:-0}" -gt 0 ]; then
  PASS "G-D1: NO LONGER DIFFERENTIAL — both locators recover ${D1_ANCH}. The requirement table has moved back inside the contract-header fence; this arm no longer establishes the anchor choice and is reported as such rather than as passing"
else
  FAIL "G-D1: the header-row anchor recovers ${D1_ANCH} declared verbs against the fence-scoped locator's ${D1_FENCE} — it cannot be poorer, so one of the two is broken"
fi

D2_COL0=0; D2_TRIM=0
for gf in "$CDIR"/*.md; do
  [ -e "$gf" ] || continue
  gb="$(basename "$gf" .md)"
  gcnt="$(getcount "$RECS" "READS_$gb")"
  D2_COL0=$(( D2_COL0 + ${gcnt:-0} ))
  D2_TRIM=$(( D2_TRIM + $(trimfirst_reads "$gf") ))
done
if [ "$D2_TRIM" -gt "$D2_COL0" ]; then
  PASS "G-D2: LIVE DIFFERENTIAL — the column-0 matcher sees ${D2_COL0} read declarations where the trim-first matcher sees ${D2_TRIM}. The extra $(( D2_TRIM - D2_COL0 )) are indented template exemplars in a non-verb section; a trim-first matcher fires a FALSE implemented-but-undeclared finding on committed state"
elif [ "$D2_TRIM" -eq "$D2_COL0" ] && [ "$D2_COL0" -gt 0 ]; then
  PASS "G-D2: NO LONGER DIFFERENTIAL — both matchers see ${D2_COL0}. The indented exemplars are gone; this arm no longer establishes the column-0 rule and is reported as such rather than as passing. The rule stands on its own reasoning"
else
  FAIL "G-D2: the column-0 matcher sees ${D2_COL0} read declarations against the trim-first matcher's ${D2_TRIM} — the column-0 matcher cannot see MORE, so one of the two is broken"
fi

# ── the negative arms. One per emittable id; group Y asserts the mapping is total.
ctl() {  # ctl <id> <want> <label> <charter-defect> <cmd-defect> <integrity-probe>
  local id="$1" want="$2" label="$3" cdd="$4" mdd="$5" probe="$6"
  local d="$WORK/$id"; gen_tree "$d" "$cdd" "$mdd"
  arm "$want"
  if ! eval "$probe"; then FAIL "${id}a: fixture integrity — the deliberate defect is absent; ${id}b would prove nothing"; return; fi
  PASS "${id}a: fixture integrity — the deliberate defect is present"
  local out; out="$(run_tree "$d")"
  if ! printf '%s\n' "$out" | grep -q '^FINDING '; then FAIL "${id}b: the deliberate defect was NOT flagged ($label)"
  elif printf '%s\n' "$out" | grep -q "^FINDING $want "; then PASS "${id}b: flagged, naming $want — $label"
  else FAIL "${id}b: flagged but not as $want ($label): $(printf '%s' "$out" | grep '^FINDING ' | head -1)"; fi
}

ctl GA0  A0 "an empty command directory — a FAIL, not a vacuous pass"          ok        nocmds  '[ -d "$WORK/GA0/commands" ] && [ -z "$(ls -A "$WORK/GA0/commands")" ]'
ctl GA0b A0 "an absent Step-1 slice — a FAIL, not a vacuous pass"              nostep1   ok      '! grep -q "^### Step 1:" "$WORK/GA0b/CLAUDE.md"'
ctl GV0  V0 "a command file whose requirement table is absent"                 ok        notable    '! grep -q "^| verb | lifecycle" "$WORK/GV0/commands/trip.md"'
ctl GV0b V0 "a command file carrying TWO requirement-table header rows"        ok        twotables  '[ "$(grep -c "^| verb | lifecycle" "$WORK/GV0b/commands/trip.md")" = "2" ]'
ctl GV1  V1 "a requirement-table row that does not parse at five columns"      ok        badrow     'grep -qF "| broken | ACTIVE | any |" "$WORK/GV1/commands/trip.md"'
ctl GV2  V2 "one verb identity declared twice with no parenthetical"           ok        dupident   '[ "$(grep -c "^| status | ACTIVE" "$WORK/GV2/commands/trip.md")" = "2" ]'
ctl GV3  V3 "a declared verb with no implementing region"                      ok        nosection  '! grep -q "^## status$" "$WORK/GV3/commands/trip.md"'
ctl GV3b V3 "a declared verb with TWO implementing regions"                    ok        twosections 'grep -qF "## status <other>" "$WORK/GV3b/commands/trip.md"'
ctl GV4  V4 "a column-0 read declaration in a NON-verb section"                ok        strayreads 'grep -qF "**Reads:** something undeclared." "$WORK/GV4/commands/trip.md"'
ctl GV5  V5 "a command file with no contract-header block"                     ok        noheader   '! grep -q "trip-contract-header" "$WORK/GV5/commands/trip.md"'
ctl GV5b V5 "a command file carrying TWO contract-header blocks"               ok        twoheader  '[ "$(grep -c "trip-contract-header" "$WORK/GV5b/commands/trip.md")" = "2" ]'
ctl GV6  V6 "a Step-1 cell whose code-span strip changes the VALUE while the row count holds" badspan ok 'grep -qF "st${BT}atus" "$WORK/GV6/CLAUDE.md"'
ctl GB1  B1 "a Step-1 row with neither a code span nor an exclusion"           badcell   ok  'grep -qF "| ex | neither |" "$WORK/GB1/CLAUDE.md"'
ctl GB4  B4 "the same row seen as an exhaustiveness gap — it is counted as neither" badcell ok 'grep -qF "| ex | neither |" "$WORK/GB4/CLAUDE.md"'
ctl GB2  B2 "an EXCLUDED reason outside the closed five-value enum"            offenum   ok  'grep -qF "because I said so" "$WORK/GB2/CLAUDE.md"'
ctl GB2b B2 "an EXCLUDED cell carrying the same reason twice"                  dupreason ok  'grep -qF "repo-creation + repo-creation" "$WORK/GB2b/CLAUDE.md"'
ctl GB3  B3 "a cell the MINIMAL widening would admit and the alternation rejects" badgrammar ok 'grep -qF -- "/trip --.x" "$WORK/GB3/CLAUDE.md"'
ctl GB5  B5 "an ADDRESSED cell whose COMMAND component fails N1"               badn1     ok  'grep -qF "/Trip status" "$WORK/GB5/CLAUDE.md"'
ctl GK1  K1 "an ADDRESSED cell naming a verb no requirement table declares"    ghostkey  ok  'grep -qF "nosuchverb" "$WORK/GK1/CLAUDE.md"'
ctl GK2  K2 "a declared verb covered by no ADDRESSED cell"                     uncovered ok  '! grep -qF "| /trip check |" "$WORK/GK2/CLAUDE.md"'
ctl GK3  K3 "a command carrying both a verbless and a verbed ADDRESSED cell"   dblcover  ok  'grep -qF "| ex | ${BT}/trip${BT} |" "$WORK/GK3/CLAUDE.md"'
ctl GS1  S1 "a key present in Step 1 and absent from Step 2"                   step2drift ok '[ "$(grep -c "trip-record log" "$WORK/GS1/CLAUDE.md")" = "1" ]'
ctl GS2  S2 "only ONE enumeration derivable — SINGLE-SOURCE, not agreement"    nostep2   ok  '! grep -q "^### Step 2:" "$WORK/GS2/CLAUDE.md"'
ctl GF1  F1 "a verb region invoking the EXCLUDED form rotate"                  ok        rotate      'grep -qF "publish-trip-site.sh rotate" "$WORK/GF1/commands/trip-publish.md"'
ctl GF2  F2 "an unpublish invocation lacking the pages-only flag"              ok        nounpubflag 'grep -qF "unpublish trips/x" "$WORK/GF2/commands/trip-publish.md"'
ctl GF3  F3 "a forbidden flag passed on a publish-script invocation"           ok        badflag     'grep -qF -- "--passphrase secret" "$WORK/GF3/commands/trip-publish.md"'
ctl GF4  F4 "a command file that SETS the plaintext override, not merely names it" ok    allowplain  'grep -qF "ALLOW_PLAINTEXT=1" "$WORK/GF4/commands/trip.md"'
ctl GF5  F5 "a script mention reached through a variable — unresolved, not silently clean" ok varmention 'grep -q "^SCRIPT=scripts" "$WORK/GF5/commands/trip.md"'
ctl GF6  F6 "a fenced invocation in no verb region — a finding that could name only a FILE" ok orphaninv 'grep -q "^## Not a verb$" "$WORK/GF6/commands/trip.md"'

# ── X-group: the key channel, driven with a synthetic record stream. Feeding the
# consumer directly is what makes these ids reachable without a debug backdoor and
# without a fixture that could not occur on a real surface.
arm X1
XS1="FILE /a
DECL /a plan
KEY /a:plann
ADDRPARTS /a plan"
if printf '%s\n' "$XS1" | grep -q '^KEY /a:plann$'; then
  PASS "GX1a: fixture integrity — the synthetic record stream carries a key that disagrees with its declaration"
  if printf '%s\n' "$(coverage_check "$XS1")" | grep -q '^FINDING X1 '; then
    PASS "GX1b: flagged, naming X1 — an emitted key that did not round-trip byte-identical is caught even though the COUNT of keys is unchanged"
  else FAIL "GX1b: a key whose VALUE changed in transport was NOT flagged"; fi
else FAIL "GX1a: fixture integrity — the synthetic stream was not built; GX1b would prove nothing"; fi

arm X2
XS2="FILE /a
DECL /a plan
KEY /a:two words
ADDRPARTS /a plan"
if printf '%s\n' "$XS2" | grep -q '^KEY /a:two words$'; then
  PASS "GX2a: fixture integrity — the synthetic record stream carries a whitespace-bearing key"
  if printf '%s\n' "$(coverage_check "$XS2")" | grep -q '^FINDING X2 '; then
    PASS "GX2b: flagged, naming X2 — a whitespace-bearing key is a hard failure, so the lossy channel cannot return by accident"
  else FAIL "GX2b: a whitespace-bearing key was NOT flagged"; fi
else FAIL "GX2a: fixture integrity — the synthetic stream was not built; GX2b would prove nothing"; fi

# ── E-group arms: the ADR, the script and the record stream, each built.
GE="$WORK/ge"; gen_tree "$GE" ok ok; GEREC="$(run_tree "$GE")"
ectl() {  # ectl <id> <want> <label> <adr-defect> <script-extra> <probe>
  local id="$1" want="$2" label="$3" ad="$4" sx="$5" probe="$6"
  local d="$WORK/$id"; mkdir -p "$d"; gen_adr "$d" "$ad"; gen_script "$d/pub.sh" "$sx"
  arm "$want"
  if ! eval "$probe"; then FAIL "${id}a: fixture integrity — the deliberate defect is absent; ${id}b would prove nothing"; return; fi
  PASS "${id}a: fixture integrity — the deliberate defect is present"
  local out; out="$(adr4_check "$d/ADR.md" "$d/pub.sh" "$GEREC")"
  if printf '%s\n' "$out" | grep -q "^FINDING $want "; then PASS "${id}b: flagged, naming $want — $label"
  else FAIL "${id}b: not flagged as $want ($label): $(printf '%s' "$out" | grep '^FINDING ' | head -1)"; fi
}
ectl GE1 E1 "a §4 row that does not parse at five columns"                    badrow       ''        'grep -qF "| 10 | ${BT}unpublish${BT} | EXCLUDED |" "$WORK/GE1/ADR.md"'
ectl GE2 E2 "a §4 EXCLUDED form carrying no reason"                           noreason     ''        'grep -qF "| 4 | ${BT}publish${BT} | EXCLUDED | ${EMDASH} |" "$WORK/GE2/ADR.md"'
ectl GE3 E3 "a §4 row omitted, breaking the held form denominator"            omitform     ''        '! grep -qF "plaintext --opaque" "$WORK/GE3/ADR.md"'
ectl GE4 E4 "a §4 EXCLUDED form that names a command"                         exclnamescmd ''        'grep -qF "EXCLUDED | ${BT}repo-creation${BT} | ${BT}/trip-publish update${BT}" "$WORK/GE4/ADR.md"'
ectl GE6 E6 "a seventh main() dispatch arm — the enumeration has gone stale"  ok           archive   'grep -qF "archive)" "$WORK/GE6/pub.sh"'
ectl GE7 E7 "a §4 ADDRESSED cell naming a key the live surface does not carry" deadkey     ''        'grep -qF "trip-publish nosuch" "$WORK/GE7/ADR.md"'
ectl GE8 E8 "a §4 ADDRESSED Command cell that fails the cell grammar"         badcmdcell   ''        'grep -qF "/Trip-Publish list" "$WORK/GE8/ADR.md"'

arm E5
GE5="$WORK/ge5"; mkdir -p "$GE5"; gen_adr "$GE5" ok
if [ ! -f "$GE5/pub.sh" ]; then
  PASS "GE5a: fixture integrity — no publish script exists at the fixture path"
  if printf '%s\n' "$(adr4_check "$GE5/ADR.md" "$GE5/pub.sh" "$GEREC")" | grep -q '^FINDING E5 '; then
    PASS "GE5b: flagged, naming E5 — an unreadable publish script makes the sentinel unable to run, which is a failure and not a skip"
  else FAIL "GE5b: an unreadable publish script did NOT fail the sentinel"; fi
else FAIL "GE5a: fixture integrity — a script exists where none should; GE5b would prove nothing"; fi

# ── R-group arms.
arm R1
if printf '%s\n' "$GEREC" | grep -q '^INV /trip-publish update '; then
  PASS "GR1a: fixture integrity — a fixture verb region carries a fenced invocation line"
  if printf '%s\n' "$(readonly_check "$GEREC" '/trip-publish:update' -- status check)" | grep -q '^FINDING R1 '; then
    PASS "GR1b: flagged, naming R1 — a declared read-only key whose region carries an executable instruction. Non-vacuous: regions that DO carry one exist, so the assertion has something to catch"
  else FAIL "GR1b: an executable instruction in a declared read-only region was NOT flagged"; fi
else FAIL "GR1a: fixture integrity — no fixture region carries an invocation; GR1b would prove nothing"; fi

arm R2
if printf '%s\n' "$(readonly_check "$RECS" "${READONLY_KEYS[@]}" -- status check nosuchverb)" | grep -q '^FINDING R2 '; then
  PASS "GR2: flagged, naming R2 — the MEMBERSHIP-DELTA SENTINEL fires on a set difference in either direction, and the message names the required action. Diffed as a SET: a verb removed and another added holds the count while membership churns"
else FAIL "GR2: the membership-delta sentinel did not fire on a deliberate set difference"; fi

arm N1
NEEDLES_SAVE=( "${NEEDLES[@]}" )
NEEDLES+=( 'trailing ' )
if printf '%s\n' "$(needle_check)" | grep -q '^FINDING N1 '; then
  PASS "GN1: flagged, naming N1 — a needle that does not survive the haystack's normalisation, and is not registered UNTRIMMED, is a build error rather than a silent non-match"
else FAIL "GN1: a needle failing norm(needle) == needle was NOT flagged"; fi
NEEDLES=( "${NEEDLES_SAVE[@]}" )

# ── the grammar control: the minimal widening admits junk the alternation rejects.
GRAM_OK=1
for gc in "${BT}/trip status${BT}" "${BT}/trip-record .publish-slug${BT}" "${BT}/trip-decommission --archive${BT}" "${BT}/trip-new${BT}" "${BT}/trip-publish list${BT}" "${BT}/trip-record .a-b${BT}"; do
  [[ "$gc" =~ $CELL_RE ]] || GRAM_OK=0
done
GRAM_BAD=0
for gc in "${BT}/trip <verb>${BT}" "${BT}/trip-new new (create)${BT}" "${BT}/Trip status${BT}" "${BT}trip status${BT}" "${BT}/trip status extra${BT}" "${BT}/trip_status${BT}" "${BT}/trip -status${BT}" "${BT}/trip-record .${BT}"; do
  [[ "$gc" =~ $CELL_RE ]] && GRAM_BAD=$((GRAM_BAD+1))
done
MIN_ADMITS_JUNK=0
[[ "${BT}/trip --.x${BT}" =~ $CELL_RE_MINIMAL ]] && MIN_ADMITS_JUNK=1
ALT_REJECTS_JUNK=1
[[ "${BT}/trip --.x${BT}" =~ $CELL_RE ]] && ALT_REJECTS_JUNK=0
if [ "$GRAM_OK" -eq 1 ] && [ "$GRAM_BAD" -eq 0 ] && [ "$MIN_ADMITS_JUNK" -eq 1 ] && [ "$ALT_REJECTS_JUNK" -eq 1 ]; then
  PASS "G-GR: grammar control — six true forms admitted, eight malformed rejected, and the MINIMAL widening admits the junk cell the ALTERNATION rejects. A leading dot is part of an identity; a double dash is a spelling variant the key rule normalises away; the two can never co-occur, so the grammar must not express both at once"
else
  FAIL "G-GR: grammar control — true admitted=$GRAM_OK, malformed admitted=$GRAM_BAD, minimal admits junk=$MIN_ADMITS_JUNK, alternation rejects junk=$ALT_REJECTS_JUNK"
fi

# ── the DERIVATION mutation pair. This is the arm a green run on unchanged state cannot
# satisfy. Both arms, or neither: a guard that failed on ANY change would pass the red
# arm while proving nothing, so the green arm is load-bearing. Both trees are BUILT from
# tuples — the rename is a different tuple table, never a patch over a generated file.
GM1="$WORK/gm1"; gen_tree "$GM1" ok  ok "${WORLD_MUT[@]}"
GM2="$WORK/gm2"; gen_tree "$GM2" mut ok "${WORLD_MUT[@]}"
if grep -q "checkx" "$GM1/commands/trip.md" && ! grep -q "checkx" "$GM1/CLAUDE.md" \
   && grep -q "checkx" "$GM2/commands/trip.md" && grep -q "checkx" "$GM2/CLAUDE.md"; then
  PASS "GM-a: fixture integrity — one tree carries the rename in the command file ONLY; the other carries the same rename on BOTH surfaces"
  M1="$(run_tree "$GM1")"; M2="$(run_tree "$GM2")"
  if printf '%s\n' "$M1" | grep -q '^FINDING ' && printf '%s\n' "$M1" | grep -q 'checkx'; then
    PASS "GM-b: RED ARM — a verb renamed in a command file with the charter untouched turns the guard red and NAMES the affected key. The verb population is DERIVED, not remembered"
  else
    FAIL "GM-b: RED ARM — a one-sided rename did NOT turn the guard red, or did not name the affected key: $(printf '%s' "$M1" | grep '^FINDING ' | head -1)"
  fi
  if printf '%s\n' "$M2" | grep -q '^FINDING '; then
    FAIL "GM-c: GREEN ARM — the same rename applied to BOTH surfaces was still flagged, so the red arm proves only that the guard dislikes change: $(printf '%s' "$M2" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
  else
    PASS "GM-c: GREEN ARM — the same rename applied to BOTH surfaces stays green. Both arms, or neither: a green run on unchanged state does not satisfy this control; only the pair does"
  fi
else
  FAIL "GM-a: fixture integrity — the mutation pair was not constructed; GM-b and GM-c would prove nothing"
fi

# ── a fresh specificity token, minted per run and never written into the repository.
# A published token stops being impossible.
TOKEN="tx$$$(date +%s)$RANDOM"
TOKHITS=0
for gp in "$MD" "$ADR" "$PUB" "$SELF"; do
  [ -f "$gp" ] && grep -qF "$TOKEN" "$gp" && TOKHITS=$((TOKHITS+1))
done
for gp in "$CDIR"/*.md; do
  [ -e "$gp" ] && grep -qF "$TOKEN" "$gp" && TOKHITS=$((TOKHITS+1))
done
CTLHITS=0
grep -qF 'trip-contract-header' "$MD" && CTLHITS=$((CTLHITS+1))
if [ "$TOKHITS" -eq 0 ] && [ "$CTLHITS" -eq 1 ]; then
  PASS "G-TOK: specificity — a token minted for this run and never written into the repository resolves against nothing across the charter, the command surface, the ADR, the publish script and this guard. The zero is a real zero, not a dead matcher: the same matcher returns non-zero on a known-present needle"
else
  FAIL "G-TOK: specificity — a per-run token resolved against $TOKHITS file(s), and the control needle resolved $CTLHITS time(s) where 1 was required"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group Y — the assertion inventory, machine-checked against this file.
#
# The emittable ids are DERIVED from this file's own emission sites, never held as a
# list, so an id added below is in the denominator on the same commit. The mapping is
# asserted TOTAL in both directions: every emittable id is surfaced by a reporting group
# AND exercised by a control arm, and every id a group surfaces or an arm exercises is
# one this guard can actually emit. This is what stops a finding from being emitted by
# no group, and a group from testing for an id no code emits.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group Y — the assertion inventory, derived from this file and checked in both directions."
EMIT_MARK="printf ${Q}FIND""ING "
DECLARED=""
while IFS= read -r yline || [ -n "$yline" ]; do
  case "$yline" in
    *"$EMIT_MARK"*)
      yrest="${yline#*"$EMIT_MARK"}"
      yid="${yrest%% *}"
      [[ "$yid" =~ ^[A-Z][0-9]$ ]] || continue
      in_list "$yid" $DECLARED || DECLARED="$DECLARED$yid "
      ;;
  esac
done < "$SELF"

SURFACED="$(sort -u "$SURF_LOG" | tr '\n' ' ')"
ARMED="$(sort -u "$ARM_LOG" | tr '\n' ' ')"

y_ms=""; y_ma=""; y_es=""; y_ea=""
for yid in $DECLARED; do
  in_list "$yid" $SURFACED || y_ms="$y_ms$yid "
  in_list "$yid" $ARMED    || y_ma="$y_ma$yid "
done
for yid in $SURFACED; do in_list "$yid" $DECLARED || y_es="$y_es$yid "; done
for yid in $ARMED;    do in_list "$yid" $DECLARED || y_ea="$y_ea$yid "; done

NDECL=0; for yid in $DECLARED; do NDECL=$((NDECL+1)); done
if [ "$NDECL" -eq 0 ]; then
  FAIL "Y0: no emittable finding id was derived from this file — the inventory check would be vacuous"
else
  PASS "Y0: ${NDECL} emittable finding ids derived from this file's own emission sites, not held as a list"
fi
if [ -z "$y_ms" ] && [ -z "$y_es" ]; then
  PASS "Y1: every emittable id is surfaced by at least one reporting group, and every id a group surfaces is one this guard can emit"
else
  [ -n "$y_ms" ] && FAIL "Y1: emittable ids surfaced by no group: $y_ms"
  [ -n "$y_es" ] && FAIL "Y1: groups test for ids no code emits: $y_es"
fi
if [ -z "$y_ma" ] && [ -z "$y_ea" ]; then
  PASS "Y2: every emittable id is exercised by at least one control arm, and every id an arm exercises is one this guard can emit. The mapping id -> group -> arm is TOTAL in both directions"
else
  [ -n "$y_ma" ] && FAIL "Y2: emittable ids exercised by no control arm: $y_ma"
  [ -n "$y_ea" ] && FAIL "Y2: control arms exercise ids no code emits: $y_ea"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group Z — the guard mutates nothing.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group Z — non-mutation."
STATE_AFTER="$(tree_state)"
if [ "$STATE_BEFORE" = "$STATE_AFTER" ]; then
  PASS "Z1: the working tree is byte-identical before and after this run — every fixture was built under a temporary directory"
else
  FAIL "Z1: the working tree changed during this run; a guard that mutates what it grades is not a guard"
fi

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m\n' "$pass" "$fail" "$skip"
rc=0
[ "$fail" -eq 0 ] || rc=1
# STRICT SKIP MODE — a skip is a failure unless its group is declared. Contract adopted
# unchanged from scripts/test-publish-guard.sh: same variable names, same semantics, same
# group-id convention. This suite declares NO expected skips, because it has no
# dependency-gated group — no Node, no gh, no network. So every skip fails the run.
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
