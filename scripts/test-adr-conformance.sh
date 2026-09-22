#!/usr/bin/env bash
#
# test-adr-conformance.sh — the architecture-record conformance suite.
#
#   ./scripts/test-adr-conformance.sh
#
# Grades the shape of reference/adr/. The status field is the only thing telling a reader
# whether a decision is in force, and it lagged reality four times before anything here
# looked for it — every one of those corrections was made by a human who happened to read
# the file. Every suite that existed before this one already read this directory as INPUT;
# none graded it. That is stated without a count on purpose — this same change re-anchors
# the suite-count denominator everywhere it was live, and shipping a fresh one here would
# be the defect being retired, reintroduced by the change retiring it.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   HD   THE HEADER BLOCK. Status, Deciders and Driving work present on every record, and
#        the status value parseable. The block is delimited by THE FIRST `## ` HEADING and
#        never by a line count — see the parser contract below, which records the measured
#        reason.
#   IX   INDEX / FILE AGREEMENT, IN BOTH DIRECTIONS. The status in the record must equal
#        the status in the index table; a record with no index row fails; an index row
#        naming no record fails; and a record carrying MORE THAN ONE index row fails,
#        because a first-match reader is blind to a second row and would stay green while
#        the two disagreed.
#   SP   THE EXPECTED SPINE, ABSENT-ONLY. reference/adr/README.md states the escape hatch
#        in its own words — the list is the expected spine, not a closed set, and carrying
#        a further section is not a divergence to be recorded. So an ABSENT spine section
#        fails and an EXTRA section must not. The spine is read from that convention, and
#        the match is EXACT on the normalised heading rather than a prefix: `Decision
#        drivers` begins with `Decision`, so a prefix reader certifies a record carrying
#        only the former. No live record has that shape; the arm is what keeps it that way.
#   LF   THE LIFECYCLE. A status token drawn from the lifecycle the index declares, and a
#        Superseded record naming the record that supersedes it. The token is the value's
#        LEADING ALPHABETIC WORD, not a substring search — three live records carry the
#        word `Proposed` inside a status line whose actual value is something else.
#   NU   RECORD-NUMBER CONTIGUITY, pinned in BOTH DIRECTIONS against a declared exemption.
#        An undeclared gap fails, and a declared exemption whose number has since been
#        authored fails too. That second direction is what makes this a pin rather than an
#        allowlist: it forces the declaration out in the same change that closes the gap.
#   LG   THE STATUS-LAG CANDIDATE. A record still marked Proposed while an Accepted record
#        cites it — the signature of the defect this suite exists for. It REPORTS and never
#        fails: whether a Proposed record is stale is a question about meaning, and a static
#        arm decides a shape.
#   CTL  a synthetic fixture tree built in a temp dir ON EVERY RUN, plus two arms that
#        replay defects this repository actually shipped. One MUST-FIRE arm per finding code
#        this file can emit, each observed flipping on a mutation that is asserted to have
#        LANDED, alongside the specificity arms that tell a correct implementation from a
#        lookalike and the ADD-ONLY arms that close addition-blindness.
#   Y    the assertion inventory, derived from this file's own emission sites and checked in
#        BOTH DIRECTIONS. The code set is READ FROM this file on every run.
#   PF   no verdict in this file is decided by a pipeline's exit status.
#   MD   the Discriminating-Evidence Rule, asserted against this file's own extractors.
#
# ── THE RECORD SET IS DERIVED, AND ONLY THE GAP IS PINNED ────────────────────────
# THIS FILE HOLDS NO LIST OF RECORDS AND NO COUNT OF THEM. The set is read from the
# directory on every invocation. That is not a style preference — it is the property the
# operator locked this card on, and events rather than argument have validated it: while
# this release was being built, sibling releases kept merging and the record set kept
# growing. Any list written here would have been wrong each time, and re-pinning it by hand
# is the very maintenance this suite exists to remove.
#
# THIS PARAGRAPH CARRIED THE FIGURES ITSELF and they went stale exactly as predicted, four
# lines under the sentence forbidding them. They are gone rather than refreshed: a tally
# here is a copy with no assertion behind it, and the arms below read the real set.
#
# ONE VALUE IS PINNED: ADR_NUM_EXEMPT, the known gap in the sequence. It is declared HERE
# rather than in the index, because this card ships a mechanism and is forbidden from
# reorganising the index. It is asserted in both directions, so the gap can neither widen
# silently (NU2) nor close silently (NU3).
#
# ARM CTL-NU-ORDER DEMONSTRATES MERGE-ORDER INDEPENDENCE rather than asserting it. It drives
# the SAME extractor over three roots built from the live derived set — the set as it is, the
# set with records appended above its maximum (a sibling merging after this release), and the
# set with its top records removed (this release landing first) — and requires the verdict to
# be IDENTICAL across all three. A reader is more likely to assume that property than to
# check it, which is why it is an arm.
#
# ── THE PARSER CONTRACT — three constraints that were measured, not chosen ───────
#   1. THE HEADER BLOCK ENDS AT THE FIRST `## ` HEADING. Not a line count. Measured across
#      the live corpus, the first heading falls anywhere from line 6 to line 169, because an
#      amendment paragraph sits between the title and the fields. A fixed 40-line window was
#      run against a conformant corpus and emitted false findings; that measurement is the
#      whole of why this rule is written down here.
#   2. A STATUS VALUE IS ITS LEADING ALPHABETIC TOKEN. Shipped values carry a parenthesised
#      date, a trailing amendment count, and in one case a whole paragraph of ratification
#      prose that CONTAINS the word `Proposed` while the record is `Accepted`. A substring
#      reader classifies that record as Proposed. Measured on the live tree: three records
#      carry `Proposed` somewhere in the status text and exactly one IS Proposed.
#   3. THE SPINE IS ABSENT-ONLY AND MATCHED EXACTLY. Extra sections are conventional and
#      common; a prefix match on the spine name is satisfied by a longer heading that merely
#      begins with it.
#
# ── WHY THIS FILE ASSERTS NO COUNT OF ITS OWN ────────────────────────────────────
# Every population this suite reports is EMITTED at run time from the tree it just read. No
# numeral in this banner names a corpus population, a group tally, an arm inventory or a code
# set. A numeral written here would be a copy with no assertion behind it, in a repository
# whose corpus-hygiene suite exists to catch exactly that.
#
# ── STRICT SKIP MODE (set by CI — .github/workflows/adr-conformance.yml) ─────────
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# This suite is pure bash and awk with no Node, no gh and no network, so it has NO legitimate
# skip and its expected-skip set is correctly EMPTY. VACUOUS is a distinct verdict from SKIP:
# a skipped GROUP is a hole in the suite, an empty POPULATION is a real measurement of the
# tree, and collapsing the two would hide one behind the other.
#
# ── TWO DEPENDENCIES ON REPOSITORY HISTORY, STATED ───────────────────────────────
# Arms CTL-RETRO-IX and CTL-RETRO-LG read blobs from this repository's history. They are the
# only arms testing these detectors against defects the repository actually shipped rather
# than fixtures this file wrote. They need history deeper than a single commit, which is why
# .github/workflows/adr-conformance.yml sets fetch-depth: 0 and says why. If a blob is
# unreachable the arm FAILS rather than skipping: an unreachable regression witness is a
# hole, and a hole that reports green is the failure mode this suite exists to close.
#
# THERE ARE TWO OF THEM BECAUSE THE TWO CLASSES ARE DIFFERENT, and this was measured rather
# than read off the card. The card presents the index-divergence class and the status-lag
# class together and names one record as the witness for both. At the revision that carried
# the lag, the record's file said Proposed AND SO DID THE INDEX — they agreed. A divergence
# arm replaying that revision would therefore have a PASS its own cited defect could not
# fail, which is precisely the defect class this milestone exists to close. The divergence
# class does have a real witness elsewhere in history, and that is the one IX replays.
#
set -uo pipefail
# Deterministic collation and byte semantics, for the same reason test-corpus-hygiene.sh
# pins it: the character classes below resolve against the collating sequence, and under a
# UTF-8 default a range can match glyphs a C-locale run would not — CI would then enforce a
# rule an operator's own run did not. This suite reads the same markdown corpus that one
# does. It is the OPPOSITE of test-artifact-schema.sh's requirement, which grades the
# locale-sensitivity of its own validator and false-fails when LC_ALL is pinned; the two
# must not borrow a locale from each other or from a shared harness.
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Resolved absolutely and BEFORE anything reads it: groups Y, PF and MD read this file.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"

# The graded directory and its index, relative to a root, so every extractor can be driven
# against a fixture root as readily as against the real tree.
ADR_DIR='reference/adr'
ADR_INDEX='reference/adr/README.md'

# THE ONE PINNED VALUE. The known gap in the record sequence, asserted in both directions.
# Space-separated if it ever holds more than one.
ADR_NUM_EXEMPT='20'

# The historical witnesses. Each is a real revision of this repository.
#   IX — a record whose file read Accepted while the index still read Proposed.
ADR_RETRO_IX_REV='29136df'
ADR_RETRO_IX_TAG='ADR-018'
#   LG — the record that sat Proposed while Accepted records cited its rule.
ADR_RETRO_LG_REV='b22e2ad'
ADR_RETRO_LG_TAG='ADR-019'

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""; VACUOUS_IDS=""
PASS()    { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL()    { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP()    { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
# VACUOUS records the ID of every arm that rendered it, so the closing NOTE can NAME them
# rather than assert a compensating group. The footer used to hardcode one group as the basis
# whenever any vacuous verdict existed; the group that compensates is a property of the arm,
# not of the suite, so a literal there is a claim about a run it never read.
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); VACUOUS_IDS="$VACUOUS_IDS${*%%:*} "; }

# ── THE DISCRIMINATING-EVIDENCE RULE (DER) — helpers, asserted by group MD ─────────
#
# THE RULE. An assertion is MUTATION-DETECTABLE iff every path to its PASS requires evidence
# the subject could only have produced by RUNNING. Equivalently: PASS may never be reached on
# a branch a DEGENERATE outcome also reaches — an absent subject, an empty haystack, an
# unreadable input, an empty population.
#
# md_probe re-runs an assertion in a subshell with its SUBJECT removed and reports the verdict
# counts it produced. PASS/FAIL are rebound to silent counters inside that subshell, so
# nothing a probe emits reaches the run's counters or its output.
md_probe() {   # md_probe <subject-fn> <assertion-fn> [args…] -> "<pass> <fail>" on stdout
  local victim="$1"; shift
  ( unset -f "$victim" 2>/dev/null
    pass=0; fail=0
    PASS() { pass=$((pass+1)); }
    FAIL() { fail=$((fail+1)); }
    "$@" >/dev/null 2>&1
    printf '%d %d' "$pass" "$fail" )
}

# md_flips is the REGISTRATION primitive named by DER clause 6: for assertion X over subject
# S, removing S must flip X specifically. This suite registers its six extractors from its
# FIRST commit rather than shipping the empty-registration note a sibling suite still carries.
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

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
ARM_LOG="$WORK/arms";  : > "$ARM_LOG"
SURF_LOG="$WORK/surf"; : > "$SURF_LOG"

# n_code <output> <code> — how many times the code appears as a finding token, compared as a
# WHOLE FIELD so a code is never a substring of a longer one. This is what every code check in
# this file routes through: the arms compare a COUNT rather than a presence, so an arm reads
# the same way whether a code fired once or five times.
n_code()   { awk -v c="$2" '$1 == "FINDING" && $2 == c { n++ } END { print n + 0 }' <<<"$1"; }
# The denominator line every scan emits. A scan that produced none did not run.
#
# Both here-strings are load-bearing and group PF asserts that they stay here-strings: grep -q
# exits on its first match, and feeding it from a PIPELINE kills the writer with SIGPIPE, which
# under pipefail reports the pipeline as failed even though the match succeeded. A here-string
# is a redirection on a simple command, so there is no second status to aggregate.
#
# A `has_code` predicate sat here and was called by NOTHING — the suite's code checks have
# routed through n_code since they were written. It is removed rather than wired in: wiring a
# dead predicate into live arms changes what those arms evaluate, and the sentences that
# described the routing were the thing that was wrong, not the routing.
has_denom() { grep -q "^DENOM " <<<"$1"; }

# ═════════════════════════════════════════════════════════════════════════════════
# THE EXTRACTORS. Each is written once and is driven by BOTH the real-tree assertion and
# every control arm. A control that ran different code from the assertion would prove
# nothing about the assertion.
# ═════════════════════════════════════════════════════════════════════════════════

# ── ad_records <root> — THE RECORD SET, derived from the directory on every call ──
# No list, no count, no glob written anywhere but here. A record is a file whose basename
# is the three-digit form the index's own convention prescribes.
ad_records() {
  local root="$1" f b
  for f in "$root/$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    case "$b" in
      ADR-[0-9][0-9][0-9]-*.md) printf '%s\n' "$b" ;;
    esac
  done | sort
}

# ── ad_head <file> — the header block: every line up to the FIRST `## ` heading ───
ad_head() { awk '/^## / { exit } { print }' "$1"; }

# ── ad_head_fields — the header FIELDS, named once and read by two groups ────────
# Group HD grades their presence. Group SP SUBTRACTS them from the expected spine, and that
# subtraction is load-bearing rather than tidy: the index convention lists `Status` among its
# "Sections", but the corpus realises Status as a header BULLET and every other entry as a
# `## ` heading. Deriving the subtraction from this one list means every convention entry is
# graded by exactly one group — none falls between them, and none is graded twice. Writing
# `Status` into the spine reader instead would have SP demand a `## Status` heading no record
# has ever carried, which is what the first run of this suite did.
ad_head_fields() { printf 'Status\nDeciders\nDriving work\n'; }

# ── ad_has_field <field> <file> — the field appears as a header bullet, anchored ──
ad_has_field() {
  awk -v fld="$1" '
    /^## / { exit }
    { if ($0 ~ ("^[[:space:]]*-[[:space:]]*\\*\\*" fld ":\\*\\*")) { found = 1; exit } }
    END { exit(found ? 0 : 1) }' "$2"
}

# ── ad_status_raw <file> — the Status value as written, header block only ────────
ad_status_raw() {
  awk '/^## / { exit }
       /^[[:space:]]*-[[:space:]]*\*\*Status:\*\*/ {
         s = $0; sub(/^.*\*\*Status:\*\*[[:space:]]*/, "", s); print s; exit }' "$1"
}

# ── ad_status_tok <file> — its LEADING ALPHABETIC TOKEN, never a substring search ─
ad_status_tok() {
  ad_status_raw "$1" | awk '{ if (match($0, /^[A-Za-z]+/)) print substr($0, RSTART, RLENGTH); exit }'
}

# ── ad_sections <file> — every `## ` heading, normalised: lowercased, a trailing
#    parenthetical dropped, whitespace collapsed. Normalisation is what lets the match be
#    EXACT without being brittle about `## Follow-on build slices (out of scope…)`.
ad_sections() {
  awk '/^## / { s = substr($0, 4)
                sub(/[[:space:]]*\(.*$/, "", s)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
                gsub(/[[:space:]]+/, " ", s)
                print tolower(s) }' "$1"
}

# ── ad_spine <root> — THE EXPECTED SPINE, read from the index's own convention ────
# The convention sentence names the sections separated by the middle dot. Read rather than
# held, so a change to the convention moves this suite with it. Falls back to nothing —
# group SP's vacuity guard turns an unreadable convention red rather than green.
ad_spine() {
  # Joined on a character no field name carries: awk's -v assignment rejects an embedded
  # newline outright, so the natural one-per-line form cannot be passed this way.
  local flds; flds="$(ad_head_fields | tr 'A-Z' 'a-z' | tr '\n' '|')"
  awk '/\*\*Sections:\*\*/, /^$/ {
         line = line " " $0 }
       END {
         if (line == "") exit
         sub(/^.*\*\*Sections:\*\*/, "", line)
         sub(/\..*$/, "", line)
         n = split(line, part, "\302\267")     # the middle dot, byte-wise under LC_ALL=C
         for (i = 1; i <= n; i++) {
           s = part[i]
           gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
           gsub(/[[:space:]]+/, " ", s)
           if (s != "") print tolower(s)
         }
       }' "$1/$ADR_INDEX" 2>/dev/null \
  | awk -v f="$flds" '
      BEGIN { n = split(f, a, "|"); for (i = 1; i <= n; i++) if (a[i] != "") drop[a[i]] = 1 }
      !($0 in drop) { print }'
}

# ── ad_index_rows <root> — TSV "<tag>\t<link>\t<token>\t<raw>" per index row ──────
ad_index_rows() {
  awk '
    /^\|[[:space:]]*\[ADR-[0-9][0-9][0-9]\]\(/ {
      line = $0
      if (!match(line, /ADR-[0-9][0-9][0-9]/)) next
      tag = substr(line, RSTART, RLENGTH)
      lk = ""
      if (match(line, /\]\([^)]*\)/)) lk = substr(line, RSTART + 2, RLENGTH - 3)
      n = split(line, c, "|")
      st = ""
      for (i = n; i >= 1; i--) {
        t = c[i]; gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (t != "") { st = t; break }
      }
      tok = ""
      if (match(st, /^[A-Za-z]+/)) tok = substr(st, RSTART, RLENGTH)
      printf "%s\t%s\t%s\t%s\n", tag, lk, tok, st
    }' "$1/$ADR_INDEX" 2>/dev/null
}

# ── ad_lifecycle <root> — the declared status enum, read from the index convention ─
ad_lifecycle() {
  awk '/\*\*Status lifecycle:\*\*/ {
         line = $0
         while (match(line, /`[A-Za-z]+`/)) {
           print tolower(substr(line, RSTART + 1, RLENGTH - 2))
           line = substr(line, RSTART + RLENGTH)
         }
         exit }' "$1/$ADR_INDEX" 2>/dev/null
}

# ═════════════════════════════════════════════════════════════════════════════════
# THE SCANNERS. Each emits `FINDING <code> …` lines and exactly one `DENOM <group> …`
# line. The DENOM line is the evidence the scan RAN: every assertion below refuses to
# reach PASS without one, so an absent or broken extractor reddens rather than passing.
# ═════════════════════════════════════════════════════════════════════════════════

ad_scan_hd() {   # header block — Status / Deciders / Driving work, present and parseable
  local root="$1" recs b tag f nrec=0 nhead=0 fld
  recs="$(ad_records "$root")"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1)); tag="${b%%-*}-${b:4:3}"
    f="$root/$ADR_DIR/$b"
    if [ -z "$(ad_head "$f")" ]; then
      printf 'FINDING HD0 %s empty-header-block\n' "$tag"; continue
    fi
    nhead=$((nhead+1))
    while IFS= read -r fld; do
      [ -n "$fld" ] || continue
      ad_has_field "$fld" "$f" || printf 'FINDING HD1 %s %s\n' "$tag" "${fld// /-}"
    done <<<"$(ad_head_fields)"
    if ad_has_field 'Status' "$f" && [ -z "$(ad_status_tok "$f")" ]; then
      printf 'FINDING HD2 %s unparseable-status\n' "$tag"
    fi
  done <<<"$recs"
  [ "$nrec" -gt 0 ] && [ "$nhead" -gt 0 ] || printf 'FINDING HD0 no-records-or-no-header-blocks\n'
  printf 'DENOM HD %d %d\n' "$nrec" "$nhead"
}

ad_scan_ix() {   # index / file agreement, both directions
  local root="$1" recs rows b tag f ftok line itag itok iraw ilink nrec=0 nrow=0 seen dup
  recs="$(ad_records "$root")"
  rows="$(ad_index_rows "$root")"
  seen=" "; dup=" "
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    nrow=$((nrow+1))
    itag="${line%%	*}"
    case "$seen" in *" $itag "*) case "$dup" in *" $itag "*) ;; *) dup="$dup$itag " ;; esac ;;
                    *) seen="$seen$itag " ;; esac
  done <<<"$rows"
  for itag in $dup; do
    printf 'FINDING IX4 %s duplicate-index-row\n' "$itag"
  done
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1)); tag="${b%%-*}-${b:4:3}"
    f="$root/$ADR_DIR/$b"
    ftok="$(ad_status_tok "$f")"
    itok=""; iraw=""; ilink=""
    while IFS='	' read -r a bb c d; do
      [ "$a" = "$tag" ] || continue
      ilink="$bb"; itok="$c"; iraw="$d"; break
    done <<<"$rows"
    if [ -z "$ilink" ] && [ -z "$itok" ] && [ -z "$iraw" ]; then
      case "$seen" in
        *" $tag "*) ;;
        *) printf 'FINDING IX2 %s no-index-row\n' "$tag"; continue ;;
      esac
    fi
    if [ "$ftok" != "$itok" ]; then
      printf 'FINDING IX1 %s file=%s index=%s\n' "$tag" "${ftok:-<none>}" "${itok:-<none>}"
    fi
  done <<<"$recs"
  while IFS='	' read -r itag ilink itok iraw; do
    [ -n "$itag" ] || continue
    [ -n "$ilink" ] || { printf 'FINDING IX3 %s no-link\n' "$itag"; continue; }
    [ -f "$root/$ADR_DIR/$ilink" ] || printf 'FINDING IX3 %s %s\n' "$itag" "$ilink"
  done <<<"$rows"
  [ "$nrec" -gt 0 ] && [ "$nrow" -gt 0 ] || printf 'FINDING IX0 no-records-or-no-index-rows\n'
  printf 'DENOM IX %d %d\n' "$nrec" "$nrow"
}

ad_scan_sp() {   # the expected spine — ABSENT-only; an extra section must not fire
  local root="$1" recs spine b tag f secs s nrec=0 nsec=0 nspine=0
  recs="$(ad_records "$root")"
  spine="$(ad_spine "$root")"
  while IFS= read -r s; do [ -n "$s" ] && nspine=$((nspine+1)); done <<<"$spine"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1)); tag="${b%%-*}-${b:4:3}"
    f="$root/$ADR_DIR/$b"
    secs="$(ad_sections "$f")"
    while IFS= read -r s; do [ -n "$s" ] && nsec=$((nsec+1)); done <<<"$secs"
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      # EXACT equality on the normalised heading. A prefix test here is satisfied by
      # `decision drivers` standing in for `decision`, and the arm CTL-SP1-PFX is the
      # standing proof that this line is what refuses it.
      printf '%s\n' "$secs" | awk -v want="$s" '$0 == want { f = 1 } END { exit(f ? 0 : 1) }' \
        || printf 'FINDING SP1 %s %s\n' "$tag" "${s// /-}"
    done <<<"$spine"
  done <<<"$recs"
  [ "$nrec" -gt 0 ] && [ "$nsec" -gt 0 ] && [ "$nspine" -gt 0 ] \
    || printf 'FINDING SP0 no-records-no-sections-or-no-spine\n'
  printf 'DENOM SP %d %d %d\n' "$nrec" "$nsec" "$nspine"
}

ad_scan_lf() {   # the lifecycle enum, and a Superseded record naming its superseder
  local root="$1" recs life b tag f tok raw nrec=0 nlife=0 nstat=0 ok
  recs="$(ad_records "$root")"
  life="$(ad_lifecycle "$root")"
  while IFS= read -r ok; do [ -n "$ok" ] && nlife=$((nlife+1)); done <<<"$life"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1)); tag="${b%%-*}-${b:4:3}"
    f="$root/$ADR_DIR/$b"
    tok="$(ad_status_tok "$f")"
    [ -n "$tok" ] || continue
    nstat=$((nstat+1))
    if [ "$nlife" -gt 0 ]; then
      printf '%s\n' "$life" | awk -v want="$(printf '%s' "$tok" | tr 'A-Z' 'a-z')" \
        '$0 == want { f = 1 } END { exit(f ? 0 : 1) }' \
        || printf 'FINDING LF1 %s %s\n' "$tag" "$tok"
    fi
    if [ "$(printf '%s' "$tok" | tr 'A-Z' 'a-z')" = "superseded" ]; then
      raw="$(ad_status_raw "$f")"
      case "$raw" in
        *ADR-[0-9][0-9][0-9]*) ;;
        *) printf 'FINDING LF2 %s names-no-superseder\n' "$tag" ;;
      esac
    fi
  done <<<"$recs"
  [ "$nrec" -gt 0 ] && [ "$nstat" -gt 0 ] && [ "$nlife" -gt 0 ] \
    || printf 'FINDING LF0 no-records-no-statuses-or-no-lifecycle\n'
  printf 'DENOM LF %d %d %d\n' "$nrec" "$nstat" "$nlife"
}

ad_scan_nu() {   # contiguity, pinned in BOTH directions against the declared exemption
  local root="$1" exempt="${2-}" recs b n lo hi i nrec=0 nums=" " dup=" " e
  recs="$(ad_records "$root")"
  lo=""; hi=""
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1))
    n="${b:4:3}"; n="$((10#$n))"
    case "$nums" in
      *" $n "*) case "$dup" in *" $n "*) ;; *) dup="$dup$n " ;; esac ;;
      *) nums="$nums$n " ;;
    esac
    [ -z "$lo" ] || [ "$n" -ge "$lo" ] || lo="$n"; [ -n "$lo" ] || lo="$n"
    [ -z "$hi" ] || [ "$n" -le "$hi" ] || hi="$n"; [ -n "$hi" ] || hi="$n"
  done <<<"$recs"
  for n in $dup; do printf 'FINDING NU1 %s duplicate-record-number\n' "$n"; done
  if [ -n "$lo" ] && [ -n "$hi" ]; then
    i="$lo"
    while [ "$i" -le "$hi" ]; do
      case "$nums" in
        *" $i "*) # present — a DECLARED exemption that is present is a stale declaration
          case " $exempt " in
            *" $i "*) printf 'FINDING NU3 %s declared-exempt-but-present\n' "$i" ;;
          esac ;;
        *) # absent — a gap is a finding unless it is the declared one
          case " $exempt " in
            *" $i "*) ;;
            *) printf 'FINDING NU2 %s undeclared-gap\n' "$i" ;;
          esac ;;
      esac
      i=$((i+1))
    done
  fi
  [ "$nrec" -gt 0 ] || printf 'FINDING NU0 no-record-numbers-parsed\n'
  printf 'DENOM NU %d %s %s\n' "$nrec" "${lo:--}" "${hi:--}"
}

ad_scan_lg() {   # the status-lag candidate — a Proposed record an Accepted record cites
  local root="$1" recs b tag f tok nrec=0 nclass=0 nprop=0 t2 f2 tok2 b2
  recs="$(ad_records "$root")"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    nrec=$((nrec+1)); tag="${b%%-*}-${b:4:3}"
    f="$root/$ADR_DIR/$b"
    tok="$(ad_status_tok "$f")"
    [ -n "$tok" ] || continue
    nclass=$((nclass+1))
    [ "$(printf '%s' "$tok" | tr 'A-Z' 'a-z')" = "proposed" ] || continue
    nprop=$((nprop+1))
    while IFS= read -r b2; do
      [ -n "$b2" ] || continue
      t2="${b2%%-*}-${b2:4:3}"
      [ "$t2" != "$tag" ] || continue
      f2="$root/$ADR_DIR/$b2"
      tok2="$(ad_status_tok "$f2")"
      [ "$(printf '%s' "$tok2" | tr 'A-Z' 'a-z')" = "accepted" ] || continue
      if awk -v t="$tag" 'index($0, t) { f = 1 } END { exit(f ? 0 : 1) }' "$f2"; then
        printf 'FINDING LG1 %s cited-by=%s\n' "$tag" "$t2"
      fi
    done <<<"$recs"
  done <<<"$recs"
  [ "$nrec" -gt 0 ] && [ "$nclass" -gt 0 ] || printf 'FINDING LG0 no-records-classified-by-status\n'
  printf 'DENOM LG %d %d %d\n' "$nrec" "$nclass" "$nprop"
}

# ═════════════════════════════════════════════════════════════════════════════════
# THE LIVE ASSERTIONS. One verdict per group, its denominator stated in the verdict text.
# Each refuses to reach PASS without a DENOM line, so an absent extractor reddens.
# ═════════════════════════════════════════════════════════════════════════════════

ad_denom() { awk -v g="$2" '$1 == "DENOM" && $2 == g { $1=""; $2=""; sub(/^  /,""); print }' <<<"$1"; }

ad_assert_hd() {   # ad_assert_hd <root>
  local out d n0 n1 n2
  out="$(ad_scan_hd "$1")"
  if ! has_denom "$out"; then
    FAIL "HD: the header scan produced no denominator, so it did not run — its zero findings prove nothing about any record"; return 0
  fi
  d="$(ad_denom "$out" HD)"
  n0="$(n_code "$out" HD0)"; n1="$(n_code "$out" HD1)"; n2="$(n_code "$out" HD2)"
  if [ "$n0" -gt 0 ]; then
    FAIL "HD: the graded surface is degenerate — $n0 vacuity finding(s) over <record,header> = $d. A conformance verdict over no records is not a clean corpus"
  elif [ "$n1" -eq 0 ] && [ "$n2" -eq 0 ]; then
    PASS "HD: every record carries Status, Deciders and Driving work in its header block, and every Status yields a leading token — <records,header-blocks> = $d. The block is delimited by the first '## ' heading, so a record whose fields sit behind an amendment paragraph is read correctly"
  else
    FAIL "HD: $n1 absent header field(s) and $n2 unparseable status value(s) over <records,header-blocks> = $d — $(grep '^FINDING HD[12] ' <<<"$out" | tr '\n' ';')"
  fi
  return 0
}

ad_assert_ix() {   # ad_assert_ix <root>
  local out d n0 n1 n2 n3 n4
  out="$(ad_scan_ix "$1")"
  if ! has_denom "$out"; then
    FAIL "IX: the index scan produced no denominator, so it did not run — its agreement verdict is not a measurement"; return 0
  fi
  d="$(ad_denom "$out" IX)"
  n0="$(n_code "$out" IX0)"; n1="$(n_code "$out" IX1)"; n2="$(n_code "$out" IX2)"
  n3="$(n_code "$out" IX3)"; n4="$(n_code "$out" IX4)"
  if [ "$n0" -gt 0 ]; then
    FAIL "IX: the graded surface is degenerate — <records,index-rows> = $d. An agreement check with one side empty agrees with nothing"
  elif [ "$n1" -eq 0 ] && [ "$n2" -eq 0 ] && [ "$n3" -eq 0 ] && [ "$n4" -eq 0 ]; then
    PASS "IX: file and index agree on every record's status, in BOTH directions — <records,index-rows> = $d, no record without a row, no row without a record, no record carrying two rows. The live population is clean, which is why this group's regression evidence is the historical arm rather than this verdict"
  else
    FAIL "IX: $n1 divergence(s), $n2 record(s) with no index row, $n3 index row(s) with no record, $n4 duplicated row(s) over <records,index-rows> = $d — $(grep '^FINDING IX[1234] ' <<<"$out" | tr '\n' ';')"
  fi
  return 0
}

ad_assert_sp() {   # ad_assert_sp <root>
  local out d n0 n1
  out="$(ad_scan_sp "$1")"
  if ! has_denom "$out"; then
    FAIL "SP: the spine scan produced no denominator, so it did not run — no record was graded"; return 0
  fi
  d="$(ad_denom "$out" SP)"
  n0="$(n_code "$out" SP0)"; n1="$(n_code "$out" SP1)"
  if [ "$n0" -gt 0 ]; then
    FAIL "SP: the graded surface is degenerate — <records,sections,spine> = $d. A spine read as empty certifies every record trivially"
  elif [ "$n1" -eq 0 ]; then
    PASS "SP: every record carries every expected-spine section — <records,sections,spine-entries> = $d. Extra sections are admitted by the index's own escape hatch and are not graded"
  else
    FAIL "SP: $n1 expected-spine section(s) absent over <records,sections,spine-entries> = $d — $(grep '^FINDING SP1 ' <<<"$out" | awk '{ print $3 " lacks " $4 }' | tr '\n' ';'). This is the known day-one backlog and the whole of the flip-to-enforce condition; this card ships a mechanism and may not edit a record"
  fi
  return 0
}

ad_assert_lf() {   # ad_assert_lf <root>
  local out d n0 n1 n2 nsup
  out="$(ad_scan_lf "$1")"
  if ! has_denom "$out"; then
    FAIL "LF: the lifecycle scan produced no denominator, so it did not run — no status value was classified"; return 0
  fi
  d="$(ad_denom "$out" LF)"
  n0="$(n_code "$out" LF0)"; n1="$(n_code "$out" LF1)"; n2="$(n_code "$out" LF2)"
  nsup="$(ad_supersede_count "$1")"
  if [ "$n0" -gt 0 ]; then
    FAIL "LF: the graded surface is degenerate — <records,statuses,lifecycle-values> = $d. A status enum read as empty admits every value"
  elif [ "$n1" -gt 0 ] || [ "$n2" -gt 0 ]; then
    FAIL "LF: $n1 status value(s) outside the declared lifecycle and $n2 Superseded record(s) naming no superseder, over <records,statuses,lifecycle-values> = $d — $(grep '^FINDING LF[12] ' <<<"$out" | tr '\n' ';')"
  elif [ "$nsup" -eq 0 ]; then
    VACUOUS "LF: every status value is drawn from the declared lifecycle — <records,statuses,lifecycle-values> = $d — but the SUPERSESSION limb graded 0 Superseded record(s) and therefore proved nothing about this tree. That limb's verdict rests entirely on arm CTL-LF2, which plants one"
  else
    PASS "LF: every status value is drawn from the declared lifecycle and each of the $nsup Superseded record(s) names its superseding record — <records,statuses,lifecycle-values> = $d"
  fi
  return 0
}

# The Superseded population, counted separately so the LF verdict can say which of its two
# limbs was vacuous rather than rendering the whole group vacuous or the whole group clean.
ad_supersede_count() {
  local root="$1" b n=0 tok
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    tok="$(ad_status_tok "$root/$ADR_DIR/$b")"
    [ "$(printf '%s' "$tok" | tr 'A-Z' 'a-z')" = "superseded" ] && n=$((n+1))
  done <<<"$(ad_records "$root")"
  printf '%d' "$n"
}

ad_assert_nu() {   # ad_assert_nu <root>
  local out d n0 n1 n2 n3
  out="$(ad_scan_nu "$1" "$ADR_NUM_EXEMPT")"
  if ! has_denom "$out"; then
    FAIL "NU: the numbering scan produced no denominator, so it did not run — the contiguity verdict is not a measurement"; return 0
  fi
  d="$(ad_denom "$out" NU)"
  n0="$(n_code "$out" NU0)"; n1="$(n_code "$out" NU1)"
  n2="$(n_code "$out" NU2)"; n3="$(n_code "$out" NU3)"
  if [ "$n0" -gt 0 ]; then
    FAIL "NU: no record number was parsed — <records,lo,hi> = $d. A contiguity verdict over an empty sequence is contiguous by vacuity"
  elif [ "$n1" -eq 0 ] && [ "$n2" -eq 0 ] && [ "$n3" -eq 0 ]; then
    PASS "NU: the record sequence is contiguous over <records,lo,hi> = $d except for the declared exemption(s) '$ADR_NUM_EXEMPT', which are still absent. Pinned in BOTH directions: an undeclared gap fails, and a declared exemption that has since been authored fails too, so closing the gap forces the declaration out in the same change"
  else
    FAIL "NU: $n1 duplicate number(s), $n2 undeclared gap(s), $n3 stale exemption(s) over <records,lo,hi> = $d — $(grep '^FINDING NU[123] ' <<<"$out" | tr '\n' ';')"
  fi
  return 0
}

ad_assert_lg() {   # ad_assert_lg <root>
  local out d n0 n1 nprop
  out="$(ad_scan_lg "$1")"
  if ! has_denom "$out"; then
    FAIL "LG: the lag scan produced no denominator, so it did not run — no record was classified by status"; return 0
  fi
  d="$(ad_denom "$out" LG)"
  n0="$(n_code "$out" LG0)"; n1="$(n_code "$out" LG1)"
  nprop="$(awk '{ print $5 }' <<<"$(grep '^DENOM LG ' <<<"$out")")"
  if [ "$n0" -gt 0 ]; then
    FAIL "LG: no record was classified by status — <records,classified,proposed> = $d. A lag report over an unclassified corpus reports nothing"
  elif [ "${nprop:-0}" -eq 0 ]; then
    VACUOUS "LG: no record carries the Proposed status — <records,classified,proposed> = $d — so the lag population is empty and this group proved nothing about this tree. Its verdict rests on arms CTL-LG1 and CTL-RETRO-LG"
  elif [ "$n1" -eq 0 ]; then
    PASS "LG: ${nprop} Proposed record(s) graded over <records,classified,proposed> = $d, and NONE is cited by an Accepted record — no citation pressure, so no lag candidate. This group REPORTS and never fails: whether a Proposed record is stale is a question about meaning, and a static arm decides a shape"
  else
    PASS "LG: REPORT ONLY — $n1 lag candidate(s) over <records,classified,proposed> = $d: $(grep '^FINDING LG1 ' <<<"$out" | tr '\n' ';'). A record still marked Proposed while an Accepted record cites it is the signature this suite exists for. This is a candidate for a human to adjudicate, not a verdict — the group does not fail on it"
  fi
  return 0
}

# ═════════════════════════════════════════════════════════════════════════════════
# THE FIXTURE BUILDER. One conformant tree, built from parts, mutated by each arm. Every
# arm asserts its mutation LANDED before reading a verdict, so a fixture that silently
# failed to change cannot be reported as a detector that correctly stayed silent.
# ═════════════════════════════════════════════════════════════════════════════════

ctl_arm() { echo "$1" >> "$ARM_LOG"; }

ctl_record() {   # ctl_record <root> <NNN> <status-value> [extra-section…]
  local root="$1" n="$2" st="$3"; shift 3
  local d="$root/$ADR_DIR" f s
  mkdir -p "$d"
  f="$d/ADR-$n-fixture.md"
  { printf '# ADR-%s: A fixture record written by the control arms\n\n' "$n"
    printf -- '- **Status:** %s\n' "$st"
    printf -- '- **Deciders:** repo maintainer\n'
    printf -- '- **Driving work:** the fixture tree this suite builds on every run.\n\n'
    printf '## Context\n\nFixture.\n\n'
    printf '## Decision drivers\n\nFixture.\n\n'
    printf '## Options considered\n\nFixture.\n\n'
    printf '## Decision\n\nFixture.\n\n'
    printf '## Consequences\n\nFixture.\n\n'
    printf '## References\n\nFixture.\n\n'
    for s in "$@"; do printf '## %s\n\nFixture.\n\n' "$s"; done
  } > "$f"
}

ctl_index() {   # ctl_index <root> <"NNN:Status">…  — writes the convention AND the table
  local root="$1"; shift
  local d="$root/$ADR_DIR" r n st
  mkdir -p "$d"
  { printf '# Architecture Decision Records\n\n## Convention\n\n'
    printf -- '- **Sections:** Status \302\267 Context \302\267 Decision drivers \302\267 Options considered \302\267 Decision \302\267\n'
    printf '  Consequences \302\267 References. A `Follow-on build slices` section is conventional.\n'
    printf '  This list is the expected spine, not a closed set.\n'
    printf -- '- **Status lifecycle:** `Proposed` \342\206\222 `Accepted` \342\206\222 `Superseded`.\n\n'
    printf '## Index\n\n| ADR | Title | Status |\n|-----|-------|--------|\n'
    for r in "$@"; do
      n="${r%%:*}"; st="${r#*:}"
      printf '| [ADR-%s](ADR-%s-fixture.md) | A fixture record | %s |\n' "$n" "$n" "$st"
    done
  } > "$d/README.md"
}

ctl_clean() {   # ctl_clean <root> — a wholly conformant fixture tree
  local root="$1"
  rm -rf "$root"; mkdir -p "$root/$ADR_DIR"
  ctl_record "$root" 001 'Accepted (2026-01-01)'
  ctl_record "$root" 002 'Accepted (2026-01-02)' 'Follow-on build slices'
  ctl_record "$root" 003 'Accepted (2026-01-03)'
  ctl_index  "$root" '001:Accepted' '002:Accepted' '003:Accepted'
}

# ctl_landed asserts a mutation actually changed the tree before any verdict is read from
# it. A fixture that silently failed to change would let a detector's silence read as a
# correct negative — the degenerate branch DER forbids.
ctl_landed() {   # ctl_landed <label> <file> <pattern-that-must-now-be-present>
  local label="$1" f="$2" pat="$3"
  if [ ! -r "$f" ]; then
    FAIL "$label: the mutation target $f is unreadable, so nothing was planted and the verdict below would grade an unmutated tree"; return 1
  fi
  if ! grep -q -- "$pat" "$f"; then
    FAIL "$label: the mutation did not LAND in $f — the planted text is absent, so a silent detector below would be indistinguishable from a correct one"; return 1
  fi
  return 0
}

ctl_mustfire() {   # ctl_mustfire <label> <code> <output> <what-was-planted> [<expected-n>]
  local label="$1" code="$2" out="$3" what="$4" want="${5:-}"
  ctl_arm "$code"
  local n; n="$(n_code "$out" "$code")"
  if [ "$n" -eq 0 ]; then
    FAIL "$label: MUST FIRE — $what, and the extractor reported no $code. A code with no arm behind it is a check indistinguishable from one that cannot fire"
  elif [ -n "$want" ] && [ "$n" -ne "$want" ]; then
    FAIL "$label: MUST FIRE $want time(s) — $what, and the extractor reported $code $n time(s). The arity is the assertion here, not merely the firing"
  else
    PASS "$label: $code fired ($n) — $what"
  fi
}

ctl_mustnot() {   # ctl_mustnot <label> <code> <output> <what-was-planted>
  local label="$1" code="$2" out="$3" what="$4"
  local n; n="$(n_code "$out" "$code")"
  if [ "$n" -eq 0 ]; then
    PASS "$label: $code correctly silent — $what"
  else
    FAIL "$label: $code fired $n time(s) on an input it must NOT fire on — $what. A detector that cannot tell a correct implementation from a lookalike reports the corpus, not the defect"
  fi
}

# ═════════════════════════════════════════════════════════════════════════════════
echo "══ test-adr-conformance.sh — the architecture-record conformance suite"
echo

echo "── Group HD — the header block: Status, Deciders and Driving work, present and parseable."
echo "HD0" >> "$SURF_LOG"; echo "HD1" >> "$SURF_LOG"; echo "HD2" >> "$SURF_LOG"
ad_assert_hd "$ROOT"

echo
echo "── Group IX — index and file agree on status, in both directions."
for c in IX0 IX1 IX2 IX3 IX4; do echo "$c" >> "$SURF_LOG"; done
ad_assert_ix "$ROOT"

echo
echo "── Group SP — the expected spine, absent-only; an extra section is admitted."
echo "SP0" >> "$SURF_LOG"; echo "SP1" >> "$SURF_LOG"
ad_assert_sp "$ROOT"

echo
echo "── Group LF — the declared lifecycle, and a Superseded record names its superseder."
for c in LF0 LF1 LF2; do echo "$c" >> "$SURF_LOG"; done
ad_assert_lf "$ROOT"

echo
echo "── Group NU — record-number contiguity, pinned in both directions."
for c in NU0 NU1 NU2 NU3; do echo "$c" >> "$SURF_LOG"; done
ad_assert_nu "$ROOT"

echo
echo "── Group LG — the status-lag candidate. Reports; never fails."
echo "LG0" >> "$SURF_LOG"; echo "LG1" >> "$SURF_LOG"
ad_assert_lg "$ROOT"

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "CTL — the control arms. Every finding code above, fired on a mutation asserted to have landed."
# ═════════════════════════════════════════════════════════════════════════════════

CLEAN="$WORK/clean"
ctl_clean "$CLEAN"

# ── The baseline. A conformant fixture must be SILENT on every code, or every arm below
#    is measuring the fixture rather than the mutation.
CTL_BASE="$(ad_scan_hd "$CLEAN"; ad_scan_ix "$CLEAN"; ad_scan_sp "$CLEAN"
            ad_scan_lf "$CLEAN"; ad_scan_nu "$CLEAN" ''; ad_scan_lg "$CLEAN")"
CTL_BASE_N="$(grep -c '^FINDING ' <<<"$CTL_BASE" || true)"
if [ "$CTL_BASE_N" -eq 0 ]; then
  PASS "CTL-BASE: the conformant fixture tree emits 0 findings across all six scanners, so every arm below measures its own mutation rather than a defect the fixture was born with"
else
  FAIL "CTL-BASE: the conformant fixture tree emits $CTL_BASE_N finding(s) before any mutation — every MUST-FIRE arm below is therefore uninterpretable: $(grep '^FINDING ' <<<"$CTL_BASE" | tr '\n' ';')"
fi

# ── HD1 — a record missing a header field, one arm per field (arity is the assertion) ──
D="$WORK/hd1"; ctl_clean "$D"
awk '!/^- \*\*Deciders:\*\*/' "$D/$ADR_DIR/ADR-002-fixture.md" > "$D/tmp" && mv "$D/tmp" "$D/$ADR_DIR/ADR-002-fixture.md"
if ctl_landed "CTL-HD1" "$D/$ADR_DIR/ADR-002-fixture.md" '\*\*Status:\*\*'; then
  ctl_mustfire "CTL-HD1" HD1 "$(ad_scan_hd "$D")" "one record's Deciders bullet was deleted from its header block" 1
fi

# ── HD1 ADD-ONLY — the addition-blind closure. Two EXTRA header fields are added and one
#    required field removed; a reader satisfied by field COUNT, or by the presence of any
#    bold header bullet, stays green.
D="$WORK/hd1add"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-003-fixture.md"
awk '{ print }
     /^- \*\*Deciders:\*\*/ { print "- **Supersedes:** nothing"; print "- **Review date:** 2027-01-01" }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
awk '!/^- \*\*Driving work:\*\*/' "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-HD1-ADD" "$F" '\*\*Review date:\*\*'; then
  ctl_mustfire "CTL-HD1-ADD" HD1 "$(ad_scan_hd "$D")" "a record gained TWO extra header fields and lost Driving work — an ADD-ONLY input for every reader that counts fields rather than naming them" 1
fi

# ── HD2 — a Status bullet present but yielding no leading alphabetic token ─────────
D="$WORK/hd2"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-001-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** (2026-01-01)"; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-HD2" "$F" '\*\*Status:\*\* (2026-01-01)'; then
  ctl_mustfire "CTL-HD2" HD2 "$(ad_scan_hd "$D")" "a Status bullet whose value opens with a parenthesis yields no token to classify" 1
fi

# ── HD0 — the vacuity guard. An empty record directory is degenerate, never clean ──
D="$WORK/hd0"; ctl_clean "$D"; rm -f "$D/$ADR_DIR"/ADR-*.md
ctl_mustfire "CTL-HD0" HD0 "$(ad_scan_hd "$D")" "every record file was removed, so the header scan has no subject at all" 1

# ── IX1 — file and index disagree ─────────────────────────────────────────────────
D="$WORK/ix1"; ctl_clean "$D"
ctl_index "$D" '001:Accepted' '002:Proposed' '003:Accepted'
if ctl_landed "CTL-IX1" "$D/$ADR_INDEX" '| \[ADR-002\](ADR-002-fixture.md) | A fixture record | Proposed |'; then
  ctl_mustfire "CTL-IX1" IX1 "$(ad_scan_ix "$D")" "the index row says Proposed where the record file says Accepted" 1
fi

# ── IX2 — a record with no index row ──────────────────────────────────────────────
D="$WORK/ix2"; ctl_clean "$D"
ctl_index "$D" '001:Accepted' '002:Accepted'
ctl_mustfire "CTL-IX2" IX2 "$(ad_scan_ix "$D")" "a record file exists that the index does not list" 1

# ── IX3 — an index row naming no record. This IS the addition case for the pair ────
D="$WORK/ix3"; ctl_clean "$D"
ctl_index "$D" '001:Accepted' '002:Accepted' '003:Accepted' '004:Accepted'
if ctl_landed "CTL-IX3" "$D/$ADR_INDEX" 'ADR-004-fixture.md'; then
  ctl_mustfire "CTL-IX3" IX3 "$(ad_scan_ix "$D")" "an index row was ADDED for a record that does not exist — an addition-only mutation to the index" 1
fi

# ── IX4 — a SECOND index row for one record. The addition-blind closure: a first-match
#    reader takes one row, never sees the second, and stays green while the two disagree.
D="$WORK/ix4"; ctl_clean "$D"
ctl_index "$D" '001:Accepted' '002:Accepted' '003:Accepted' '002:Proposed'
if ctl_landed "CTL-IX4" "$D/$ADR_INDEX" '| A fixture record | Proposed |'; then
  ctl_mustfire "CTL-IX4" IX4 "$(ad_scan_ix "$D")" "a SECOND index row was added for one record, disagreeing with the first — the input a first-match reader is blind to" 1
fi

# ── IX0 — the vacuity guard: an index with no rows ────────────────────────────────
D="$WORK/ix0"; ctl_clean "$D"; ctl_index "$D"
ctl_mustfire "CTL-IX0" IX0 "$(ad_scan_ix "$D")" "the index table carries no rows at all, so the agreement check has one empty side" 1

# ── SP1 — an expected-spine section absent ────────────────────────────────────────
D="$WORK/sp1"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-002-fixture.md"
awk '/^## References$/ { skip = 1 } /^## / && !/^## References$/ { skip = 0 } !skip { print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ! grep -q '^## References$' "$F"; then
  ctl_mustfire "CTL-SP1" SP1 "$(ad_scan_sp "$D")" "one record's References section was deleted" 1
else
  FAIL "CTL-SP1: the mutation did not land — the References heading is still present, so the verdict below would grade an unmutated record"
fi

# ── SP1 ADD-ONLY — three EXTRA sections added and one spine section removed. A reader
#    satisfied by section COUNT, or by 'has at least N sections', stays green.
D="$WORK/sp1add"; ctl_clean "$D"
ctl_record "$D" 003 'Accepted (2026-01-03)' 'Residuals' 'Open questions' 'Follow-on build slices'
F="$D/$ADR_DIR/ADR-003-fixture.md"
awk '/^## Consequences$/ { skip = 1 } /^## / && !/^## Consequences$/ { skip = 0 } !skip { print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-SP1-ADD" "$F" '^## Open questions$'; then
  ctl_mustfire "CTL-SP1-ADD" SP1 "$(ad_scan_sp "$D")" "a record gained THREE extra sections and lost Consequences — an ADD-ONLY input for any count-based reader" 1
fi

# ── SP1 SPECIFICITY — extra sections alone must be SILENT. This is the index's own
#    escape hatch, quoted in its convention, and the half a stricter reader gets wrong.
D="$WORK/sp1not"; ctl_clean "$D"
ctl_record "$D" 003 'Accepted (2026-01-03)' 'Follow-on build slices' 'Residuals' 'Open questions'
if ctl_landed "CTL-SP1-NOT" "$D/$ADR_DIR/ADR-003-fixture.md" '^## Residuals$'; then
  ctl_mustnot "CTL-SP1-NOT" SP1 "$(ad_scan_sp "$D")" "a record carrying every spine section PLUS three extra ones — carrying a further section is not a divergence, and the index says so in its own words"
fi

# ── SP1 SPECIFICITY, THE PREFIX LOOKALIKE — 'Decision drivers' must not stand in for
#    'Decision'. No live record has this shape; this arm is what keeps it a defect.
D="$WORK/sp1pfx"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-001-fixture.md"
awk '/^## Decision$/ { skip = 1 } /^## / && !/^## Decision$/ { skip = 0 } !skip { print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-SP1-PFX" "$F" '^## Decision drivers$'; then
  if grep -q '^## Decision$' "$F"; then
    FAIL "CTL-SP1-PFX: the mutation did not land — '## Decision' survives, so this arm cannot discriminate exact matching from prefix matching"
  else
    ctl_mustfire "CTL-SP1-PFX" SP1 "$(ad_scan_sp "$D")" "'## Decision' was removed while '## Decision drivers' remains — a PREFIX matcher certifies this record and an exact matcher refuses it" 1
  fi
fi

# ── SP0 — the vacuity guard: a spine that reads empty certifies every record trivially ──
D="$WORK/sp0"; ctl_clean "$D"
printf '# Architecture Decision Records\n\nNo convention block at all.\n' > "$D/$ADR_INDEX"
ctl_mustfire "CTL-SP0" SP0 "$(ad_scan_sp "$D")" "the index carries no Sections convention, so the expected spine reads empty" 1

# ── LF1 — a status token outside the declared lifecycle ───────────────────────────
D="$WORK/lf1"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-002-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Ratified (2026-01-02)"; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-LF1" "$F" '\*\*Status:\*\* Ratified'; then
  ctl_mustfire "CTL-LF1" LF1 "$(ad_scan_lf "$D")" "a record's status reads Ratified, which the declared lifecycle does not admit" 1
fi

# ── LF1 SPECIFICITY — the live shape a substring reader gets wrong. The status value is
#    Accepted and the SAME LINE contains the word Proposed. Measured on the live tree:
#    more than one record carries this, and exactly one record actually IS Proposed.
D="$WORK/lf1not"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-001-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Accepted (2026-01-09). Landed `Proposed` (2026-01-01) and ratified here."; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
if ctl_landed "CTL-LF1-NOT" "$F" 'Landed `Proposed`'; then
  LF1NOT_TOK="$(ad_status_tok "$F")"
  if [ "$LF1NOT_TOK" = "Accepted" ]; then
    PASS "CTL-LF1-NOT: a status line reading 'Accepted (…). Landed \`Proposed\` (…) and ratified here.' classifies as '$LF1NOT_TOK' — the LEADING TOKEN, not a substring. A substring reader calls this record Proposed, and the live corpus carries this exact shape"
  else
    FAIL "CTL-LF1-NOT: the same status line classified as '$LF1NOT_TOK' rather than 'Accepted' — the reader is taking a substring, which misclassifies live records whose ratification prose names the earlier status"
  fi
  ctl_mustnot "CTL-LG1-SUB" LG1 "$(ad_scan_lg "$D")" "a record whose status PROSE contains the word Proposed while its value is Accepted — it must not enter the lag population. This is the same fixture read by the other group, because the substring defect would corrupt BOTH the lifecycle classification and the lag population and a fix to one does not imply a fix to the other"
fi

# ── LF2 — a Superseded record naming no superseding record ────────────────────────
D="$WORK/lf2"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-002-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Superseded (2026-01-05)"; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
ctl_index "$D" '001:Accepted' '002:Superseded' '003:Accepted'
if ctl_landed "CTL-LF2" "$F" '\*\*Status:\*\* Superseded'; then
  ctl_mustfire "CTL-LF2" LF2 "$(ad_scan_lf "$D")" "a record marked Superseded names no ADR-NNN that supersedes it" 1
fi

# ── LF2 SPECIFICITY — a Superseded record that DOES name its superseder is silent, and
#    an Accepted record whose header mentions 'Supersedes ADR-NNN' is not in scope at all.
D="$WORK/lf2not"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-002-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Superseded by ADR-003 (2026-01-05)"; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
F3="$D/$ADR_DIR/ADR-003-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Accepted (2026-01-03). Supersedes ADR-002."; else print }' \
  "$F3" > "$D/tmp" && mv "$D/tmp" "$F3"
ctl_index "$D" '001:Accepted' '002:Superseded' '003:Accepted'
if ctl_landed "CTL-LF2-NOT" "$F" 'Superseded by ADR-003'; then
  ctl_mustnot "CTL-LF2-NOT" LF2 "$(ad_scan_lf "$D")" "a Superseded record that names ADR-003, alongside an Accepted record whose own status names what it supersedes — neither is a finding"
fi

# ── LF0 — the vacuity guard: a lifecycle read as empty admits every value ─────────
D="$WORK/lf0"; ctl_clean "$D"
awk '!/\*\*Status lifecycle:\*\*/' "$D/$ADR_INDEX" > "$D/tmp" && mv "$D/tmp" "$D/$ADR_INDEX"
ctl_mustfire "CTL-LF0" LF0 "$(ad_scan_lf "$D")" "the index declares no status lifecycle, so the enum reads empty and would admit anything" 1

# ── NU1 — two records claiming one number ─────────────────────────────────────────
D="$WORK/nu1"; ctl_clean "$D"
cp "$D/$ADR_DIR/ADR-003-fixture.md" "$D/$ADR_DIR/ADR-003-duplicate.md"
ctl_mustfire "CTL-NU1" NU1 "$(ad_scan_nu "$D" '')" "a second file claims record number 3" 1

# ── NU2 — an UNDECLARED gap in the sequence ───────────────────────────────────────
D="$WORK/nu2"; ctl_clean "$D"
ctl_record "$D" 005 'Accepted (2026-01-05)'
ctl_index "$D" '001:Accepted' '002:Accepted' '003:Accepted' '005:Accepted'
ctl_mustfire "CTL-NU2" NU2 "$(ad_scan_nu "$D" '')" "record 005 was ADDED above a hole at 004, and nothing declares 004 exempt — an addition-only mutation that opens a gap" 1

# ── NU3 — the OTHER direction of the pin. A declared exemption whose number has since
#    been authored is a STALE DECLARATION, and it fails so the declaration is forced out
#    in the same change that closes the gap. This arm is itself an addition-only input:
#    authoring the exempt record is what fires it.
D="$WORK/nu3"; ctl_clean "$D"
ctl_record "$D" 004 'Accepted (2026-01-04)'
ctl_index "$D" '001:Accepted' '002:Accepted' '003:Accepted' '004:Accepted'
ctl_mustfire "CTL-NU3" NU3 "$(ad_scan_nu "$D" '4')" "record 004 was AUTHORED while 4 is still declared exempt — the pin's second direction, and an addition-only input" 1

# ── NU2 SPECIFICITY — the declared gap must be SILENT, which is the whole point of the
#    declaration. Same tree as CTL-NU2, with the exemption supplied.
ctl_mustnot "CTL-NU2-NOT" NU2 "$(ad_scan_nu "$WORK/nu2" '4')" "the same hole at 004, with 4 declared exempt — a declared gap is not a finding"

# ── NU0 — the vacuity guard ───────────────────────────────────────────────────────
D="$WORK/nu0"; ctl_clean "$D"; rm -f "$D/$ADR_DIR"/ADR-*.md
ctl_mustfire "CTL-NU0" NU0 "$(ad_scan_nu "$D" '')" "no record number could be parsed, so contiguity would hold by vacuity" 1

# ── CTL-NU-ORDER — MERGE-ORDER INDEPENDENCE, DEMONSTRATED. ────────────────────────
# The scope-lock criterion this arm discharges is the one a future reader is most likely to
# assume rather than check. Three roots are built FROM THE LIVE DERIVED SET: the set as it
# stands, the set with records APPENDED above its maximum (a sibling release merging after
# this one), and the set with its top records REMOVED (this release landing first). The
# verdict must be byte-identical across all three, because the declared gap sits below every
# one of those boundaries.
#
# WHAT THE AGREEMENT IS WORTH DEPENDS ON ITS SHAPE, and the arm now says so on its own
# verdict rather than leaving a reader to work it out. On a clean corpus all three reads are
# empty, and three empty reads agree for reasons unrelated to merge order — a scanner pinned
# to a maximum would produce the same three. So this arm establishes that the verdict does
# not MOVE with merge order, and never that nothing is pinned; the firing is CTL-NU2's and
# CTL-NU3's to establish, and both are MUST-FIRE.
NUO_A="$WORK/nuo-a"; NUO_B="$WORK/nuo-b"; NUO_C="$WORK/nuo-c"
mkdir -p "$NUO_A/$ADR_DIR" "$NUO_B/$ADR_DIR" "$NUO_C/$ADR_DIR"
NUO_LIVE="$(ad_records "$ROOT")"
NUO_N=0; NUO_MAX=0
while IFS= read -r b; do
  [ -n "$b" ] || continue
  NUO_N=$((NUO_N+1)); n="$((10#${b:4:3}))"
  [ "$n" -le "$NUO_MAX" ] || NUO_MAX="$n"
  : > "$NUO_A/$ADR_DIR/$b"; : > "$NUO_B/$ADR_DIR/$b"
done <<<"$NUO_LIVE"
# (b) two records arrive above the maximum — the sibling merges second
printf '' > "$NUO_B/$ADR_DIR/ADR-$(printf '%03d' $((NUO_MAX+1)))-sibling.md"
printf '' > "$NUO_B/$ADR_DIR/ADR-$(printf '%03d' $((NUO_MAX+2)))-sibling.md"
# (c) the top two records are absent — this release lands first
NUO_KEEP=0
while IFS= read -r b; do
  [ -n "$b" ] || continue
  n="$((10#${b:4:3}))"
  [ "$n" -ge $((NUO_MAX-1)) ] || { : > "$NUO_C/$ADR_DIR/$b"; NUO_KEEP=$((NUO_KEEP+1)); }
done <<<"$NUO_LIVE"
NUO_VA="$(ad_scan_nu "$NUO_A" "$ADR_NUM_EXEMPT" | grep '^FINDING ' || true)"
NUO_VB="$(ad_scan_nu "$NUO_B" "$ADR_NUM_EXEMPT" | grep '^FINDING ' || true)"
NUO_VC="$(ad_scan_nu "$NUO_C" "$ADR_NUM_EXEMPT" | grep '^FINDING ' || true)"
# THE SHAPE OF THE AGREEMENT IS REPORTED, because three EMPTY verdicts agree for reasons that
# have nothing to do with merge order. On a contiguous set with its one hole declared exempt
# every root is clean, so the comparison below is between three empty strings — and a scanner
# that had stopped scanning past some boundary would produce the same three and pass here.
# Naming the shape is what stops this arm being read as more than it is; CTL-NU2 and CTL-NU3
# are the arms that establish the scanner fires at all, and they are MUST-FIRE.
if [ -z "$NUO_VA" ] && [ -z "$NUO_VB" ] && [ -z "$NUO_VC" ]; then
  NUO_SHAPE="all three verdicts are EMPTY — the agreement is between three clean reads, which is agreement of the weakest kind"
else
  NUO_SHAPE="the verdicts are NON-EMPTY and identical, so the agreement is between three actual findings"
fi
if [ "$NUO_N" -eq 0 ] || [ "$NUO_MAX" -eq 0 ]; then
  FAIL "CTL-NU-ORDER: the live record set derived to $NUO_N record(s) with maximum $NUO_MAX, so the three orderings were built over nothing and their agreement proves nothing"
elif [ "$NUO_KEEP" -eq "$NUO_N" ]; then
  FAIL "CTL-NU-ORDER: the 'lands first' root kept all $NUO_N record(s) — the removal did not land, so root (c) is not a different ordering and the comparison below is between three identical trees"
elif [ "$NUO_VA" = "$NUO_VB" ] && [ "$NUO_VB" = "$NUO_VC" ]; then
  PASS "CTL-NU-ORDER: the contiguity verdict is IDENTICAL across three merge orders built from the LIVE derived set of $NUO_N record(s), max $NUO_MAX — as-is, plus two records above the maximum (a sibling merging second), and minus its top two (this release landing first; $NUO_KEEP kept). The declared exemption '$ADR_NUM_EXEMPT' sits below every boundary, so whichever release lands first the arm returns the same answer. WHAT THIS DOES NOT ESTABLISH: $NUO_SHAPE. Three clean reads agree whether or not anything is pinned to a maximum — a scanner that had stopped reading past some boundary would produce the same three and pass here — so this arm does NOT establish that nothing is pinned to a maximum, which is what its earlier wording claimed. It establishes that the verdict does not MOVE with merge order. That the scanner fires at all is CTL-NU2's and CTL-NU3's to establish, and each is MUST-FIRE"
else
  FAIL "CTL-NU-ORDER: the contiguity verdict CHANGED with merge order — as-is '$NUO_VA', sibling-merges-second '$NUO_VB', lands-first '$NUO_VC'. Something in the arm is pinned to the record set's boundary, which is exactly the coupling the scope-lock forbids"
fi

# ── LG1 — a Proposed record cited by an Accepted one ──────────────────────────────
D="$WORK/lg1"; ctl_clean "$D"
F="$D/$ADR_DIR/ADR-002-fixture.md"
awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Proposed (2026-01-02)"; else print }' \
  "$F" > "$D/tmp" && mv "$D/tmp" "$F"
printf 'The rule stated in ADR-002 is binding on this decision.\n' >> "$D/$ADR_DIR/ADR-001-fixture.md"
ctl_index "$D" '001:Accepted' '002:Proposed' '003:Accepted'
if ctl_landed "CTL-LG1" "$D/$ADR_DIR/ADR-001-fixture.md" 'ADR-002 is binding'; then
  ctl_mustfire "CTL-LG1" LG1 "$(ad_scan_lg "$D")" "an Accepted record cites a record still marked Proposed — the lag signature itself" 1
fi

# ── LG1 SPECIFICITY — a Proposed record cited by NOBODY, and one cited only by another
#    Proposed record, must both be silent. Citation pressure from a peer is not a lag.
D="$WORK/lg1not"; ctl_clean "$D"
for t in 002 003; do
  F="$D/$ADR_DIR/ADR-$t-fixture.md"
  awk '{ if ($0 ~ /^- \*\*Status:\*\*/) print "- **Status:** Proposed (2026-01-02)"; else print }' \
    "$F" > "$D/tmp" && mv "$D/tmp" "$F"
done
printf 'This builds on ADR-002, which is also still open.\n' >> "$D/$ADR_DIR/ADR-003-fixture.md"
ctl_index "$D" '001:Accepted' '002:Proposed' '003:Proposed'
if ctl_landed "CTL-LG1-NOT" "$D/$ADR_DIR/ADR-003-fixture.md" 'builds on ADR-002'; then
  ctl_mustnot "CTL-LG1-NOT" LG1 "$(ad_scan_lg "$D")" "one Proposed record cited by nobody and another cited only by a fellow Proposed record — neither carries citation pressure from an Accepted record"
fi

# ── LG0 — the vacuity guard ───────────────────────────────────────────────────────
D="$WORK/lg0"; ctl_clean "$D"; rm -f "$D/$ADR_DIR"/ADR-*.md
ctl_mustfire "CTL-LG0" LG0 "$(ad_scan_lg "$D")" "no record remains to classify by status, so a silent lag report would mean nothing" 1

# ═════════════════════════════════════════════════════════════════════════════════
# THE TWO HISTORICAL ARMS. These are the only arms here graded against defects this
# repository actually shipped rather than fixtures this file wrote.
# ═════════════════════════════════════════════════════════════════════════════════

# ── CTL-RETRO-IX — a real file/index divergence, replayed ─────────────────────────
D="$WORK/retro-ix"; mkdir -p "$D/$ADR_DIR"
RETRO_IX_OK=1
if ! git -C "$ROOT" ls-tree --name-only "${ADR_RETRO_IX_REV}:${ADR_DIR}" > "$WORK/retro-ix.ls" 2>/dev/null; then
  RETRO_IX_OK=0
fi
if [ "$RETRO_IX_OK" -eq 1 ]; then
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    git -C "$ROOT" show "${ADR_RETRO_IX_REV}:${ADR_DIR}/${b}" > "$D/$ADR_DIR/$b" 2>/dev/null || RETRO_IX_OK=0
  done < "$WORK/retro-ix.ls"
fi
if [ "$RETRO_IX_OK" -eq 0 ] || [ ! -s "$D/$ADR_INDEX" ]; then
  FAIL "CTL-RETRO-IX: the historical tree at ${ADR_RETRO_IX_REV} is unreachable, so the one arm testing the divergence detector against a divergence this repository actually shipped did not run. This is a hole, not a skip — CI must check out with fetch-depth: 0, and .github/workflows/adr-conformance.yml says so"
else
  RETRO_IX_OUT="$(ad_scan_ix "$D")"
  RETRO_IX_N="$(n_code "$RETRO_IX_OUT" IX1)"
  ctl_arm IX1
  if [ "$RETRO_IX_N" -eq 0 ]; then
    FAIL "CTL-RETRO-IX: MUST FIRE — the extractor reported no IX1 over the revision ${ADR_RETRO_IX_REV}, in which ${ADR_RETRO_IX_TAG}'s file read Accepted while the index still read Proposed. A probe returning zero on a tree known to carry the defect is broken"
  elif ! grep -q "^FINDING IX1 ${ADR_RETRO_IX_TAG} " <<<"$RETRO_IX_OUT"; then
    FAIL "CTL-RETRO-IX: IX1 fired $RETRO_IX_N time(s) at ${ADR_RETRO_IX_REV} but NOT on ${ADR_RETRO_IX_TAG} — it is firing on something else, so the regression being witnessed is not the one this arm exists for"
  else
    PASS "CTL-RETRO-IX: IX1 fired on the real historical tree at ${ADR_RETRO_IX_REV} — $RETRO_IX_N divergence(s) including ${ADR_RETRO_IX_TAG}, whose file said Accepted while the index still said Proposed. That divergence ran for several commits and was closed incidentally by a commit doing something else entirely; every required check was green throughout"
  fi
fi

# ── CTL-RETRO-LG — the real status lag the card names, replayed ───────────────────
# AND THE MEASUREMENT THAT SPLIT THE TWO ARMS: at this same revision the file and the index
# AGREED, so the divergence detector is correctly SILENT here. That silence is asserted, not
# assumed — it is the evidence that an arm wired the way the criterion literally reads would
# have had a PASS its own cited defect could not fail.
D="$WORK/retro-lg"; mkdir -p "$D/$ADR_DIR"
RETRO_LG_OK=1
if ! git -C "$ROOT" ls-tree --name-only "${ADR_RETRO_LG_REV}:${ADR_DIR}" > "$WORK/retro-lg.ls" 2>/dev/null; then
  RETRO_LG_OK=0
fi
if [ "$RETRO_LG_OK" -eq 1 ]; then
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    git -C "$ROOT" show "${ADR_RETRO_LG_REV}:${ADR_DIR}/${b}" > "$D/$ADR_DIR/$b" 2>/dev/null || RETRO_LG_OK=0
  done < "$WORK/retro-lg.ls"
fi
if [ "$RETRO_LG_OK" -eq 0 ] || [ ! -s "$D/$ADR_INDEX" ]; then
  FAIL "CTL-RETRO-LG: the historical tree at ${ADR_RETRO_LG_REV} is unreachable, so the arm replaying the status lag this card was written about did not run. This is a hole, not a skip — CI must check out with fetch-depth: 0"
else
  RETRO_LG_OUT="$(ad_scan_lg "$D")"
  RETRO_LG_N="$(n_code "$RETRO_LG_OUT" LG1)"
  ctl_arm LG1
  if [ "$RETRO_LG_N" -eq 0 ]; then
    FAIL "CTL-RETRO-LG: MUST FIRE — the extractor reported no LG1 over the revision ${ADR_RETRO_LG_REV}, in which ${ADR_RETRO_LG_TAG} sat Proposed while Accepted records cited the rule it states"
  elif ! grep -q "^FINDING LG1 ${ADR_RETRO_LG_TAG} " <<<"$RETRO_LG_OUT"; then
    FAIL "CTL-RETRO-LG: LG1 fired $RETRO_LG_N time(s) at ${ADR_RETRO_LG_REV} but NOT on ${ADR_RETRO_LG_TAG} — the wrong record is being witnessed"
  else
    PASS "CTL-RETRO-LG: LG1 fired on the real historical tree at ${ADR_RETRO_LG_REV} — $RETRO_LG_N citation(s) of ${ADR_RETRO_LG_TAG}, which sat Proposed while Accepted records cited the rule it states. The status line was flipped by hand eight days later"
  fi
  # THE SPLIT, ASSERTED. The divergence detector must be SILENT on this same revision.
  RETRO_LG_IX="$(ad_scan_ix "$D")"
  RETRO_LG_IXN="$(n_code "$RETRO_LG_IX" IX1)"
  if [ "$RETRO_LG_IXN" -eq 0 ]; then
    PASS "CTL-RETRO-SPLIT: at ${ADR_RETRO_LG_REV} the divergence detector reports 0 IX1 — ${ADR_RETRO_LG_TAG}'s file and index BOTH read Proposed and agreed. This is why the lag and the divergence are two arms against two witnesses: an arm replaying this revision through IX would have a PASS the defect it cites could not fail, which is the very shape this milestone exists to close"
  else
    FAIL "CTL-RETRO-SPLIT: at ${ADR_RETRO_LG_REV} the divergence detector reported $RETRO_LG_IXN IX1 finding(s), so the premise separating the two historical arms does not hold on this tree and the arm split needs re-deriving rather than restating: $(grep '^FINDING IX1 ' <<<"$RETRO_LG_IX" | tr '\n' ';')"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "Y — the assertion inventory, derived from this file and checked in both directions"
# ═════════════════════════════════════════════════════════════════════════════════
# The needle is assembled from two pieces so that this scan does not match itself. Without
# that, the search term is its own first hit and the inventory is one member wrong.
Y_MARK="FIND""ING "
Y_DECL="$(awk -v m="$Y_MARK" '
  { s = $0
    while ((i = index(s, m)) > 0) {
      s = substr(s, i + length(m))
      c = s; sub(/[^A-Za-z0-9].*$/, "", c)
      if (c ~ /^[A-Z][A-Z][0-9]$/) print c
    }
  }' "$SELF" | sort -u)"
Y_SURF="$(sort -u "$SURF_LOG")"
Y_ARM="$(sort -u "$ARM_LOG")"
Y_NDECL="$(grep -c '[^[:space:]]' <<<"$Y_DECL" || true)"
printf '  INVENTORY: %s emittable code(s) derived from this file, %s reported by a group, %s exercised by a must-fire arm.\n' \
  "$Y_NDECL" "$(grep -c '[^[:space:]]' <<<"$Y_SURF" || true)" "$(grep -c '[^[:space:]]' <<<"$Y_ARM" || true)"

if [ "${Y_NDECL:-0}" -eq 0 ]; then
  FAIL "Y0: no emittable finding code was derived from this file's own emission sites — the inventory below would be vacuous, and a green would mean only that nothing was compared"
else
  PASS "Y0: $Y_NDECL emittable code(s) derived from this file's own emission sites rather than held here as a list, so a code added by a later slice enters this inventory automatically"
fi

Y_UNARMED="$(comm -23 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_ARM") | grep -c '[^[:space:]]' || true)"
Y_ORPHAN="$(comm -13 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_ARM") | grep -c '[^[:space:]]' || true)"
if [ "$Y_UNARMED" -eq 0 ] && [ "$Y_ORPHAN" -eq 0 ]; then
  PASS "Y1: every emittable code has a MUST-FIRE arm behind it and every arm names a code some site can emit — checked in both directions, so neither a code with no arm nor an arm for a code nothing emits can hide"
else
  [ "$Y_UNARMED" -eq 0 ] || FAIL "Y1: code(s) with NO must-fire arm — a check indistinguishable from one that cannot fire: $(comm -23 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_ARM") | tr '\n' ' ')"
  [ "$Y_ORPHAN" -eq 0 ] || FAIL "Y1: arm(s) naming a code NO site emits, so the arm is testing for something this file cannot report: $(comm -13 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_ARM") | tr '\n' ' ')"
fi

Y_UNREP="$(comm -23 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_SURF") | grep -c '[^[:space:]]' || true)"
if [ "$Y_UNREP" -eq 0 ]; then
  PASS "Y2: every emittable code is reported by a group above, so no code can fire into silence"
else
  FAIL "Y2: code(s) emitted by some site but reported by NO group — they would fire and nothing would say so: $(comm -23 <(printf '%s\n' "$Y_DECL") <(printf '%s\n' "$Y_SURF") | tr '\n' ' ')"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PF — no verdict in this file is decided by a pipeline's exit status.
#
# A verdict site whose writer pipes into an early-exiting `grep -q` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on first
# match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed although the
# match succeeded. That status is 141 only where SIGPIPE is fatal; where the shell inherited
# it ignored the writer returns 1 instead, indistinguishable from the reader finding nothing.
#
# This suite routes its code checks through n_code(), which returns a COUNT its callers then
# compare, and its scan-ran checks through has_denom(), which is a predicate. Both read from
# a here-string for the reason above. The risk the inverted form carries is real wherever a
# predicate decides a verdict — a spurious non-zero resolves toward the quiet answer, the
# finding goes unreported, and the arm records a pass on a state that carries it — which is
# why has_denom's shape is asserted here rather than assumed.
#
# The needle is assembled from two pieces because this scan reads its own source — a literal
# spelling of the shape in the detector would make the detector match itself.
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
    # An OR-list is not a pipeline. Its two-character operator carries the one-character one
    # as a substring, so a correct OR-list of two file-reading greps would read as the defect
    # shape. Neutralise the operator before the test rather than teaching both patterns.
    pfscrub="${pfline//||/  }"
    case "$pfscrub" in
      *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
    esac
    case "$pfline" in
      *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
    esac
  done < "$SELF"
  if [ "$PF_GOOD" -eq 0 ]; then
    FAIL "PF1: the scan found 0 here-string grep -q sites in this file, so its zero on the pipeline shape proves nothing — the convention or the scan has moved, and neither verdict is trustworthy"
  elif [ "$PF_BAD" -eq 0 ]; then
    PASS "PF1: ${PF_GOOD} here-string grep -q site(s) in this file, 0 of them pipelines — no verdict in this file can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan. WHAT THIS GRADES is every grep -q site in this file, by their line shape; the earlier wording named an arm set routed through a predicate that nothing in this file called, which made the clause vacuously true over an empty denominator. The code checks route through n_code, a count, and the scan-ran checks through has_denom, a predicate — both read from a here-string and both are inside this scan's denominator"
  else
    FAIL "PF1: ${PF_BAD} verdict site(s) in this file pipe into an early-exiting grep under pipefail — it exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead"
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group MD — the Discriminating-Evidence Rule, asserted against this file's extractors.
#
# THIS SUITE SHIPS MD REGISTERED FROM ITS FIRST COMMIT rather than carrying the
# empty-registration note a sibling still carries. All six extractors are registered, and
# each is probed against the CONFORMANT FIXTURE rather than the live tree — that is what
# makes the oracle meaningful. Over the fixture each assertion PASSes, so removing its
# extractor flips a PASS to a FAIL; probed against the live tree a group whose verdict is
# already FAIL would report one FAIL either way and the oracle would certify nothing.
#
# ── CLAUSE 6 OPT-OUT, DECLARED RATHER THAN LEFT SILENT ───────────────────────────
# The record corpus and the two historical trees are FILES, not functions, and cannot be
# `unset -f`. REASON: the subject there is the INPUT UNDER TEST, so its removal is a
# degenerate POPULATION rather than a degenerate SUBJECT. COMPENSATING POSITIVE CONTROL:
# every group's vacuity code FAILs on an empty surface — arms CTL-HD0, CTL-IX0, CTL-SP0,
# CTL-LF0, CTL-NU0 and CTL-LG0 each plant exactly that and require the red — and both
# CTL-RETRO arms FAIL loudly rather than skipping when their blob is unreachable. So a
# corpus that vanished, moved or globbed to zero turns this suite red instead of green.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group MD — every PASS here must require evidence its subject could only have produced by running."

md_flips ad_scan_hd HD ad_assert_hd "$CLEAN"
md_flips ad_scan_ix IX ad_assert_ix "$CLEAN"
md_flips ad_scan_sp SP ad_assert_sp "$CLEAN"
md_flips ad_scan_lf LF ad_assert_lf "$CLEAN"
md_flips ad_scan_nu NU ad_assert_nu "$CLEAN"
md_flips ad_scan_lg LG ad_assert_lg "$CLEAN"

# The oracle must convict as well as certify. A deliberately blind assertion — one whose
# PASS is reachable with its subject absent — must be caught, or a green MD above proves
# only that MD ran.
zzq_md_subject() { printf 'ran\n'; }
md_blind_probe()  { if zzq_md_subject >/dev/null 2>&1; then PASS "blind"; else PASS "blind"; fi; }
md_sound_probe()  { if [ "$(zzq_md_subject 2>/dev/null)" = "ran" ]; then PASS "sound"; else FAIL "sound"; fi; }
MD_CB="$(md_probe zzq_md_subject md_blind_probe)"
if [ "$MD_CB" = "1 0" ]; then
  PASS "MD-C1: CONTROL on the oracle — a deliberately blind assertion returns pass=1 fail=0 with its subject removed, so the oracle CONVICTS the defective shape rather than certifying everything put to it"
else
  FAIL "MD-C1: CONTROL on the oracle did not fire — the planted blind assertion returned '$MD_CB' rather than '1 0'. An oracle that convicts nothing certifies nothing"
fi
MD_CS="$(md_probe zzq_md_subject md_sound_probe)"
if [ "$MD_CS" = "0 1" ]; then
  PASS "MD-C2: CONTROL on the oracle — a remediated assertion over the same subject returns pass=0 fail=1 with that subject removed, so the oracle CERTIFIES the sound shape as well as convicting the defective one. Both directions fired on the same subject in the same process"
else
  FAIL "MD-C2: CONTROL on the oracle did not fire — the planted remediated assertion returned '$MD_CS' rather than '0 1'. An oracle that convicts everything is as useless as one that convicts nothing"
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
AD_FINAL="$(ad_scan_hd "$ROOT"; ad_scan_ix "$ROOT"; ad_scan_sp "$ROOT"
            ad_scan_lf "$ROOT"; ad_scan_nu "$ROOT" "$ADR_NUM_EXEMPT"; ad_scan_lg "$ROOT")"
printf 'CORPUS: %s record(s) derived from %s on this run; %s index row(s); %s expected-spine section(s); %s declared lifecycle value(s).\n' \
  "$(ad_records "$ROOT" | grep -c '[^[:space:]]' || true)" "$ADR_DIR" \
  "$(ad_index_rows "$ROOT" | grep -c '[^[:space:]]' || true)" \
  "$(ad_spine "$ROOT" | grep -c '[^[:space:]]' || true)" \
  "$(ad_lifecycle "$ROOT" | grep -c '[^[:space:]]' || true)"
printf 'NUMBERING: declared exemption(s) "%s", asserted in both directions.\n' "$ADR_NUM_EXEMPT"
printf 'FINDINGS: %s on the live tree.\n' "$(grep -c '^FINDING ' <<<"$AD_FINAL" || true)"
if [ "$vacuous" -gt 0 ]; then
  printf 'NOTE: %d assertion(s) had an EMPTY POPULATION and proved nothing about this tree: %s. Read each named arm and its own verdict above for what carries it. This line names the vacuous ARMS rather than a compensating group, because the arms that compensate are not always in the group the vacuous arm belongs to, and a hardcoded group here was a claim about a run it had not read.\n' "$vacuous" "${VACUOUS_IDS% }"
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
