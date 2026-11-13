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
#   ./scripts/check-round-trip.sh [--root <dir>] [--data-root <dir>] --trip <slug> [--state <MODE>:<DISPOSITION>]
#   ./scripts/check-round-trip.sh [--root <dir>] --plan <path> --site <path> [--state <MODE>:<DISPOSITION>]
#
# ── THE WALK HAS TWO HALVES AND ONLY ONE OF THEM HAS A CI POPULATION ─────────────
# This is the whole shape of the file and it is stated first because a gate that conflates
# the two claims more than it grades.
#
#   THE CONTRACT HALF (--contract-only). Every element TYPE the itinerary grammar can emit
#   carries a declared disposition, rendered or excluded, and every declared disposition
#   names an element the grammar still emits. Real population, tracked tree, graded in CI
#   on every push. Codes RT1 / RT2, and RT7 for the artifact grain, with RT0 guarding the
#   instrument.
#
#   THE INSTANCE HALF (--trip, --plan/--site). For a given plan and the site built from it,
#   every element INSTANCE resolves to its component, per day and per track. Codes RT3-RT6,
#   and RT8 for the shape pass.
#   ITS REAL POPULATION IN CI IS EMPTY AND CAN NEVER BE NON-EMPTY. .gitignore carries
#   `trips/*`, so no CI checkout holds a render; and reference/schemas/travel-site.md
#   carries a no-witness clause it calls terminal rather than pending, naming a committed
#   site fixture as "exactly the wrong repair". So the instance half runs HERE, at the verb,
#   on the operator's real trip — and in CI only over synthetic pairs the suite builds.
#
# ── THREE PASSES, AND σ ──────────────────────────────────────────────────────────
# reference/site-layout-spec.md § 9.4 runs the walk in three passes over σ: the trip's
# resolved mode and its destination's DISPOSITION, passed as --state <MODE>:<DISPOSITION>,
# DISPOSITION being DECIDED or UNDECIDED and never the destination itself.
#
#   ARTIFACT  The contract half (RT7) holds the render table in § 9.2 to § 1.1's bound classes
#             and to the states the `site` row of skills/trip/SKILL.md admits, both directions,
#             on the tracked tree. The instance half reads that every artifact the table renders
#             in σ is readable under the trip.
#   ELEMENT   The walk below — the contract half and the instance half — once per element fence
#             the per-artifact declarations name, against the artifact the render table binds to it.
#   SHAPE     (RT8) The render carries no component that some state admits and σ does not.
#
# Without σ, and with a σ in which the `site` row admits no build, the artifact pass's instance
# half and the shape pass are NOT RUN, and each is reported as RT0: nothing was read for it, so
# it is never a clean result. The walker never infers σ, and never echoes the value it was given:
# an argument it does not know is named by its position rather than its text, and a second
# --state is refused rather than either value taken.
# --contract-only reads no render, so it runs the two contract halves and nothing that needs σ.
# Where the shape pass ran, the CLEAN line states how many components it could observe, because
# a component § 3 gives no class is one it cannot see, and a clean verdict carries that limit.
#
# ── TWO ROOTS, AND WHY ONE FLAG CANNOT CARRY BOTH ────────────────────────────────
# `--root` roots the ENGINE: agents/05-hub-planner.md, which owns the itinerary grammar;
# reference/site-layout-spec.md, which owns the fences and the component catalog; and the
# three tables the artifact grain reads — § 1.1 of reference/data-architecture.md, CLAUDE.md
# § Resolving a trip gates G5 and G6, and the `site` row of skills/trip/SKILL.md. Those are
# engine assets and follow this script wherever it is installed.
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
#        element extraction returned ZERO ROWS. The same for the render table: it does not
#        resolve, a row is malformed, a state cell reads `any` or names a key G5 and G6 do
#        not yield, two rows cover one artifact in one state, a home is undefined; a read of
#        the bound set, the vocabulary or the `site` row returns nothing; an artifact σ
#        renders is unreadable; σ is not a state; or a pass this run owed was NOT RUN. A zero-row extraction is a broken
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
#   RT7  the artifact grain does not close: a bound class or scaffolding token with no
#        render-table row for a state the `site` row admits; a row for a class that is not
#        bound, or for a state the row does not admit; or an excluded row § 9.3 does not name
#        in that state. THE ADDITION CASE one grain up: a class turned bound without rows.
#        A scaffolding token is known only from the table's own rows, so a token whose every
#        row is deleted leaves no subject and is NOT reported: that deletion is a stated
#        residual, not a closed case. A bound class is read from § 1.1 and has no such hole.
#   RT8  the render carries a component some state admits and σ does not — a section left
#        from another state. It is seen only by a class § 3 declares for the component, so a
#        component § 3 gives no class is counted as unobserved, never read as absent.
#
# ── WHAT THIS WALK ESTABLISHES, AND WHAT IT CANNOT ───────────────────────────────
# Declared here rather than left to be inferred from a green, because an unstated limit is
# how a gate comes to claim more than it grades.
#
# IT ESTABLISHES: that every element type the grammar can emit carries a declared
# disposition, both directions, on the real tree; that every bound class is dispositioned in
# every state the `site` row admits; that for a given (plan, site) pair every rendered element
# instance resolves to its component, per day and per track; and, given σ, that the render
# carries no component σ does not admit, of those § 3 gives a class.
#
# IT CANNOT ESTABLISH that the site it read is the site the verb WROTE. The trip tree lives
# under the operator's data root (CLAUDE.md § Resolving a trip), and this repository holds
# no earlier state of it, so this walk grades the artifact after the write and never the
# act. Nor can any inspection of any tree establish that a given run INVOKED this walker at
# all: the suite grades that the verb DECLARES the invocation, and no further.
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

# ── THE DECLARATIONS ─────────────────────────────────────────────────────────────
# One spec, one render table, one state flag, read from the engine root. The ELEMENT
# fences are declared per artifact below, because there is one per rendered artifact.
RT_SPEC_REL='reference/site-layout-spec.md'
RT_CHARTER_REL='CLAUDE.md'
RT_VERB_REL='skills/trip/SKILL.md'
RT_ARTIFACT_TAG='round-trip-contract-artifacts'
RT_STATE_FLAG='--state'
RT_TAB="$(printf '\t')"
RT_SHAPE_SEEN=''   # "<observable> of <population>", set by the shape pass for the CLEAN line

# ── THE PER-ARTIFACT DECLARATIONS ────────────────────────────────────────────────
# One record per element fence, tab-separated:
#   <fence tag> <grammar file> <grammar region heading> <label shape> <instance walker>
# WHICH ARTIFACT a fence grades is not declared here. The render table's `elements:<tag>`
# home binds it, and a binding written in two places is two sources able to disagree. A
# label shape names a function `rt_labels_<shape>`, and an instance walker names a
# function, so an artifact whose grammar or instances need a reader this file lacks adds
# that function and one record here, and no existing code path changes.
RT_ELEMENT_DECLS=(
  $'round-trip-contract-elements\tagents/05-hub-planner.md\t### File: outputs/final-itinerary.md\tbold-line\trt_instance_walk'
)
rt_decls() { printf '%s\n' "${RT_ELEMENT_DECLS[@]}"; }
rt_decl_get() {   # rt_decl_get <tag> <field> -> that record's field, empty when no record carries the tag
  rt_decls | awk -F'\t' -v t="$1" -v f="$2" '$1 == t && !seen { print $f; seen = 1 }'
}
rt_decl_first() { rt_decls | awk -F'\t' -v f="$1" 'NR == 1 { print $f }'; }

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
  local f="$1" h="${2:-$(rt_decl_first 3)}"
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
  local f="$1" tag="${2:-$(rt_decl_first 1)}"
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
  local f="$1" tag="${2:-$(rt_decl_first 1)}"
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
rt_contract_walk() {   # rt_contract_walk <engine-root> [grammar-rel] [spec-rel] [tag] [heading] [shape]
  local root="$1"
  local gfile="$root/${2:-$(rt_decl_first 2)}"
  local sfile="$root/${3:-$RT_SPEC_REL}"
  local tag="${4:-$(rt_decl_first 1)}" heading="${5:-$(rt_decl_first 3)}" shape="${6:-$(rt_decl_first 4)}"
  local rc=0 labels rows comps sites n_lab n_row n_bad lfn

  if [ ! -r "$gfile" ]; then
    rt_finding RT0 "the itinerary grammar is unreadable at '$gfile' — nothing was compared, and a green here would be a statement about a file that was never opened"
    return 2
  fi
  if [ ! -r "$sfile" ]; then
    rt_finding RT0 "the site-layout spec is unreadable at '$sfile' — the contract fence has no home to resolve from"
    return 2
  fi

  sites="$(rt_fence_sites "$sfile" "$tag")"
  if [ "$sites" != "1" ]; then
    rt_finding RT0 "the '$tag' fence opens $sites time(s) in $sfile, expected exactly one — a declaration with two homes is two sources able to disagree, and with none there is nothing to compare against"
    return 2
  fi

  # The label shape names its reader. A shape with no reader is a declaration nothing can
  # grade, so it is a broken instrument rather than a fence with no labels.
  lfn="rt_labels_${shape//-/_}"
  if ! declare -F "$lfn" >/dev/null 2>&1; then
    rt_finding RT0 "the '$tag' fence declares label shape '$shape' and no reader '$lfn' exists — the grammar cannot be read, so nothing was compared"
    return 2
  fi
  labels="$("$lfn" "$gfile" "$heading")"
  n_lab="$(printf '%s\n' "$labels" | grep -c '[^[:space:]]')"
  if [ "$n_lab" -eq 0 ]; then
    rt_finding RT0 "the element extraction returned ZERO rows from $gfile — the instrument is broken, not the corpus clean. Every comparison below would be vacuously true over an empty set"
    return 2
  fi

  rows="$(rt_fence_rows "$sfile" "$tag")"
  n_row="$(printf '%s\n' "$rows" | grep -c '[^[:space:]]')"
  if [ "$n_row" -eq 0 ]; then
    rt_finding RT0 "the '$tag' fence in $sfile parsed to ZERO rows — the contract did not resolve"
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

  printf 'CONTRACT fence=%s labels=%s rows=%s\n' "$tag" "$n_lab" "$n_row"
  return $rc
}

# The itinerary grammar's reader under the name its label shape gives it.
rt_labels_bold_line() { rt_grammar_labels "$@"; }

# THE ELEMENT PASS'S CONTRACT HALF — the walk above, once per declared element fence.
rt_element_contract() {   # rt_element_contract <engine-root>
  local root="$1" rc=0 r tag gram head shape
  while IFS="$RT_TAB" read -r tag gram head shape _; do
    [ -n "$tag" ] || continue
    rt_contract_walk "$root" "$gram" "$RT_SPEC_REL" "$tag" "$head" "$shape"; r=$?
    [ "$r" -gt "$rc" ] && rc=$r
  done <<<"$(rt_decls)"
  return $rc
}

# ── THE ARTIFACT GRAIN — the render table, and what it is held to ────────────────
#
# Every set below is READ, and this file holds no copy of any of them: the `bound` classes
# from reference/data-architecture.md § 1.1 through the validator's own reader, the states
# the `site` row admits from skills/trip/SKILL.md, the mode and destination dispositions
# from CLAUDE.md § Resolving a trip, gates G5 and G6, and the component catalog from § 3.
# A reading that returns nothing is a broken instrument and is RT0, never an empty set.

# § 1.1 is read by the validator's reader, sourced on demand and only where it is not
# already defined, so a caller that sourced the validator first keeps its own globals.
rt_load_class_reader() {
  declare -F va_class_rows >/dev/null 2>&1 && return 0
  local v
  v="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-artifacts.sh"
  [ -r "$v" ] || return 1
  # shellcheck source=validate-artifacts.sh
  source "$v" || return 1
  declare -F va_class_rows >/dev/null 2>&1
}

rt_bound_classes() {   # rt_bound_classes <engine-root> -> one § 1.1 class per line whose P is `bound`
  rt_load_class_reader || return 1
  va_class_rows "$1" | awk -F'\t' 'NF >= 6 && $6 == "bound" { print $2 }'
}

# rt_state_vocab <engine-root> -> "<axis>\t<token>" from CLAUDE.md § Resolving a trip:
#   mode      each mode G5 resolves          mode-any  G5's placeholder disposition (UNSET)
#   dest      G6's decided disposition        dest-any  G6's placeholder disposition (UNDECIDED)
# Each disposition is read as the bolded code span its branch writes, the decided one as the
# placeholder one is. A branch reworded out of its span yields no token: an empty decided axis
# is RT0, and an empty placeholder narrows what a cell reading `any` admits.
rt_state_vocab() {
  local f="$1/$RT_CHARTER_REL"
  [ -r "$f" ] || return 1
  awk '
    function after(s, k,   p) { p = index(s, k); return p ? substr(s, p + length(k)) : "" }
    function tick(s,   q) { if (substr(s, 1, 1) != "`") return ""; s = substr(s, 2); q = index(s, "`"); return q > 1 ? substr(s, 1, q - 1) : "" }
    index($0, "- **G5 ") == 1 {
      t = tick(after($0, "**value is a placeholder** → **")); if (t != "") print "mode-any\t" t
      if (match($0, /\([A-Z]+( \/ [A-Z]+)+\)/)) {
        n = split(substr($0, RSTART + 1, RLENGTH - 2), M, " / ")
        for (i = 1; i <= n; i++) print "mode\t" M[i]
      }
    }
    index($0, "- **G6 ") == 1 {
      t = tick(after($0, "**value is a placeholder** → **")); if (t != "") print "dest-any\t" t
      t = tick(after($0, "**value is anything else** → **")); if (t != "") print "dest\t" t
    }' "$f"
}

# The `site` row of the requirement table, located by the table's frozen header row:
# "<mode cell>\t<destination cell>". A row of any other width yields nothing.
rt_site_cells() {   # rt_site_cells <engine-root>
  local f="$1/$RT_VERB_REL"
  [ -r "$f" ] || return 1
  awk -F'|' '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    !hdr && !done && NF == 7 && trim($2) == "verb" && trim($3) == "lifecycle" && trim($4) == "mode" && trim($5) == "destination" && trim($6) == "depth" { hdr = 1; next }
    hdr && !/^\|/ { hdr = 0; done = 1 }
    hdr && NF == 7 && trim($2) == "site" { printf "%s\t%s\n", trim($4), trim($5) }
  ' "$f"
}

# G7's cell grammar: values joined by commas. `any` is returned as itself; the caller decides.
rt_cell_tokens() {   # rt_cell_tokens <cell> -> one value per line
  awk -v c="$1" 'BEGIN { n = split(c, T, ","); for (i = 1; i <= n; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", T[i]); if (T[i] != "") print T[i] } }'
}

# The states the `site` row admits, as G7 reads its cells: a cell naming values admits those
# values, and `any` admits the axis's values plus the placeholder disposition its gate yields.
rt_admitted() {   # rt_admitted <engine-root> -> "<MODE>\t<DEST>" per admitted state
  local root="$1" cells vocab mcell dcell ms ds m d
  cells="$(rt_site_cells "$root")" || return 1
  [ "$(printf '%s\n' "$cells" | awk 'NF { n++ } END { print n+0 }')" -eq 1 ] || return 1
  vocab="$(rt_state_vocab "$root")" || return 1
  mcell="${cells%%"$RT_TAB"*}"; dcell="${cells#*"$RT_TAB"}"
  if [ "$mcell" = any ]; then ms="$(awk -F'\t' '$1 == "mode" || $1 == "mode-any" { print $2 }' <<<"$vocab")"; else ms="$(rt_cell_tokens "$mcell")"; fi
  if [ "$dcell" = any ]; then ds="$(awk -F'\t' '$1 == "dest" || $1 == "dest-any" { print $2 }' <<<"$vocab")"; else ds="$(rt_cell_tokens "$dcell")"; fi
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      printf '%s\t%s\n' "$m" "$d"
    done <<<"$ds"
  done <<<"$ms"
}

# The render table: "<artifact>\t<modes>\t<destination>\t<disposition>\t<home>", or a `!`
# record for a row that does not carry exactly five columns. Columns are separated by two or
# more spaces, as in the element fence, because a mode cell carries ", " of its own.
rt_artifact_rows() {   # rt_artifact_rows <spec-file>
  local f="$1"
  [ -r "$f" ] || return 1
  awk -v open='```'"$RT_ARTIFACT_TAG" '
    $0 == open { inside = 1; next }
    inside && $0 == "```" { inside = 0; next }
    !inside { next }
    {
      line = $0
      sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
      if (line == "" || line ~ /^#/) next
      n = split(line, F, /[[:space:]][[:space:]]+/)
      if (n != 5) { printf "!\tmalformed\t%s\n", line; next }
      printf "%s\t%s\t%s\t%s\t%s\n", F[1], F[2], F[3], F[4], F[5]
    }' "$f"
}

# One line per state a row covers: "<artifact>\t<MODE>\t<DEST>\t<disposition>\t<home>".
rt_artifact_keys() {   # rt_artifact_keys <spec-file>
  local rows a mc dc disp home m d
  rows="$(rt_artifact_rows "$1")" || return 1
  while IFS="$RT_TAB" read -r a mc dc disp home; do
    case "$a" in ''|'!') continue ;; esac
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        printf '%s\t%s\t%s\t%s\t%s\n' "$a" "$m" "$d" "$disp" "$home"
      done <<<"$(rt_cell_tokens "$dc")"
    done <<<"$(rt_cell_tokens "$mc")"
  done <<<"$rows"
}

# The § 3 components a `rendered` home admits: each `|`-joined token, and for
# `elements:<tag>` the components that element fence's rendered rows name. `—` admits none.
rt_home_components() {   # rt_home_components <spec-file> <home>
  local s="$1" part
  while IFS= read -r part; do
    case "$part" in
      ''|'—') ;;
      elements:*) rt_fence_rows "$s" "${part#elements:}" | awk -F'\t' '$1 != "!" && $2 == "rendered" { n = split($3, C, "|"); for (i = 1; i <= n; i++) if (C[i] != "") print C[i] }' ;;
      *) printf '%s\n' "$part" ;;
    esac
  done <<<"$(tr '|' '\n' <<<"$2")"
}

# § 9.3's artifact rows: "<name>\t<MODE>\t<DEST>" for a row whose first cell is one code
# span and whose State cell reads "<modes> × <destinations>", groups joined by ";". An
# element row names its artifact rather than states, and is not read here.
rt_exclusion_states() {   # rt_exclusion_states <spec-file>
  awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^### 9\.3 / { insec = 1; next }
    insec && /^##/ { insec = 0 }
    !insec || !/^\|/ { next }
    {
      n = split($0, F, "|"); if (n < 5) next
      name = trim(F[2]); if (name !~ /^`[^`]+`$/) next
      name = substr(name, 2, length(name) - 2)
      ng = split(F[3], G, ";")
      for (g = 1; g <= ng; g++) {
        x = index(G[g], "×"); if (!x) continue
        nm = split(substr(G[g], 1, x - 1), M, ","); nd = split(substr(G[g], x + length("×")), D, ",")
        for (i = 1; i <= nm; i++) for (j = 1; j <= nd; j++) {
          m = trim(M[i]); d = trim(D[j])
          if (m != "" && d != "") printf "%s\t%s\t%s\n", name, m, d
        }
      }
    }' "$1"
}

# THE ARTIFACT PASS'S CONTRACT HALF — RT0 for a table that cannot be resolved, RT7 for one
# that resolves and does not close over the `bound` set and the admitted states.
rt_artifact_contract() {   # rt_artifact_contract <engine-root> [spec-rel]
  local root="$1" sfile="$1/${2:-$RT_SPEC_REL}"
  local rc=0 sites rows nrow bound nbound vocab nmode ndest adm nadm comps keys a mc dc disp home tok part tag
  if [ ! -r "$sfile" ]; then
    rt_finding RT0 "the site-layout spec is unreadable at '$sfile' — the render table has no home to resolve from"
    return 2
  fi
  sites="$(rt_fence_sites "$sfile" "$RT_ARTIFACT_TAG")"
  if [ "$sites" != "1" ]; then
    rt_finding RT0 "the '$RT_ARTIFACT_TAG' fence opens $sites time(s) in $sfile, expected exactly one — the render table has two homes or none"
    return 2
  fi
  rows="$(rt_artifact_rows "$sfile")"
  nrow="$(printf '%s\n' "$rows" | awk 'NF { n++ } END { print n+0 }')"
  if [ "$nrow" -eq 0 ]; then
    rt_finding RT0 "the '$RT_ARTIFACT_TAG' fence parsed to ZERO rows — the render table did not resolve"
    return 2
  fi
  bound="$(rt_bound_classes "$root")"
  nbound="$(printf '%s\n' "$bound" | awk 'NF { n++ } END { print n+0 }')"
  if [ "$nbound" -eq 0 ]; then
    rt_finding RT0 "the § 1.1 class reader returned ZERO bound classes from '$root' — the reader is broken or unreachable, not the model empty"
    return 2
  fi
  vocab="$(rt_state_vocab "$root")"
  nmode="$(awk -F'\t' '$1 == "mode" { n++ } END { print n+0 }' <<<"$vocab")"
  ndest="$(awk -F'\t' '$1 == "dest" { n++ } END { print n+0 }' <<<"$vocab")"
  if [ "$nmode" -eq 0 ] || [ "$ndest" -eq 0 ]; then
    rt_finding RT0 "the state vocabulary read from $RT_CHARTER_REL gates G5 and G6 is empty (modes=$nmode, decided dispositions=$ndest) — no state key can be checked against it"
    return 2
  fi
  adm="$(rt_admitted "$root")"
  nadm="$(printf '%s\n' "$adm" | awk 'NF { n++ } END { print n+0 }')"
  if [ "$nadm" -eq 0 ]; then
    rt_finding RT0 "the 'site' row of $RT_VERB_REL could not be read, or admits no state — the render table has no denominator"
    return 2
  fi
  comps="$(rt_components "$sfile" | sort -u)"

  # Row integrity. Every failure here means the table cannot be resolved, so it is RT0.
  while IFS="$RT_TAB" read -r a mc dc disp home; do
    [ -n "$a" ] || continue
    if [ "$a" = "!" ]; then
      rt_finding RT0 "a render-table row does not carry five columns: '$dc'"; rc=2; continue
    fi
    case "$disp" in
      rendered|excluded) ;;
      *) rt_finding RT0 "render-table row '$a' declares disposition '$disp', outside the closed enum {rendered, excluded}"; rc=2; continue ;;
    esac
    if [ "$mc" = any ] || [ "$dc" = any ]; then
      rt_finding RT0 "render-table row '$a' reads 'any' in a state cell — under G7 'any' admits UNSET, so a row names its states"; rc=2; continue
    fi
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      awk -F'\t' -v t="$tok" '($1 == "mode" || $1 == "mode-any") && $2 == t { f = 1 } END { exit f ? 0 : 1 }' <<<"$vocab" && continue
      rt_finding RT0 "render-table row '$a' names mode '$tok', which G5 does not resolve to — the row's states cannot be read"; rc=2
    done <<<"$(rt_cell_tokens "$mc")"
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      awk -F'\t' -v t="$tok" '($1 == "dest" || $1 == "dest-any") && $2 == t { f = 1 } END { exit f ? 0 : 1 }' <<<"$vocab" && continue
      rt_finding RT0 "render-table row '$a' carries a destination token outside the dispositions G6 yields — it is not echoed, because a destination cell holds a disposition and never a value"; rc=2
    done <<<"$(rt_cell_tokens "$dc")"
    if [ "$disp" = excluded ]; then
      [ "$home" = '§9.3' ] || { rt_finding RT0 "excluded row '$a' carries home '$home' — an excluded row's home is '§9.3', where its reason is named"; rc=2; }
      continue
    fi
    if [ "$home" = '—' ]; then
      case "$a" in
        '<'*)
          tok="${a#<}"; tok="${tok%>}"
          if grep -qxF -- "$tok" <<<"$comps"; then
            rt_finding RT0 "render-table row '$a' is rendered with no component ('—'), and § 3 defines the component '$tok' — '—' stands only on a scaffolding row § 3 gives no component"; rc=2
          fi ;;
        *) rt_finding RT0 "render-table row '$a' is rendered with no component ('—') — only a scaffolding row may render with no § 3 component"; rc=2 ;;
      esac
      continue
    fi
    while IFS= read -r part; do
      [ -n "$part" ] || continue
      case "$part" in
        elements:*)
          tag="${part#elements:}"
          if [ -z "$(rt_decl_get "$tag" 1)" ]; then
            rt_finding RT0 "render-table row '$a' names element fence '$tag', and the walker carries no declaration for it — nothing could grade that artifact's elements"; rc=2
          elif [ "$(rt_fence_sites "$sfile" "$tag")" != "1" ]; then
            rt_finding RT0 "render-table row '$a' names element fence '$tag', which does not open exactly once in $sfile"; rc=2
          fi ;;
        *)
          grep -qxF -- "$part" <<<"$comps" || { rt_finding RT0 "render-table row '$a' names component '$part', which the § 3 component catalog does not define — a rendered home that does not exist"; rc=2; } ;;
      esac
    done <<<"$(tr '|' '\n' <<<"$home")"
  done <<<"$rows"
  [ "$rc" -eq 2 ] && return 2

  keys="$(rt_artifact_keys "$sfile")"

  # Precedence: one row per artifact and state. Two rows covering one are refused, never ranked.
  local dup
  dup="$(awk -F'\t' '{ k = $1 "\t" $2 "\t" $3; c[k]++ } END { for (k in c) if (c[k] > 1) print k }' <<<"$keys")"
  if [ -n "$dup" ]; then
    while IFS="$RT_TAB" read -r a mc dc; do
      [ -n "$a" ] && rt_finding RT0 "render-table artifact '$a' is covered by more than one row in state $mc × $dc — the table does not say which governs"
    done <<<"$dup"
    return 2
  fi

  # An element fence belongs to one artifact; a declaration no row names grades nothing.
  local named
  named="$(awk -F'\t' '$4 == "rendered" { n = split($5, H, "|"); for (i = 1; i <= n; i++) if (H[i] ~ /^elements:/) print substr(H[i], 10) "\t" $1 }' <<<"$keys" | sort -u)"
  while IFS= read -r tag; do
    [ -n "$tag" ] || continue
    if [ "$(awk -F'\t' -v t="$tag" '$1 == t { n++ } END { print n+0 }' <<<"$named")" -gt 1 ]; then
      rt_finding RT0 "element fence '$tag' is named by rows of more than one artifact — a fence grades one artifact"; rc=2
    fi
  done <<<"$(cut -f1 <<<"$named" | sort -u)"
  while IFS= read -r tag; do
    [ -n "$tag" ] || continue
    awk -F'\t' -v t="$tag" '$1 == t { f = 1 } END { exit f ? 0 : 1 }' <<<"$named" && continue
    rt_finding RT0 "the walker declares element fence '$tag' and no render-table row names it — a declaration with no artifact behind it"; rc=2
  done <<<"$(rt_decls | cut -f1)"
  [ "$rc" -eq 2 ] && return 2

  # RT7 — the artifact grain closes, both directions, over the bound set and the admitted states.
  local subjects s miss states
  while IFS="$RT_TAB" read -r a mc dc _; do
    [ -n "$a" ] || continue
    grep -qxF -- "$mc$RT_TAB$dc" <<<"$adm" && continue
    rt_finding RT7 "render-table artifact '$a' has a row for state $mc × $dc, which the 'site' row does not admit — a declaration that outlives its state"; rc=1
  done <<<"$keys"
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$a" in '<'*) continue ;; esac
    grep -qxF -- "$a" <<<"$bound" && continue
    rt_finding RT7 "the render table has rows for '$a', which § 1.1 does not hold as a bound class — a class that is not bound is excluded by its class and takes no row"; rc=1
  done <<<"$(cut -f1 <<<"$keys" | sort -u)"
  subjects="$( { printf '%s\n' "$bound"; cut -f1 <<<"$keys" | awk '/^</'; } | awk 'NF && !seen[$0]++')"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    miss="$(awk -F'\t' -v a="$s" 'NR == FNR { if ($1 == a) H[$2 "\t" $3] = 1; next } NF && !(($1 "\t" $2) in H) { printf "%s%s × %s", (n++ ? ", " : ""), $1, $2 }' <(printf '%s\n' "$keys") <(printf '%s\n' "$adm"))"
    [ -n "$miss" ] || continue
    rt_finding RT7 "'$s' has no render-table row for state(s) $miss, which the 'site' row admits — it is neither rendered nor excluded there, so a build in that state disposes of it silently"; rc=1
  done <<<"$subjects"
  states="$(rt_exclusion_states "$sfile")"
  while IFS="$RT_TAB" read -r a mc dc disp _; do
    [ "$disp" = excluded ] || continue
    grep -qxF -- "$a$RT_TAB$mc$RT_TAB$dc" <<<"$states" && continue
    rt_finding RT7 "render-table artifact '$a' is excluded in state $mc × $dc and § 9.3 names no reason for it there — an exclusion is named, or it is a silent drop"; rc=1
  done <<<"$keys"

  printf 'ARTIFACT bound=%s states=%s rows=%s\n' "$nbound" "$nadm" "$nrow"
  return $rc
}

# ── THE SHAPE PASS AND THE ARTIFACT PASS'S INSTANCE HALF — both need σ ──────────
#
# σ is (MODE, DEST): the trip's resolved mode and its destination's DISPOSITION, passed as
# <MODE>:<DEST>. The value of the destination never reaches this file through it.
rt_state_parse() {   # rt_state_parse <engine-root> <value> -> "<MODE>\t<DEST>", or 1
  local root="$1" v="$2" m d vocab
  case "$v" in *:*) ;; *) return 1 ;; esac
  m="${v%%:*}"; d="${v#*:}"
  case "$d" in *:*) return 1 ;; esac
  vocab="$(rt_state_vocab "$root")" || return 1
  awk -F'\t' -v t="$m" '($1 == "mode" || $1 == "mode-any") && $2 == t { f = 1 } END { exit f ? 0 : 1 }' <<<"$vocab" || return 1
  awk -F'\t' -v t="$d" '($1 == "dest" || $1 == "dest-any") && $2 == t { f = 1 } END { exit f ? 0 : 1 }' <<<"$vocab" || return 1
  printf '%s\t%s\n' "$m" "$d"
}

# A state the build runs in: one the `site` row admits. The set is captured before it is
# searched: `grep -q` leaving a pipe early would fail its writer under pipefail, and a match
# would then read as a miss.
rt_state_built() {   # rt_state_built <engine-root> <MODE> <DEST>
  local adm
  adm="$(rt_admitted "$1")" || return 1
  grep -qxF -- "$2$RT_TAB$3" <<<"$adm"
}

# The render's class words, one per line, unique. Double-quoted `class` attributes only, the
# form every marker the instance walk reads already takes.
rt_site_classes() {   # rt_site_classes <site-file>
  awk '{ s = $0
    while (match(s, /class="[^"]*"/)) {
      v = substr(s, RSTART + 7, RLENGTH - 8); n = split(v, W, /[[:space:]]+/)
      for (i = 1; i <= n; i++) if (W[i] != "") print W[i]
      s = substr(s, RSTART + RLENGTH)
    } }' "$1" | sort -u
}

# A component's MARKER is a class § 3 declares for it: the class in its heading's
# parenthetical — `### Coordination Notice (`.coord-notice`)` — or the token itself where §
# 3 writes the token as a class (`.act-card`). A component § 3 gives no class has no marker,
# and the shape pass cannot see it; it is counted as unobserved, never read as absent.
rt_class_tokens() {   # rt_class_tokens <spec-file> -> the classes § 3 writes, one per line, unique
  awk '
    /^## 3\./ { insec = 1; next }
    insec && /^## / { insec = 0 }
    !insec { next }
    { rest = $0
      while (match(rest, /`\.[a-z0-9][a-z0-9-]*`/)) { print substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH) } }' "$1" | sort -u
}
rt_component_markers() {   # rt_component_markers <spec-file> -> "<heading-slug>\t<class>"
  awk '
    /^## 3\./ { insec = 1; next }
    insec && /^## / { insec = 0 }
    !insec { next }
    /^### / && match($0, /\(`\.[a-z0-9][a-z0-9-]*`\)/) {
      cls = substr($0, RSTART + 3, RLENGTH - 5)
      h = substr($0, 5); gsub(/\(`[^`]*`\)/, "", h); h = tolower(h)
      gsub(/[^a-z0-9]+/, "-", h); sub(/^-+/, "", h); sub(/-+$/, "", h)
      if (h != "") printf "%s\t%s\n", h, cls
    }' "$1"
}

# The components a state admits, and the population the shape pass reads: every component
# some row admits in some state. A component outside the population is not a section any
# state declares, so its presence is never a finding.
rt_state_components() {   # rt_state_components <spec-file> <MODE> <DEST>
  local h
  rt_artifact_keys "$1" | awk -F'\t' -v m="$2" -v d="$3" '$4 == "rendered" && $2 == m && $3 == d { print $5 }' | sort -u |
    while IFS= read -r h; do rt_home_components "$1" "$h"; done | sort -u
}
rt_shape_population() {   # rt_shape_population <spec-file>
  local h
  rt_artifact_keys "$1" | awk -F'\t' '$4 == "rendered" { print $5 }' | sort -u |
    while IFS= read -r h; do rt_home_components "$1" "$h"; done | sort -u
}

# THE SHAPE PASS — RT8: the render carries a component σ does not admit. The population is
# every component some row admits in some state; the admitted set is the rows rendered in σ.
rt_shape_pass() {   # rt_shape_pass <engine-root> <site-file> <MODE> <DEST>
  local root="$1" site="$2" m="$3" d="$4" sfile="$1/$RT_SPEC_REL"
  local rc=0 pop adm markers ctoks classes t mk n=0 unobs=0
  if [ ! -r "$site" ]; then
    rt_finding RT0 "the site is unreadable at '$site' — the shape pass has no render to read"
    return 2
  fi
  pop="$(rt_shape_population "$sfile")"
  adm="$(rt_state_components "$sfile" "$m" "$d")"
  markers="$(rt_component_markers "$sfile")"
  ctoks="$(rt_class_tokens "$sfile")"
  classes="$(rt_site_classes "$site")"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    mk="$(awk -F'\t' -v t="$t" '$1 == t && !s { print $2; s = 1 }' <<<"$markers")"
    if [ -z "$mk" ] && grep -qxF -- "$t" <<<"$ctoks"; then mk="$t"; fi
    # Counted over the whole population, admitted or not: a component with no marker is one
    # this pass cannot see in ANY state, and the count says how many there are.
    if [ -z "$mk" ]; then unobs=$((unobs+1)); continue; fi
    grep -qxF -- "$t" <<<"$adm" && continue
    grep -qxF -- "$mk" <<<"$classes" || continue
    rt_finding RT8 "the render carries component '$t' (class '$mk'), which state $m × $d does not admit — a section left from another state, which a patch across a change of state must remove"
    rc=1; n=$((n+1))
  done <<<"$pop"
  local npop
  npop="$(printf '%s\n' "$pop" | awk 'NF { n++ } END { print n+0 }')"
  printf 'SHAPE state=%s×%s admitted=%s population=%s surplus=%s unobserved=%s\n' "$m" "$d" \
    "$(printf '%s\n' "$adm" | awk 'NF { n++ } END { print n+0 }')" "$npop" "$n" "$unobs"
  RT_SHAPE_SEEN="$((npop - unobs)) of $npop"
  return $rc
}

# THE ARTIFACT PASS'S INSTANCE HALF — every artifact the table renders in σ is readable.
rt_artifact_instance() {   # rt_artifact_instance <engine-root> <trip-dir> <MODE> <DEST>
  local root="$1" trip="$2" m="$3" d="$4" rc=0 a n=0
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    n=$((n+1))
    [ -r "$trip/$a" ] && continue
    rt_finding RT0 "state $m × $d renders '$a' and it is unreadable at '$trip/$a' — a degraded read, never a smaller site"
    rc=2
  done <<<"$(rt_artifact_keys "$root/$RT_SPEC_REL" | awk -F'\t' -v m="$m" -v d="$d" '$4 == "rendered" && $2 == m && $3 == d && $1 !~ /^</ { print $1 }' | sort -u)"
  printf 'ARTIFACTS state=%s×%s rendered=%s\n' "$m" "$d" "$n"
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

  local events tracks nightlife d
  events="$(rt_plan_events "$plan")"
  tracks="$(rt_plan_tracks "$plan")"
  nightlife="$(rt_plan_nightlife "$plan")"

  while IFS="$RT_TAB" read -r d _; do
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
  check-round-trip.sh [--root <dir>] [--data-root <dir>] --trip <slug> [--state <MODE>:<DECIDED|UNDECIDED>]
  check-round-trip.sh [--root <dir>] --plan <path> --site <path> [--state <MODE>:<DECIDED|UNDECIDED>]

  --root       the ENGINE root: the grammars, the site-layout spec and the tables the walk reads
  --data-root  the TRIP root: the tree whose plan and site are read
  --state      the trip's resolved mode and its destination's disposition, never its value.
               Without it the artifact pass's instance half and the shape pass are NOT RUN,
               which is reported and is never clean.

Exit 0 clean, 1 findings, 2 degraded read.
A pass that was not run is reported as RT0, a degraded read, and never as clean.
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

# THE ELEMENT PASS'S INSTANCE HALF — each declared element fence's instance walker, over the
# artifact the render table binds to that fence. With σ it runs for the artifacts σ renders;
# without σ, or with a σ in which no build runs, it runs for every declared fence, which is
# the walk this file ran before σ existed.
rt_element_instance() {   # rt_element_instance <engine-root> <trip-dir> <site> <MODE|''> <DEST|''>
  local root="$1" trip="$2" site="$3" m="$4" d="$5" rc=0 r tag fn a keys selective=0
  keys="$(rt_artifact_keys "$root/$RT_SPEC_REL")"
  if [ -n "$m" ] && rt_state_built "$root" "$m" "$d"; then selective=1; fi
  while IFS="$RT_TAB" read -r tag _ _ _ fn; do
    [ -n "$tag" ] || continue
    a="$(awk -F'\t' -v t="elements:$tag" '$4 == "rendered" { n = split($5, H, "|"); for (i = 1; i <= n; i++) if (H[i] == t) print $1 }' <<<"$keys" | sort -u)"
    if [ "$(printf '%s\n' "$a" | awk 'NF { n++ } END { print n+0 }')" -ne 1 ]; then
      rt_finding RT0 "the element instance walk for fence '$tag' was NOT RUN: no single render-table artifact is bound to it — this is not a clean result"
      rc=2; continue
    fi
    if [ "$selective" -eq 1 ] && ! awk -F'\t' -v a="$a" -v m="$m" -v d="$d" -v t="elements:$tag" '$1 == a && $2 == m && $3 == d && $4 == "rendered" && index("|" $5 "|", "|" t "|") { f = 1 } END { exit f ? 0 : 1 }' <<<"$keys"; then
      continue
    fi
    if ! declare -F "$fn" >/dev/null 2>&1; then
      rt_finding RT0 "fence '$tag' declares instance walker '$fn' and no such function exists — the instances were not walked"
      rc=2; continue
    fi
    "$fn" "$trip/$a" "$site"; r=$?
    [ "$r" -gt "$rc" ] && rc=$r
  done <<<"$(rt_decls)"
  return $rc
}

# The passes σ selects. Without σ, or with a σ in which no build runs, each pass this
# invocation would have run is reported NOT RUN — an RT0, because nothing was read for it —
# and the walk does not close. The walker never infers σ.
rt_state_passes() {   # rt_state_passes <engine-root> <trip-dir|-> <site> <MODE|''> <DEST|''> <artifact-contract-rc>
  local root="$1" trip="$2" site="$3" m="$4" d="$5" acr="$6" rc=0 r why=""
  if [ -z "$m" ]; then
    why="no $RT_STATE_FLAG was given, and the walker never infers the state"
  elif [ "$acr" -eq 2 ]; then
    why="the render table did not resolve, so no state's shape can be read from it"
  elif ! rt_state_built "$root" "$m" "$d"; then
    why="state $m × $d is not one the 'site' row admits for a build"
  fi
  if [ -n "$why" ]; then
    [ "$trip" = - ] || rt_finding RT0 "the artifact pass's instance half was NOT RUN: $why — this is not a clean result"
    rt_finding RT0 "the shape pass was NOT RUN: $why — this is not a clean result"
    return 2
  fi
  if [ "$trip" != - ]; then
    rt_artifact_instance "$root" "$trip" "$m" "$d"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
  fi
  rt_shape_pass "$root" "$site" "$m" "$d"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
  return $rc
}

rt_main() {
  local root="" data_root="" slug="" plan="" site="" mode="" state="" has_state=0 rc=0 r argc=$#
  RT_SHAPE_SEEN=''
  while [ $# -gt 0 ]; do
    case "$1" in
      --root)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; root="$2";      shift 2 ;;
      --data-root)     rt_need_value $# "$1" || { rt_usage >&2; return 2; }; data_root="$2"; shift 2 ;;
      --trip)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; slug="$2"; mode="trip"; shift 2 ;;
      --plan)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; plan="$2"; mode="pair"; shift 2 ;;
      --site)          rt_need_value $# "$1" || { rt_usage >&2; return 2; }; site="$2"; mode="pair"; shift 2 ;;
      "$RT_STATE_FLAG")
        rt_need_value $# "$1" || { rt_usage >&2; return 2; }
        # A second state is refused rather than either value taken: last-wins would let an
        # earlier malformed value pass unread, and first-wins the later one.
        if [ "$has_state" -eq 1 ]; then
          rt_finding RT0 "$RT_STATE_FLAG was given more than once — neither value is echoed, and nothing was read"; return 2
        fi
        state="$2"; has_state=1; shift 2 ;;
      --contract-only) mode="contract"; shift ;;
      -h|--help)       rt_usage; return 0 ;;
      # Named by position, never by text: a value split off its flag, or written as
      # --state=<value>, arrives here, and it must not reach this output either.
      *) printf 'unknown argument at position %s, not echoed\n' "$((argc - $# + 1))" >&2; rt_usage >&2; return 2 ;;
    esac
  done
  if [ -z "$root" ]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
  [ -n "$data_root" ] || data_root="$root"

  # σ is checked before anything is read, and its value is never echoed: a destination value
  # passed by mistake must not reach this output.
  local sm="" sd="" parsed
  if [ "$has_state" -eq 1 ]; then
    if [ "$mode" = contract ]; then
      rt_finding RT0 "$RT_STATE_FLAG was given with --contract-only, which reads no render — nothing was read"; return 2
    fi
    if ! parsed="$(rt_state_parse "$root" "$state")"; then
      rt_finding RT0 "the $RT_STATE_FLAG value is not <MODE>:<DECIDED|UNDECIDED> with MODE a mode CLAUDE.md § Resolving a trip declares — it is not echoed, and nothing was read"; return 2
    fi
    sm="${parsed%%"$RT_TAB"*}"; sd="${parsed#*"$RT_TAB"}"
  fi

  local acr=0
  case "$mode" in
    contract)
      rt_element_contract "$root"; rc=$?
      rt_artifact_contract "$root"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
      ;;
    trip)
      if [ -z "$slug" ]; then
        rt_finding RT0 "--trip was given no slug"; return 2
      fi
      plan="$data_root/trips/$slug/outputs/final-itinerary.md"
      site="$(ls "$data_root/trips/$slug/outputs/"*-travel-site.html 2>/dev/null | awk 'NR == 1')"
      if [ -z "$site" ]; then
        rt_finding RT0 "no '*-travel-site.html' exists under '$data_root/trips/$slug/outputs/' — there is no site to walk the plan against"
        return 2
      fi
      rt_element_contract "$root"; rc=$?
      rt_artifact_contract "$root"; acr=$?; [ "$acr" -gt "$rc" ] && rc=$acr
      rt_element_instance "$root" "$data_root/trips/$slug" "$site" "$sm" "$sd"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
      rt_state_passes "$root" "$data_root/trips/$slug" "$site" "$sm" "$sd" "$acr"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
      ;;
    pair)
      if [ -z "$plan" ] || [ -z "$site" ]; then
        rt_finding RT0 "--plan and --site must be given together"; return 2
      fi
      rt_instance_walk "$plan" "$site"; rc=$?
      if [ -n "$sm" ]; then
        rt_artifact_contract "$root"; acr=$?; [ "$acr" -gt "$rc" ] && rc=$acr
      fi
      rt_state_passes "$root" - "$site" "$sm" "$sd" "$acr"; r=$?; [ "$r" -gt "$rc" ] && rc=$r
      ;;
    *)
      rt_usage >&2; return 2
      ;;
  esac

  if [ "$rc" -eq 0 ]; then
    printf 'CLEAN every element the walk reached resolved to a rendered component or to a named exclusion, and every pass this run attempted closed%s\n' \
      "${RT_SHAPE_SEEN:+ — shape: $RT_SHAPE_SEEN components observable}"
  fi
  return $rc
}

# Run only when executed directly; sourcing (e.g. for the suite) exposes the functions
# without dispatch. Same shape as scripts/validate-artifacts.sh and
# scripts/publish-trip-site.sh, deliberately — one pattern, one reading.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  rt_main "$@"
fi
