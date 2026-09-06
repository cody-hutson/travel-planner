#!/usr/bin/env bash
#
# test-corpus-hygiene.sh — the corpus-hygiene guard suite.
#
#   ./scripts/test-corpus-hygiene.sh
#
# Grades the tracked markdown corpus for three defect classes that survive a reorganisation
# because nothing mechanical looks for them. Each was removed by hand at least once, and
# each came back — inside the very work that removed it.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   A    CITATION FORM. A `.md` basename written bare, where that basename resolves to
#        exactly one tracked file whose home is a durable repo-qualified path. This is a
#        citation-form rule and NOT a basename tally: a bare basename is correct usage when
#        the thing named is a per-trip artifact CLASS living at a templated path, so
#        `examples/` and `trips/` are excluded by construction, as are table rows that put
#        the directory in an adjacent cell. The home map is DERIVED from the tracked tree
#        on every run; this file holds no list of citable documents.
#   B    LINE-NUMBER LOCATORS. A `path.ext:NNN` reference in tracked markdown. A line number
#        is the least durable reference form there is — it rots on the next insertion above
#        it, silently, and points at whatever moved into its place. The tracked population
#        is empty and is expected to stay empty, so this group renders VACUOUS rather than a
#        bare PASS, and group CTL is the only thing that ever exercises it.
#   C    BASIS-FREE COUNT ASSERTIONS. A count asserted about a countable corpus population
#        while carrying no re-derivable basis. The unit is the SENTENCE — see the note on
#        the unit below, which records why. A count is NOT a defect for being a count; it is
#        a defect for being unreproducible. Four basis forms are admitted, each already
#        demonstrated in this corpus, and a sentence carrying one is not a site:
#
#          F1  ANCHORED MEASUREMENT — the sentence names the commit it was probed at, or
#              says "as of", or calls itself a baseline. Frozen to a point in history, so
#              it cannot go stale. Exemplar: reference/adr/ADR-010-per-traveler-approval-
#              collection.md, which asserts a tracked-file count against a live tree that
#              has since grown, and is CORRECT because the same sentence pins the probe.
#          F1' HISTORICAL — the sentence is in the past tense, or says the state no longer
#              holds. It describes a state that was, which is not a claim about now.
#          F2  DERIVED REGION — the assertion sits inside a `<!-- …: derived -->` region
#              regenerated from its source on every run, or carries an inline
#              `<!-- count: … -->` marker. Exemplar: the command-surface region in
#              reference/command-reference.md, graded by scripts/test-command-taxonomy.sh.
#          F3  RECONCILED RULE — the sentence writes out the arithmetic, so a change moves
#              a countable that can be re-derived. Exemplar: reference/data-model.md, which
#              also STATES this convention: "The denominator is stated as a rule, not as a
#              number."
#          F4  AGREEMENT-PINNED POPULATION — several homes assert equal and a marked
#              population is the reference. Exemplars: groups ST and CA in
#              scripts/test-artifact-schema.sh. F4 is not recognised by a token in the
#              sentence; it is recognised by the count-assertion-digest fence, which is
#              what group C compares against.
#
#        Three further shapes are not counts at all and are excluded: a LOCATOR (`§ 4`,
#        `row 10`, `step 3` — an address, not a census), a THRESHOLD (`minimum`, `at least`,
#        `per` — a requirement, not a measurement), and a YEAR, PRICE or VERSION.
#
#        The residual — every count assertion that carries none of those — is DECLARED per
#        path in the `count-assertion-digest` fence in reference/data-architecture.md and
#        asserted in BOTH DIRECTIONS. That is what makes this a pin and not an allowlist.
#        An allowlist entry blinds a file permanently; a pinned population still fails when
#        an already-listed file gains one more, which is where this defect class actually
#        recurred. A removed assertion whose row was not updated fails too, on group ST's
#        warrant: a floor cannot see the deletion of one of two sites.
#
#   CTL  a synthetic fixture tree, built in a temp dir ON EVERY RUN, plus one arm that
#        replays a defect this repository actually shipped. One MUST-FIRE arm per finding
#        code this file can emit, alongside the specificity arms that tell a correct
#        implementation from a lookalike. A code with no arm is a check indistinguishable
#        from one that CANNOT fire.
#   Y    the assertion inventory, derived from this file's own emission sites and checked
#        in BOTH DIRECTIONS: every code this file can emit has a must-fire arm behind it,
#        and every arm names a code that some site can emit. The code set is READ FROM this
#        file on every run and is not held here as a list.
#
# ── THE UNIT IS THE SENTENCE, AND THAT IS A MEASURED CHOICE ──────────────────────
# Three units were measured over the same corpus before this one was written.
#
#   LINE       over-fires. A basis usually sits one line away from the count it grounds, so
#              a line-anchored reading splits the two and reports the count as unfounded.
#   PARAGRAPH  under-fires, and it fails the way that matters: one exemption token blinds
#              every sentence in the paragraph. Flattened to paragraphs, the probe returned
#              ZERO hits on a historical revision that provably contains this card's own
#              motivating defect. That is a broken probe, not a clean document.
#   SENTENCE   the only unit measured both wrap-insensitive and tight enough to keep an
#              exemption scoped to the claim it grounds.
#
# WRAP-INSENSITIVITY IS THE POINT, not a nicety. The motivating instance —
# "…names that file one way in all / twelve places" — has its cardinal and its noun on
# opposite sides of a line break, and a naive line-anchored substring probe reports it
# clean. Arm CTL-C-WRAP is that exact sentence, and arm CTL-RETRO is the real historical
# blob. A line-anchored implementation passes neither.
#
# ── WHY THIS FILE ASSERTS NO COUNT OF ITS OWN ────────────────────────────────────
# Every population this suite reports is EMITTED at run time from the tree it just read.
# No numeral in this banner names a corpus population, a group tally, an arm inventory or a
# code set, because a numeral written here would be a copy with no assertion behind it —
# which is the defect this file exists to catch, in the file that forbids it. That is not a
# hypothetical: the workflow comment describing an earlier gate's coverage boundary acquired
# a stale count in a block that twice forbids exactly this. Where a population belongs in
# prose, it is DECLARED in the digest fence and asserted, or it is derived and printed.
#
# ── STRICT SKIP MODE (set by CI — .github/workflows/corpus-hygiene.yml) ──────────
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# This suite is pure bash and awk with no Node, no gh and no network, so it has NO
# legitimate skip and its expected-skip set is correctly EMPTY. VACUOUS is a distinct
# verdict from SKIP, for the reason the sibling suites already state: a skipped GROUP is a
# hole in the suite, an empty POPULATION is a real measurement of the tree, and collapsing
# the two would hide one behind the other. Group B is the empty population; it renders
# VACUOUS and says so.
#
# ── ONE DEPENDENCY ON REPOSITORY HISTORY, STATED ─────────────────────────────────
# Arm CTL-RETRO reads a blob from a commit in this repository's history. It is the only arm
# that tests the detector against a defect the repository actually shipped rather than one
# this file wrote, and it is therefore the arm worth keeping honest. It requires history
# deeper than a single commit, which is why .github/workflows/corpus-hygiene.yml sets
# fetch-depth: 0 and says why. If the blob is unreachable this arm FAILS rather than
# skipping: an unreachable regression witness is a hole, and a hole that reports green is
# the exact failure mode this suite exists to close.
#
set -uo pipefail
# Deterministic collation and byte semantics. Bracket ranges and character classes below
# resolve against the collating sequence, and a UTF-8 default makes a range match glyphs a
# C-locale run would not — CI would then enforce a rule an operator's own run did not.
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# Resolved absolutely and BEFORE anything reads it: group Y reads this file.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"

# The document that carries the declaring fence, and the fence's own tag. Named once.
CH_FENCE_DOC='reference/data-architecture.md'
CH_FENCE_TAG='count-assertion-digest'
# The commit whose ADR-008 revision carries the motivating defect, and the path inside it.
CH_RETRO_REV='b582bbb0038a4f8a007fa431c9241fe96fffd01d'
CH_RETRO_PATH='reference/adr/ADR-008-publish-content-guard.md'

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""
PASS()    { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL()    { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP()    { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
ARM_LOG="$WORK/arms";  : > "$ARM_LOG"
SURF_LOG="$WORK/surf"; : > "$SURF_LOG"

# has_code <output> <code> — the code appears as a FINDING token and not as a substring of
# a longer one. A substring test would let C1 match C10 and read as a pass. The here-string
# is load-bearing: `grep -q` exits on its first match, and feeding it from a PIPELINE kills
# the writer with SIGPIPE, which under `pipefail` reports the pipeline as failed even though
# the match succeeded. A here-string is a redirection on a simple command, so there is no
# second status to aggregate and no second process to signal.
has_code() { grep -q "^FINDING $2 " <<<"$1"; }
n_code()   { awk -v c="$2" '$1 == "FINDING" && $2 == c { n++ } END { print n + 0 }' <<<"$1"; }

# ═════════════════════════════════════════════════════════════════════════════════
# THE EXTRACTORS. Each is written once, into $WORK, and is driven by BOTH the real-tree
# arm and every control arm. A control that ran different code from the assertion would
# prove nothing about the assertion.
# ═════════════════════════════════════════════════════════════════════════════════

# ── homes.awk — the class-A home map, DERIVED from the tracked list ──────────────
cat > "$WORK/homes.awk" <<'AWK'
# stdin: one repo-relative path per line. stdout: TSV "<basename>\t<path>" for every
# basename that resolves to EXACTLY ONE tracked file whose path is directory-qualified and
# is not a per-trip artifact class. Those two exclusions are the whole of the card's
# "only some bare basenames were ever the defect": a name that resolves two ways cannot be
# repaired by qualification without choosing, and a name whose home is a templated per-trip
# path is correct usage bare.
{
  p = $0
  if (p == "") next
  b = p; sub(/^.*\//, "", b)
  seen[b]++
  home[b] = p
}
END {
  for (b in seen) {
    if (seen[b] != 1) continue          # ambiguous — qualification is not mechanical
    p = home[b]
    if (index(p, "/") == 0) continue    # already at the root; there is nothing to qualify
    if (p ~ /^examples\//) continue     # a worked fixture, cited as a class
    if (p ~ /^trips\//) continue        # a per-trip artifact class at a templated path
    printf "%s\t%s\n", b, p
  }
}
AWK

# ── a.awk — class A, the citation-form scan ──────────────────────────────────────
cat > "$WORK/a.awk" <<'AWK'
# ARGV[1] homes TSV, ARGV[2] newline-separated relative path list. -v ROOT=<dir>
# Emits "FINDING A1 <path> <line> <basename> <home>" per bare citation, and reports its
# own denominator on a DENOM line so a zero can be told from an empty scan.
FNR == NR { split($0, h, "\t"); if (h[1] != "") { HOME[h[1]] = h[2]; nhome++ }; next }
{ if ($0 != "") FILES[++nf] = $0 }
END {
  total = 0; bare = 0
  for (i = 1; i <= nf; i++) {
    rel = FILES[i]; f = ROOT "/" rel
    infence = 0; ln = 0
    while ((getline line < f) > 0) {
      ln++
      t = line; sub(/^[ \t]+/, "", t)
      if (substr(t, 1, 3) == "```") { infence = !infence; continue }
      if (infence) continue
      # A table row that carries a directory in another cell is citing by parts, not by a
      # bare name. That shape is correct and is excluded by construction.
      if (substr(t, 1, 1) == "|" && rowhasdir(t)) continue
      rest = line; off = 0
      while (match(rest, /[A-Za-z0-9_.-]+\.md/)) {
        tok = substr(rest, RSTART, RLENGTH)
        before = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : (off > 0 ? "x" : "")
        total++
        # A SIBLING reference is not a bare citation. Where the cited file lives in the
        # citing file's own directory, the basename IS the correct relative path: it
        # resolves, it renders as a working link, and "qualifying" it would break it —
        # `[ADR-004](ADR-004-contact-emergency-privacy.md)` from inside reference/adr/ is
        # right, and rewriting it to the repo-qualified form points it at a path that does
        # not exist. The defect this group names is a citation that does not say where the
        # file lives; a sibling says so by position. The motivating instance was
        # cross-directory — a reference/ document cited from reference/adr/ — and that is
        # the shape this keeps.
        if (before != "/" && (tok in HOME) && dirof(HOME[tok]) != dirof(rel)) {
          bare++
          printf "FINDING A1 %s %d %s %s\n", rel, ln, tok, HOME[tok]
        }
        off = off + RSTART + RLENGTH - 1
        rest = substr(rest, RSTART + RLENGTH)
      }
    }
    close(f)
  }
  # A0 is emitted BY THE EXTRACTOR rather than decided by the group, so it enters the
  # inventory in group Y on the same terms as every other code. A surface that came back
  # empty is a broken probe or a relocated corpus; reporting it as a clean tree is the one
  # answer that must not be reachable.
  if (nf == 0 || total == 0 || nhome == 0)
    printf "FINDING A0 files=%d citations=%d homes=%d\n", nf + 0, total + 0, nhome + 0
  printf "DENOM %d %d %d\n", nf, total, bare
}
function dirof(p,   d) { d = p; if (sub(/\/[^\/]*$/, "", d)) return d; return "." }
# rowhasdir — some cell of this table row is a bare directory. Backticks and spaces are
# stripped before the test, because the corpus writes the cell as `templates/`.
function rowhasdir(s,   n, c, i, x) {
  n = split(s, c, "|")
  for (i = 1; i <= n; i++) {
    x = c[i]; gsub(/[` \t]/, "", x)
    if (x != "" && substr(x, length(x), 1) == "/") return 1
  }
  return 0
}
AWK

# ── b.awk — class B, the line-number locator scan ────────────────────────────────
cat > "$WORK/b.awk" <<'AWK'
# ARGV[1] newline-separated relative path list. -v ROOT=<dir>
# A locator is <path-ish><.ext>:<digits>. A section address (`§ 4`), a version (`v0.17.0`)
# and a URL with a port are not locators and must not match.
{ if ($0 != "") FILES[++nf] = $0 }
END {
  hits = 0
  for (i = 1; i <= nf; i++) {
    rel = FILES[i]; f = ROOT "/" rel
    infence = 0; ln = 0
    while ((getline line < f) > 0) {
      ln++
      t = line; sub(/^[ \t]+/, "", t)
      if (substr(t, 1, 3) == "```") { infence = !infence; continue }
      if (infence) continue
      # A URL is blanked WHOLE, before the scan. Testing the text preceding each match
      # instead cannot work: after the first match inside a URL is consumed, the remaining
      # text no longer carries the scheme, so a `host:port/path.md:1` reports its port as a
      # locator and then its line number as a second one. Arm CTL-B1-SPEC is that case.
      rest = line
      gsub(/(https?|ftp|file):\/\/[^ )>]*/, " url ", rest)
      while (match(rest, /[A-Za-z0-9_.\/-]+\.[A-Za-z0-9]+:[0-9]+/)) {
        tok = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        hits++
        printf "FINDING B1 %s %d %s\n", rel, ln, tok
      }
    }
    close(f)
  }
  printf "DENOM %d %d\n", nf, hits
}
AWK

# ── c.awk — class C, the basis-aware count-assertion scan ────────────────────────
cat > "$WORK/c.awk" <<'AWK'
# ARGV[1] newline-separated relative path list. -v ROOT=<dir> [-v SHOW=1]
# stdout: "SITE <path> <unit-ordinal> <excerpt>" per detected site when SHOW=1, and always
# a "COUNT <path> <n>" line per file with at least one site, plus a DENOM line carrying the
# files walked and the sentences graded — the denominator that makes a zero a measurement.
BEGIN {
  if (LOOK == 0) LOOK = 2
  n = split("two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty thirty forty fifty", w, " ")
  for (i = 1; i <= n; i++) CARD[w[i]] = 1
  # The countable-corpus nouns, singular and plural, enumerated. A closed list can be read,
  # argued with and extended in a diff; an open predicate ("any word ending in s") cannot be
  # reviewed and measured about one site in ten as a real defect.
  n = split("file row occurrence place site agent command script workflow section entry artifact group arm check gate suite template document adr field line path reference citation home surface", w, " ")
  for (i = 1; i <= n; i++) { NOUN[w[i]] = 1; NOUN[plural(w[i])] = 1 }
}
function plural(s) {
  if (s == "entry") return "entries"
  if (s == "occurrence") return "occurrences"
  return s "s"
}
{ if ($0 != "") FILES[++nf] = $0 }
END {
  nsent = 0
  for (i = 1; i <= nf; i++) {
    rel = FILES[i]; f = ROOT "/" rel
    infence = 0; inderived = 0; buf = ""; ord = 0; sites = 0
    while ((getline line < f) > 0) {
      t = line; sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      if (substr(t, 1, 3) == "```") { ord = flush(rel, buf, ord); buf = ""; infence = !infence; continue }
      if (infence) continue
      # F2 — a derived region is regenerated from its source, so nothing inside it is an
      # assertion anybody has to maintain.
      if (t ~ /<!--[^>]*: *derived/) { ord = flush(rel, buf, ord); buf = ""; inderived = 1; continue }
      if (inderived) { if (t ~ /<!--[ \t]*\//) inderived = 0; continue }
      if (t == "") { ord = flush(rel, buf, ord); buf = ""; continue }
      if (isblockstart(t)) { ord = flush(rel, buf, ord); buf = "" }
      buf = (buf == "" ? line : buf " " line)
    }
    close(f)
    ord = flush(rel, buf, ord); buf = ""
    nsent += ord
    if (sites > 0) printf "COUNT %s %d\n", rel, sites
  }
  printf "DENOM %d %d\n", nf, nsent
}
# A block-level construct starts its own unit; anything else is a wrapped continuation of
# the one above it. This is what makes the unit wrap-insensitive while keeping a table row
# and a list item from merging into one another.
function isblockstart(s) {
  if (s ~ /^#+ /)          return 1
  if (substr(s, 1, 1) == "|") return 1
  if (s ~ /^[-*+] /)       return 1
  if (s ~ /^[0-9]+[.)] /)  return 1
  if (substr(s, 1, 1) == ">") return 1
  if (s ~ /^(---|===|\*\*\*)/) return 1
  if (substr(s, 1, 4) == "<!--") return 1
  return 0
}
# flush — split the accumulated unit into sentences and grade each. Returns the running
# ordinal so a site can be named by the sentence it was found in rather than by a line.
function flush(rel, b, o,   k, m, cur, nn, arr) {
  if (b == "") return o
  nn = sentences(b, arr)
  for (k = 1; k <= nn; k++) { o++; grade(rel, arr[k], o) }
  return o
}
# sentences — cut after a terminator plus any trailing emphasis or closing markup, when
# what follows is whitespace and a sentence-start glyph. `slots.**  Every` therefore splits,
# and `v0.17.0` and `e.g. the` do not.
function sentences(s, out,   n, m, sp, cut) {
  n = 0
  while (match(s, /[.!?][]*_`")]* +[A-Z`*_"(]/)) {
    m = substr(s, RSTART, RLENGTH)
    sp = index(m, " ")
    cut = RSTART + sp - 2
    n++; out[n] = substr(s, 1, cut)
    s = substr(s, RSTART + RLENGTH - 1)
  }
  if (s ~ /[^ \t]/) { n++; out[n] = s }
  return n
}
function has_word(pad, w) { return index(pad, " " w " ") > 0 }
# F1 — anchored measurement. The hex arm requires at least one DIGIT: without it, ordinary
# words built from the letters a-f ("defaced", "deadbeef"-shaped prose) would read as commit
# shas and exempt a sentence that carries no anchor at all.
function exempt_f1(pad,   i, nt, tk, x) {
  if (index(pad, " probed at ") > 0) return 1
  if (index(pad, " as of ") > 0)     return 1
  if (has_word(pad, "baseline"))     return 1
  nt = split(pad, tk, / +/)
  for (i = 1; i <= nt; i++) {
    x = tk[i]
    if (length(x) >= 7 && length(x) <= 40 && x ~ /^[0-9a-f]+$/ && x ~ /[0-9]/) return 1
  }
  return 0
}
function exempt_past(pad) {
  if (has_word(pad, "was") || has_word(pad, "were")) return 1
  if (index(pad, " used to ") > 0)   return 1
  if (has_word(pad, "previously"))   return 1
  if (index(pad, " no longer ") > 0) return 1
  if (index(pad, " an earlier revision ") > 0) return 1
  if (index(pad, " as the spike measured ") > 0) return 1
  return 0
}
function exempt_thresh(pad) {
  if (has_word(pad, "min") || has_word(pad, "minimum")) return 1
  if (has_word(pad, "max") || has_word(pad, "maximum")) return 1
  if (index(pad, " at least ") > 0 || index(pad, " at most ") > 0) return 1
  if (has_word(pad, "per")) return 1
  return 0
}
# F3 — the sentence writes out its own arithmetic, so the countable can be re-derived.
function exempt_arith(s) { return (s ~ /[0-9`*)] *\+ / && s ~ /= *\**[0-9]/) }
# A locator is an address. The cardinal after it names a position, never a population.
function exempt_locator(pad) { return (pad ~ / (sect|section|row|rule|step|wave|group|adr|item|phase) +[0-9]/) }
function exempt_yv(low) {
  if (low ~ /(19|20)[0-9][0-9]/) return 1
  if (low ~ /v[0-9]+\.[0-9]+/)   return 1
  if (low ~ /money[0-9]/)        return 1
  return 0
}
# GOVERNANCE DISTANCE. "Immediately governing" admits ONE adjective between the cardinal and
# the noun — "121 tracked files" and "Four validator checks" are each one cardinal governing
# one noun — and admits nothing more. The width was measured over this corpus at one, two
# and three, and hand-classified at each:
#
#   ONE   strict adjacency. Highest precision, and it silently misses the whole
#         adjective-separated shape — "Nine specialized agents", "two dated sections",
#         "42 priced entries" — which is common enough here to be a recall hole, not a tail.
#   TWO   the shipped width. The sites it adds over one were hand-classified at roughly
#         three in four genuine, and they include the architecture document's own class
#         enumeration, which is exactly the kind of live count this gate exists for.
#   THREE too wide to mean anything. A window that big finds a corpus noun near almost any
#         numeral, manufacturing matches out of unrelated neighbours ("four different
#         branches: line absent", "~1 hour — timed entry"). That is the low-precision gate
#         this design rejected, reached by a different route.
#
# Widening it is not free recall, and narrowing it is not free precision. Both directions
# were measured before this one was chosen.
function grade(rel, s, o,   pad, low, i, j, nt, tk, hit) {
  low = tolower(s)
  if (index(low, "<!-- count:") > 0) return       # F2, inline form
  gsub(/\302\247/, " sect ", low)                 # the section glyph, byte-wise under LC_ALL=C
  gsub(/\302\245|\342\202\254|\302\243/, " money", low)
  gsub(/\$/, " money", low)
  # An issue or pull-request reference is an identifier, not a cardinal. Left in, `(#66)`
  # reads as the number 66 governing whatever noun follows the parenthesis.
  gsub(/#[0-9]+/, " issueref ", low)
  # A clock time is not a cardinal either: `12:00 PM entry slot` is an hour, not two entries.
  gsub(/[0-9]+:[0-9][0-9]/, " clocktime ", low)
  # A numeral opening a heading is that heading's section address — the same locator class
  # the exemption table already names, reached by position rather than by a keyword.
  sub(/^[ \t]*#+[ \t]*[0-9][0-9.]*/, " heading ", low)
  # CLAUSE BARRIERS. A cardinal governs a noun inside one clause; it does not reach across a
  # dash, a colon, a semicolon or a table-cell wall. Without this the lookahead pairs a row
  # label with the first cell of the next column — `| 5 | Group` — and a phrase with the
  # start of the one after it — `the two: no line`. Both read as counts and neither is one.
  gsub(/\342\200\224|\342\200\223|[:;|]/, " brk ", low)
  gsub(/[*_`~]/, "", low)
  # A hyphenated compound is ONE word. Split on the hyphen, `a two-value section-owned list`
  # puts `section` one token after `two` and manufactures a count out of an adjective.
  gsub(/-/, "", low)
  while (match(low, /[0-9],[0-9]/)) low = substr(low, 1, RSTART) substr(low, RSTART + 2)
  if (exempt_yv(low)) return
  pad = low
  gsub(/[^0-9a-z]+/, " ", pad)
  pad = " " pad " "
  if (exempt_f1(pad))      return
  if (exempt_past(pad))    return
  if (exempt_thresh(pad))  return
  if (exempt_locator(pad)) return
  if (exempt_arith(s))     return
  nt = split(pad, tk, / +/)
  for (i = 1; i <= nt; i++) {
    if (!(tk[i] ~ /^[0-9]+$/) && !CARD[tk[i]]) continue
    hit = 0
    # The cardinal must GOVERN the noun: ONE adjective may intervene, another cardinal may
    # not. LOOK is the governance distance; see the note above for why it is not wider.
    for (j = i + 1; j <= i + LOOK && j <= nt; j++) {
      if (tk[j] in NOUN) { hit = 1; break }
      if (tk[j] == "brk") break
      if (tk[j] ~ /^[0-9]+$/ || CARD[tk[j]]) break
    }
    if (!hit) continue
    sites++
    if (SHOW == 1) printf "SITE %s %d %s\n", rel, o, squeeze(s)
  }
}
function squeeze(s) { gsub(/[ \t]+/, " ", s); sub(/^ +/, "", s); return substr(s, 1, 140) }
AWK

# ── fence.awk — the declaring fence, read from the document and nowhere else ─────
cat > "$WORK/fence.awk" <<'AWK'
# -v TAG=<fence-tag>. stdout: TSV "<declared-count>\t<path>". Two columns, both required,
# whitespace-separated; a line whose first non-blank character is # is a comment, and a
# blank line is ignored — byte-for-byte the shape the frozen-witness fence already uses.
$0 == "```" TAG { infence = 1; next }
infence && $0 == "```" { infence = 0; next }
infence {
  line = $0
  sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
  if (line == "" || substr(line, 1, 1) == "#") next
  n = split(line, f, /[ \t]+/)
  if (n >= 2) printf "%s\t%s\n", f[1], f[2]
}
AWK

# ═════════════════════════════════════════════════════════════════════════════════
# THE COMPARATOR. ONE function, driven by the real-tree arm and by every group-C control
# arm below.
# ═════════════════════════════════════════════════════════════════════════════════
ch_list_real() { ( cd "$1" && git ls-files '*.md' ); }
ch_list_dir()  { ( cd "$1" && find . -name '*.md' -type f | sed 's|^\./||' | sort ); }

ch_scan_a() {  # ch_scan_a <root> <listfile>
  awk -v ROOT="$1" -f "$WORK/homes.awk" < "$2" > "$WORK/homes.tsv"
  awk -v ROOT="$1" -f "$WORK/a.awk" "$WORK/homes.tsv" "$2"
}
ch_scan_b() { awk -v ROOT="$1" -f "$WORK/b.awk" "$2"; }
# The governance distance is a CONSTANT of the detector, deliberately not an environment
# knob: a gate whose strictness can be set by the caller is not a gate. It is changed by
# editing the line below, in a diff, alongside the fence rows that change with it.
ch_scan_c() { awk -v ROOT="$1" -v SHOW="${3:-0}" -v LOOK=2 -f "$WORK/c.awk" "$2"; }
ch_fence()  { awk -v TAG="$CH_FENCE_TAG" -f "$WORK/fence.awk" "$1"; }

# ch_compare_c <root> <fence-doc-abs> <listfile> — the both-direction assertion.
#   C0 the fence yields zero rows: an empty declaration asserts nothing.
#   C1 observed ABOVE the declared row — a new assertion was introduced.
#   C2 observed BELOW it — an assertion was removed and the fence was not updated.
#   C3 a path absent from the fence carrying a non-zero observation — a clean file went dirty.
#   C4 a fence row naming a path that no longer exists — the fence rotted.
ch_compare_c() {
  local root="$1" doc="$2" listfile="$3"
  ch_scan_c "$root" "$listfile" | grep '^COUNT ' > "$WORK/obs.txt" || true
  if [ -r "$doc" ]; then ch_fence "$doc" > "$WORK/dec.tsv"; else : > "$WORK/dec.tsv"; fi
  awk -v root="$root" -v tag="$CH_FENCE_TAG" '
    FNR == NR { split($0, d, "\t"); if (d[2] != "") { DEC[d[2]] = d[1] + 0; nrow++ }; next }
    $1 == "COUNT" { OBS[$2] = $3 + 0 }
    END {
      if (nrow == 0) { print "FINDING C0 the " tag " fence yielded zero rows"; exit }
      for (p in OBS) {
        if (!(p in DEC))          { printf "FINDING C3 %s observed %d declared none\n", p, OBS[p]; continue }
        if (OBS[p] > DEC[p])      printf "FINDING C1 %s observed %d declared %d\n", p, OBS[p], DEC[p]
        else if (OBS[p] < DEC[p]) printf "FINDING C2 %s observed %d declared %d\n", p, OBS[p], DEC[p]
      }
      for (p in DEC) {
        cmd = "test -r \"" root "/" p "\""
        if (system(cmd) != 0) { printf "FINDING C4 %s declared %d but the path is absent\n", p, DEC[p]; continue }
        if (!(p in OBS) && DEC[p] > 0) printf "FINDING C2 %s observed 0 declared %d\n", p, DEC[p]
      }
    }
  ' "$WORK/dec.tsv" "$WORK/obs.txt" | sort
}

# ── THE EMITTERS ─────────────────────────────────────────────────────────────────
# CH_EMIT=census prints the declaring fence's rows for the tracked tree, and CH_EMIT=sites
# prints the individual sentences behind them. The census emitter is how the declaration is
# SEEDED, and how a legitimate re-pin is computed when an assertion is deliberately added or
# removed. It is NOT a way to make a red go away: regenerating the whole fence turns the
# assertion into a rubber stamp, which is the same warning § 10's freeze declaration already
# carries for the frozen-witness fence. Re-pin only the rows you meant to change.
if [ "${CH_EMIT:-}" = "census" ] || [ "${CH_EMIT:-}" = "sites" ]; then
  ch_list_real "$ROOT" > "$WORK/list.real"
  if [ "$CH_EMIT" = "sites" ]; then
    ch_scan_c "$ROOT" "$WORK/list.real" 1 | grep '^SITE ' | sort
  else
    printf '# sites  path\n'
    ch_scan_c "$ROOT" "$WORK/list.real" | awk '$1 == "COUNT" { print $2 "\t" $3 }' \
      | sort | awk -F'\t' '{ printf "%-7s %s\n", $2, $1 }'
  fi
  # A diagnostic run EXITS NON-ZERO, deliberately. It asserts nothing — no group ran, no
  # control arm fired — so an exit status of 0 would be indistinguishable from a passing
  # gate, and an environment variable that turns a required check green without running it
  # is a bypass however well-intentioned. The status below cannot be mistaken for a pass.
  printf 'NOTE: this was a %s emission, not a test run. Nothing was asserted.\n' "$CH_EMIT" >&2
  exit 2
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "A — citation form: a bare basename where a unique durable home exists"
# ═════════════════════════════════════════════════════════════════════════════════
ch_list_real "$ROOT" > "$WORK/list.real"
A_OUT="$(ch_scan_a "$ROOT" "$WORK/list.real")"
A_NFILE="$(awk '$1 == "DENOM" { print $2 }' <<<"$A_OUT")"
A_NCITE="$(awk '$1 == "DENOM" { print $3 }' <<<"$A_OUT")"
A_NBARE="$(awk '$1 == "DENOM" { print $4 }' <<<"$A_OUT")"
A_NHOME="$(grep -c '[^[:space:]]' "$WORK/homes.tsv" || true)"
printf '  SURFACE: %s tracked markdown file(s) walked, %s markdown citation(s) read, %s unique durable home(s) derived from the tracked tree.\n' \
  "$A_NFILE" "$A_NCITE" "$A_NHOME"
echo "A0" >> "$SURF_LOG"; echo "A1" >> "$SURF_LOG"

if has_code "$A_OUT" A0; then
  FAIL "A0: the class-A surface came back EMPTY (files=$A_NFILE citations=$A_NCITE homes=$A_NHOME) — a zero here is a broken probe or a relocated corpus, never a clean tree, and A1 below would be a verdict over nothing"
else
  PASS "A0: the scan surface is non-empty and its home map was DERIVED from the tracked tree rather than held here — $A_NCITE citation(s) read across $A_NFILE file(s), against $A_NHOME resolvable home(s)"
fi

if [ "${A_NBARE:-0}" -eq 0 ]; then
  PASS "A1: no bare basename citation carries a unique durable home. The zero is a measurement — the same extractor finds and reports $A_NCITE citation(s) on this tree, and arm CTL-A1 below shows it still firing on a planted one"
else
  FAIL "A1: $A_NBARE bare citation(s) name a document that has exactly one directory-qualified home. Write the qualified path, so the reference survives the file moving:"
  grep '^FINDING A1 ' <<<"$A_OUT" | awk '{ printf "      %s:%s  %s -> %s\n", $3, $4, $5, $6 }'
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "B — line-number locators"
# ═════════════════════════════════════════════════════════════════════════════════
B_OUT="$(ch_scan_b "$ROOT" "$WORK/list.real")"
B_NFILE="$(awk '$1 == "DENOM" { print $2 }' <<<"$B_OUT")"
B_NHIT="$(awk '$1 == "DENOM" { print $3 }' <<<"$B_OUT")"
printf '  SURFACE: %s tracked markdown file(s) walked for path:line locators.\n' "$B_NFILE"
echo "B1" >> "$SURF_LOG"

if [ "${B_NHIT:-0}" -eq 0 ]; then
  VACUOUS "B1: the tracked population is EMPTY — $B_NFILE file(s) walked, no path:line locator found. This group proves nothing about this tree by itself and says so rather than reporting a bare PASS; what it rests on is arm CTL-B1, which plants two locators in a fixture and requires both to be found"
else
  FAIL "B1: $B_NHIT line-number locator(s) in tracked markdown. A line number rots on the next insertion above it and then points at whatever moved into its place — cite the section or the quoted text instead:"
  grep '^FINDING B1 ' <<<"$B_OUT" | awk '{ printf "      %s:%s  %s\n", $3, $4, $5 }'
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "C — count assertions carry a re-derivable basis"
# ═════════════════════════════════════════════════════════════════════════════════
C_DOC="$ROOT/$CH_FENCE_DOC"
C_SCAN="$(ch_scan_c "$ROOT" "$WORK/list.real")"
C_NFILE="$(awk '$1 == "DENOM" { print $2 }' <<<"$C_SCAN")"
C_NSENT="$(awk '$1 == "DENOM" { print $3 }' <<<"$C_SCAN")"
C_NSITE="$(awk '$1 == "COUNT" { n += $3 } END { print n + 0 }' <<<"$C_SCAN")"
C_NDIRTY="$(awk '$1 == "COUNT" { n++ } END { print n + 0 }' <<<"$C_SCAN")"
C_ROWS="$(ch_fence "$C_DOC")"
C_NROW="$(grep -c '[^[:space:]]' <<<"$C_ROWS" || true)"
printf '  SURFACE: %s tracked markdown file(s) walked, %s sentence(s) graded, %s residual site(s) observed in %s file(s), against %s declared row(s).\n' \
  "$C_NFILE" "$C_NSENT" "$C_NSITE" "$C_NDIRTY" "$C_NROW"
for c in C0 C1 C2 C3 C4; do echo "$c" >> "$SURF_LOG"; done

if [ "${C_NSENT:-0}" -eq 0 ]; then
  FAIL "C0: ZERO sentences were graded across $C_NFILE file(s) — the segmenter returned nothing, so every verdict below is over the empty set. This is a broken probe, not a clean corpus"
elif [ "${C_NROW:-0}" -eq 0 ]; then
  FAIL "C0: the \`$CH_FENCE_TAG\` fence in $CH_FENCE_DOC yielded ZERO rows. An empty declaration asserts nothing and every comparison below would be vacuous — this fails rather than passing quietly"
else
  PASS "C0: the declaration in $CH_FENCE_DOC pins $C_NROW path(s), and the segmenter graded $C_NSENT sentence(s) over $C_NFILE file(s). Neither population is empty, so the comparison below is a measurement"
fi

C_FIND="$(ch_compare_c "$ROOT" "$C_DOC" "$WORK/list.real")"
C_NFIND="$(grep -c '^FINDING ' <<<"$C_FIND" || true)"
if [ "${C_NFIND:-0}" -eq 0 ]; then
  PASS "C1/C2/C3/C4: the observed residual population agrees with the declaration in BOTH DIRECTIONS — no path exceeds its row, none falls below it, no undeclared path carries a site, and no row names an absent path"
else
  FAIL "C1/C2/C3/C4: $C_NFIND disagreement(s) between the observed count assertions and the \`$CH_FENCE_TAG\` declaration. For each one: remove the assertion, give it a basis (F1 anchor it to a commit, F2 move it inside a derived region, F3 write out the arithmetic), or update the row in the SAME commit so the diff carries the decision. Do not regenerate the whole fence to make this green — re-pin only the rows you meant to change:"
  printf '%s\n' "$C_FIND" | awk '$1 == "FINDING" { $1 = ""; printf "     %s\n", $0 }'
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "CTL — the control arms: a fixture tree built on every run, plus one real regression"
# ═════════════════════════════════════════════════════════════════════════════════
# Each arm plants ONE defect and requires the SAME extractor that graded the tree above to
# report it. The specificity arms plant a lookalike and require silence. Without both
# polarities a green above is indistinguishable from a probe that cannot fire.

ctl_mk() {  # ctl_mk <name> — a fixture root, returns its path on stdout
  local d="$WORK/fx/$1"
  mkdir -p "$d/reference/adr" "$d/examples/demo" "$d/docs"
  printf '%s\n' "$d"
}
ctl_fence() {  # ctl_fence <root> <row...> — write the declaring document
  local d="$1"; shift
  { printf '# Fixture architecture document\n\n## 10. Migration Sequence\n\n'
    printf '```%s\n' "$CH_FENCE_TAG"
    printf '# sites  path\n'
    local r; for r in "$@"; do printf '%s\n' "$r"; done
    printf '```\n'
  } > "$d/$CH_FENCE_DOC"
}
ctl_list() { ch_list_dir "$1" > "$WORK/list.fx"; printf '%s\n' "$WORK/list.fx"; }
ctl_arm()  { echo "$1" >> "$ARM_LOG"; }

ctl_mustfire() {  # ctl_mustfire <label> <code> <output> <what-was-planted> [<expected-n>]
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
ctl_mustnot() {  # ctl_mustnot <label> <code> <output> <what-was-planted>
  local label="$1" code="$2" out="$3" what="$4"
  if has_code "$out" "$code"; then
    FAIL "$label: MUST NOT FIRE — $what, and the extractor reported $code anyway. The gate cannot tell a sound construct from a defect"
  else
    PASS "$label: $code stayed silent — $what"
  fi
}

# ── A ────────────────────────────────────────────────────────────────────────────
D="$(ctl_mk a1)"
printf 'one\n' > "$D/docs/decisions-index.md"
printf 'See decisions-index.md for the list.\n' > "$D/reference/adr/ADR-900-fixture.md"
ctl_fence "$D" '1  reference/adr/ADR-900-fixture.md'
O="$(ch_scan_a "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-A1" A1 "$O" "a bare \`decisions-index.md\` is cited from an ADR while the file's only home is \`docs/decisions-index.md\`" 1

D="$(ctl_mk a1spec)"
printf 'one\n' > "$D/docs/decisions-index.md"
printf 'one\n' > "$D/docs/twin.md"
printf 'one\n' > "$D/reference/twin.md"
printf 'See docs/decisions-index.md and twin.md for the list.\n' > "$D/reference/adr/ADR-900-fixture.md"
ctl_fence "$D" '1  reference/adr/ADR-900-fixture.md'
O="$(ch_scan_a "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-A1-SPEC" A1 "$O" "the same basename is written QUALIFIED, and a second bare basename resolves TWO ways so no qualification is mechanical"

D="$(ctl_mk a1tbl)"
printf 'one\n' > "$D/docs/decisions-index.md"
printf '| `docs/` | `decisions-index.md` — the index |\n' > "$D/reference/adr/ADR-900-fixture.md"
ctl_fence "$D" '1  reference/adr/ADR-900-fixture.md'
O="$(ch_scan_a "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-A1-TBL" A1 "$O" "the citation is a table row whose adjacent cell carries the directory — the row cites by parts, which is correct usage"

D="$(ctl_mk a1fence)"
printf 'one\n' > "$D/docs/decisions-index.md"
printf 'Example:\n\n```\nSee decisions-index.md here.\n```\n' > "$D/reference/adr/ADR-900-fixture.md"
ctl_fence "$D" '1  reference/adr/ADR-900-fixture.md'
O="$(ch_scan_a "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-A1-FENCE" A1 "$O" "the bare basename sits inside a fenced code block, where it is sample text rather than a citation"

# No ctl_fence here, deliberately: this arm asserts an EMPTY home map, and the fence document
# lives at reference/data-architecture.md — writing it would itself be a directory-qualified
# markdown file and would populate the very map this arm requires to be empty. Group A reads
# no fence, so the fixture correctly carries none.
D="$(ctl_mk a0)"
printf 'nothing to cite here\n' > "$D/README.md"
O="$(ch_scan_a "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-A0" A0 "$O" "a fixture whose every markdown file sits at the ROOT yields an empty home map — the state A0 refuses to report as clean, which is what makes the real tree's green a measurement" 1
ch_scan_a "$ROOT" "$WORK/list.real" > /dev/null   # restore homes.tsv for any later reader

# ── B ────────────────────────────────────────────────────────────────────────────
D="$(ctl_mk b1)"
printf 'See foo/bar.md:42 and scripts/publish-trip-site.sh:1180 for the detail.\n' > "$D/docs/notes.md"
ctl_fence "$D" '1  docs/notes.md'
O="$(ch_scan_b "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-B1" B1 "$O" "two path:line locators are planted on ONE line — the arity is asserted, so a scanner that stops at the first match on a line is caught" 2

D="$(ctl_mk b1spec)"
printf 'See ADR-007 4 row 10, released in v0.17.0, at https://example.com:8080/x.md:1 in a URL.\n' > "$D/docs/notes.md"
ctl_fence "$D" '1  docs/notes.md'
O="$(ch_scan_b "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-B1-SPEC" B1 "$O" "a section address, a version string and a URL carrying a port are each shaped like a locator and are none"

# ── C ────────────────────────────────────────────────────────────────────────────
ctl_c_doc() {  # ctl_c_doc <root> <relpath> <body...>
  local d="$1" rel="$2"; shift 2
  mkdir -p "$(dirname "$d/$rel")"
  printf '# Fixture\n\n' > "$d/$rel"
  local l; for l in "$@"; do printf '%s\n\n' "$l" >> "$d/$rel"; done
}

D="$(ctl_mk c1)"
ctl_c_doc "$D" docs/notes.md \
  'The guard walks 12 files.' 'It grades 9 rows.' 'Three templates carry the marker.'
ctl_fence "$D" '2  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C1" C1 "$O" "a declared path carries THREE basis-free assertions against a row of two — the second-instance case an allowlist cannot see, and the case four of this defect's recurrences actually took" 1

D="$(ctl_mk c2)"
ctl_c_doc "$D" docs/notes.md 'The guard walks 12 files.'
ctl_fence "$D" '2  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C2" C2 "$O" "a declared path carries ONE assertion against a row of two — a deletion whose row was not updated, which a floor could not see" 1

D="$(ctl_mk c3)"
ctl_c_doc "$D" docs/notes.md 'The guard walks 12 files.'
ctl_c_doc "$D" docs/clean.md 'The guard walks the corpus.'
ctl_fence "$D" '1  docs/clean-other.md'
printf 'placeholder\n' > "$D/docs/clean-other.md"
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C3" C3 "$O" "a path absent from the fence carries an assertion — a clean file went dirty" 1

D="$(ctl_mk c4)"
ctl_c_doc "$D" docs/notes.md 'The guard walks the corpus.'
ctl_fence "$D" '3  docs/deleted.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C4" C4 "$O" "a fence row names a path that no longer exists — the fence rotted, and nothing else in the suite would say so" 1

D="$(ctl_mk c0)"
ctl_c_doc "$D" docs/notes.md 'The guard walks the corpus.'
ctl_fence "$D"
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C0" C0 "$O" "the fence is present and carries ZERO rows — an empty declaration asserts nothing, and every comparison behind it would be vacuously green" 1

# CTL-C-WRAP — the motivating defect, wrapped across a line break exactly as it shipped.
# A line-anchored implementation passes every other arm in this group and fails this one.
D="$(ctl_mk cwrap)"
mkdir -p "$D/docs"
{ printf '# Fixture\n\n'
  printf '  All three now carry the prefix, so this document names that file one way in all\n'
  printf '  twelve places. No decision is changed.\n'
} > "$D/docs/notes.md"
ctl_fence "$D" '0  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-WRAP" C1 "$O" "the cardinal and its noun sit on OPPOSITE SIDES of a line break — the wrap-insensitivity assertion, and the arm a naive substring probe fails while passing all the rest" 1

D="$(ctl_mk cf1)"
ctl_c_doc "$D" docs/notes.md 'Probed at `326a2a1`, the commit this record sits on: across all 121 tracked files, 0 occurrences.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-F1" C3 "$O" "the assertion names the commit it was probed at — an F1 anchored measurement is frozen to a point in history and cannot go stale, and flagging it would turn the gate red on content that is right"

D="$(ctl_mk cf2)"
mkdir -p "$D/docs"
{ printf '# Fixture\n\n'
  printf '<!-- surface: derived — regenerate by running the suite -->\n'
  printf 'The guard walks 12 files.\n'
  printf '<!-- /surface -->\n'
} > "$D/docs/notes.md"
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-F2" C3 "$O" "the assertion sits inside an F2 derived region, regenerated from its source on every run, so there is nothing for anyone to maintain"

D="$(ctl_mk cf3)"
ctl_c_doc "$D" docs/notes.md 'The forms carry 36 bullets + `Name` + `Applies to` = 38 labelled fields.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-F3" C3 "$O" "the sentence writes out its own arithmetic — an F3 reconciled rule moves a countable that can be re-derived rather than invalidating one that cannot"

D="$(ctl_mk cdet)"
ctl_c_doc "$D" docs/notes.md 'It dispatches no agent.' 'One row per key.' 'Both files are read.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-DET" C3 "$O" "\`no\`, \`one\` and \`both\` are DETERMINERS here and not counts — they carry most of a naive cardinal probe's hits, and admitting them is what drops such a probe to roughly one true positive in ten"

D="$(ctl_mk cthr)"
ctl_c_doc "$D" docs/notes.md 'Minimum 30 entries per traveler.' 'At least 4 rows are required.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-THR" C3 "$O" "a threshold is a requirement, not a census — nothing about the tree makes it true or false, so it cannot go stale"

D="$(ctl_mk cloc)"
ctl_c_doc "$D" docs/notes.md 'See section 4 row 10 and step 3 for the detail.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-LOC" C3 "$O" "a locator is an address — the cardinal names a position and not a population"

D="$(ctl_mk cpast)"
ctl_c_doc "$D" docs/notes.md 'The suite was 12 files before the split.' 'Three groups were removed.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-PAST" C3 "$O" "an F1' past-tense claim describes a state that WAS, which is not an assertion about the tree as it stands"

# CTL-C-SEG — the sentence unit is the assertion, so it is arm-tested directly. A paragraph
# reading merges these two sentences and lets the first one's anchor blind the second.
D="$(ctl_mk cseg)"
mkdir -p "$D/docs"
{ printf '# Fixture\n\n'
  printf 'Probed at `326a2a1`, the tree carried 121 files. The suite now grades 14 rows.\n'
} > "$D/docs/notes.md"
ctl_fence "$D" '0  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-SEG" C1 "$O" "an anchored sentence and a basis-free one sit in the SAME paragraph — the exemption must scope to the sentence that carries it, and a paragraph-flattened reading returns clean here" 1

# CTL-RETRO — the real historical blob. Every other arm tests a fixture this file wrote;
# this one tests the defect the repository actually shipped, at the commit that carried it.
ctl_arm C1
D="$(ctl_mk retro)"
mkdir -p "$D/$(dirname "$CH_RETRO_PATH")"
RETRO_OK=1
git -C "$ROOT" show "$CH_RETRO_REV:$CH_RETRO_PATH" > "$D/$CH_RETRO_PATH" 2>/dev/null || RETRO_OK=0
if [ "$RETRO_OK" -eq 0 ] || [ ! -s "$D/$CH_RETRO_PATH" ]; then
  FAIL "CTL-RETRO: the historical blob at $CH_RETRO_REV is unreachable, so the one arm that tests this detector against a defect this repository actually shipped did not run. This is a hole, not a skip — CI must check out with fetch-depth: 0, and .github/workflows/corpus-hygiene.yml says so"
else
  RETRO_N="$(ch_scan_c "$D" "$(ctl_list "$D")" | awk '$1 == "COUNT" { n += $3 } END { print n + 0 }')"
  RETRO_WRAP="$(ch_scan_c "$D" "$WORK/list.fx" 1 | grep -c 'twelve places' || true)"
  if [ "$RETRO_N" -eq 0 ]; then
    FAIL "CTL-RETRO: MUST FIRE — the extractor found NO basis-free assertion in the revision of $CH_RETRO_PATH that provably contains one. A probe that returns zero on a document known to carry the defect is broken, and this is the exact signature a paragraph-flattened reading produced"
  elif [ "$RETRO_WRAP" -eq 0 ]; then
    FAIL "CTL-RETRO: the extractor found $RETRO_N site(s) in the historical revision but NONE of them is the wrapped \"twelve places\" instance this arm exists for — it is firing on something else, so the regression is not the one being witnessed"
  else
    PASS "CTL-RETRO: C1 fired on the real historical revision of $CH_RETRO_PATH — $RETRO_N site(s), including the wrapped \"…one way in all / twelve places\" claim that passed every required check green on the day it shipped. This is the only arm here that tests a defect the repository actually carried"
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
      if (c ~ /^[A-Z][0-9]$/) print c
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

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
printf 'CITATION: %s markdown citation(s) read over %s tracked file(s); %s bare where a unique durable home exists.\n' \
  "$A_NCITE" "$A_NFILE" "$A_NBARE"
printf 'LOCATOR: %s path:line locator(s) over %s tracked file(s).\n' "$B_NHIT" "$B_NFILE"
printf 'COUNT-ASSERTION: %s residual site(s) in %s file(s) over %s sentence(s) graded; %s declared row(s).\n' \
  "$C_NSITE" "$C_NDIRTY" "$C_NSENT" "$C_NROW"
if [ "$vacuous" -gt 0 ]; then
  printf 'NOTE: %d assertion group(s) had an EMPTY POPULATION and proved nothing about this tree. Those verdicts rest on group CTL.\n' "$vacuous"
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
