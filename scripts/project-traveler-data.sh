#!/usr/bin/env bash
#
# project-traveler-data.sh — the traveller projection: a trip's traveller data with every
# line a non-publishable `field` row labels left out.
#
# THE SAFEGUARD. ADR-030 § 6 safeguard 7: no dispatched agent that writes a file the site
# build reads receives a passport or documents value. `/trip` runs this script and puts its
# stdout inline in the dispatch prompt of each agent the test in CLAUDE.md § *Dispatching
# agents* admits, so that agent is GIVEN its traveller data with those lines taken out, and
# no file is written anywhere. This script writes nothing.
#
# It is a LIBRARY FIRST and a CLI second, the shape scripts/check-round-trip.sh ships:
# sourcing exposes the pj_* functions without running the dispatch, so
# scripts/test-artifact-schema.sh (group PJ) drives THE SAME functions the verb runs.
#
#   ./scripts/project-traveler-data.sh --data-root <dir> --trip <slug>
#
# ── TWO ROOTS, AND WHY ONLY ONE IS A FLAG ────────────────────────────────────────
# The ENGINE root holds the declaration, reference/data-architecture.md § 5.6, and is this
# script's own parent directory, taken from BASH_SOURCE. It is NOT a flag: the omit set is a
# privacy class, and a flag would let the class be read from a declaration that is not the
# engine's own. `--data-root` roots the POPULATION, the tree whose trips/<slug>/ is read, and
# it is required: the script never resolves a data root itself and reads no pointer file.
#
# ── WHAT IS READ, IN ORDER ───────────────────────────────────────────────────────
#   1. the `publish-contract-values` fence of reference/data-architecture.md § 5.6, for the
#      union of its `field` selectors, whatever each row's artifact scope;
#   2. trips/<slug>/outputs/traveler-model.md where it exists; otherwise every
#      trips/<slug>/travelers/*.md, each under a header naming it.
# Nothing else is opened.
#
# ── THE OMIT RULE ────────────────────────────────────────────────────────────────
# SCOPE-BLIND, on purpose: every `field` selector is applied to every input file. ADR-030
# § 5 says an OUT value stays out wherever it is carried, and omitting more than the publish
# guard's four literal (limb, scope) pairs is the fail-safe direction for what an agent sees.
#
# A LINE IS A HIT, and is omitted, when its STRIPPED text begins with a selector,
# case-insensitively, optionally followed by a plural `s`, and then by a character that is
# not a letter, or by the end of the line. No trailing `:` is required, so `Passport
# number:`, `Passports held:` and `Passport-country note` are all hits. STRIPPED means:
# leading blockquote markers, whitespace, one list marker, then any run of emphasis
# characters, heading marks (`#`), bracketed marks and `<!--` comment openers, taken off the
# front. A table row is a hit when any one of its cells, stripped the same way, begins with a
# selector. Every test reads the line with a trailing carriage return taken off, a byte-order
# mark taken off the first line, and each no-break space read as a space; what is printed is
# the line as read. The comparison is a substring test, never a regex built from a selector:
# a selector is corpus text, and one carrying a regex metacharacter must not silently become
# a pattern.
#
# WHAT A HIT TAKES WITH IT depends on the markdown shape it sits in:
#   a HEADING — `#` to `######`, or a hit line underlined with `===` or `---` — takes its
#     whole section, up to the next heading of the same or a higher level;
#   a TABLE ROW takes itself, and where it is the header row above a `|---|` delimiter row
#     it takes the whole table;
#   any other hit takes every following line until one of these ends it: a list item at the
#     label's own indent or shallower; a heading no deeper than the label; a blank line, but
#     only when the next line that is not blank is no deeper than the label, so a loose
#     sub-item past a blank line goes too; the closing delimiter of a fenced block the label
#     sits inside; and, in the frontmatter, its closing `---`, so every key after a selector
#     key goes with it. So a deeper-indented line goes (a wrapped value, a nested sub-list, a
#     heading nested in the payload, a fenced block it opens, which goes whole), and so does a
#     line no deeper that is not a list item (markdown's lazy continuation). A selector line
#     found inside the payload is taken with it and never raises the indent the payload ends
#     at: it can lower it, so a shallower selector line's own sub-items go too.
# This is WIDER than the publish guard's continuation limb, and a slightly over-broad
# omission is the accepted cost: a heading's section goes whole, kept lines in it included.
#
# KEPT, verbatim: everything else — the frontmatter, so the tolerant-read rule still
# applies; every `entry`-limb entry, `[THIRD-PARTY]` included, with its marks, because the
# hub applies a third-party need as a hard bound. An entry mark is non-publishable because
# its subject could not consent, not because it is identification data, and ADR-006 holds
# its non-publication at every writer. A selector line inside such an entry is still omitted.
#
# ── THE EXIT CODES ───────────────────────────────────────────────────────────────
#   0  projected: one header line naming the source and the omitted selectors, then the
#      projected text.
#   2  UNDETERMINED, and stdout is EMPTY: the output is buffered and printed only at the
#      end, so nothing partial is ever passed on. One `PJ0: <cause>` line goes to stderr.
#      Every cause below is fail-closed:
#        the declaration is unreadable; the fence yields zero rows; a fence row is not four
#        fields; a row's limb is outside field/entry; ZERO `field` rows (an empty omit set is
#        indistinguishable from a field limb that failed to read — data-architecture § 5.4,
#        "an empty read is not an empty class"); the trip directory is missing; a source
#        exists but is not a readable, non-empty file; travelers/ exists but cannot be read;
#        a flag is missing, unknown or empty.
#   3  NO SOURCE on file — no traveller model and no travelers/*.md. One header line saying
#      so, and nothing else. A legal state the ideation agent already degrades on.
# `/trip` dispatches only on 0 or 3. On anything else, a status of 127 and a refused run
# included, it dispatches nothing and never passes a source file in the projection's place.
#
# ── WHAT THIS DOES NOT DO, STATED PLAINLY ────────────────────────────────────────
# It decides what an agent is GIVEN, never what the agent OPENS. A dispatched agent keeps
# `Read`, and nothing here takes it away: that it opens none of these files itself is a
# rule its prompt, its dispatch line and CLAUDE.md state — FOLLOWED, NOT ENFORCED. It reads
# labels, not values, so three shapes still pass it: a label behind an emoji, a homoglyph or
# any other non-ASCII character but a no-break space; a value written as prose under some
# other label; and a camel-case key such as `passportNumber:`, which the whole-word rule
# keeps. It does not cover trips/<slug>/trip-context.md or trip-log.md, which no § 5.6 row
# scopes.
#
# ── THE LIFTED FENCE READER, AND ITS DEBT ────────────────────────────────────────
# pj_fence_block is the repository's fenced-block reader, lifted from
# scripts/test-trip-resolution-contract.sh by way of scripts/publish-trip-site.sh's own lift,
# with the same explicit `return 0`. This is the THIRD copy. It is lifted rather than sourced
# because `/trip` never reaches scripts/publish-trip-site.sh through any wrapper (its standing
# clause), and a second label matcher beside the guard's is held to agreement by the suite's
# PJ arms rather than by shared code. Both are debt, named here as the guard names its own.
#
# Bash 3.2 and POSIX awk, every awk under LC_ALL=C: the label match lowercases ASCII only,
# and a selector is ASCII.

set -uo pipefail

PJ_DECL_REL='reference/data-architecture.md'
PJ_DECL_HEADING='### 5.6 The declaration'
PJ_DECL_FENCE='publish-contract-values'
PJ_MODEL_REL='outputs/traveler-model.md'
PJ_PROFILES_REL='travelers'

# Lines of the first fenced block carrying <info> inside the section headed <heading>,
# emitted verbatim. The lift named above; the algorithm is unchanged.
pj_fence_block() {  # pj_fence_block <file> <info> <heading>
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
  return 0
}

# The union of the declaration's `field` selectors, one per line, de-duplicated in first-seen
# order. Any degenerate read returns 2, prints nothing on stdout and names its cause on
# stderr; the zero-`field`-rows cause has its own token, `PJ0: zero field rows`, so a control
# can tell "refused for the reason under test" from "broke".
pj_selectors() {   # pj_selectors <declaration-file>
  local decl="${1:-}" rows out rc
  if [ -z "$decl" ] || [ ! -f "$decl" ] || [ ! -r "$decl" ]; then
    printf 'PJ0: the declaration is unreadable\n' >&2
    return 2
  fi
  rows="$(pj_fence_block "$decl" "$PJ_DECL_FENCE" "$PJ_DECL_HEADING")"
  out="$(LC_ALL=C awk '
    { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") }
    $0 == "" || substr($0, 1, 1) == "#" { next }
    { rows++ }
    NF != 4 { bad = 1; next }
    $1 != "field" && $1 != "entry" { limb = 1; next }
    $1 == "field" { fields++; if (!seen[$2]++) sel[++n] = $2 }
    END {
      if (rows == 0) exit 3
      if (bad) exit 4
      if (limb) exit 5
      if (fields == 0) exit 6
      for (i = 1; i <= n; i++) print sel[i]
    }' <<<"$rows")"
  rc=$?
  case "$rc" in
    0) ;;
    3) printf 'PJ0: the fence yields zero rows\n' >&2; return 2 ;;
    4) printf 'PJ0: a fence row is not four fields\n' >&2; return 2 ;;
    5) printf 'PJ0: a fence row names a limb outside field and entry\n' >&2; return 2 ;;
    6) printf 'PJ0: zero field rows\n' >&2; return 2 ;;
    *) printf 'PJ0: the fence could not be read (awk exit %s)\n' "$rc" >&2; return 2 ;;
  esac
  if [ -z "$out" ]; then
    printf 'PJ0: zero field rows\n' >&2
    return 2
  fi
  printf '%s\n' "$out"
  return 0
}

# One file, projected: every line the omit rule above takes is left out, every other line is
# printed verbatim. <selectors> is pj_selectors' output, one per line. An empty selector set
# is refused, never read as "omit nothing".
pj_project_file() {   # pj_project_file <selectors> <file>
  local sel="${1:-}" f="${2:-}"
  if [ -z "$sel" ]; then
    printf 'PJ0: no selector was given, so nothing would be omitted\n' >&2
    return 2
  fi
  if [ -z "$f" ] || [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf 'PJ0: a source is not a readable file\n' >&2
    return 2
  fi
  PJ_SEL="$sel" LC_ALL=C awk '
    BEGIN {
      k = split(ENVIRON["PJ_SEL"], raw, "\n")
      for (i = 1; i <= k; i++) if (raw[i] != "") sel[++m] = tolower(raw[i])
      if (m == 0) exit 2
      NB = "\302\240"; BOM = "\357\273\277"
    }
    # The line every test reads: a trailing carriage return off, a byte-order mark off the
    # first line, and each no-break space read as a space. What is printed is $0, as read.
    function norm(s,   i) {
      sub(/\r$/, "", s)
      if (NR == 1 && substr(s, 1, 3) == BOM) s = substr(s, 4)
      while ((i = index(s, NB)) > 0) s = substr(s, 1, i - 1) " " substr(s, i + 2)
      return s
    }
    # The line with any blockquote markers taken off its front.
    function unquote(s) {
      while (match(s, /^[ \t]*>/)) { s = substr(s, RLENGTH + 1); sub(/^ /, "", s) }
      return s
    }
    # Indent width of an unquoted line; a tab advances to the next multiple of four.
    function width(s,   i, c, w) {
      w = 0
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == " ") w++
        else if (c == "\t") w = w + 4 - (w % 4)
        else break
      }
      return w
    }
    function blank(s) { return s ~ /^[ \t]*$/ }
    function item(s) { return s ~ /^[ \t]*([-*+]|[0-9]+[.)])([ \t]|$)/ }
    # The level of a `#` heading, 0 for any other line.
    function hlevel(s) {
      if (!match(s, /^[ \t]*#+([ \t]|$)/)) return 0
      s = substr(s, 1, RLENGTH); gsub(/[^#]/, "", s)
      return length(s)
    }
    # A setext underline: a run of `=` or of `-` alone on its line.
    function setext(s) { return s ~ /^[ \t]*(=+|-+)[ \t]*$/ }
    # The first three characters after the indent, for the fence tests.
    function lead(s) { sub(/^[ \t]+/, "", s); return substr(s, 1, 3) }
    # A table delimiter row, such as |---|:--:|.
    function delimrow(s) { return s ~ /^[ \t]*[|: \t-]+$/ && index(s, "|") && index(s, "-") }
    function cut(s) {
      sub(/^[ \t]+/, "", s)
      if (match(s, /^([-*+]|[0-9]+[.)])([ \t]+|$)/)) s = substr(s, RLENGTH + 1)
      while (1) {
        if (match(s, /^[*_`~# \t]+/)) { s = substr(s, RLENGTH + 1); continue }
        if (match(s, /^\[[^]]*\]/)) { s = substr(s, RLENGTH + 1); continue }
        if (substr(s, 1, 4) == "<!--") { s = substr(s, 5); continue }
        break
      }
      return s
    }
    function opens(t,   i, n, c) {
      t = tolower(t)
      for (i = 1; i <= m; i++) {
        n = length(sel[i])
        if (substr(t, 1, n) != sel[i]) continue
        c = substr(t, n + 1, 1)
        if (c == "s") c = substr(t, n + 2, 1)
        if (c == "" || c !~ /[a-z]/) return 1
      }
      return 0
    }
    # A hit: the stripped line opens with a selector, or, where it holds a `|`, a cell does.
    function label(u,   s, k, i, cell) {
      if (opens(cut(u))) return 1
      if (!index(u, "|")) return 0
      s = u; gsub(/\\\|/, "", s)
      k = split(s, cell, "|")
      for (i = 1; i <= k; i++) if (opens(cut(cell[i]))) return 1
      return 0
    }
    {
      t = norm($0); u = unquote(t)
      infm = fm; inf = fence; opened = 0; closed = 0
      if (NR == 1 && t == "---") fm = 1
      else if (fm) { if (t == "---") fm = 0 }
      else if (!fence && (lead(u) == "```" || lead(u) == "~~~")) { fence = 1; fch = lead(u); opened = 1 }
      else if (fence && lead(u) == fch) { fence = 0; closed = 1 }
      # A fenced block opened inside a payload is literal text: it goes whole, closer included.
      if (payf) { if (closed) payf = 0; next }
      # Blank lines inside a payload wait for the next line that is not blank: deeper, and
      # the payload goes on past them; no deeper, and they ended it.
      if (pend) {
        if (blank(u)) { pbuf = pbuf $0 "\n"; next }
        pend = 0
        if (width(u) > at) pbuf = ""
        else { printf "%s", pbuf; pbuf = ""; taking = 0 }
      }
      # A table: after a header-row hit its delimiter row and every row below it go.
      if (tbl) { if (!blank(u) && index(u, "|")) next; tbl = 0 }
      if (thd) { thd = 0; if (delimrow(u)) { tbl = 1; next } }
      # A heading hit: its section, up to a heading of the same or a higher level.
      if (taking == 2) {
        lv = hlevel(u)
        if (inf || infm || lv == 0 || lv > lvl || width(u) > 3) next
        taking = 0
      }
      if (taking == 1) {
        first = fst; fst = 0
        if (infm && t == "---") taking = 0
        else if (hitf && closed) taking = 0
        else if (blank(u)) { pend = 1; pbuf = $0 "\n"; next }
        else if (first && plain && setext(u)) { taking = 2; lvl = index(u, "=") ? 1 : 2; next }
        else if (!inf && !infm && hlevel(u) > 0 && width(u) <= at) taking = 0
        else if (label(u)) { w = width(u); if (w < at) at = w; if (opened) payf = 1; next }
        else if (infm || width(u) > at || !item(u)) { if (opened) payf = 1; next }
        else taking = 0
      }
      if (label(u)) {
        if (!inf && !infm && hlevel(u) > 0) { taking = 2; lvl = hlevel(u); next }
        if (!inf && !infm && u ~ /^[ \t]*\|/) { thd = 1; next }
        taking = 1; at = width(u); hitf = inf; plain = !inf && !infm && !item(u); fst = 1
        if (opened) payf = 1
        next
      }
      print
    }
    END { if (pend) printf "%s", pbuf }' "$f"
}

# A trip's projection: the source choice, the header, and the buffered output. Prints
# nothing on stdout unless it returns 0 or 3.
pj_project_trip() {   # pj_project_trip <declaration-file> <trip-dir>
  local decl="${1:-}" trip="${2:-}" sel rc part buf="" n=0 f dir names src
  sel="$(pj_selectors "$decl")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    return 2
  fi
  if [ -z "$sel" ]; then
    printf 'PJ0: zero field rows\n' >&2
    return 2
  fi
  names="$(LC_ALL=C awk 'NF { printf "%s%s", (n++ ? "," : ""), $0 }' <<<"$sel")"
  if [ -z "$trip" ] || [ ! -d "$trip" ]; then
    printf 'PJ0: the trip directory does not exist\n' >&2
    return 2
  fi
  f="$trip/$PJ_MODEL_REL"
  if [ -e "$f" ] || [ -L "$f" ]; then
    if [ ! -f "$f" ] || [ ! -r "$f" ] || [ ! -s "$f" ]; then
      printf 'PJ0: the traveller model exists but is not a readable, non-empty file\n' >&2
      return 2
    fi
    part="$(pj_project_file "$sel" "$f")"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      return 2
    fi
    printf '<!-- projection: source=%s; omitted: every line labelled %s; generated by scripts/project-traveler-data.sh -->\n%s\n' \
      "$PJ_MODEL_REL" "$names" "$part"
    return 0
  fi
  dir="$trip/$PJ_PROFILES_REL"
  if [ -e "$dir" ] || [ -L "$dir" ]; then
    if [ ! -d "$dir" ] || [ ! -r "$dir" ] || [ ! -x "$dir" ]; then
      printf 'PJ0: %s/ exists but cannot be read\n' "$PJ_PROFILES_REL" >&2
      return 2
    fi
    for f in "$dir"/*.md; do
      if [ ! -e "$f" ] && [ ! -L "$f" ]; then
        continue
      fi
      if [ ! -f "$f" ] || [ ! -r "$f" ] || [ ! -s "$f" ]; then
        printf 'PJ0: a traveller file exists but is not a readable, non-empty file\n' >&2
        return 2
      fi
      part="$(pj_project_file "$sel" "$f")"
      rc=$?
      if [ "$rc" -ne 0 ]; then
        return 2
      fi
      buf="$buf<!-- projection of $PJ_PROFILES_REL/${f##*/} -->
$part
"
      n=$((n + 1))
    done
  fi
  if [ "$n" -eq 0 ]; then
    printf '<!-- projection: source=none; no traveller model and no traveller file is on file; generated by scripts/project-traveler-data.sh -->\n'
    return 3
  fi
  src="$PJ_PROFILES_REL/*.md (no traveller model on file)"
  printf '<!-- projection: source=%s; omitted: every line labelled %s; generated by scripts/project-traveler-data.sh -->\n%s' \
    "$src" "$names" "$buf"
  return 0
}

pj_usage() {
  cat <<'USAGE'
project-traveler-data.sh — the traveller projection (ADR-030 § 6 safeguard 7)

  project-traveler-data.sh --data-root <dir> --trip <slug>

  --data-root  the TRIP root: the tree whose trips/<slug>/ is read (required)
  --trip       the resolved trip slug (required)

The declaration is read from this script's own engine root, never from a flag.
Exit 0 projected, 2 undetermined (stdout empty), 3 no traveller source on file.
USAGE
}

pj_main() {
  local data_root="" slug="" root out rc
  while [ $# -gt 0 ]; do
    case "$1" in
      --data-root|--trip)
        if [ $# -lt 2 ] || [ -z "$2" ]; then
          printf 'PJ0: the flag %s takes a value and none was given\n' "$1" >&2
          pj_usage >&2
          return 2
        fi
        if [ "$1" = "--trip" ]; then slug="$2"; else data_root="$2"; fi
        shift 2
        ;;
      -h|--help) pj_usage >&2; return 2 ;;   # 2, not 0: exit 0 means a projection was printed
      *) printf 'PJ0: unknown argument: %s\n' "$1" >&2; pj_usage >&2; return 2 ;;
    esac
  done
  if [ -z "$data_root" ] || [ -z "$slug" ]; then
    printf 'PJ0: --data-root and --trip are both required\n' >&2
    pj_usage >&2
    return 2
  fi
  case "$slug" in
    .|..|*/*|-*) printf 'PJ0: the trip slug is not a single path segment\n' >&2; return 2 ;;
  esac
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  out="$(pj_project_trip "$root/$PJ_DECL_REL" "$data_root/trips/$slug")"
  rc=$?
  case "$rc" in
    0|3) printf '%s\n' "$out"; return "$rc" ;;
    *) return 2 ;;
  esac
}

# Run only when executed directly; sourcing (the suite) exposes the functions without
# dispatch. Same shape as scripts/check-round-trip.sh and scripts/validate-artifacts.sh.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  pj_main "$@"
fi
