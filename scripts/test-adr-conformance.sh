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
#        A CONVENTION SENTENCE THAT IS NOT WELL-FORMED FAILS THE GROUP, as SP2, and no
#        record is graded against it: the read is refused. A period after a name in mid-list
#        and a later bullet opening with the token each used to leave a shorter spine behind,
#        and the group passed over what was left; so did a blank line inside the list, which
#        is now read through. The parser contract below says what well-formed means, why the
#        bullet rather than the sentence is the unit that bounds the read, and what the read
#        DOES NOT DECIDE: a well-formed sentence that names fewer sections is read as written,
#        and a period typed in place of the list's last separator leaves exactly that.
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
#        The arm CTL-SP2-LIVE plants its mutation in a COPY OF THE LIVE INDEX rather than in
#        the fixture, so the convention sentence the repository ships is graded as well as
#        this file's own copy of it.
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
# ── THE PARSER CONTRACT — constraints that were measured, not chosen ─────────────
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
#   4. THE CONVENTION SENTENCE IS READ FROM ONE BOUNDED BULLET, AND A MALFORMED ONE IS REFUSED.
#      The spine is the first sentence of the index's `**Sections:**` bullet. The bullet is
#      anchored on the line that OPENS it as a list item, and it is that LIST ITEM: a line
#      indented deeper than the opening line is inside it, a blank line before it
#      notwithstanding; a line indented no deeper ends it when it follows a blank line, opens
#      a list item or is a heading, and continues its paragraph when it does none of those.
#      Its list ends at the bullet's first period. It is well-formed when all of these hold:
#        - EXACTLY ONE LINE OPENS A `**Sections:**` BULLET. The reader used to anchor on the
#          LAST occurrence of the bare token anywhere in the text it gathered, so a later
#          bullet opening with it moved the read — onto a shorter list that passed — and a
#          sentence that merely mentioned it turned every record red.
#        - THE LIST IS TERMINATED INSIDE THE BULLET. A bullet that ends before its list has
#          reached a period states no list the reader can bound, and it does not guess one.
#        - EVERY MIDDLE DOT IN THE BULLET STANDS BEFORE ITS FIRST PERIOD, WITH A NAME ON EACH
#          SIDE: the names read from the first sentence are as many as the bullet's middle
#          dots separate. A period after a name in mid-list used to end the sentence early,
#          and the group passed over the prefix. A sentence cannot bound itself against the
#          one character that ends it, so the BULLET bounds it — which is why a middle dot
#          anywhere else in this one bullet is refused as well: a list resumed after a stray
#          period and a later sentence that happens to use the separator are the same bytes.
#          A middle dot in a bullet at this bullet's own depth is outside the read and is not
#          graded; one in a list item nested under this bullet is inside the read.
#      A name therefore carries neither a period nor a middle dot. A BLANK LINE INSIDE THE
#      LIST does not end it: the reader used to stop there and pass over the names above the
#      break, and it now reads the list whole, as the page renders it.
#      WHAT THIS DOES NOT DECIDE. A well-formed sentence that names fewer sections is a change
#      to the convention, and the spine moves with it — that is the design, and the count on
#      the CORPUS line is what keeps it visible. It stays true when the shorter sentence is
#      what a stray period left, wherever what it left is well-formed:
#        - A PERIOD TYPED IN PLACE OF THE LIST'S LAST SEPARATOR — ONE CHARACTER. The middle dot
#          that would have testified against the period is the character it replaced, so the
#          names separated and the names read agree, one short; the last name stands behind
#          them as a sentence of its own, and the group passes without grading it. Arm
#          CTL-SP2-NOT-LASTSEP plants exactly this and REQUIRES this verdict: the limit is
#          asserted, not left to be discovered, and a change that closes it turns that arm
#          over.
#        - A PERIOD WHERE THE BULLET REALLY DOES END JUST AFTER IT, at a bullet of its own depth,
#          at a heading, or at a blank line and then text at that depth: the page then states a
#          shorter list beside a neighbour.
#      A reader of the bullet cannot decide either. What a stray period left and what a writer
#      shortened on purpose are the same well-formed bytes, and this file holds no count and no
#      name to tell them by, so a reader that refused one would refuse a lawful rewrite. And a
#      stray character that neither ends the sentence nor separates a name leaves the count
#      alone and garbles one name, which no record then carries, so every record reads SP1:
#      red, and for a reason one step removed.
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
# S, removing S must flip X specifically. This suite has registered its scanners since its
# FIRST commit, and registers the convention reader beside them, rather than shipping the
# empty-registration note a sibling suite still carries.
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
  ad_status_raw "$1" | awk 'NR == 1 { if (match($0, /^[A-Za-z]+/)) print substr($0, RSTART, RLENGTH) }'
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

# ── ad_spine_read <root> — THE CONVENTION BULLET, read once and bounded ───────────
# Prints `SHAPE <openers> <named> <read> <terminated>` for a readable index, then EITHER one
# `WHY <cause>` line OR the `ENTRY <name>` lines — never both. The entries are printed only
# for a well-formed bullet, so nothing downstream can grade a record against a list this
# reader has already refused: a caller that forgets to ask why reads an EMPTY spine, and
# group SP's vacuity guard turns that red.
#   <openers>     lines that open a `**Sections:**` list item, anywhere in the index
#   <named>       the names the first such bullet separates with the middle dot, counted
#                 over the WHOLE bullet — its middle dots, plus one
#   <read>        the non-empty names read from its first sentence, up to its first period
#   <terminated>  1 when the bullet carries a period at all, 0 when it does not
# THE BULLET IS THE LIST ITEM, bounded the way the page that renders it bounds it. A line
# indented deeper than the line that opens it is inside it, whatever it opens and whether or
# not a blank line stands before it. A line indented no deeper ENDS it when it follows a
# blank line, opens a list item or is a heading, and otherwise continues its paragraph. The
# reader errs toward the WIDER bullet: text wrongly taken in can only add a middle dot or
# garble a name — a refusal, or a red record — and text wrongly left out is how a list
# reads short.
# An index with no such bullet, or one that cannot be read, is `SHAPE 0 0 0 0` and nothing
# else — ABSENT, which is SP0's to report, and not malformed. The parser contract in this
# file's banner says why the bullet, and not the sentence, is the unit that bounds the read.
ad_spine_read() {
  [ -r "$1/$ADR_INDEX" ] || { printf 'SHAPE 0 0 0 0\n'; return 0; }
  awk '
    /^[[:space:]]*-[[:space:]]*\*\*Sections:\*\*/ {
      openers++
      if (openers == 1) {
        inb = 1; gap = 0; b = $0
        t = $0; sub(/^[[:space:]]+/, "", t); depth = length($0) - length(t)
        next
      }
    }
    inb {
      if ($0 ~ /^[[:space:]]*$/) { gap = 1; next }
      t = $0; sub(/^[[:space:]]+/, "", t)
      if (length($0) - length(t) <= depth && (gap || t ~ /^-[[:space:]]/ || t ~ /^#+[[:space:]]/)) inb = 0
      else { b = b " " $0; gap = 0 }
    }
    END {
      if (openers == 0) { print "SHAPE 0 0 0 0"; exit }
      sub(/^[[:space:]]*-[[:space:]]*\*\*Sections:\*\*/, "", b)
      named = split(b, all, "\302\267")      # the middle dot, byte-wise under LC_ALL=C
      p = index(b, ".")
      s1 = (p > 0) ? substr(b, 1, p - 1) : b
      n = split(s1, part, "\302\267"); nread = 0
      for (i = 1; i <= n; i++) {
        s = part[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
        gsub(/[[:space:]]+/, " ", s)
        if (s != "") ent[++nread] = tolower(s)
      }
      printf "SHAPE %d %d %d %d\n", openers, named, nread, (p > 0)
      if (openers > 1)         print "WHY second-opener"
      else if (p == 0)         print "WHY unterminated-list"
      else if (named != nread) print "WHY entries-read-differ-from-entries-named"
      else for (i = 1; i <= nread; i++) print "ENTRY " ent[i]
    }' "$1/$ADR_INDEX" 2>/dev/null
}

# ── ad_spine <root> — THE EXPECTED SPINE, read from the index's own convention ────
# The names the convention bullet's first sentence lists, less the header fields. Read rather
# than held, so a change to the convention moves this suite with it. Prints NOTHING for a
# bullet the reader refused or could not find: the refusal is SP2's to name and the absence
# is SP0's, and neither is ever a shorter spine.
ad_spine() {
  # Joined on a character no field name carries: awk's -v assignment rejects an embedded
  # newline outright, so the natural one-per-line form cannot be passed this way.
  local flds; flds="$(ad_head_fields | tr 'A-Z' 'a-z' | tr '\n' '|')"
  ad_spine_read "$1" | awk -v f="$flds" '
      BEGIN { n = split(f, a, "|"); for (i = 1; i <= n; i++) if (a[i] != "") drop[a[i]] = 1 }
      $1 == "ENTRY" { s = substr($0, 7); if (!(s in drop)) print s }'
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
  local root="$1" recs raw why spine b tag f secs s nrec=0 nsec=0 nspine=0
  local so="" sn="" sr="" st=""
  recs="$(ad_records "$root")"
  # THE READER'S OWN VERDICT decides the measurement state, on the rule group G of
  # test-corpus-hygiene.sh states for its own: a convention the reader refused is reported
  # FIRST AND ALONE, as SP2 with its cause, and SP1 is withheld under it — no record is graded
  # against a list that was not read. ad_spine prints nothing for a refused bullet, so the
  # withholding is a property of the reader and not a branch this function has to remember.
  raw="$(ad_spine_read "$root")"
  why="$(awk '$1 == "WHY" { print $2 }' <<<"$raw")"
  read -r so sn sr st <<<"$(awk '$1 == "SHAPE" { print $2, $3, $4, $5 }' <<<"$raw")"
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
  if [ -n "$why" ]; then
    printf 'FINDING SP2 %s openers=%s named=%s read=%s terminated=%s\n' \
      "$why" "${so:--}" "${sn:--}" "${sr:--}" "${st:--}"
  else
    [ "$nrec" -gt 0 ] && [ "$nsec" -gt 0 ] && [ "$nspine" -gt 0 ] \
      || printf 'FINDING SP0 no-records-no-sections-or-no-spine\n'
  fi
  printf 'DENOM SP %d %d %d %s %s\n' "$nrec" "$nsec" "$nspine" "${sn:--}" "${sr:--}"
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
  local root="$1" exempt="${2-}" recs b n lo hi i nrec=0 nums=" " dup=" "
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
  local out d n0 n1 n2 why dr="" ds="" dp="" dn="" dd=""
  out="$(ad_scan_sp "$1")"
  if ! has_denom "$out"; then
    FAIL "SP: the spine scan produced no denominator, so it did not run — no record was graded"; return 0
  fi
  d="$(ad_denom "$out" SP)"
  read -r dr ds dp dn dd <<<"$d"
  n0="$(n_code "$out" SP0)"; n1="$(n_code "$out" SP1)"; n2="$(n_code "$out" SP2)"
  if [ "$n2" -gt 0 ]; then
    why="$(awk '$1 == "FINDING" && $2 == "SP2" { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' <<<"$out")"
    FAIL "SP: the spine is NOT a measurement on this run — the index's convention sentence is not well-formed ($why), so the reader refused it, no record was graded and SP1 is withheld. The bullet's middle dots separate $dn name(s) and $dd were read from its first sentence. A refused sentence is never a shorter spine: before this guard a period after a name in mid-list left a prefix behind and this group passed over it. Well-formed means exactly one line opens a Sections bullet, the list ends at a period inside that bullet, and every middle dot in the bullet stands before that period with a name on each side — the parser contract in this file's banner records why each is required"
  elif [ "$n0" -gt 0 ]; then
    FAIL "SP: the graded surface is degenerate — <records,sections,spine> = $dr $ds $dp. A spine read as empty certifies every record trivially"
  elif [ "$n1" -eq 0 ]; then
    PASS "SP: every record carries every expected-spine section — <records,sections,spine-entries> = $dr $ds $dp. The convention bullet's middle dots separate $dn name(s) and $dd were read from its first sentence. The names among them that are header fields are group HD's. Extra sections are admitted by the index's own escape hatch and are not graded"
  else
    FAIL "SP: $n1 expected-spine section(s) absent over <records,sections,spine-entries> = $dr $ds $dp — $(grep '^FINDING SP1 ' <<<"$out" | awk '{ print $3 " lacks " $4 }' | tr '\n' ';'). Each finding means one of two things: the record lacks a section the convention sentence names, or the sentence names something no record carries. Where every record lacks the same name, read the sentence before the records"
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
for c in SP0 SP1 SP2; do echo "$c" >> "$SURF_LOG"; done
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

# ═════════════════════════════════════════════════════════════════════════════════
# SP2 — THE CONVENTION SENTENCE IS REFUSED WHEN IT IS NOT WELL-FORMED.
#
# Every fixture arm in this block rewrites the fixture INDEX and leaves the fixture records
# alone, so the conformant fixture's own spine scan is the reference each is read against.
# Each MUST-FIRE arm plants one spelling the reader refuses — most of them spellings it used
# to read short and green — and each MUST-NOT-MOVE arm plants a lawful neighbour of one and
# requires the read to stay exactly where it was. The MUST-NOT-FIRE arms hold what the
# refusal leaves open: a well-formed shorter list is read as written, whether its writer
# shortened it or a period typed in place of its last separator did. The last arm plants the
# truncating spelling in a copy of the LIVE index.
# ═════════════════════════════════════════════════════════════════════════════════
SP_REF="$(ad_denom "$(ad_scan_sp "$CLEAN")" SP)"
SP_REF_NAMES="$(ad_spine "$CLEAN")"

# ctl_sp_plant <root> <awk-program> — rewrite that root's index through one awk program.
ctl_sp_plant() { awk "$2" "$1/$ADR_INDEX" > "$1/tmp" && mv "$1/tmp" "$1/$ADR_INDEX"; }

# ctl_sp_refused <label> <root> <want> <what> — SP2 MUST FIRE: once, ALONE, FOR THE CAUSE
# NAMED, and HANDING ON NO SPINE. The cause and its figures are the assertion, not merely the
# firing: an arm that accepted any SP2 would pass when a planted period was refused for some
# other reason, and an arm that passes for the wrong reason is indistinguishable from one that
# tests nothing. The empty spine is asserted too, because a refusal that still printed the
# prefix it read would leave that prefix for something to grade against.
ctl_sp_refused() {
  local label="$1" out got n2 nsp
  out="$(ad_scan_sp "$2")"
  ctl_arm SP2
  n2="$(n_code "$out" SP2)"
  got="$(awk '$1 == "FINDING" && $2 == "SP2" { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' <<<"$out")"
  nsp="$(awk '$1 == "DENOM" && $2 == "SP" { print $5 }' <<<"$out")"
  if [ "$n2" -ne 1 ]; then
    FAIL "$label: MUST FIRE once — $4, and the scan reported SP2 $n2 time(s). A convention the reader does not refuse is a convention it reads short"
  elif [ "$got" != "$3" ]; then
    FAIL "$label: SP2 fired for the WRONG CAUSE — $4. Wanted '$3' and read '$got', so the planted spelling is not what this arm is witnessing"
  elif [ "$(n_code "$out" SP1)" -ne 0 ] || [ "$(n_code "$out" SP0)" -ne 0 ]; then
    FAIL "$label: SP2 did not fire ALONE — $4, and the scan also reported SP1 $(n_code "$out" SP1) time(s) and SP0 $(n_code "$out" SP0) time(s). A record graded against a refused list is a verdict about nothing"
  elif [ "$nsp" != "0" ]; then
    FAIL "$label: the refused convention still handed on a spine — $4, and the scan's denominator carries '$nsp' spine entr(ies) where a refusal carries none. A prefix that leaves the reader is a prefix something will grade against"
  else
    PASS "$label: SP2 fired once and alone, handing on no spine ($got) — $4"
  fi
}

# ctl_sp_holds <label> <root> <what> — THE READ DID NOT MOVE. Silence alone is not accepted as
# a hold: the scan must have run, must report neither SP2 nor SP0, and must return the
# conformant fixture's own denominator AND its own names — the same spine, not merely a spine
# of the same length.
ctl_sp_holds() {
  local label="$1" out d names
  out="$(ad_scan_sp "$2")"
  if ! has_denom "$out"; then
    FAIL "$label: the spine scan produced no denominator, so it did not run — its silence on SP2 is not a hold"; return 0
  fi
  d="$(ad_denom "$out" SP)"
  names="$(ad_spine "$2")"
  if [ -z "$SP_REF" ] || [ -z "$SP_REF_NAMES" ]; then
    FAIL "$label: the conformant fixture's own spine read returned nothing, so there is nothing to hold this read against"
  elif [ "$(n_code "$out" SP2)" -eq 0 ] && [ "$(n_code "$out" SP0)" -eq 0 ] && [ "$d" = "$SP_REF" ] && [ "$names" = "$SP_REF_NAMES" ]; then
    PASS "$label: the read is unmoved — <records,sections,spine-entries,names-separated,names-read> = $d and every name equal to the conformant fixture's own — $3"
  else
    FAIL "$label: the read MOVED on an input it must not move on — $3. It returned <records,sections,spine-entries,names-separated,names-read> = $d against the conformant fixture's $SP_REF, and the names '$(printf '%s' "$names" | tr '\n' ';')' against '$(printf '%s' "$SP_REF_NAMES" | tr '\n' ';')': $(grep '^FINDING SP' <<<"$out" | tr '\n' ';')"
  fi
}

# ── SP2 — a period after a name in MID-LIST. The spelling this code exists for: the reader
#    ended the sentence there and the group passed over the names before it.
D="$WORK/sp2trunc"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Decision drivers \302\267", "Decision drivers. \302\267"); print }'
if ctl_landed "CTL-SP2-TRUNC" "$D/$ADR_INDEX" 'Decision drivers\. '; then
  ctl_sp_refused "CTL-SP2-TRUNC" "$D" 'entries-read-differ-from-entries-named openers=1 named=7 read=3 terminated=1' "a period was planted after 'Decision drivers', in mid-list"
fi

# ── SP2, THE VERDICT — group SP itself reads FAIL over that truncated index, and PASS over
#    the conformant one. Every other arm in this block grades a FINDING; this one grades what
#    the group SAYS, because the defect this code exists for was a verdict: the read came back
#    short and the group passed. With SP1 withheld and SP0 silent under a refusal, an assertion
#    that did not read SP2 would pass over a convention nobody read, and no finding-level arm
#    would see it. zzq_no_subject names no function, so the oracle removes nothing here: it is
#    used for its counting subshell alone.
SPV_BAD="$(md_probe zzq_no_subject ad_assert_sp "$WORK/sp2trunc")"
SPV_OK="$(md_probe zzq_no_subject ad_assert_sp "$CLEAN")"
if [ "$SPV_BAD" = "0 1" ] && [ "$SPV_OK" = "1 0" ]; then
  PASS "CTL-SP2-VERDICT: group SP's own assertion reports exactly one FAIL and no PASS over the index CTL-SP2-TRUNC planted its period in, and exactly one PASS and no FAIL over the conformant fixture — the refusal reaches the verdict, which is where the defect was"
else
  FAIL "CTL-SP2-VERDICT: group SP's own assertion returned <pass fail> = '$SPV_BAD' over the truncated index and '$SPV_OK' over the conformant one, where '0 1' and '1 0' are required — a refusal that does not reach the verdict leaves the group passing over a convention it did not read"
fi

# ── SP2 — the same period, EARLY: after the first name that is not a header field.
D="$WORK/sp2early"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267", "Context. \302\267"); print }'
if ctl_landed "CTL-SP2-TRUNC-EARLY" "$D/$ADR_INDEX" 'Context\. '; then
  ctl_sp_refused "CTL-SP2-TRUNC-EARLY" "$D" 'entries-read-differ-from-entries-named openers=1 named=7 read=2 terminated=1' "a period was planted after 'Context', the first name that is not a header field"
fi

# ── SP2 — the same period, LATE: after the name before the last. The read is ONE short,
#    which is the truncation hardest to notice in a printed count.
D="$WORK/sp2late"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Consequences \302\267", "Consequences. \302\267"); print }'
if ctl_landed "CTL-SP2-TRUNC-LATE" "$D/$ADR_INDEX" 'Consequences\. '; then
  ctl_sp_refused "CTL-SP2-TRUNC-LATE" "$D" 'entries-read-differ-from-entries-named openers=1 named=7 read=6 terminated=1' "a period was planted after 'Consequences', leaving the read one name short"
fi

# ── SP2 — the same period after the HEADER FIELD that opens the list. Every name the reader
#    is left with is a header field, so the spine it would hand on is empty: this is the one
#    spelling the vacuity guard already caught, and it is refused here for its cause instead.
D="$WORK/sp2head"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Status \302\267", "Status. \302\267"); print }'
if ctl_landed "CTL-SP2-TRUNC-HEAD" "$D/$ADR_INDEX" 'Status\. '; then
  ctl_sp_refused "CTL-SP2-TRUNC-HEAD" "$D" 'entries-read-differ-from-entries-named openers=1 named=7 read=1 terminated=1' "a period was planted after 'Status', the header field that opens the list"
fi

# ── SP2 — a period, then a PARAGRAPH BREAK. The names after the break are still inside the
#    bullet: a blank line does not end a list item, and they are still indented under it. So
#    what the period left is not a short, well-formed list. It is a list cut in two.
D="$WORK/sp2split"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267 ", "Context.\n\n  "); print }'
if awk 'prev ~ /Context\.$/ && $0 == "" { hit = 1 } { prev = $0 } END { exit(hit ? 0 : 1) }' "$D/$ADR_INDEX"; then
  ctl_sp_refused "CTL-SP2-SPLIT" "$D" 'entries-read-differ-from-entries-named openers=1 named=6 read=2 terminated=1' "a period and a blank line were planted after 'Context', leaving the rest of the list in a second paragraph of the same bullet"
else
  FAIL "CTL-SP2-SPLIT: the mutation did not land — no line ending 'Context.' is followed by a blank line, so the verdict below would grade an unmutated index"
fi

# ── SP2 — a period, then the rest of the list as a NESTED list item. A list item indented
#    under the bullet is inside the bullet; only one at the bullet's own depth ends it.
D="$WORK/sp2nest"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267 ", "Context.\n  - "); print }'
if ctl_landed "CTL-SP2-NEST" "$D/$ADR_INDEX" '^  - Decision drivers '; then
  ctl_sp_refused "CTL-SP2-NEST" "$D" 'entries-read-differ-from-entries-named openers=1 named=6 read=2 terminated=1' "a period was planted after 'Context' and the rest of the list made a list item nested under the bullet"
fi

# ── SP2 — a period, then a LINE BREAK with nothing indented after it. A line at the
#    bullet's own depth that follows no blank line and opens nothing continues the bullet's
#    paragraph, so the names on it are still inside the bullet.
D="$WORK/sp2lazy"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267 ", "Context.\n"); print }'
if ctl_landed "CTL-SP2-LAZY" "$D/$ADR_INDEX" '^Decision drivers '; then
  ctl_sp_refused "CTL-SP2-LAZY" "$D" 'entries-read-differ-from-entries-named openers=1 named=6 read=2 terminated=1' "a period and a line break were planted after 'Context', leaving the rest of the list on an unindented line of the same paragraph"
fi

# ── SP2 — a PARAGRAPH BREAK inside the list, and THEN a period and a line break with nothing
#    indented after it. The blank line was answered by the indented line that followed it:
#    that line is inside the bullet, and the bullet's paragraph resumes there. So the
#    unindented line further down follows NO blank line. It continues the paragraph, as in
#    CTL-SP2-LAZY, and the names on it are still inside the bullet. A reader that went on
#    remembering the blank line would end the bullet at that line and read the names above the
#    period as a whole, well-formed list — short, and green.
D="$WORK/sp2reset"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267 Decision drivers \302\267 Options considered \302\267 ", "Context \302\267\n\n  Decision drivers \302\267 Options considered.\n"); print }'
if ! awk 'prev ~ /Context [^ ]+$/ && $0 == "" { hit = 1 } { prev = $0 } END { exit(hit ? 0 : 1) }' "$D/$ADR_INDEX"; then
  FAIL "CTL-SP2-RESET: the mutation did not land — no blank line follows a line ending at the separator after 'Context', so the verdict below would grade an unmutated index"
elif ctl_landed "CTL-SP2-RESET" "$D/$ADR_INDEX" '^  Decision drivers [^ ][^ ] Options considered\.$' \
     && ctl_landed "CTL-SP2-RESET" "$D/$ADR_INDEX" '^Decision [^ ][^ ]$'; then
  ctl_sp_refused "CTL-SP2-RESET" "$D" 'entries-read-differ-from-entries-named openers=1 named=6 read=4 terminated=1' "a paragraph break was planted inside the list after 'Context', then a period after 'Options considered' and a line break, leaving the rest of the list on an unindented line of the bullet's second paragraph"
fi

# ── SP2 — the list CUT OFF by the next bullet, with no period reached. A bullet at the
#    Sections bullet's own depth ends it, and a list that ends there has no terminator: the
#    reader does not guess where it would have ended. The cut is made after a WHOLE name —
#    the separator that trailed it is taken off — so the names read and the names separated
#    AGREE, and the missing period is the only thing left to refuse it for.
D="$WORK/sp2cut"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Sections:\*\*/ { sub(" \302\267$", ""); print; print "- **Aside:** unrelated."; next } { print }'
if ctl_landed "CTL-SP2-CUT" "$D/$ADR_INDEX" '\*\*Sections:\*\*.* Decision$' \
   && ctl_landed "CTL-SP2-CUT" "$D/$ADR_INDEX" '^- \*\*Aside:\*\* unrelated\.$'; then
  ctl_sp_refused "CTL-SP2-CUT" "$D" 'unterminated-list openers=1 named=5 read=5 terminated=0' "the line that opens the Sections bullet was ended after a whole name and a bullet at its own depth planted directly after it, before the list's period"
fi

# ── SP2 — a SECOND bullet opening with the token, whose own text reads as a list every
#    fixture record satisfies. The reader used to anchor on the last token it gathered, so
#    this moved the read onto the shorter list and the group passed.
D="$WORK/sp2opener"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "- **Sections:** Context \302\267 Decision." } { print }'
if ctl_landed "CTL-SP2-OPENER" "$D/$ADR_INDEX" '^- \*\*Sections:\*\* Context '; then
  ctl_sp_refused "CTL-SP2-OPENER" "$D" 'second-opener openers=2 named=7 read=7 terminated=1' "a second bullet opening with the Sections token was planted after the first, carrying a shorter list every fixture record satisfies"
fi

# ── SP2 — a middle dot in a LATER SENTENCE of the same bullet. A list resumed after a stray
#    period and a later sentence that uses the separator are the same bytes, so the reader
#    cannot admit one without admitting the other; it refuses both.
D="$WORK/sp2dot"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "  An aside \302\267 a remark." } { print }'
if ctl_landed "CTL-SP2-DOT" "$D/$ADR_INDEX" '^  An aside [^ ][^ ] a remark\.$'; then
  ctl_sp_refused "CTL-SP2-DOT" "$D" 'entries-read-differ-from-entries-named openers=1 named=8 read=7 terminated=1' "a sentence carrying a middle dot was planted as the last line of the Sections bullet, after the list's own period"
fi

# ── SP2 — a DOUBLED separator in mid-list: a name that is empty. The reader used to drop it
#    without a word.
D="$WORK/sp2sep"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Context \302\267", "Context \302\267 \302\267"); print }'
if ctl_landed "CTL-SP2-SEP" "$D/$ADR_INDEX" 'Context [^ ][^ ] [^ ][^ ] Decision drivers'; then
  ctl_sp_refused "CTL-SP2-SEP" "$D" 'entries-read-differ-from-entries-named openers=1 named=8 read=7 terminated=1' "a second middle dot was planted after 'Context', leaving an empty name in mid-list"
fi

# ── SP2 MUST-NOT-MOVE — a PERIOD in the bullet's second sentence. The list has already ended;
#    a period after it is prose, and the read must not notice.
D="$WORK/sp2notperiod"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "  See e.g. the records themselves." } { print }'
if ctl_landed "CTL-SP2-NOT-PERIOD" "$D/$ADR_INDEX" '^  See e\.g\. the records themselves\.$'; then
  ctl_sp_holds "CTL-SP2-NOT-PERIOD" "$D" "a sentence carrying periods of its own and no middle dot was planted as the last line of the Sections bullet"
fi

# ── SP2 MUST-NOT-MOVE — the words after the list REPLACED. What follows the list's period is
#    free prose so long as it carries no middle dot, which is what lets a later change correct
#    it. The arm anchors on the list's last name and on nothing the prose says, so it does not
#    have to be edited when that prose is.
D="$WORK/sp2notreword"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub(/References\..*$/, "References. A record states what follows from it."); print }'
if ctl_landed "CTL-SP2-NOT-REWORD" "$D/$ADR_INDEX" 'References\. A record states what follows from it\.$'; then
  ctl_sp_holds "CTL-SP2-NOT-REWORD" "$D" "everything after the list's period on its own line was replaced by different words"
fi

# ── SP2 MUST-NOT-MOVE — a BLANK LINE inside the list, the rest still indented under the
#    bullet. The list is whole, in two paragraphs of one list item, and it is read whole. The
#    reader used to stop at the blank line and hand on the names above it.
D="$WORK/sp2notblank"; ctl_clean "$D"
ctl_sp_plant "$D" '{ print } /\*\*Sections:\*\*/ { print "" }'
if awk 'prev ~ /\*\*Sections:\*\*/ && $0 == "" { hit = 1 } { prev = $0 } END { exit(hit ? 0 : 1) }' "$D/$ADR_INDEX"; then
  ctl_sp_holds "CTL-SP2-NOT-BLANK" "$D" "a blank line was planted inside the list, after the line that opens the bullet"
else
  FAIL "CTL-SP2-NOT-BLANK: the mutation did not land — no blank line follows the line that opens the Sections bullet, so the verdict below would grade an unmutated index"
fi

# ── SP2 MUST-NOT-MOVE — an UNINDENTED PARAGRAPH after a blank line, carrying middle dots.
#    A blank line followed by text at the bullet's own depth is where the bullet ends, so
#    that paragraph is outside the read.
D="$WORK/sp2notpara"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print ""; print "A paragraph of its own \302\267 with a separator \302\267 or two."; print "" } { print }'
if ctl_landed "CTL-SP2-NOT-PARA" "$D/$ADR_INDEX" '^A paragraph of its own '; then
  ctl_sp_holds "CTL-SP2-NOT-PARA" "$D" "an unindented paragraph carrying middle dots was planted after the Sections bullet, behind a blank line"
fi

# ── SP2 MUST-NOT-MOVE — a HEADING carrying a middle dot, directly after the bullet's last
#    line with no blank line between. A heading at the bullet's own depth ends the bullet
#    whether or not a blank line stands before it.
D="$WORK/sp2notheading"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "## A heading \302\267 with a separator" } { print }'
if ctl_landed "CTL-SP2-NOT-HEADING" "$D/$ADR_INDEX" '^## A heading '; then
  ctl_sp_holds "CTL-SP2-NOT-HEADING" "$D" "a heading carrying a middle dot was planted directly after the Sections bullet, with no blank line between them"
fi

# ── SP2 MUST-NOT-MOVE — a LATER BULLET carrying middle dots. The read is bounded by the
#    bullet and not by the paragraph the bullets share, so a neighbour's separators are
#    outside it: the index now carries more middle dots than the read counts.
D="$WORK/sp2notbullet"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "- **Related terms:** alpha \302\267 beta \302\267 gamma." } { print }'
if ctl_landed "CTL-SP2-NOT-BULLET" "$D/$ADR_INDEX" '^- \*\*Related terms:\*\* alpha '; then
  ctl_sp_holds "CTL-SP2-NOT-BULLET" "$D" "a bullet carrying two middle dots was planted directly after the Sections bullet, with no blank line between them"
fi

# ── SP2 MUST-NOT-MOVE — a later bullet that MENTIONS the token in mid-line. The anchor is
#    the line that opens the bullet, not the bare token: the reader used to re-anchor here
#    and turn every record red.
D="$WORK/sp2notmention"; ctl_clean "$D"
ctl_sp_plant "$D" '/\*\*Status lifecycle:\*\*/ { print "- **Extra sections.** The `**Sections:**` bullet above lists the spine." } { print }'
if ctl_landed "CTL-SP2-NOT-MENTION" "$D/$ADR_INDEX" 'bullet above lists the spine'; then
  ctl_sp_holds "CTL-SP2-NOT-MENTION" "$D" "a later bullet naming the Sections token in mid-line was planted after the Sections bullet"
fi

# ── SP2 MUST-NOT-FIRE — a WELL-FORMED SHORTER LIST. A sentence that names fewer sections and
#    ends where it says it does is a change to the convention, not a malformed one: the spine
#    moves with it, which is the design, and the count this run prints is what shows it. The
#    arm is here so that boundary is asserted rather than left to be discovered — a guard that
#    began refusing a lawful shorter list would be a held count by another name.
D="$WORK/sp2notshorter"; ctl_clean "$D"
ctl_sp_plant "$D" '
  /\*\*Sections:\*\*/ { print "- **Sections:** Status \302\267 Context \302\267 Decision. This list is the whole of it."; drop = 1; next }
  drop && /^  / { next }
  { drop = 0; print }'
if ctl_landed "CTL-SP2-NOT-SHORTER" "$D/$ADR_INDEX" 'Decision\. This list is the whole of it\.$'; then
  SPS_OUT="$(ad_scan_sp "$D")"
  SPS_NAMES="$(ad_spine "$D" | tr '\n' ';')"
  if has_denom "$SPS_OUT" && [ "$(n_code "$SPS_OUT" SP2)" -eq 0 ] && [ "$(n_code "$SPS_OUT" SP0)" -eq 0 ] \
     && [ "$(n_code "$SPS_OUT" SP1)" -eq 0 ] && [ "$SPS_NAMES" = "context;decision;" ]; then
    PASS "CTL-SP2-NOT-SHORTER: a well-formed list naming fewer sections is read as written — the spine is '$SPS_NAMES' and neither SP2 nor SP0 nor SP1 fired — so the convention still moves this suite, and only a malformed sentence is refused"
  else
    FAIL "CTL-SP2-NOT-SHORTER: a well-formed shorter list was not read as written — the spine came back '$SPS_NAMES' where 'context;decision;' is required: $(grep '^FINDING SP' <<<"$SPS_OUT" | tr '\n' ';'). A reader that refuses a lawful change to the convention has stopped reading the convention"
  fi
fi

# ── SP2 MUST-NOT-FIRE, A DECLARED LIMIT — a period typed IN PLACE OF THE LIST'S LAST
#    SEPARATOR. One character. The middle dot that would have testified against the period is
#    the character it replaced, so the bullet's middle dots separate one name fewer and exactly
#    that many are read: a well-formed list, one name short, with the last name left behind it
#    as a sentence of its own. The reader reads it as written and the group passes at the
#    smaller count, which this run prints and nothing else shows. The parser contract in this
#    file's banner declares it under WHAT THIS DOES NOT DECIDE. The arm PINS that verdict, so
#    the limit is asserted rather than left to be discovered: a change that makes the reader
#    refuse this input turns this arm red, and has to turn it over — into a MUST-FIRE arm —
#    and take the limit out of the contract in the same change.
D="$WORK/sp2notlastsep"; ctl_clean "$D"
ctl_sp_plant "$D" '{ sub("Consequences \302\267 References", "Consequences . References"); print }'
if ctl_landed "CTL-SP2-NOT-LASTSEP" "$D/$ADR_INDEX" 'Consequences \. References\.'; then
  SPQ_OUT="$(ad_scan_sp "$D")"
  SPQ_D="$(ad_denom "$SPQ_OUT" SP)"
  SPQ_NAMES="$(ad_spine "$D" | tr '\n' ';')"
  if has_denom "$SPQ_OUT" && [ "$(n_code "$SPQ_OUT" SP2)" -eq 0 ] && [ "$(n_code "$SPQ_OUT" SP0)" -eq 0 ] \
     && [ "$(n_code "$SPQ_OUT" SP1)" -eq 0 ] \
     && [ "$SPQ_NAMES" = "context;decision drivers;options considered;decision;consequences;" ]; then
    PASS "CTL-SP2-NOT-LASTSEP: A DECLARED LIMIT, HELD — a period typed in place of the list's last separator leaves a well-formed list one name short, and it is read as written: the spine is '$SPQ_NAMES' over <records,sections,spine-entries,names-separated,names-read> = $SPQ_D, and neither SP2 nor SP0 nor SP1 fired. The name the period cut off is not graded and the group passes; the count this run prints is what shows it. The arm asserts that limit so it is not left to be discovered"
  else
    FAIL "CTL-SP2-NOT-LASTSEP: the DECLARED LIMIT MOVED — a period typed in place of the list's last separator is no longer read as the well-formed shorter list it leaves. The spine came back '$SPQ_NAMES' where 'context;decision drivers;options considered;decision;consequences;' is the pinned read, over <records,sections,spine-entries,names-separated,names-read> = $SPQ_D: $(grep '^FINDING SP' <<<"$SPQ_OUT" | tr '\n' ';'). If the reader now refuses this input on purpose, the limit is closed: make this a MUST-FIRE arm and take the limit out of the parser contract in the same change. If it does not, the read moved on an input this arm pins"
  fi
fi

# ── SP2 ON THE LIVE SENTENCE — the truncating period, planted in a COPY OF THE REAL INDEX.
# Every arm above grades the copy of the convention bullet this file writes into its own
# fixture, and a fixture can drift from the sentence the repository ships. This arm grades
# those bytes instead: it copies the live index, plants a period before the last middle dot
# on the line that opens the bullet, and requires the refusal — with the names the bullet
# separates unchanged and the names read fallen below them. The position is derived from the
# line and no name is written here, so a change to the convention needs no edit to this arm.
# Where the live sentence offers no such position, or is already refused, the arm is VACUOUS
# and says which: the live verdict above and the fixture arms carry it then.
D="$WORK/sp2live"; mkdir -p "$D/$ADR_DIR"
SPL_NAMED=""; SPL_WHY0="unread"
if [ -r "$ROOT/$ADR_INDEX" ]; then
  cp "$ROOT/$ADR_INDEX" "$D/$ADR_INDEX"
  SPL_RAW="$(ad_spine_read "$D")"
  SPL_NAMED="$(awk '$1 == "SHAPE" { print $3 }' <<<"$SPL_RAW")"
  SPL_WHY0="$(awk '$1 == "WHY" { print $2 }' <<<"$SPL_RAW")"
  ctl_sp_plant "$D" '
    /^[[:space:]]*-[[:space:]]*\*\*Sections:\*\*/ && !done {
      n = split($0, seg, "\302\267")
      if (n > 1) {
        line = seg[1]
        for (i = 2; i <= n; i++) line = line (i == n ? ".\302\267" : "\302\267") seg[i]
        $0 = line; done = 1
      }
    }
    { print }'
fi
if [ -n "$SPL_WHY0" ]; then
  VACUOUS "CTL-SP2-LIVE: the live convention sentence is not a well-formed one to plant a period in ($SPL_WHY0), so this arm proved nothing about it. Group SP's own verdict above reports that sentence, and the CTL-SP2-TRUNC arms carry the firing on the fixture"
elif cmp -s "$ROOT/$ADR_INDEX" "$D/$ADR_INDEX"; then
  VACUOUS "CTL-SP2-LIVE: the line that opens the live Sections bullet carries no middle dot, so it offers no mid-list position to plant a period at and this arm proved nothing about it. The CTL-SP2-TRUNC arms carry the firing on the fixture"
else
  SPL_OUT="$(ad_scan_sp "$D")"
  ctl_arm SP2
  SPL_GOT="$(awk '$1 == "FINDING" && $2 == "SP2" { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' <<<"$SPL_OUT")"
  SPL_N="${SPL_GOT#*named=}"; SPL_N="${SPL_N%% *}"
  SPL_R="${SPL_GOT#*read=}";  SPL_R="${SPL_R%% *}"
  if [ "$(n_code "$SPL_OUT" SP2)" -ne 1 ]; then
    FAIL "CTL-SP2-LIVE: MUST FIRE once — a period was planted before the last middle dot on the line that opens the LIVE Sections bullet, and the scan reported SP2 $(n_code "$SPL_OUT" SP2) time(s). The sentence this repository ships can be read short"
  elif [ "${SPL_GOT%% *}" != "entries-read-differ-from-entries-named" ] || [ "$SPL_N" != "$SPL_NAMED" ]; then
    FAIL "CTL-SP2-LIVE: SP2 fired on the planted live sentence but not as a truncation of it — read '$SPL_GOT' where the unplanted sentence separates $SPL_NAMED name(s). The names separated must be unchanged and the cause must be the mismatch"
  else
    PASS "CTL-SP2-LIVE: SP2 fired once on a copy of the LIVE index ($SPL_GOT) — a period planted before the last middle dot on the line that opens its Sections bullet leaves the $SPL_NAMED name(s) the bullet separates unchanged and only $SPL_R of them read, and the reader refuses it rather than handing on the prefix"
  fi
fi

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
# empty-registration note a sibling still carries. Every scanner is registered, and the
# convention reader beside them; each is probed against the CONFORMANT FIXTURE rather than
# the live tree — that is what
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
# The convention reader is a subject of the SAME assertion: with it removed the spine reads
# empty, and the group must go red through its vacuity guard rather than pass over nothing.
md_flips ad_spine_read SPR ad_assert_sp "$CLEAN"
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
# The measurement state group SP decided above, read here rather than decided again. Under SP2
# the line carries the cause and no count, on the rule test-corpus-hygiene.sh states for its
# own summary lines: a counter printed beside a withheld comparison reads as a measured zero.
AD_SP_WHY="$(awk '$1 == "FINDING" && $2 == "SP2" { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' <<<"$AD_FINAL")"
if [ -z "$AD_SP_WHY" ]; then
  AD_SPINE_PHRASE="$(ad_spine "$ROOT" | grep -c '[^[:space:]]' || true) expected-spine section(s)"
else
  AD_SPINE_PHRASE="expected spine NOT-EVALUATED — $AD_SP_WHY — this is not a clean result"
fi
printf 'CORPUS: %s record(s) derived from %s on this run; %s index row(s); %s; %s declared lifecycle value(s).\n' \
  "$(ad_records "$ROOT" | grep -c '[^[:space:]]' || true)" "$ADR_DIR" \
  "$(ad_index_rows "$ROOT" | grep -c '[^[:space:]]' || true)" \
  "$AD_SPINE_PHRASE" \
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
