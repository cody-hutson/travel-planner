#!/usr/bin/env bash
#
# check-round-trip.sh — the round-trip completeness walker.
#
# Executes the walk reference/site-layout-spec.md § 9.4 prescribes: every element of a
# trip's outputs/final-itinerary.md — every day, and every track of a split day — resolves
# to a rendered component or to a named exclusion, so a patch never silently drops plan
# detail. Until this file existed that rule was stated in three places and executed in
# none, and the obligation was discharged by whoever happened to be reading the prose.
#
# It is a LIBRARY FIRST and a CLI second, the shape scripts/validate-artifacts.sh already
# ships and scripts/test-artifact-schema.sh already sources: sourcing exposes the rt_*
# functions without running the dispatch, so the suite drives THE SAME functions the verb
# drives. A control arm running different code from the assertion proves nothing about the
# assertion.
#
#   ./scripts/check-round-trip.sh [--root <dir>] --contract-only
#   ./scripts/check-round-trip.sh [--root <dir>] [--data-root <dir>] --trip <slug>
#   ./scripts/check-round-trip.sh [--root <dir>] --plan <path> --site <path>
#
# ── THE WALK HAS TWO HALVES AND ONLY ONE OF THEM HAS A CI POPULATION ─────────────
# This is the whole shape of the file and it is stated first because a gate that conflates
# the two claims more than it grades.
#
#   THE CONTRACT HALF (--contract-only). Every element TYPE the itinerary grammar can emit
#   carries a declared disposition, rendered or excluded, and every declared disposition
#   names an element the grammar still emits. Real population, tracked tree, graded in CI
#   on every push. Codes RT1 / RT2, with RT0 guarding the instrument.
#
#   THE INSTANCE HALF (--trip, --plan/--site). For a given plan and the site built from it,
#   every element INSTANCE resolves to its component, per day and per track. Codes RT3-RT6.
#   ITS REAL POPULATION IN CI IS EMPTY AND CAN NEVER BE NON-EMPTY. .gitignore carries
#   `trips/*`, so no CI checkout holds a render; and reference/schemas/travel-site.md
#   carries a no-witness clause it calls terminal rather than pending, naming a committed
#   site fixture as "exactly the wrong repair". So the instance half runs HERE, at the verb,
#   on the operator's real trip — and in CI only over synthetic pairs the suite builds.
#
# ── TWO ROOTS, AND WHY ONE FLAG CANNOT CARRY BOTH ────────────────────────────────
# `--root` roots the ENGINE: agents/05-hub-planner.md, which owns the itinerary grammar,
# and reference/site-layout-spec.md, which owns the contract fence and the component
# catalog. Those are engine assets and follow this script wherever it is installed.
# `--data-root` roots the POPULATION: the trip tree whose plan and site are read. They are
# the same directory in this checkout and they diverge the moment the engine is installed,
# because operator trips live wherever the operator keeps them. scripts/validate-artifacts.sh
# and scripts/publish-trip-site.sh each already state this seam for their own reasons; this
# script has the same two roots to name and names them the same way.
#
# ── THE FINDING CODES ────────────────────────────────────────────────────────────
#   RT0  DEGRADED READ, and the vacuity guard. The plan or the site is unreadable, the
#        grammar region does not resolve, the contract fence does not resolve or resolves
#        at more than one site, a fence row is malformed, a disposition is outside the
#        closed enum, a rendered row names a component the catalog does not define, or the
#        element extraction returned ZERO ROWS. A zero-row extraction is a broken
#        instrument and is never a clean read — that distinction is the reason this code
#        exists and it is the first thing every arm asks.
#   RT1  a grammar element label has NO fence row — neither rendered nor excluded. THE
#        ADDITION CASE: an element added to the grammar with no declared disposition.
#   RT2  a fence row names a label the grammar NO LONGER EMITS. The pin's other direction.
#        RT1 and RT2 together are what make the fence a pin rather than an allowlist: an
#        undeclared element fails, AND a declaration whose element no longer exists fails.
#   RT3  a `rendered` element INSTANCE has no component in the site — the silent drop this
#        contract exists to forbid. A day with no rendered day body is the same finding
#        one level up.
#   RT4  a split-day TRACK has no labeled track column of its own. § 9.2 names this as the
#        sharpest test of the rule and § 9.4 names it as the most common silent drop: a
#        patch that touches the first track and leaves the second behind.
#   RT5  a rendered event carries NO `.map-link` — the location invariant § 3's Map-Link
#        Component declares of every event card.
#   RT6  the nightlife band's content — a night card, or the stated `No nightlife tonight`
#        line — resolves to nothing. A stated decline and a dropped subgroup must not look
#        alike on the page.
#
# ── WHAT THIS WALK ESTABLISHES, AND WHAT IT CANNOT ───────────────────────────────
# Declared here rather than left to be inferred from a green, because an unstated limit is
# how a gate comes to claim more than it grades.
#
# IT ESTABLISHES: that every element type the grammar can emit carries a declared
# disposition, both directions, on the real tree; and that for a given (plan, site) pair
# every rendered element instance resolves to its component, per day and per track.
#
# IT CANNOT ESTABLISH that the site it read is the site the verb WROTE. The trip tree is
# git-ignored and carries no history, so this walk grades the artifact after the write and
# never the act. Nor can any inspection of any tree establish that a given run INVOKED this
# walker at all: the suite grades that the verb DECLARES the invocation, and no further.
# That residual is real, it is not closable from the tree, and it rides on every suite run
# as its own reported line rather than sitting in this comment.
#
# ── § 9.5 IS HONOURED, NOT ABSORBED ──────────────────────────────────────────────
# An element type with no POSSIBLE rendered home is reported as RT1 — a named finding
# routed to a fast-follow. This walker never demands that a component be built, and growing
# the contract to absorb a structural gap is exactly what § 9.5 forbids.
#
# Bash and awk only. No Node, no network, no gh. Exit 0 clean, 1 findings, 2 degraded read.
#
set -uo pipefail

RT_FENCE_TAG='round-trip-contract-elements'
RT_GRAMMAR_REL='agents/05-hub-planner.md'
RT_SPEC_REL='reference/site-layout-spec.md'
RT_GRAMMAR_HEADING='### File: outputs/final-itinerary.md'
RT_TAB="$(printf '\t')"

# Every finding leaves the process through here, so `FINDING <CODE> ` has one producer and
# the suite's census has one shape to read. The CODE is a literal at every CALL SITE, which
# is what lets the inventory arm derive the emittable set from the sourced function bodies
# rather than from this file's text — a comment naming a code cannot enter a set read out of
# `declare -f`, because bash discards comments when it stores a function.
rt_finding() { printf 'FINDING %s %s\n' "$1" "$2"; }

# ── THE INSTRUMENT: the itinerary grammar's element labels ───────────────────────
#
# THE EXTRACTOR IS THE INSTRUMENT AND IT IS GRADED AS ONE. Scoped to the grammar region,
# fenced blocks removed, and keyed on WHOLE-LINE bold: the whole line is a bold run,
# optionally followed by one italic parenthetical. Both halves of that are load-bearing and
# both were measured on this corpus rather than predicted.
#
#   THE SCOPE does real work: the same reader run unscoped over the whole prompt returns
#   twice the rows, so an unscoped extractor would carry the prompt's ordinary bold prose
#   into the contract comparison.
#
#   THE WHOLE-LINE TEST is what separates a LABEL from a bold LEAD-IN. This region carries
#   bold rationale sentences — a bolded lead-in followed by ordinary prose on the same line
#   — and a line-leading-bold reader returns them as element labels. It also MISSES the two
#   longest real labels, the day header and the Parallel Track block, if it bounds the run's
#   length to keep those sentences out. Whole-line keeps every real label including the long
#   ones and drops every lead-in, because a lead-in by definition has prose after it.
#
# A zero-row extraction is RT0 and fails closed. It is never a clean read: an assertion over
# an empty label set is vacuously true, never skipped, and silently green.
rt_grammar_labels() {   # rt_grammar_labels <prompt-file> [heading] -> one label per line
  local f="$1" h="${2:-$RT_GRAMMAR_HEADING}"
  [ -r "$f" ] || return 1
  awk -v want="$h" '
    index($0, want) == 1 && length($0) == length(want) { inreg = 1; next }
    inreg && (/^### / || /^## /) { inreg = 0 }
    !inreg { next }
    /^[[:space:]]*```/ { infence = !infence; next }
    infence { next }
    {
      line = $0
      sub(/[[:space:]]+$/, "", line)
      # whole line is **…**, optionally followed by one *(…)* parenthetical
      if (line ~ /^\*\*.+\*\*$/) {
        lab = substr(line, 3, length(line) - 4)
      } else if (line ~ /^\*\*.+\*\*[[:space:]]+\*\([^)]*\)\*$/) {
        p = index(line, "**")
        rest = substr(line, 3)
        q = index(rest, "**")
        lab = substr(rest, 1, q - 1)
      } else {
        next
      }
      if (lab == "") next
      if (index(lab, "**") > 0) next
      print lab
    }' "$f"
}

# ── THE CONTRACT FENCE ───────────────────────────────────────────────────────────
#
# Columns are separated by TWO OR MORE spaces and that is a parsing requirement rather than
# a formatting preference: an element label carries single spaces of its own, so the
# single-space split the sibling `publish-contract-artifacts` fence can use would cut
# `Food Anchors` in half. The sibling's values are path-shaped and have no interior space;
# this one's are prose labels and do. Same document, same shape, one honest difference.
#
# A malformed row is emitted as a `!` record rather than dropped. A dropped row is a row the
# comparison never sees, which is how a fence quietly stops declaring something.
rt_fence_rows() {   # rt_fence_rows <spec-file> [tag] -> "<label>\t<disposition>\t<component>"
  local f="$1" tag="${2:-$RT_FENCE_TAG}"
  [ -r "$f" ] || return 1
  awk -v open='```'"$tag" '
    $0 == open { inside = 1; next }
    inside && $0 == "```" { inside = 0; next }
    !inside { next }
    {
      line = $0
      sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      n = split(line, F, /[[:space:]][[:space:]]+/)
      if (n < 3) { printf "!\tmalformed\t%s\n", line; next }
      printf "%s\t%s\t%s\n", F[1], F[2], F[3]
    }' "$f"
}

# How many times the fence opens in the document. More than one home for one declaration is
# two sources able to disagree, so it is RT0 rather than a preference.
rt_fence_sites() {   # rt_fence_sites <spec-file> [tag] -> count
  local f="$1" tag="${2:-$RT_FENCE_TAG}"
  [ -r "$f" ] || { printf '0'; return 1; }
  awk -v open='```'"$tag" '$0 == open { n++ } END { printf "%d", n+0 }' "$f"
}

# ── THE COMPONENT CATALOG, DERIVED AND NEVER HELD ────────────────────────────────
# The vocabulary a `rendered` row's component must be a member of, read from § 3 on every
# run: each component's own backticked class token, plus the slug of each component
# heading. THIS FILE HOLDS NO COPY. A component renamed in the catalog turns the fence row
# that names it red, which is the whole reason the set is read rather than listed.
rt_components() {   # rt_components <spec-file> -> one token per line
  local f="$1"
  [ -r "$f" ] || return 1
  awk '
    /^## 3\./ { insec = 1; next }
    insec && /^## / { insec = 0 }
    !insec { next }
    {
      line = $0
      if (line ~ /^### /) {
        h = substr(line, 5)
        gsub(/\(`[^`]*`\)/, "", h)
        h = tolower(h)
        gsub(/[^a-z0-9]+/, "-", h)
        sub(/^-+/, "", h); sub(/-+$/, "", h)
        if (h != "") print h
      }
      rest = line
      while (match(rest, /`\.[a-z0-9][a-z0-9-]*`/)) {
        tok = substr(rest, RSTART + 2, RLENGTH - 3)
        print tok
        rest = substr(rest, RSTART + RLENGTH)
      }
    }' "$f"
}

# ── THE CONTRACT WALK — RT0 / RT1 / RT2 ──────────────────────────────────────────
#
# The instrument is graded BEFORE anything it feeds. Every verdict below is vacuous without
# it, so the order is not cosmetic: a fence that did not resolve makes both set-differences
# empty and both directions pass against nothing — a probe failure wearing a clean bill.
rt_contract_walk() {   # rt_contract_walk <engine-root> [grammar-rel] [spec-rel]
  local root="$1"
  local gfile="$root/${2:-$RT_GRAMMAR_REL}"
  local sfile="$root/${3:-$RT_SPEC_REL}"
  local rc=0 labels rows comps sites n_lab n_row n_bad

  if [ ! -r "$gfile" ]; then
    rt_finding RT0 "the itinerary grammar is unreadable at '$gfile' — nothing was compared, and a green here would be a statement about a file that was never opened"
    return 2
  fi
  if [ ! -r "$sfile" ]; then
    rt_finding RT0 "the site-layout spec is unreadable at '$sfile' — the contract fence has no home to resolve from"
    return 2
  fi

  sites="$(rt_fence_sites "$sfile")"
  if [ "$sites" != "1" ]; then
    rt_finding RT0 "the '$RT_FENCE_TAG' fence opens $sites time(s) in $sfile, expected exactly one — a declaration with two homes is two sources able to disagree, and with none there is nothing to compare against"
    return 2
  fi

  labels="$(rt_grammar_labels "$gfile")"
  n_lab="$(printf '%s\n' "$labels" | grep -c '[^[:space:]]')"
  if [ "$n_lab" -eq 0 ]; then
    rt_finding RT0 "the element extraction returned ZERO rows from $gfile — the instrument is broken, not the corpus clean. Every comparison below would be vacuously true over an empty set"
    return 2
  fi

  rows="$(rt_fence_rows "$sfile")"
  n_row="$(printf '%s\n' "$rows" | grep -c '[^[:space:]]')"
  if [ "$n_row" -eq 0 ]; then
    rt_finding RT0 "the '$RT_FENCE_TAG' fence in $sfile parsed to ZERO rows — the contract did not resolve"
    return 2
  fi

  n_bad="$(awk -F"$RT_TAB" '$1 == "!" { n++ } END { print n+0 }' <<<"$rows")"
  if [ "$n_bad" -gt 0 ]; then
    while IFS="$RT_TAB" read -r c1 _ c3; do
      [ "$c1" = "!" ] && rt_finding RT0 "a fence row does not carry three whitespace-separated columns: '$c3'"
    done <<<"$rows"
    rc=2
  fi

  # The closed disposition enum, and the component-catalog membership of every rendered row.
  comps="$(rt_components "$sfile")"
  while IFS="$RT_TAB" read -r lab disp comp; do
    [ -n "$lab" ] || continue
    [ "$lab" = "!" ] && continue
    case "$disp" in
      rendered|excluded) ;;
      *) rt_finding RT0 "fence row '$lab' declares disposition '$disp', which is outside the closed enum {rendered, excluded} — the contract cannot be resolved for that element"; rc=2; continue ;;
    esac
    [ "$disp" = "rendered" ] || continue
    local part ok=1
    while IFS= read -r part; do
      [ -n "$part" ] || continue
      grep -qxF -- "$part" <<<"$comps" || { ok=0; break; }
    done <<<"$(tr '|' '\n' <<<"$comp")"
    if [ "$ok" -ne 1 ]; then
      rt_finding RT0 "fence row '$lab' names component '$comp', which the § 3 component catalog does not define — the row declares a rendered home that does not exist"
      rc=2
    fi
  done <<<"$rows"
  [ "$rc" -eq 2 ] && return 2

  # RT1 — a grammar label with no fence row. THE ADDITION CASE.
  local lab
  while IFS= read -r lab; do
    [ -n "$lab" ] || continue
    awk -F"$RT_TAB" -v k="$lab" '$1 == k { f = 1 } END { exit f ? 0 : 1 }' <<<"$rows" && continue
    rt_finding RT1 "the itinerary grammar emits element '$lab' and the contract fence carries no row for it — it is neither rendered nor excluded, so a build that drops it drops it silently"
    rc=1
  done <<<"$labels"

  # RT2 — a fence row whose label the grammar no longer emits. The pin's other direction.
  local frow
  while IFS="$RT_TAB" read -r frow _ _; do
    [ -n "$frow" ] || continue
    case "$frow" in '!'|'<'*) continue ;; esac
    grep -qxF -- "$frow" <<<"$labels" && continue
    rt_finding RT2 "the contract fence declares element '$frow' and the itinerary grammar no longer emits it — a declaration that outlives its element is a standing exemption for whatever next takes that spelling"
    rc=1
  done <<<"$rows"

  printf 'CONTRACT labels=%s rows=%s\n' "$n_lab" "$n_row"
  return $rc
}

# ── THE INSTANCE WALK — RT3 / RT4 / RT5 / RT6 ────────────────────────────────────
#
# Days are joined between plan and site by ORDINAL, through the per-day gradient class § 3
# declares (`.bg-d1` through `.bg-dN`). That is a real join read out of the rendered markup
# rather than a positional guess: a site missing day 3 entirely is a missing `bg-d3`, and a
# day whose banner is present but whose body was dropped is a section with neither a day
# grid nor a split-day region.
#
# An event resolves BY VENUE NAME inside its own day's section, which is what makes the
# "replay a dropped element" control a real replay: delete one act-card from the site and
# the anchor's venue name leaves that section, so the walk names the element that did not
# resolve rather than reporting a count that moved.

# The plan's day blocks: "<day-number>\t<start-line>\t<end-line>".
rt_plan_days() {   # rt_plan_days <plan-file>
  local f="$1"
  [ -r "$f" ] || return 1
  awk '
    /^\*\*Day [0-9]+/ {
      if (cur != "") printf "%s\t%d\t%d\n", cur, st, NR - 1
      line = $0
      match(line, /Day [0-9]+/)
      cur = substr(line, RSTART + 4, RLENGTH - 4)
      st = NR
      next
    }
    END { if (cur != "") printf "%s\t%d\t%d\n", cur, st, NR }
  ' "$f"
}

# Every venue an event block names, per day: "<day>\t<kind>\t<venue>".
# A venue is the text before the first em-dash of an entry line, which is the entry grammar
# the prompt's own day template states for every card-bearing block.
rt_plan_events() {   # rt_plan_events <plan-file>
  local f="$1"
  [ -r "$f" ] || return 1
  awk '
    function venue(s,   v) {
      v = s
      sub(/^[[:space:]]*[-*][[:space:]]*/, "", v)
      sub(/^[A-Za-z ]+:[[:space:]]*/, "", v)
      if (index(v, "\342\200\224") > 0) v = substr(v, 1, index(v, "\342\200\224") - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      return v
    }
    /^\*\*Day [0-9]+/ { match($0, /Day [0-9]+/); day = substr($0, RSTART + 4, RLENGTH - 4); kind = ""; next }
    day == "" { next }
    # A horizontal rule closes the open block. Without this the separator line itself is
    # read as an entry of whichever block was last opened, and a `-`-leading venue-stripper
    # then turns `---` into a plausible venue name that resolves against nothing.
    /^---/                           { kind = "";            next }
    /^\*\*Anchor\*\*/                { kind = "anchor";      next }
    /^\*\*Supporting Experiences\*\*/{ kind = "supporting";  next }
    /^\*\*AC Bailout\*\*/            { kind = "bailout";     next }
    /^\*\*Food Anchors\*\*/          { kind = "food";        next }
    /^\*\*Nightlife\*\*/             { kind = "nightlife";   next }
    # A per-track venue IS an event. The Map-Link Component section says so in terms —
    # "including each per-track venue on a split day" — so a track stop carries the same
    # location invariant every other card does, and a track column that renders its label
    # and drops its stops is a drop like any other.
    /^\*\*Parallel Track/            { kind = "track";       next }
    /^\*\*/                          { kind = "";            next }
    kind == "" { next }
    /^[[:space:]]*$/ { next }
    /^\*/ { next }
    /^No nightlife tonight/ { next }
    { v = venue($0); if (v ~ /[A-Za-z0-9]/) printf "%s\t%s\t%s\n", day, kind, v }
  ' "$f"
}

# The split-day tracks the plan declares: "<day>\t<members>".
#
# THE SEPARATOR IS A STRING AND NEVER A REGEX LITERAL, and that is a correctness
# requirement rather than a style call. awk processes the octal escapes of a STRING literal
# before compiling it as a separator, and does not process them inside a `/…/` REGEX
# literal: measured on this host, `split($0, P, /\342\200\224/)` over a real Parallel Track
# line returns 1 — no split at all — while the same line through a string separator returns
# 3 with the members in field two. The regex form does not error; it silently returns the
# whole line as one field, the members string comes back empty, and RT4 then never fires on
# a dropped track. That is the exact silent-pass this group exists to make impossible, and
# it was found by the control arm rather than by reading.
rt_plan_tracks() {   # rt_plan_tracks <plan-file>
  local f="$1"
  [ -r "$f" ] || return 1
  awk '
    BEGIN { DASH = "\342\200\224" }
    /^\*\*Day [0-9]+/ { match($0, /Day [0-9]+/); day = substr($0, RSTART + 4, RLENGTH - 4); next }
    day == "" { next }
    /^\*\*Parallel Track/ {
      line = $0
      sub(/[[:space:]]*\*\*[[:space:]]*$/, "", line)
      n = split(line, P, DASH)
      if (n < 2) next
      m = P[2]
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", m)
      if (m != "") printf "%s\t%s\n", day, m
    }
  ' "$f"
}

# Whether the plan's day carries a nightlife block at all: "<day>\t<cards>\t<declines>".
rt_plan_nightlife() {   # rt_plan_nightlife <plan-file>
  local f="$1"
  [ -r "$f" ] || return 1
  awk '
    /^\*\*Day [0-9]+/ {
      if (day != "") printf "%s\t%d\t%d\n", day, c, d
      match($0, /Day [0-9]+/); day = substr($0, RSTART + 4, RLENGTH - 4)
      inb = 0; c = 0; d = 0; next
    }
    day == "" { next }
    /^\*\*Nightlife\*\*/ { inb = 1; next }
    /^\*\*/ { inb = 0 }
    /^---/ { inb = 0; next }
    inb && /^No nightlife tonight/ { d++; next }
    inb && /^[[:space:]]*$/ { next }
    inb && /^\*/ { next }
    inb { c++ }
    END { if (day != "") printf "%s\t%d\t%d\n", day, c, d }
  ' "$f"
}

# The site's per-day section, extracted by the day-gradient class the catalog declares.
rt_site_day() {   # rt_site_day <site-file> <day-number> -> that day's markup on stdout
  local f="$1" n="$2"
  [ -r "$f" ] || return 1
  awk -v want="bg-d$n" '
    {
      if (match($0, /bg-d[0-9]+/)) {
        tok = substr($0, RSTART, RLENGTH)
        if (tok == want) { on = 1 } else if (on) { exit }
      }
      if (on) print
    }' "$f"
}

# The site's event cards, one chunk per card, so a map-link is resolved INSIDE the card that
# names the venue rather than anywhere on the page. A page-wide map-link scan would pass a
# site whose every link sat on one card.
rt_site_cards() {   # rt_site_cards <markup-on-stdin-file> -> "<has-map-link>\t<card-text>"
  local f="$1"
  awk '
    function flush(   ) { if (open) { printf "%s\t%s\n", (ml ? 1 : 0), buf; buf = ""; ml = 0 } }
    {
      if ($0 ~ /class="(act-card|act-mini|food-card|night-card)"/) { flush(); open = 1 }
      if (open) {
        buf = buf " " $0
        if ($0 ~ /class="map-link"/) ml = 1
      }
    }
    END { flush() }
  ' "$f"
}

# The site's LABELED TRACK COLUMNS, one label's text per line, so a track member is resolved
# INSIDE the `.track-label` the split-day component puts it in rather than anywhere on the day.
# § 9.3 names `.track-label` as the element that carries the subgroup members, so that element
# is what "carries a labeled track column naming it" can mean. A section-wide scan is the same
# defect rt_site_cards exists to prevent one level down: it passes a day whose member string
# appears only in a `.track-why` kicker, in a rejoin line, or in ordinary prose — the label
# gone, the members still legible somewhere, and the column never rendered.
#
# The file is read into ONE buffer before splitting, so a label whose text sits on a different
# line from its opening tag is still read. A line-keyed reader returns nothing for that shape
# and a nothing is indistinguishable here from a label that is genuinely absent.
rt_site_track_labels() {   # rt_site_track_labels <day-markup-file> -> one label's text per line
  local f="$1"
  awk '
    { buf = buf " " $0 }
    END {
      n = split(buf, part, /class="track-label"[^>]*>/)
      for (i = 2; i <= n; i++) {
        seg = part[i]
        p = index(seg, "<")
        if (p > 0) seg = substr(seg, 1, p - 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", seg)
        if (seg != "") print seg
      }
    }' "$f"
}

rt_instance_walk() {   # rt_instance_walk <plan-file> <site-file> [work-dir]
  local plan="$1" site="$2" work="${3:-}"
  local rc=0 days n_days

  if [ ! -r "$plan" ]; then
    rt_finding RT0 "the plan is unreadable at '$plan' — there is no element set to walk, so nothing below is a measurement"
    return 2
  fi
  if [ ! -r "$site" ]; then
    rt_finding RT0 "the site is unreadable at '$site' — there is nothing to resolve the plan's elements against"
    return 2
  fi
  [ -n "$work" ] || work="$(mktemp -d)"
  mkdir -p "$work"

  days="$(rt_plan_days "$plan")"
  n_days="$(printf '%s\n' "$days" | grep -c '[^[:space:]]')"
  if [ "$n_days" -eq 0 ]; then
    rt_finding RT0 "the plan at '$plan' yielded ZERO day blocks — the instrument is broken, not the plan clean"
    return 2
  fi

  local events tracks nightlife d dstart dend
  events="$(rt_plan_events "$plan")"
  tracks="$(rt_plan_tracks "$plan")"
  nightlife="$(rt_plan_nightlife "$plan")"

  while IFS="$RT_TAB" read -r d dstart dend; do
    [ -n "$d" ] || continue
    local sec="$work/day-$d.html"
    rt_site_day "$site" "$d" > "$sec"
    if [ ! -s "$sec" ]; then
      rt_finding RT3 "plan day $d has no rendered day section in the site — the day banner class 'bg-d$d' appears nowhere, so the whole day resolved to nothing"
      rc=1
      continue
    fi
    if ! grep -qE 'class="(day-grid|split-day)"' "$sec"; then
      rt_finding RT3 "plan day $d has a day banner but no day body — neither a day grid nor a split-day region is present, so the day's contents resolved to nothing"
      rc=1
    fi

    # RT4 — every declared track has its OWN labeled column. Resolved against the day's
    # `.track-label` elements alone, and as a FIXED STRING: the finding names a labeled track
    # column, so the labels are the population it may be measured over, and a member string is
    # prose that carries regex metacharacters of its own — read as a pattern, `Sam (w/ Pat)`
    # matches on a grouping it never wrote. Same `-qF --` form the venue arm below already uses.
    local tlabels tday tmem
    tlabels="$(rt_site_track_labels "$sec")"
    while IFS="$RT_TAB" read -r tday tmem; do
      [ "$tday" = "$d" ] || continue
      if ! grep -qF -- "$tmem" <<<"$tlabels"; then
        rt_finding RT4 "day $d declares a Parallel Track for '$tmem' and the site carries no labeled track column naming it — this is the split-day drop § 9.4 names as the most common one, a patch that moved the first track and left the second behind"
        rc=1
      fi
    done <<<"$tracks"

    # RT3 — every rendered event instance resolves, BY NAME, inside its own day's section.
    local cards="$work/cards-$d.txt"
    rt_site_cards "$sec" > "$cards"
    local eday ekind evenue
    while IFS="$RT_TAB" read -r eday ekind evenue; do
      [ "$eday" = "$d" ] || continue
      [ -n "$evenue" ] || continue
      if ! grep -qF -- "$evenue" "$sec"; then
        rt_finding RT3 "day $d's plan names the $ekind '$evenue' and the site's day section renders no component carrying it — a plan element reached the site and was dropped"
        rc=1
        continue
      fi
      # RT5 — the location invariant, resolved inside the card that names the venue.
      local ml
      ml="$(awk -F"$RT_TAB" -v v="$evenue" 'index($2, v) > 0 { if ($1 == 1) { ok = 1 } ; seen = 1 } END { print (seen ? (ok ? "1" : "0") : "none") }' "$cards")"
      if [ "$ml" = "0" ]; then
        rt_finding RT5 "day $d's event card for '$evenue' carries no map-link — every event card resolves to exactly one, and a card whose venue has no reachable link is a broken card"
        rc=1
      fi
    done <<<"$events"

    # RT6 — the nightlife band's contents, cards AND any stated decline.
    local nday ncards ndecl
    while IFS="$RT_TAB" read -r nday ncards ndecl; do
      [ "$nday" = "$d" ] || continue
      [ $((ncards + ndecl)) -gt 0 ] || continue
      if ! grep -qE 'class="(night-card|night-zone)"' "$sec"; then
        rt_finding RT6 "day $d's plan carries nightlife-band content and the site renders no nightlife band for it — block content resolved to nothing"
        rc=1
        continue
      fi
      if [ "$ndecl" -gt 0 ] && ! grep -qF 'No nightlife tonight' "$sec"; then
        rt_finding RT6 "day $d's plan states a nightlife decline and the site does not carry it — a stated decline and a dropped subgroup must not look alike on the page, which is the whole reason a decline is rendered rather than excluded"
        rc=1
      fi
    done <<<"$nightlife"
  done <<<"$days"

  printf 'INSTANCE days=%s\n' "$n_days"
  return $rc
}

rt_usage() {
  cat <<'USAGE'
check-round-trip.sh — the round-trip completeness walker (site-layout-spec.md § 9.4)

  check-round-trip.sh [--root <dir>] --contract-only
  check-round-trip.sh [--root <dir>] [--data-root <dir>] --trip <slug>
  check-round-trip.sh [--root <dir>] --plan <path> --site <path>

  --root       the ENGINE root: the itinerary grammar and the site-layout spec
  --data-root  the TRIP root: the tree whose plan and site are read

Exit 0 clean, 1 findings, 2 degraded read.
USAGE
}

# A value-taking flag that reaches the end of the argument list with no value is a TERMINAL
# argument error, and saying so is what keeps the parse loop finite. `shift 2` with one
# argument remaining shifts NOTHING and returns 1 — measured, `$#` stays 1 and `$1` is
# unchanged — and this file runs under `set -uo pipefail` with no `-e`, so that status is
# discarded. The loop then re-reads the same `$1` on every pass and never terminates, which
# makes every guard downstream of it unreachable: `--trip` alone never reaches the `[ -z
# "$slug" ]` arm that exists to diagnose exactly that invocation. The guard is attached to
# each arm that needs it rather than to a parallel list of value-taking flag names, because a
# parallel list is a second place to forget a flag and re-open this.
rt_need_value() {   # rt_need_value <remaining-argc> <flag>
  [ "$1" -ge 2 ] && return 0
  rt_finding RT0 "the flag '$2' takes a value and none was given — nothing was read"
  return 1
}

rt_main() {
  local root="" data_root="" slug="" plan="" site="" mode="" rc=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --root)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; root="$2";      shift 2 ;;
      --data-root)     rt_need_value $# "$1" || { rt_usage >&2; return 2; }; data_root="$2"; shift 2 ;;
      --trip)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; slug="$2"; mode="trip"; shift 2 ;;
      --plan)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; plan="$2"; mode="pair"; shift 2 ;;
      --site)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; site="$2"; mode="pair"; shift 2 ;;
      --contract-only) mode="contract"; shift ;;
      -h|--help)       rt_usage; return 0 ;;
      *) printf 'unknown argument: %s\n' "$1" >&2; rt_usage >&2; return 2 ;;
    esac
  done
  if [ -z "$root" ]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
  [ -n "$data_root" ] || data_root="$root"

  case "$mode" in
    contract)
      rt_contract_walk "$root"; rc=$?
      ;;
    trip)
      if [ -z "$slug" ]; then
        rt_finding RT0 "--trip was given no slug"; return 2
      fi
      plan="$data_root/trips/$slug/outputs/final-itinerary.md"
      site="$(ls "$data_root/trips/$slug/outputs/"*-travel-site.html 2>/dev/null | head -1)"
      if [ -z "$site" ]; then
        rt_finding RT0 "no '*-travel-site.html' exists under '$data_root/trips/$slug/outputs/' — there is no site to walk the plan against"
        return 2
      fi
      rt_contract_walk "$root"; rc=$?
      rt_instance_walk "$plan" "$site"; local irc=$?
      [ "$irc" -gt "$rc" ] && rc=$irc
      ;;
    pair)
      if [ -z "$plan" ] || [ -z "$site" ]; then
        rt_finding RT0 "--plan and --site must be given together"; return 2
      fi
      rt_instance_walk "$plan" "$site"; rc=$?
      ;;
    *)
      rt_usage >&2; return 2
      ;;
  esac

  if [ "$rc" -eq 0 ]; then
    printf 'CLEAN every element the walk reached resolved to a rendered component or to a named exclusion\n'
  fi
  return $rc
}

# Run only when executed directly; sourcing (e.g. for the suite) exposes the functions
# without dispatch. Same shape as scripts/validate-artifacts.sh and
# scripts/publish-trip-site.sh, deliberately — one pattern, one reading.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  rt_main "$@"
fi
