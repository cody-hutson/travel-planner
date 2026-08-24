#!/usr/bin/env bash
#
# test-command-taxonomy.sh — the command-taxonomy bijection guard.
#
# Implements ADR-007 Decision 3 (taxonomy ownership): the command set owns the request
# taxonomy and CLAUDE.md's Step-1 table documents it. This suite asserts the two agree
# in BOTH directions, so a table edited on its own — or a command added on its own —
# fails CI instead of drifting quietly.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   T0  both populations non-empty and both surfaces extractable   (group A)
#   T1  no Step-1 Command cell is MALFORMED                        (group B)
#   T5  every EXCLUDED reason is in the closed 5-value enum        (group B)
#   T7  every ADDRESSED cell matches the kebab code-span shape     (group B)
#   T6  exhaustiveness — |ADDRESSED| + |EXCLUDED| == |R|           (group B)
#   T2  FORWARD  — every ADDRESSED name has a command file (A ⊆ F) (group C)
#   T3  REVERSE  — every command file has an ADDRESSED cell (F ⊆ A)(group D)
#   T4  INJECTIVITY — no name occurs in two ADDRESSED cells        (group D)
#
# T2 ∧ T3 gives A = F. T4 is what makes that a BIJECTION rather than two containments.
#
#   CIAC-6(a)  ADR-007 §4 dispositions all 10 invocation forms, plus a main() dispatch-arm
#              staleness sentinel                                  (group E)
#   CIAC-6(c)  cross-surface consistency between §4 and Step-1     (group E)
#   CIAC-6(b)  no command file invokes an EXCLUDED form, and the mention classification
#              is TOTAL (parse coverage)                           (group F)
#   controls   every failing assertion above is exercised against a synthetic fixture,
#              plus a must-NOT-fire arm                            (group G)
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# What a green here does and does NOT prove.
#
# IN SCOPE — the DECLARATION surface. Every group runs on every invocation, needs no
# network, no Node and no gh, and its verdict is real.
#
# OUT OF SCOPE — RUNTIME PRIVILEGE. `allowed-tools` / `disallowed-tools` are a
# pre-approval grant, turn-scoped: every tool stays callable, unlisted tools go through
# normal permission settings, and the grant clears at the next message. This suite
# asserts that the files DECLARE what ADR-007 requires. It cannot and does not assert
# that a declaration is enforced at runtime. A green here is not a privilege guarantee.
#
# ── TWO VACUITY DOORS, TWO MECHANISMS ────────────────────────────────────────────
# GUARD_STRICT_SKIPS closes the door where a GROUP vanishes. This suite reads the repo,
# so it has a second door the borrowed mechanism does not watch: a POPULATION vanishing.
# With `.claude/commands/` absent, the reverse direction is a universally-quantified
# statement over the empty set — vacuously true, never skipped, silently green. Group A
# closes that door, and its verdict is FAIL, never SKIP: a missing input IS the failure,
# not the absence of evidence about one. GUARD_EXPECTED_SKIPS is correctly EMPTY here —
# this suite has no dependency-gated group, so there is no legitimate skip to declare.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# NOTE: publish-trip-site.sh is deliberately NOT sourced. This suite needs zero functions
# from it, and sourcing a security-critical script to parse a markdown table would create
# shared fate — a syntax error there would make the TAXONOMY invariant unverifiable for a
# reason with nothing to do with taxonomy. Two independent invariants, two failure modes.
set +e

pass=0; fail=0; skip=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
# Records the skipped group's id — the token before the first colon of the message — so
# the aggregate verdict at the bottom can refuse a run in which a group vanished.
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

BT='`'
EMDASH='—'

# The reason vocabulary, closed at five values, shared by CLAUDE.md Step-1 and ADR-007 §4.
# An ARRAY compared literally, never a regex: 'ADR-007 §2' carries a non-ASCII section sign
# AND an internal space, and '#330-disclosure' opens with '#'. Reason lists are split on the
# literal ' + ' separator and NEVER by shell word-splitting — an unquoted `for r in $reasons`
# would split 'ADR-007 §2' into two tokens, neither in the enum, failing every correct row.
REASON_ENUM=( 'ADR-007 §2' '#330-disclosure' 'repo-creation' 'argv-secret' 'lightest-weight-action' )

# The 10 invocation forms of scripts/publish-trip-site.sh. Hardcoded deliberately: reading
# them from the §4 table would assert a table against itself, and re-deriving flag
# combinations from bash source is a parser project ('publish --plaintext --opaque' appears
# in no single line of the script). The staleness sentinel below keeps the hardcoding honest.
EXPECTED_FORMS=(
  'list' 'update' 'unpublish --disable-pages-only'
  'publish' 'publish --opaque' 'publish --plaintext' 'publish --plaintext --opaque'
  'rotate' 'rotate --passphrase' 'unpublish'
)

# main()'s dispatch arms, excluding the '*)' catch-all. A 7th arm means a new subcommand
# exists and the 10-form enumeration above has gone stale.
EXPECTED_ARMS=( 'publish' 'update' 'rotate' 'list|status' 'unpublish' '-h|--help|help|""' )

# The settled §4-ADDRESSED form -> command map (CIAC-6(c)).
EXPECTED_MAP_FORMS=( 'list' 'update' 'unpublish --disable-pages-only' )
EXPECTED_MAP_CMDS=( '/trip-list' '/trip-update' '/trip-offline' )

# Subcommand tokens a delivered command file may invoke. 'publish' and 'rotate' are
# EXCLUDED forms and are failures wherever they appear as a subcommand token.
ALLOWED_SUBS=( 'list' 'status' 'update' 'unpublish' )

SCRIPT_REL='scripts/publish-trip-site.sh'

# ─────────────────────────────────────────────────────────────────────────────────
# Small helpers
# ─────────────────────────────────────────────────────────────────────────────────
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

in_list() {  # in_list <needle> <haystack...>
  local n="$1"; shift
  local e
  for e in "$@"; do [ "$e" = "$n" ] && return 0; done
  return 1
}

# Is this line a markdown table separator (only pipes, dashes, colons, spaces)?
is_sep() { [[ "$1" =~ ^\|[-:[:space:]|]+\|[[:space:]]*$ ]]; }

getcount() { printf '%s\n' "$1" | sed -n "s/^COUNT $2 //p" | head -1; }
getlist()  { printf '%s\n' "$1" | sed -n "s/^$2 //p"; }
has_finding() { printf '%s\n' "$1" | grep -qE "^FINDING ($2) "; }
show()     { printf '%s\n' "$1" | grep -E "^FINDING ($2)" | sed 's/^FINDING /       /'; }

# ─────────────────────────────────────────────────────────────────────────────────
# taxonomy_check <claude_md_path> <commands_dir>
#
# The parameterized checker. Groups A-D drive it against the REAL tree; group G drives it
# against synthetic trees in $WORK. That is what makes the control case non-mutating and
# re-proven on every push, rather than a one-time demonstration recorded in a comment.
#
# Emits 'FINDING <T-id> <msg>', 'ADDRNAME <name>' and 'COUNT <name> <n>'. Returns 1 on any
# finding.
#
# EXTRACTION IS BOLD-AGNOSTIC and FIELD-INDEXED, both load-bearing:
#   - bold-agnostic: Step-1's first cell is bolded and Step-2's is not, so a matcher tuned
#     on a bolded first cell reads Step-2 as zero rows and is silently dead.
#   - field-indexed: the 'Context update' row is EXCLUDED, but its Action column contains
#     the code span `/trip-replan`. A row-wide match would count a command named in a
#     different column. Only field 5 is the Command cell.
# ─────────────────────────────────────────────────────────────────────────────────
taxonomy_check() {
  local md="$1" cdir="$2"
  local rc=0
  local -a ADDRESSED=()
  local n_rows=0 n_addr=0 n_excl=0

  if [ ! -f "$md" ]; then
    printf 'FINDING T0 the CLAUDE.md path does not exist: %s\n' "$md"
    printf 'COUNT R_TOTAL 0\nCOUNT R_ADDRESSED 0\nCOUNT R_EXCLUDED 0\nCOUNT F_COUNT 0\n'
    return 1
  fi

  # --- slice Step 1: from its '### Step 1:' heading to the next '### ' heading ---
  local in_slice=0 seen_sep=0 line
  local -a ROWS=()
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_slice" -eq 1 ] && [[ "$line" == '### '* ]]; then in_slice=0; fi
    if [[ "$line" == '### Step 1:'* ]]; then in_slice=1; seen_sep=0; continue; fi
    [ "$in_slice" -eq 1 ] || continue
    [[ "$line" == '|'* ]] || continue
    if is_sep "$line"; then seen_sep=1; continue; fi
    [ "$seen_sep" -eq 1 ] || continue          # skip the header row
    ROWS+=( "$line" )
  done < "$md"

  n_rows=${#ROWS[@]}
  if [ "$n_rows" -eq 0 ]; then
    printf 'FINDING T0 the Step-1 slice is empty or absent — no data rows extracted from %s\n' "$md"
    rc=1
  fi

  # --- classify each row's field-5 Command cell ---
  local row cell nf r rest name
  local -a F=() seen=()
  for row in "${ROWS[@]+"${ROWS[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    nf=${#F[@]}
    if [ "$nf" -ne 6 ]; then
      printf 'FINDING T1 MALFORMED row — expected 5 columns (6 pipe fields), got %d: %.90s\n' "$nf" "$row"
      rc=1; continue
    fi
    cell="$(trim "${F[5]}")"

    if [[ "$cell" == "EXCLUDED: "* ]]; then
      n_excl=$((n_excl+1))
      rest="$(trim "${cell#EXCLUDED: }")"
      if [ -z "$rest" ]; then
        printf 'FINDING T5 EXCLUDED cell carries no reason: %.90s\n' "$row"; rc=1; continue
      fi
      seen=()
      while [ -n "$rest" ]; do
        if [[ "$rest" == *" + "* ]]; then r="${rest%% + *}"; rest="${rest#* + }"; else r="$rest"; rest=""; fi
        r="$(trim "$r")"
        if ! in_list "$r" "${REASON_ENUM[@]}"; then
          printf 'FINDING T5 reason not in the closed 5-value enum: "%s" (cell: %s)\n' "$r" "$cell"; rc=1
        fi
        if in_list "$r" "${seen[@]+"${seen[@]}"}"; then
          printf 'FINDING T5 duplicate reason within one cell: "%s" (cell: %s)\n' "$r" "$cell"; rc=1
        fi
        seen+=( "$r" )
      done

    elif [[ "$cell" =~ ^${BT}/[a-z0-9]+(-[a-z0-9]+)*${BT}$ ]]; then
      n_addr=$((n_addr+1))
      name="${cell//${BT}/}"; name="${name#/}"
      if in_list "$name" "${ADDRESSED[@]+"${ADDRESSED[@]}"}"; then
        printf 'FINDING T4 injectivity violated — %s appears in more than one ADDRESSED cell\n' "$name"; rc=1
      fi
      ADDRESSED+=( "$name" )
      printf 'ADDRNAME %s\n' "$name"

    elif [[ "$cell" == "EXCLUDED"* ]]; then
      # Close to the exclusion shape but not it — e.g. a missing space after the colon.
      printf 'FINDING T1 MALFORMED Command cell — exclusion marker malformed, expected "EXCLUDED: <reason>": "%s"\n' "$cell"
      rc=1
    elif [[ "$cell" == ${BT}* ]]; then
      printf 'FINDING T7 ADDRESSED cell fails the kebab code-span shape: "%s"\n' "$cell"
      rc=1
    else
      printf 'FINDING T1 MALFORMED Command cell — neither a kebab code span nor an EXCLUDED marker: "%s"\n' "$cell"
      rc=1
    fi
  done

  # --- T6 exhaustiveness ---
  if [ $((n_addr + n_excl)) -ne "$n_rows" ]; then
    printf 'FINDING T6 exhaustiveness — %d ADDRESSED + %d EXCLUDED != %d rows\n' "$n_addr" "$n_excl" "$n_rows"
    rc=1
  fi

  # --- the command population ---
  local -a FSET=()
  local f b
  if [ ! -d "$cdir" ]; then
    printf 'FINDING T0 the commands directory does not exist: %s\n' "$cdir"
    rc=1
  else
    for f in "$cdir"/*.md; do
      [ -e "$f" ] || continue
      b="$(basename "$f" .md)"
      FSET+=( "$b" )
    done
    if [ "${#FSET[@]}" -eq 0 ]; then
      printf 'FINDING T0 the commands directory is empty — the reverse direction would be vacuously true: %s\n' "$cdir"
      rc=1
    fi
  fi

  # --- T2 FORWARD: every ADDRESSED name has a command file ---
  local n
  for n in "${ADDRESSED[@]+"${ADDRESSED[@]}"}"; do
    if [ ! -f "$cdir/$n.md" ]; then
      printf 'FINDING T2 forward — Step-1 names /%s but %s/%s.md does not exist\n' "$n" "$cdir" "$n"; rc=1
    fi
  done

  # --- T3 REVERSE: every command file appears as an ADDRESSED cell ---
  for n in "${FSET[@]+"${FSET[@]}"}"; do
    if ! in_list "$n" "${ADDRESSED[@]+"${ADDRESSED[@]}"}"; then
      printf 'FINDING T3 reverse — orphan command %s.md has no ADDRESSED Step-1 row\n' "$n"; rc=1
    fi
  done

  # --- N1 NAMING: every command name is `trip` or `trip-`-prefixed ---
  # Beyond the four acceptance criteria, and declared as such rather than smuggled in.
  # It enforces the single-namespace scheme rule, which has no other mechanical check
  # anywhere in the release. Checked over BOTH populations, so it still holds if the
  # bijection above is broken. Distinct finding namespace (N, not T) so it is never
  # mistaken for part of the bijection set.
  for n in "${ADDRESSED[@]+"${ADDRESSED[@]}"}" "${FSET[@]+"${FSET[@]}"}"; do
    if [[ ! "$n" =~ ^trip(-[a-z0-9]+)*$ ]]; then
      printf 'FINDING N1 naming — "%s" is outside the trip namespace; every command must be `trip` or `trip-`-prefixed\n' "$n"; rc=1
    fi
  done

  printf 'COUNT R_TOTAL %d\n' "$n_rows"
  printf 'COUNT R_ADDRESSED %d\n' "$n_addr"
  printf 'COUNT R_EXCLUDED %d\n' "$n_excl"
  printf 'COUNT F_COUNT %d\n' "${#FSET[@]}"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# adr4_check <adr_path> <script_path> <step1_addressed_names>
#
# CIAC-6(a) completeness over the 10 invocation forms + the main() staleness sentinel,
# and CIAC-6(c) cross-surface consistency between §4 and Step-1.
#
# NOTE the rendering asymmetry between the two surfaces, measured rather than assumed:
# §4 CODE-SPANS its reasons (`#330-disclosure`) while Step-1 renders them PLAIN
# (EXCLUDED: #330-disclosure). Backticks are stripped before the enum comparison, so one
# enum array serves both surfaces.
#
# The Step-1 side of the cross-surface check is passed in as a FIELD-INDEXED name list
# derived by taxonomy_check — never re-derived here by a row-wide grep, which would count
# a command named in a different column.
# ─────────────────────────────────────────────────────────────────────────────────
adr4_check() {
  local adr="$1" script="$2" step1_names="$3"
  local rc=0

  if [ ! -f "$adr" ]; then
    printf 'FINDING E0 ADR path does not exist: %s\n' "$adr"
    printf 'COUNT ADR4_ROWS 0\nCOUNT ADR4_ADDRESSED 0\nCOUNT ARMS 0\nCOUNT XSURF_LINKED 0\n'
    return 1
  fi

  # --- slice §4 ---
  local in_slice=0 seen_sep=0 line
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
    printf 'FINDING E1 the ADR-007 §4 disposition table is absent or unparseable in %s\n' "$adr"; rc=1
  fi

  local -a FOUND_FORMS=() ADDR_FORMS=() ADDR_CMDS=() F=()
  local row form disp reasons cmd r rest
  for row in "${ROWS[@]+"${ROWS[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    if [ "${#F[@]}" -ne 6 ]; then
      printf 'FINDING E1 MALFORMED §4 row — expected 5 columns, got %d: %.80s\n' "${#F[@]}" "$row"; rc=1; continue
    fi
    # Normalize the form: drop a trailing parenthetical annotation — '(alias `status`)',
    # '(delete)' — then strip code-span backticks, then trim.
    form="$(trim "${F[2]}")"; form="${form%%(*}"; form="${form//${BT}/}"; form="$(trim "$form")"
    disp="$(trim "${F[3]}")"
    reasons="$(trim "${F[4]}")"
    cmd="$(trim "$(printf '%s' "${F[5]}" | tr -d "$BT")")"
    FOUND_FORMS+=( "$form" )

    case "$disp" in
      ADDRESSED)
        ADDR_FORMS+=( "$form" ); ADDR_CMDS+=( "$cmd" )
        ;;
      EXCLUDED)
        if [ -z "$reasons" ] || [ "$reasons" = "$EMDASH" ]; then
          printf 'FINDING E2 §4 EXCLUDED form carries no reason: %s\n' "$form"; rc=1
        else
          rest="${reasons//${BT}/}"
          while [ -n "$rest" ]; do
            if [[ "$rest" == *" + "* ]]; then r="${rest%% + *}"; rest="${rest#* + }"; else r="$rest"; rest=""; fi
            r="$(trim "$r")"
            in_list "$r" "${REASON_ENUM[@]}" || { printf 'FINDING E2 §4 reason not in the closed 5-value enum: "%s" (form: %s)\n' "$r" "$form"; rc=1; }
          done
        fi
        if [ "$cmd" != "$EMDASH" ]; then
          printf 'FINDING E4 §4 EXCLUDED form names a command (%s) — an excluded form must be addressed by none: %s\n' "$cmd" "$form"; rc=1
        fi
        ;;
      *)
        printf 'FINDING E1 §4 disposition is neither ADDRESSED nor EXCLUDED: "%s" (form: %s)\n' "$disp" "$form"; rc=1
        ;;
    esac
  done

  # --- completeness over the 10 forms, both directions ---
  local e
  for e in "${EXPECTED_FORMS[@]}"; do
    in_list "$e" "${FOUND_FORMS[@]+"${FOUND_FORMS[@]}"}" || { printf 'FINDING E3 §4 does not disposition the invocation form: %s\n' "$e"; rc=1; }
  done
  for e in "${FOUND_FORMS[@]+"${FOUND_FORMS[@]}"}"; do
    in_list "$e" "${EXPECTED_FORMS[@]}" || { printf 'FINDING E3 §4 dispositions an unrecognised form: %s\n' "$e"; rc=1; }
  done

  # --- the staleness sentinel: main()'s dispatch arms ---
  local -a ARMS=()
  if [ ! -f "$script" ]; then
    printf 'FINDING E5 the publish script does not exist, so the staleness sentinel cannot run: %s\n' "$script"; rc=1
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
      [ "$pat" = '*' ] && continue          # the catch-all is not a subcommand arm
      [ -n "$pat" ] || continue
      ARMS+=( "$pat" )
    done < "$script"

    if [ "${#ARMS[@]}" -ne "${#EXPECTED_ARMS[@]}" ]; then
      printf 'FINDING E6 STALENESS SENTINEL — main() has %d dispatch arms, expected %d. A subcommand has been added or removed, so the 10-form enumeration in this guard is STALE. Required action: re-derive the invocation forms, update EXPECTED_FORMS and EXPECTED_ARMS here, and disposition the new form in ADR-007 §4.\n' "${#ARMS[@]}" "${#EXPECTED_ARMS[@]}"
      rc=1
    fi
    for e in "${ARMS[@]+"${ARMS[@]}"}"; do
      in_list "$e" "${EXPECTED_ARMS[@]}" || { printf 'FINDING E6 STALENESS SENTINEL — unrecognised main() dispatch arm "%s"; the 10-form enumeration is stale.\n' "$e"; rc=1; }
    done
    for e in "${EXPECTED_ARMS[@]}"; do
      in_list "$e" "${ARMS[@]+"${ARMS[@]}"}" || { printf 'FINDING E6 STALENESS SENTINEL — expected main() dispatch arm "%s" is gone; the 10-form enumeration is stale.\n' "$e"; rc=1; }
    done
  fi

  # --- cross-surface consistency (CIAC-6(c)) ---
  local i j n_map=${#EXPECTED_MAP_FORMS[@]} want_f want_c got_c n_link=0
  if [ "${#ADDR_FORMS[@]}" -ne "$n_map" ]; then
    printf 'FINDING E7 §4 carries %d ADDRESSED forms, expected %d\n' "${#ADDR_FORMS[@]}" "$n_map"; rc=1
  fi
  for (( i=0; i<n_map; i++ )); do
    want_f="${EXPECTED_MAP_FORMS[$i]}"; want_c="${EXPECTED_MAP_CMDS[$i]}"; got_c=""
    for (( j=0; j<${#ADDR_FORMS[@]}; j++ )); do
      [ "${ADDR_FORMS[$j]}" = "$want_f" ] && got_c="${ADDR_CMDS[$j]}"
    done
    if [ -z "$got_c" ]; then
      printf 'FINDING E7 §4 does not carry ADDRESSED form: %s\n' "$want_f"; rc=1
    elif [ "$got_c" != "$want_c" ]; then
      printf 'FINDING E7 §4 maps form %s to %s, expected %s\n' "$want_f" "$got_c" "$want_c"; rc=1
    fi
  done
  # Every §4-ADDRESSED command must appear as an ADDRESSED Step-1 cell. Matched by NAME
  # against the field-indexed list, never by row label — a row rename must not silently
  # disable this check.
  local c
  for c in "${ADDR_CMDS[@]+"${ADDR_CMDS[@]}"}"; do
    if in_list "${c#/}" $step1_names; then
      n_link=$((n_link+1))
    else
      printf 'FINDING E7 §4 ADDRESSED command %s does not appear as an ADDRESSED Step-1 cell\n' "$c"; rc=1
    fi
  done
  if [ "$n_link" -ne "$n_map" ]; then
    printf 'FINDING E7 cross-surface count identity failed — %d of %d §4 ADDRESSED commands link to a Step-1 ADDRESSED cell\n' "$n_link" "$n_map"; rc=1
  fi

  printf 'COUNT ADR4_ROWS %d\n' "$n_rows"
  printf 'COUNT ADR4_ADDRESSED %d\n' "${#ADDR_FORMS[@]}"
  printf 'COUNT ARMS %d\n' "${#ARMS[@]}"
  printf 'COUNT XSURF_LINKED %d\n' "$n_link"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# invocation_check <commands_dir>
#
# CIAC-6(b). Classifies EVERY mention of the publish script into exactly one of three
# classes and asserts the classification is TOTAL. A mention falling into none of them —
# the script reached through a variable, an alias or a heredoc — is a FAIL, not a skip.
#
# WHY CLASSIFY RATHER THAN TOKEN-SEARCH. Measured over the nine delivered command files:
# 19 mentions, of which only 3 are invocations. 10 resolve to no subcommand token at all,
# and 6 are frontmatter tool-grant declarations that read as `publish` / `rotate`
# invocations to a line-based extractor. A bare-token search over this population
# RED-LIGHTS CORRECT CODE, and the predictable repair under time pressure is to weaken the
# check until it passes — which is how a guard becomes a document.
#
#   INVOCATION  the line, stripped, BEGINS with the script path — it is a command line
#   TOOL-GRANT  the mention sits on an `allowed-tools:` / `disallowed-tools:` frontmatter
#               line — a permission DECLARATION, not an invocation
#   PROSE       the path appears inside a markdown code span in body text
#
# The banned tokens are likewise tested by USE, not by MENTION:
#   ALLOW_PLAINTEXT   fails on ASSIGNMENT or export, never on a mention. All six of its
#                     occurrences in the delivered set sit inside NEGATED declarations
#                     ("never sets `ALLOW_PLAINTEXT`"). Those sentences are deliberate, and
#                     a mention-based test would fail a conforming release.
#   --plaintext --passphrase --yes -y
#                     fail as argv tokens ON AN INVOCATION LINE. A flat substring ban on
#                     `-y` matches "destination-year" in a correct argument-hint.
# ─────────────────────────────────────────────────────────────────────────────────
invocation_check() {
  local cdir="$1"
  local rc=0
  local n_mentions=0 n_inv=0 n_grant=0 n_prose=0 n_unclass=0

  if [ ! -d "$cdir" ]; then
    printf 'FINDING F0 the commands directory does not exist: %s\n' "$cdir"
    printf 'COUNT MENTIONS 0\nCOUNT INVOCATIONS 0\nCOUNT TOOLGRANTS 0\nCOUNT PROSE 0\nCOUNT UNCLASSIFIED 0\n'
    return 1
  fi

  local f base line lno fm bare rest sub tok t found_any=0
  local -a ARGV=()
  for f in "$cdir"/*.md; do
    [ -e "$f" ] || continue
    found_any=1
    base="$(basename "$f")"
    lno=0; fm=0
    while IFS= read -r line || [ -n "$line" ]; do
      lno=$((lno+1))
      t="$(trim "$line")"
      # frontmatter region: opened by a leading '---' on line 1, closed by the next '---'
      if [ "$lno" -eq 1 ] && [ "$t" = '---' ]; then fm=1; continue; fi
      if [ "$fm" -eq 1 ] && [ "$t" = '---' ]; then fm=0; continue; fi

      # --- ALLOW_PLAINTEXT: assignment or export only, anywhere in the file ---
      if [[ "$line" =~ (^|[^A-Za-z0-9_])ALLOW_PLAINTEXT[[:space:]]*= ]] || [[ "$line" =~ export[[:space:]]+ALLOW_PLAINTEXT ]]; then
        printf 'FINDING F4 %s:%d SETS ALLOW_PLAINTEXT — ADR-007 §2 forbids the plaintext override in any command file\n' "$base" "$lno"; rc=1
      fi

      case "$line" in *"$SCRIPT_REL"*) ;; *) continue ;; esac
      n_mentions=$((n_mentions+1))

      # --- class 2: tool-grant declaration ---
      if [ "$fm" -eq 1 ] && { [[ "$t" == 'allowed-tools:'* ]] || [[ "$t" == 'disallowed-tools:'* ]]; }; then
        n_grant=$((n_grant+1)); continue
      fi

      # --- class 1: invocation — the line BEGINS with the script path ---
      bare="$t"; bare="${bare#\$ }"; bare="${bare#./}"
      if [ "$bare" = "$SCRIPT_REL" ] || [[ "$bare" == "$SCRIPT_REL "* ]]; then
        n_inv=$((n_inv+1))
        rest="$(trim "${bare#"$SCRIPT_REL"}")"
        IFS=' ' read -r -a ARGV <<< "$rest"    # split argv without globbing
        sub=""
        for tok in "${ARGV[@]+"${ARGV[@]}"}"; do
          case "$tok" in -*) continue ;; '') continue ;; *) sub="$tok"; break ;; esac
        done
        if [ -z "$sub" ]; then
          printf 'FINDING F1 %s:%d invokes the publish script with no subcommand token\n' "$base" "$lno"; rc=1
        elif ! in_list "$sub" "${ALLOWED_SUBS[@]}"; then
          printf 'FINDING F1 %s:%d invokes the EXCLUDED form "%s" — ADR-007 §4 dispositions it EXCLUDED\n' "$base" "$lno" "$sub"; rc=1
        elif [ "$sub" = 'unpublish' ] && [[ "$rest" != *'--disable-pages-only'* ]]; then
          printf 'FINDING F2 %s:%d invokes unpublish WITHOUT --disable-pages-only on the same invocation — that is the repo-delete form, which is EXCLUDED\n' "$base" "$lno"; rc=1
        fi
        for tok in "${ARGV[@]+"${ARGV[@]}"}"; do
          case "$tok" in
            '--plaintext'|'--passphrase'|'--yes'|'-y')
              printf 'FINDING F3 %s:%d passes the forbidden flag %s on a publish-script invocation\n' "$base" "$lno" "$tok"; rc=1 ;;
          esac
        done
        continue
      fi

      # --- class 3: prose reference inside a code span ---
      if [[ "$line" == *"${BT}${SCRIPT_REL}${BT}"* ]]; then
        n_prose=$((n_prose+1)); continue
      fi

      # --- residue: reached by no recognised shape ---
      n_unclass=$((n_unclass+1))
      printf 'FINDING F5 PARSE COVERAGE — %s:%d mentions the publish script in a shape this guard cannot resolve (variable, alias or heredoc?). An unresolved mention is a failure, not a skip: %.80s\n' "$base" "$lno" "$t"
      rc=1
    done < "$f"
  done

  if [ "$found_any" -eq 0 ]; then
    printf 'FINDING F0 the commands directory holds no .md files: %s\n' "$cdir"; rc=1
  fi

  # Parse coverage: the classification must be TOTAL. Without this a parser that silently
  # resolves nothing returns "0 violations" and reads as clean.
  if [ $((n_inv + n_grant + n_prose + n_unclass)) -ne "$n_mentions" ]; then
    printf 'FINDING F5 PARSE COVERAGE — %d mentions found but %d classified\n' "$n_mentions" "$((n_inv+n_grant+n_prose+n_unclass))"; rc=1
  fi

  printf 'COUNT MENTIONS %d\n' "$n_mentions"
  printf 'COUNT INVOCATIONS %d\n' "$n_inv"
  printf 'COUNT TOOLGRANTS %d\n' "$n_grant"
  printf 'COUNT PROSE %d\n' "$n_prose"
  printf 'COUNT UNCLASSIFIED %d\n' "$n_unclass"
  return "$rc"
}

# ═════════════════════════════════════════════════════════════════════════════════
# Groups A-F — the real tree
# ═════════════════════════════════════════════════════════════════════════════════
MD="$ROOT/CLAUDE.md"
CDIR="$ROOT/.claude/commands"
ADR="$ROOT/reference/adr/ADR-007-command-entry-point.md"
PUB="$ROOT/scripts/publish-trip-site.sh"

TX_OUT="$(taxonomy_check "$MD" "$CDIR")"; TX_RC=$?
R_TOTAL="$(getcount "$TX_OUT" R_TOTAL)"
R_ADDR="$(getcount "$TX_OUT" R_ADDRESSED)"
R_EXCL="$(getcount "$TX_OUT" R_EXCLUDED)"
F_COUNT="$(getcount "$TX_OUT" F_COUNT)"
STEP1_NAMES="$(getlist "$TX_OUT" ADDRNAME | tr '\n' ' ')"

echo
echo "── Group A — populations non-empty (T0). FAIL, never SKIP."
if has_finding "$TX_OUT" T0; then
  FAIL "A1: T0 — a population or surface is empty"; show "$TX_OUT" T0
else
  PASS "A1: T0 — Step-1 slice extractable and non-empty (${R_TOTAL} rows); .claude/commands/ present and non-empty (${F_COUNT} files)"
fi
if [ "${R_TOTAL:-0}" -eq 17 ]; then PASS "A2: |R| == 17"; else FAIL "A2: |R| == ${R_TOTAL:-0}, expected 17"; fi
if [ "${F_COUNT:-0}" -eq 9 ];  then PASS "A3: |F| == 9";  else FAIL "A3: |F| == ${F_COUNT:-0}, expected 9"; fi

echo
echo "── Group B — cell well-formedness, reason enum, lexical shape, exhaustiveness (T1, T5, T7, T6)."
if has_finding "$TX_OUT" T1; then FAIL "B1: T1 — a Command cell is MALFORMED"; show "$TX_OUT" T1
else PASS "B1: T1 — no MALFORMED Command cell across ${R_TOTAL} rows"; fi
if has_finding "$TX_OUT" T5; then FAIL "B2: T5 — a reason is off-enum or duplicated"; show "$TX_OUT" T5
else PASS "B2: T5 — every reason on all ${R_EXCL} EXCLUDED cells is in the closed 5-value enum, none duplicated"; fi
if has_finding "$TX_OUT" T7; then FAIL "B3: T7 — an ADDRESSED cell fails the kebab code-span shape"; show "$TX_OUT" T7
else PASS "B3: T7 — every ADDRESSED cell matches the kebab code-span shape"; fi
if has_finding "$TX_OUT" T6; then FAIL "B4: T6 — exhaustiveness broken"; show "$TX_OUT" T6
else PASS "B4: T6 — ${R_ADDR} ADDRESSED + ${R_EXCL} EXCLUDED == ${R_TOTAL} rows, no silent gap"; fi
if [ "${R_ADDR:-0}" -eq 9 ]; then PASS "B5: |ADDRESSED| == 9"; else FAIL "B5: |ADDRESSED| == ${R_ADDR:-0}, expected 9"; fi
if [ "${R_EXCL:-0}" -eq 8 ]; then PASS "B6: |EXCLUDED| == 8"; else FAIL "B6: |EXCLUDED| == ${R_EXCL:-0}, expected 8"; fi
# Beyond-AC, declared: the single-namespace scheme rule. It gates like any other check.
if has_finding "$TX_OUT" N1; then FAIL "B7: N1 — a command name is outside the trip namespace"; show "$TX_OUT" N1
else PASS "B7: N1 — every command name is \`trip\` or \`trip-\`-prefixed (beyond-AC, declared)"; fi

echo
echo "── Group C — FORWARD: every ADDRESSED row resolves to a command file (T2, A ⊆ F)."
if has_finding "$TX_OUT" T2; then FAIL "C1: T2 — a Step-1 ADDRESSED row names a command that does not exist"; show "$TX_OUT" T2
else PASS "C1: T2 — all ${R_ADDR} ADDRESSED names resolve to a file in .claude/commands/"; fi

echo
echo "── Group D — REVERSE + injectivity: every command file has an ADDRESSED row (T3, F ⊆ A; T4)."
if has_finding "$TX_OUT" T3; then FAIL "D1: T3 — an orphan command file has no Step-1 row"; show "$TX_OUT" T3
else PASS "D1: T3 — all ${F_COUNT} command files appear as an ADDRESSED Step-1 cell"; fi
if has_finding "$TX_OUT" T4; then FAIL "D2: T4 — injectivity violated"; show "$TX_OUT" T4
else PASS "D2: T4 — no command name occurs in two ADDRESSED cells (row → name is injective)"; fi
if [ "${R_ADDR:-0}" -eq "${F_COUNT:-0}" ] && [ "${R_ADDR:-0}" -eq 9 ] && [ "$TX_RC" -eq 0 ]; then
  PASS "D3: BIJECTION — T2 ∧ T3 gives A = F; T4 makes it injective. 9 ADDRESSED rows ↔ 9 command files"
else
  FAIL "D3: BIJECTION not established — |ADDRESSED|=${R_ADDR:-0}, |F|=${F_COUNT:-0}, checker rc=$TX_RC"
fi

echo
echo "── Group E — CIAC-6(a)+(c): ADR-007 §4 completeness over 10 forms, staleness sentinel, cross-surface."
E_OUT="$(adr4_check "$ADR" "$PUB" "$STEP1_NAMES")"; E_RC=$?
ADR4_ROWS="$(getcount "$E_OUT" ADR4_ROWS)"
ADR4_ADDR="$(getcount "$E_OUT" ADR4_ADDRESSED)"
ARMS_N="$(getcount "$E_OUT" ARMS)"
XLINK="$(getcount "$E_OUT" XSURF_LINKED)"
if has_finding "$E_OUT" 'E0|E1'; then FAIL "E1: the §4 table is absent or a row is malformed"; show "$E_OUT" 'E0|E1'
else PASS "E1: §4 parsed — ${ADR4_ROWS} disposition rows, each carrying exactly one of {ADDRESSED, EXCLUDED}"; fi
if has_finding "$E_OUT" 'E2|E4'; then FAIL "E2: a §4 disposition is unreasoned, off-enum, or an EXCLUDED form names a command"; show "$E_OUT" 'E2|E4'
else PASS "E2: every §4 EXCLUDED form carries ≥1 enum reason and names no command"; fi
if has_finding "$E_OUT" E3; then FAIL "E3: COMPLETENESS — the 10-form denominator is not covered"; show "$E_OUT" E3
else PASS "E3: completeness — all 10 invocation forms are dispositioned, and §4 dispositions no unrecognised form"; fi
if has_finding "$E_OUT" 'E5|E6'; then FAIL "E4: STALENESS SENTINEL fired"; show "$E_OUT" 'E5|E6'
else PASS "E4: staleness sentinel — main() carries ${ARMS_N} dispatch arms, matching the expected ${#EXPECTED_ARMS[@]}; the 10-form enumeration is current"; fi
if has_finding "$E_OUT" E7; then FAIL "E5: cross-surface consistency broken"; show "$E_OUT" E7
else PASS "E5: cross-surface — |§4 ADDRESSED| == ${ADR4_ADDR}, all ${XLINK} mapping to an ADDRESSED Step-1 cell (3/3/3)"; fi
# Self-consistency: the checker's own rc must agree with the per-assertion verdicts above.
# Without this, a FINDING carrying an id no group tests for would pass silently — the same
# "check that cannot reach what it claims to verify" defect this suite exists to prevent.
if [ "$E_RC" -eq 0 ]; then PASS "E6: adr4_check returned 0 — no §4 finding of any id went unsurfaced"
else FAIL "E6: adr4_check returned $E_RC but the assertions above did not account for every finding"; show "$E_OUT" '[A-Z][0-9]+'; fi

echo
echo "── Group F — CIAC-6(b): no command invokes an EXCLUDED form; classification is TOTAL."
F_OUT="$(invocation_check "$CDIR")"; F_RC=$?
MENTIONS="$(getcount "$F_OUT" MENTIONS)"
INVS="$(getcount "$F_OUT" INVOCATIONS)"
GRANTS="$(getcount "$F_OUT" TOOLGRANTS)"
PROSE_N="$(getcount "$F_OUT" PROSE)"
UNCLASS="$(getcount "$F_OUT" UNCLASSIFIED)"
if has_finding "$F_OUT" F1; then FAIL "F1: a command file invokes an EXCLUDED form"; show "$F_OUT" F1
else PASS "F1: all ${INVS} invocations carry a subcommand in {list, status, update, unpublish}"; fi
if has_finding "$F_OUT" F2; then FAIL "F2: an unpublish invocation lacks --disable-pages-only"; show "$F_OUT" F2
else PASS "F2: every unpublish invocation carries --disable-pages-only on the same invocation"; fi
if has_finding "$F_OUT" 'F3|F4'; then FAIL "F3: a forbidden flag or the plaintext override is used"; show "$F_OUT" 'F3|F4'
else PASS "F3: no invocation passes --plaintext/--passphrase/--yes/-y, and no file assigns ALLOW_PLAINTEXT"; fi
if has_finding "$F_OUT" 'F0|F5'; then FAIL "F4: PARSE COVERAGE — a script mention is unresolved"; show "$F_OUT" 'F0|F5'
else PASS "F4: parse coverage TOTAL — ${MENTIONS} mentions = ${INVS} invocations + ${GRANTS} tool-grants + ${PROSE_N} prose, ${UNCLASS} unresolved"; fi
# Self-consistency, as for group E above.
if [ "$F_RC" -eq 0 ]; then PASS "F5: invocation_check returned 0 — no command-file finding of any id went unsurfaced"
else FAIL "F5: invocation_check returned $F_RC but the assertions above did not account for every finding"; show "$F_OUT" '[A-Z][0-9]+'; fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group G — the control case. Fixture-driven in $WORK, NEVER repo-mutating, so it
# re-proves on every push instead of decaying into a one-time demonstration.
#
# Every arm carries a FIXTURE-INTEGRITY assertion FIRST: a control built on a fixture that
# was never constructed is a green proving nothing, one level down.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group G — control case: the guard shown FAILING on deliberate mismatches, and PASSING on a correct tree."

# Fixtures are BUILT, never sed-patched: a delimiter collision or a BSD/GNU `\n` difference
# in a patch would silently produce a fixture that does not carry the defect it claims.
#
# Two properties are deliberately baked into the base fixture so the must-NOT-fire arm
# exercises them live rather than trusting them:
#   - first cells are NOT bolded (Step-1's are), so bold-agnostic extraction is proven
#   - the Alpha row's ACTION column carries the code span `/trip-list`, so a row-wide
#     matcher would read 3 ADDRESSED names and trip injectivity. Field-indexed extraction
#     is the only way this fixture passes.
mk_md() {
  local d="$1" v="${2:-ok}"
  mkdir -p "$d"
  {
    if [ "$v" = 'noheading' ]; then printf '### Some Other Heading\n\n'
    else printf '### Step 1: Classify the request\n\n'; fi
    printf '| Type | Signal | Action | Example | Command |\n'
    printf '|------|--------|--------|---------|---------|\n'
    printf '| Alpha request | sig | act, and see `/trip-list` for the inventory | ex | `/trip-update` |\n'
    printf '| Beta request | sig | act | ex | `/trip-list` |\n'
    if   [ "$v" = 'dupname' ]; then printf '| Gamma request | sig | act | ex | `/trip-list` |\n'
    elif [ "$v" = 'offenum' ]; then printf '| Gamma request | sig | act | ex | EXCLUDED: because I said so |\n'
    else                            printf '| Gamma request | sig | act | ex | EXCLUDED: lightest-weight-action |\n'; fi
    if [ "$v" = 'dupreason' ]; then printf '| Delta request | sig | act | ex | EXCLUDED: #330-disclosure + #330-disclosure |\n'
    else                            printf '| Delta request | sig | act | ex | EXCLUDED: #330-disclosure + repo-creation |\n'; fi
    [ "$v" = 'emptycell' ] && printf '| Epsilon request | sig | act | ex |  |\n'
    [ "$v" = 'absent' ]    && printf '| Epsilon request | sig | act | ex | `/trip-absent` |\n'
    # A row AND its file, so the bijection still holds and only the naming rule fires.
    [ "$v" = 'badname' ]   && printf '| Zeta request | sig | act | ex | `/other-thing` |\n'
    printf '\n### Step 2: Read context\n'
  } > "$d/CLAUDE.md"
}

mk_cmds() {
  local d="$1" v="${2:-ok}"
  mkdir -p "$d/commands"
  [ "$v" = 'empty' ] && return 0
  # A correct /trip-update. It carries, deliberately, every shape a naive matcher trips on:
  # a path containing the literal token 'publish'; tool-grant lines naming publish/rotate;
  # a NEGATED ALLOW_PLAINTEXT sentence; and a '-y'-containing argument-hint.
  case "$v" in
    rotate)      printf -- '---\ndescription: x\n---\n\n```\n%s rotate trips/x\n```\n' "$SCRIPT_REL" > "$d/commands/trip-update.md" ;;
    nounpubflag) printf -- '---\ndescription: x\n---\n\n```\n%s unpublish trips/x\n```\n' "$SCRIPT_REL" > "$d/commands/trip-update.md" ;;
    varmention)  printf -- '---\ndescription: x\n---\n\nSCRIPT=%s\n' "$SCRIPT_REL" > "$d/commands/trip-update.md" ;;
    allowplain)  printf -- '---\ndescription: x\n---\n\n```\nALLOW_PLAINTEXT=1 %s update trips/x\n```\n' "$SCRIPT_REL" > "$d/commands/trip-update.md" ;;
    badflag)     printf -- '---\ndescription: x\n---\n\n```\n%s update trips/x --passphrase hunter2\n```\n' "$SCRIPT_REL" > "$d/commands/trip-update.md" ;;
    *)
      {
        printf -- '---\ndescription: Update a published site\nargument-hint: [destination-year]\n'
        printf -- 'allowed-tools: Bash(ls:*), Bash(%s update:*)\n' "$SCRIPT_REL"
        printf -- 'disallowed-tools: [Bash(%s publish:*), Bash(%s rotate:*)]\n' "$SCRIPT_REL" "$SCRIPT_REL"
        printf -- '---\n\nTakes an optional `[destination-year]` argument, such as `lisbon-2027`.\n\n'
        printf -- 'Run exactly this, once:\n\n```\n%s update trips/<trip>\n```\n\n' "$SCRIPT_REL"
        printf -- 'This command never runs `%s` in any other form, and never sets `ALLOW_PLAINTEXT`.\n' "$SCRIPT_REL"
      } > "$d/commands/trip-update.md" ;;
  esac
  {
    printf -- '---\ndescription: List published sites\n'
    printf -- 'allowed-tools: Bash(%s list:*)\n' "$SCRIPT_REL"
    printf -- '---\n\n```\n%s list\n```\n' "$SCRIPT_REL"
  } > "$d/commands/trip-list.md"
  [ "$v" = 'ghost' ] && printf -- '---\ndescription: ghost\n---\n' > "$d/commands/trip-ghost.md"
  [ "$v" = 'badname' ] && printf -- '---\ndescription: other\n---\n' > "$d/commands/other-thing.md"
  return 0
}

mk_tree() { mk_md "$1" "${2:-ok}"; mk_cmds "$1" "${3:-ok}"; }

mk_adr() {  # mk_adr <dir> [omit]
  local d="$1" omit="${2:-}"
  mkdir -p "$d"
  {
    printf '### 4. The publish lifecycle\n\n'
    printf '| # | Invocation form | Disposition | Reasons | Command |\n'
    printf '|---|---|---|---|---|\n'
    printf '| 1 | `list` (alias `status`) | ADDRESSED | %s | `/trip-list` |\n' "$EMDASH"
    printf '| 2 | `update` | ADDRESSED | %s | `/trip-update` |\n' "$EMDASH"
    printf '| 3 | `unpublish --disable-pages-only` | ADDRESSED | %s | `/trip-offline` |\n' "$EMDASH"
    printf '| 4 | `publish` | EXCLUDED | `#330-disclosure` + `repo-creation` | %s |\n' "$EMDASH"
    printf '| 5 | `publish --opaque` | EXCLUDED | `#330-disclosure` | %s |\n' "$EMDASH"
    printf '| 6 | `publish --plaintext` | EXCLUDED | `ADR-007 §2` | %s |\n' "$EMDASH"
    [ "$omit" = 'form7' ] || printf '| 7 | `publish --plaintext --opaque` | EXCLUDED | `ADR-007 §2` | %s |\n' "$EMDASH"
    printf '| 8 | `rotate` | EXCLUDED | `#330-disclosure` | %s |\n' "$EMDASH"
    printf '| 9 | `rotate --passphrase` | EXCLUDED | `#330-disclosure` + `argv-secret` | %s |\n' "$EMDASH"
    printf '| 10 | `unpublish` (delete) | EXCLUDED | `ADR-007 §2` | %s |\n' "$EMDASH"
    printf '\n## Consequences\n'
  } > "$d/ADR.md"
}

mk_script() {  # mk_script <path> [extra-arm]
  local p="$1" extra="${2:-}"
  {
    printf 'main() {\n  local sub="${1:-}"; shift || true\n  case "$sub" in\n'
    printf '    publish)     cmd_publish   "$@" ;;\n'
    printf '    update)      cmd_update    "$@" ;;\n'
    printf '    rotate)      cmd_rotate    "$@" ;;\n'
    printf '    list|status) cmd_list      "$@" ;;\n'
    printf '    unpublish)   cmd_unpublish "$@" ;;\n'
    [ -n "$extra" ] && printf '    %s)   cmd_%s "$@" ;;\n' "$extra" "$extra"
    printf '    -h|--help|help|"") usage 0 ;;\n'
    printf '    *) die "unknown subcommand" ;;\n  esac\n}\n'
  } > "$p"
}

# ── G1: the must-NOT-fire arm. It comes FIRST because without it the negative arms below
# prove nothing — a checker hard-wired to `return 1` passes every one of them.
G1="$WORK/g1"; mk_tree "$G1" ok ok
if [ -f "$G1/CLAUDE.md" ] && [ -f "$G1/commands/trip-update.md" ] && [ -f "$G1/commands/trip-list.md" ]; then
  PASS "G1a: fixture integrity — the well-formed control tree was constructed"
  G1OUT="$(taxonomy_check "$G1/CLAUDE.md" "$G1/commands")"; G1RC=$?
  G1F="$(invocation_check "$G1/commands")"; G1FRC=$?
  if [ "$G1RC" -eq 0 ]; then PASS "G1b: MUST-NOT-FIRE — a correct tree returns 0; the guard is not hard-wired red"
  else FAIL "G1b: MUST-NOT-FIRE — a correct tree was flagged (rc=$G1RC): $(printf '%s' "$G1OUT" | grep '^FINDING' | head -2 | tr '\n' ' ')"; fi
  if [ "$G1FRC" -eq 0 ]; then
    PASS "G1c: MUST-NOT-FIRE — a correct /trip-update invoking '$SCRIPT_REL update' PASSES, though its path contains the literal token 'publish' (AI-019)"
    PASS "G1d: MUST-NOT-FIRE — a negated 'never sets \`ALLOW_PLAINTEXT\`' sentence and a '[destination-year]' argument-hint both PASS: the test is USE, not MENTION (AI-013)"
    PASS "G1e: MUST-NOT-FIRE — frontmatter tool-grant lines naming 'publish' and 'rotate' PASS: a grant declaration is not an invocation (AI-019)"
  else
    FAIL "G1c-e: MUST-NOT-FIRE — the invocation limb red-lit correct code: $(printf '%s' "$G1F" | grep '^FINDING' | head -2 | tr '\n' ' ')"
  fi
  if [ "$(getcount "$G1OUT" R_TOTAL)" = "4" ] && [ "$(getcount "$G1OUT" R_ADDRESSED)" = "2" ]; then
    PASS "G1f: extraction properties proven live — 4 rows / 2 ADDRESSED read from a table whose first cells are NOT bolded and whose Action column carries a decoy \`/trip-list\` code span (bold-agnostic + field-indexed)"
  else
    FAIL "G1f: extraction — read $(getcount "$G1OUT" R_TOTAL) rows / $(getcount "$G1OUT" R_ADDRESSED) ADDRESSED from the fixture, expected 4 / 2"
  fi
else
  FAIL "G1a: fixture integrity — the control tree was not constructed; G1b-f would prove nothing"
fi

# ── negative arms over taxonomy_check
tctl() {  # tctl <id> <want> <label> <mdvariant> <cmdvariant> <integrity-probe>
  local id="$1" want="$2" label="$3" mv="$4" cv="$5" probe="$6"
  local d="$WORK/$id"; mk_tree "$d" "$mv" "$cv"
  if ! eval "$probe"; then FAIL "${id}a: fixture integrity — the defect was not introduced; ${id}b would prove nothing"; return; fi
  PASS "${id}a: fixture integrity — the deliberate defect is present in the fixture"
  local out rc; out="$(taxonomy_check "$d/CLAUDE.md" "$d/commands")"; rc=$?
  if [ "$rc" -eq 0 ]; then FAIL "${id}b: the deliberate mismatch was NOT flagged ($label)"
  elif printf '%s\n' "$out" | grep -q "^FINDING $want"; then PASS "${id}b: flagged, naming $want — $label"
  else FAIL "${id}b: flagged but not as $want ($label): $(printf '%s' "$out" | grep '^FINDING' | head -1)"; fi
}

tctl G2 T3 "a command added with no Step-1 row (AC-1)"                       ok        ghost     '[ -f "$WORK/G2/commands/trip-ghost.md" ]'
tctl G3 T1 "a Step-1 row with neither a command nor an exclusion (AC-2)"     emptycell ok        'grep -q "| ex |  |" "$WORK/G3/CLAUDE.md"'
tctl G4 T2 "a Step-1 row naming a command with no file (AC-2, forward)"      absent    ok        'grep -q "trip-absent" "$WORK/G4/CLAUDE.md"'
tctl G5 T5 "an EXCLUDED reason outside the closed 5-value enum (AI-007)"     offenum   ok        'grep -q "because I said so" "$WORK/G5/CLAUDE.md"'
tctl G6 T5 "an EXCLUDED cell carrying the same reason twice (AI-007)"        dupreason ok        'grep -q -- "-disclosure + #330-disclosure" "$WORK/G6/CLAUDE.md"'
tctl G7 T4 "one command name in two ADDRESSED cells (injectivity)"           dupname   ok        '! grep -q "lightest-weight-action" "$WORK/G7/CLAUDE.md"'
tctl G8 T0 "an empty commands directory — a FAIL, not a vacuous pass (AI-006)" ok      empty     '[ -d "$WORK/G8/commands" ] && [ -z "$(ls -A "$WORK/G8/commands")" ]'
tctl G9 T0 "an absent Step-1 slice — a FAIL, not a vacuous pass (AI-006)"    noheading ok        '! grep -q "^### Step 1:" "$WORK/G9/CLAUDE.md"'
# The bijection is INTACT in this fixture — the row and its file both exist — so only the
# beyond-AC naming rule can fire. That isolation is what makes the arm prove N1 specifically.
tctl G17 N1 "a command outside the trip namespace, with its row and file both present" badname badname '[ -f "$WORK/G17/commands/other-thing.md" ] && grep -q "other-thing" "$WORK/G17/CLAUDE.md"'

# ── negative arms over adr4_check (CIAC-6(a))
G10="$WORK/g10"; mk_adr "$G10" form7; mk_script "$G10/pub.sh"; mk_tree "$G10" ok ok
if [ -f "$G10/ADR.md" ] && ! grep -q 'plaintext --opaque' "$G10/ADR.md"; then
  PASS "G10a: fixture integrity — the 'publish --plaintext --opaque' row was omitted from §4"
  if printf '%s\n' "$(adr4_check "$G10/ADR.md" "$G10/pub.sh" 'trip-update trip-list trip-offline')" | grep -q '^FINDING E3'; then
    PASS "G10b: flagged, naming E3 — a deliberately-omitted §4 row breaks the 10-form denominator"
  else FAIL "G10b: an omitted §4 row was NOT flagged as a completeness failure"; fi
else FAIL "G10a: fixture integrity — the §4 omission fixture was not built; G10b would prove nothing"; fi

G11="$WORK/g11"; mk_adr "$G11"; mk_script "$G11/pub.sh" archive
if grep -q 'archive)' "$G11/pub.sh"; then
  PASS "G11a: fixture integrity — a 7th dispatch arm was added to the fixture script"
  if printf '%s\n' "$(adr4_check "$G11/ADR.md" "$G11/pub.sh" 'trip-update trip-list trip-offline')" | grep -q '^FINDING E6'; then
    PASS "G11b: flagged, naming E6 — the staleness sentinel fires on a 7th arm and names the required action"
  else FAIL "G11b: the staleness sentinel did NOT fire on a 7th dispatch arm"; fi
else FAIL "G11a: fixture integrity — the 7th arm was not added; G11b would prove nothing"; fi

# ── negative arms over invocation_check (CIAC-6(b))
fctl() {  # fctl <id> <want> <label> <cmdvariant> <integrity-probe>
  local id="$1" want="$2" label="$3" cv="$4" probe="$5"
  local d="$WORK/$id"; mk_tree "$d" ok "$cv"
  if ! eval "$probe"; then FAIL "${id}a: fixture integrity — the defect was not introduced; ${id}b would prove nothing"; return; fi
  PASS "${id}a: fixture integrity — the deliberate defect is present in the fixture"
  local out rc; out="$(invocation_check "$d/commands")"; rc=$?
  if [ "$rc" -eq 0 ]; then FAIL "${id}b: the deliberate defect was NOT flagged ($label)"
  elif printf '%s\n' "$out" | grep -q "^FINDING $want"; then PASS "${id}b: flagged, naming $want — $label"
  else FAIL "${id}b: flagged but not as $want ($label): $(printf '%s' "$out" | grep '^FINDING' | head -1)"; fi
}

fctl G12 F1 "a command file invoking the EXCLUDED form 'rotate'"                  rotate      'grep -q "publish-trip-site.sh rotate" "$WORK/G12/commands/trip-update.md"'
fctl G13 F2 "an unpublish invocation lacking --disable-pages-only"                nounpubflag 'grep -q "unpublish trips/x" "$WORK/G13/commands/trip-update.md"'
fctl G14 F5 "an unresolvable script mention (reached through a variable)"         varmention  'grep -q "SCRIPT=scripts" "$WORK/G14/commands/trip-update.md"'
fctl G15 F4 "a command file that SETS ALLOW_PLAINTEXT, not merely names it"       allowplain  'grep -q "ALLOW_PLAINTEXT=1" "$WORK/G15/commands/trip-update.md"'
fctl G16 F3 "a forbidden flag passed on a publish-script invocation"              badflag     'grep -q -- "--passphrase hunter2" "$WORK/G16/commands/trip-update.md"'

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
