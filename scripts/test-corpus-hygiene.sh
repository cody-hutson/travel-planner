#!/usr/bin/env bash
#
# test-corpus-hygiene.sh — the corpus-hygiene guard suite.
#
#   ./scripts/test-corpus-hygiene.sh
#
# Grades the tracked markdown corpus — and, in class F alone, every tracked shell file and every
# workflow run: value — for the defect classes that survive a reorganisation
# because nothing mechanical looks for them. Each was repaired by hand at least once, and
# most came back — inside the very work that removed them. Their number is not written here,
# per the rule below: a tally in this banner is a copy with no assertion behind it, and this
# one had already gone stale by the time the class after it was added.
#
# ── WHAT IT ASSERTS ──────────────────────────────────────────────────────────────
#   A    CITATION FORM. A `.md` basename written bare, where that basename resolves to
#        exactly one tracked file whose home is a durable repo-qualified path. This is a
#        citation-form rule and NOT a basename tally: a bare basename is correct usage when
#        the thing named is a per-trip artifact CLASS living at a templated path, so
#        `examples/` and `trips/` are excluded by construction, as are table rows that put
#        the directory in an adjacent cell. The home map is DERIVED from the tracked tree
#        on every run; this file holds no list of citable documents.
#   B    LINE-NUMBER LOCATORS. A `path.ext:NNN` reference in tracked markdown, IN THE BARE
#        SPELLING ONLY. A line number is the least durable reference form there is — it rots
#        on the next insertion above it, silently, and points at whatever moved into its
#        place. The in-scope population is empty, so this group renders VACUOUS rather than a
#        bare PASS, and group CTL is the only thing that ever exercises it.
#
#        THE SCOPE IS NARROWER THAN THE NAME, DELIBERATELY, AND THE GAP IS REPORTED ON EVERY
#        RUN. B1's pattern requires the extension to sit immediately against the colon, so a
#        locator whose path is code-spanned — the form this corpus actually writes, where the
#        closing backtick falls between the extension and the colon — is outside it, as is
#        one whose digits carry emphasis. The gate is narrow by the width of one markdown
#        delimiter. That is now a DECLARATION rather than a blind spot: b.awk measures the
#        wider population too, the group prints both figures and their difference beside its
#        verdict, and the VACUOUS line says in terms that it is the predicate's verdict and
#        not the corpus's. No numeral appears here, per the rule below; both are derived.
#
#        WHY NARROWED RATHER THAN WIDENED, which was the live alternative. Widening the
#        pattern to the spelling the corpus uses was measured first, over the whole tracked
#        tree rather than over one change's files: it finds a population that is entirely
#        content one in-flight change authored, with NOTHING pre-existing — so widening would
#        not turn this gate red on another author's work. It would turn it red on that
#        change's own two records, whose locators are paired with verbatim quotations of the
#        text they address. Converting them is a content change to reasoned records, on a
#        scale no scope decision inside this file is entitled to force, and B1's own
#        remediation line already prescribes the quotation those sites carry. So the boundary
#        is written down and reported instead. Widening stays available to a change whose
#        scope is those records, and it is a one-delimiter edit to the pattern below plus the
#        conversions it then requires.
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
#   D    ADR RECORD NUMBERING. A record number carried by two record files or by two index
#        rows; a number inside the sequence carried by no record and DECLARED by no row; and
#        a disagreement between the index and the directory in either direction. Two
#        concurrent branches each shipped a DIFFERENT record at one number and every required
#        check stayed green. The reason nothing objected is structural: the two records have
#        different FILENAMES, so each change is an add of a distinct path and the merge has
#        nothing to conflict on; the only file the two changes share is the index, and a
#        resolution that keeps both rows leaves the collision on the default branch. It was
#        caught by hand, and by hand is not a gate.
#
#        THE DELIBERATE GAP IS DECLARED, NOT SPECIAL-CASED. The convention forbids reuse and
#        renumbering, so a withdrawn record leaves a permanent hole — and a hole is not a
#        defect for being a hole, it is a defect for being unaccounted for. Gaps are therefore
#        DECLARED per number in the `adr-number-declaration` fence in reference/adr/README.md
#        and asserted in BOTH DIRECTIONS, on the same device and for the same reason as class
#        C's digest: an undeclared gap fails, and a declared number that is occupied, that
#        sits outside the span, or that is not readable as a number fails too. That second
#        direction is what keeps a declaration from outliving the gap it excepts. A row
#        carrying only a number is not a declaration — the reader requires both columns — and
#        its number still reads undeclared, which arm CTL-D4-BAD-GAP asserts rather than
#        leaves to be discovered.
#
#        THE SCOPE IS NARROWER THAN THE NAME, DELIBERATELY, AND THE BOUNDARY IS DECLARED.
#        Three things this group reads past rather than grades, so a green is not read as
#        more than it is. A row's record is the FIRST record-file link in it — the table's
#        key cell — so a citation in a later cell is a reference and not a second row. The
#        row's LINK TEXT is not compared against its target: a row whose label names one
#        record over a link to another's file names a file that exists, and is graded by the
#        target alone. And the number's SPELLING is ungraded: the recogniser takes the digit
#        run from the basename rather than a fixed width, so a mis-padded `ADR-27-…` is
#        numbered 27 and participates in every assertion here — but nothing fails it for the
#        padding the convention asks for. Each is a live remediation rather than a hole
#        nobody noticed, and reaching any of them is an edit to the recogniser below.
#
#        THE SPAN'S FLOOR IS THE FIRST NUMBER, NOT THE LOWEST ONE OBSERVED. Anchoring the
#        floor at the observed minimum would make a missing lowest number the one hole
#        nothing can see, because removing it moves the floor down with it.
#   F    SHORT-CIRCUIT READERS. A pipe, in any tracked shell file or any workflow run: value,
#        into a reader that can stop before end of input: head, unless its count is negative;
#        a grep, egrep, fgrep, rg, ugrep or ag carrying -q, --quiet, --silent, -m or
#        --max-count; a sed whose script carries a q or Q command; an awk, gawk, mawk or nawk
#        whose program carries exit or nextfile outside every END block. The reader is the
#        first simple command after the pipe, read past NAME=value words, redirections, and
#        the wrappers command, env, exec, nice, stdbuf and timeout with their options and
#        operands. The reader leaves first, the writer's next write meets a closed pipe, and
#        under pipefail the writer's failure becomes the pipeline's status — so a SUCCESSFUL
#        match can report failure and an `if !` predicate silently inverts — while the race
#        prints a broken-pipe line into whatever captures stderr. Diagnose it by
#        a non-zero status on such a pipeline, never by hunting for 141: a GitHub-hosted runner
#        hands a step SIGPIPE already ignored, so there the writer returns 1, which reads
#        exactly like the reader finding nothing.
#
#        THE SCAN SET IS DERIVED AND PRINTED ON EVERY RUN: every tracked file whose name ends
#        .sh or whose first line is a #! naming sh, bash, dash, ksh or zsh, and every run:
#        value of every tracked .github/workflows file, each on its own SCAN line with the
#        lines it read. A literal block runs to the first NON-EMPTY line indented at or less
#        than its key, so an empty line inside one is content and not its end. A run: form the
#        line reader cannot place is REFUSED as F2 with its form named, never skipped. F0 is
#        the vacuity guard: a surface with nothing to lex, or a unit that ends inside a quote,
#        a substitution or a heredoc, is a broken probe and never a clean tree.
#
#        THE REMEDIES, both already used in this repository: a here-string where one variable
#        feeds the reader, which leaves no writer process to signal; and a DRAINING
#        awk 'NR <= N' everywhere else, which reads to end of input, so the writer never meets
#        a closed pipe. A draining reader on an unbounded producer never terminates, so the
#        remedy presumes a finite producer, which every producer converted to it is.
#
#        WHAT IT DOES NOT REACH IS AN ENUMERATION WITH A STATED BOUNDARY, NOT A CLOSED CLASS.
#        It fails OPEN on: a reader reached through a variable, eval or an alias; a function,
#        a { } group, a ( ) subshell, a conditional or a loop as the reader, a while-read loop
#        that breaks included; sed -f and awk -f; the variable-spliced part of a program or
#        script, of which only the literal text is read; read, cmp -s, dd, grep -l, xargs and
#        every other early-closing program not named above; a wrapper outside the list above,
#        or a grep-like program outside it; a shell file with neither a .sh name nor a shell
#        #!; a run: value outside .github/workflows, such as a composite action's; a run key
#        the line reader cannot see, behind a complex key or a merged anchor; the text a
#        GitHub expression substitutes before the shell runs; and the YAML escapes of a quoted
#        scalar, which is read as the raw text between its quotes. A step's shell: key is not
#        read either: every run: value is lexed as POSIX shell, so a step naming another
#        interpreter is graded as shell all the same. It fails CLOSED, as F0 or F2, on
#        everything the paragraph above names. There is NO allow-marker and NO residual
#        list: the shape is asserted absent, adjudicated or not — PF2's banner in
#        scripts/test-artifact-schema.sh states the same rule for its own class — because a
#        tolerated site becomes a load-bearing one with an edit nobody re-reviews.
#
#        This class's findings are coded F0, F1 and F2. They are not class C's basis forms F1
#        to F4 above, which name an exemption and are never emitted.
#   G    RELEASE TAGS CARRY THEIR OWN CHANGELOG ENTRY. Every `v*` tag's own tree carries its
#        `## [X.Y.Z]` heading, outside a fenced block, as the NEWEST version heading there —
#        what CONTRIBUTING.md's release procedure exists to produce, and what its step 6 checks
#        at tag time by running scripts/check-release-tag.sh on the new tag. This group runs
#        THAT SAME SCRIPT over every tag and grades nothing about a tag itself: the predicate
#        lives in the script, so the release and this gate cannot disagree about what a tag
#        must carry. What the group asserts is the comparison. The tags that are known to fail
#        are DECLARED in the `release-tag-declaration` fence in CONTRIBUTING.md and asserted in
#        BOTH DIRECTIONS, on the device classes C and D use: a failing tag no row declares
#        fails (G1), and a row naming no failing tag fails too (G2) — tags are not protected on
#        this host, so a tag can be moved or deleted, and a declaration must not outlive the
#        failure it excepts. A census that reads no tag, cannot read one, or disagrees with its
#        own exit status, and a declaration that is empty while tags fail, are G0: a broken
#        probe or a shallow checkout, never a clean history, and G0 withholds G1 and G2. So is
#        a SHALLOW repository whose census lacks a declared tag: a depth-limited clone carries
#        only the tags its truncated history reaches, so that census is a sample of the release
#        history and not the whole of it. Shallowness alone is not G0 — a shallow clone can
#        carry every tag — and in a repository that is not shallow an absent declared tag stays
#        G2. Under G0 no line this group prints carries a counter of the comparison: each says
#        NOT-EVALUATED and names the one cause, because a counter beside a withheld comparison
#        reads as a measured zero.
#   CTL  a synthetic fixture tree, built in a temp dir ON EVERY RUN, plus the arms whose ids
#        end -RETRO, each replaying a defect this repository actually shipped. One MUST-FIRE
#        arm per finding code this file can emit, alongside the specificity arms that tell a
#        correct implementation from a lookalike. A code with no arm is a check
#        indistinguishable from one that CANNOT fire.
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
# WRAP-INSENSITIVITY IS THE POINT, not a nicety — and no single arm asserts it, because a
# line break falls on either side of the cardinal-noun pair it separates and only one of
# those positions is load-bearing.
#
#   BREAK BEFORE THE CARDINAL. The motivating instance — "…names that file one way in all /
#   twelve places" — breaks between `all` and `twelve`, so the cardinal and its noun land
#   TOGETHER on the second line. Arm CTL-C-WRAP is that exact sentence and arm CTL-RETRO is
#   the real historical blob that carried it. Both are worth keeping: they hold the shape
#   the defect actually took, and CTL-RETRO is the only class-C arm graded against a document
#   this repository shipped. Neither DISCRIMINATES on the unit, and this comment previously
#   claimed both did — a line-anchored reader finds `twelve places` intact on one line and
#   passes them, so a green from these two says nothing about whether the unit is wrapped.
#   BREAK BETWEEN THE CARDINAL AND ITS NOUN. Arm CTL-C-WRAP-PAIR breaks between `twelve` and
#   `places`. The pair now spans the break, so a line-anchored reader sees a cardinal with
#   nothing after it and a noun with nothing before it, and reports the document clean. This
#   is the arm a line-anchored implementation FAILS, and it is why the unit is not the line.
#
# Both shapes together are the assertion; either alone is a hole. The discrimination is
# measured rather than asserted — replacing the accumulation below with a per-line flush
# drops CTL-C-WRAP-PAIR to zero sites while leaving CTL-C-WRAP firing.
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
# VACUOUS and says so. Read that precisely: what is empty is group B's IN-SCOPE population,
# not the corpus's locators — the class-B entry above states the boundary and the group prints
# the out-of-scope figure beside its own verdict on every run.
#
# ── ONE DEPENDENCY ON REPOSITORY HISTORY, STATED ─────────────────────────────────
# The suite reads this repository's history as blobs and as tags, and both arrive through the
# same checkout. Every arm whose id ends -RETRO reads a blob from a commit in that history: it
# is the arm that tests its class's detector against a defect the repository actually shipped
# rather than one this file wrote, and it is therefore the arm worth keeping honest. Group G
# reads the release tags, and its arm CTL-G-RETRO grades the release check against a tag the
# repository actually shipped without its entry. Both need history deeper than a single commit,
# which is why .github/workflows/corpus-hygiene.yml sets fetch-depth: 0 and says why — that
# depth's fetch carries the tags as well as the commits. If a blob is unreachable its arm FAILS
# rather than skipping, and if no tag is present group G FAILS on G0: an unreachable regression
# witness is a hole, and a hole that reports green is the exact failure mode this suite exists
# to close.
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
# The ADR corpus: the record directory, the index that enumerates it, and the tag of the
# declaring fence that index carries. Named once, and read from nowhere else.
CH_ADR_DIR='reference/adr'
CH_ADR_INDEX='reference/adr/README.md'
CH_ADR_TAG='adr-number-declaration'
# The commit whose validator still piped into early-exiting awk readers, before they were
# converted to drain, and the path inside it: arm CTL-F-RETRO's regression witness. Named once.
CH_F_RETRO_REV='df3b8e2be9dad9c0a1d954af251c5f945674793a'
CH_F_RETRO_PATH='scripts/validate-artifacts.sh'
# The pipe and the tab that class F's control fixtures splice in at run time. No planted shape
# is spelled out in this file, which this file's own PF1 reads without regard to quoting.
F_P='|'; F_T="$(printf '\t')"
# The release check group G drives, the document carrying its declaring fence, that fence's tag,
# and the two real tags its controls read: one this repository shipped without its own entry,
# and one that carries it. Named once.
CH_G_SCRIPT='scripts/check-release-tag.sh'
CH_G_DOC='CONTRIBUTING.md'
CH_G_TAG='release-tag-declaration'
CH_G_RETRO_FAIL='v0.34.0'
CH_G_RETRO_PASS='v0.48.0'

pass=0; fail=0; skip=0; vacuous=0; SKIPPED=""; VACUOUS_IDS=""
PASS()    { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL()    { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP()    { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }
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

# VACUOUS records the ID of every arm that rendered it, so the closing NOTE can NAME them
# rather than assert a compensating group. The footer used to hardcode one group as the basis
# whenever any vacuous verdict existed; the group that compensates is a property of the arm,
# not of the suite, so a literal there is a claim about a run it never read.
VACUOUS() { printf '  \033[1;36mVACUOUS\033[0m %s\n' "$*"; vacuous=$((vacuous+1)); VACUOUS_IDS="$VACUOUS_IDS${*%%:*} "; }

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
#
# THE SCOPE IS THE BARE SPELLING, AND THE BOUNDARY IS MEASURED RATHER THAN ASSUMED.
# B1's pattern requires the extension to sit IMMEDIATELY against the colon, so a locator
# whose path is code-spanned — the form this corpus actually writes, where the closing
# backtick falls between the extension and the colon — does not match it, and neither does
# one whose digits carry emphasis. The gate is therefore narrower than its name reads by
# exactly the width of a markdown delimiter. That narrowness is DECLARED rather than
# repaired: see the class-B entry in this file's banner for why widening it is not this
# gate's call to make.
#
# So the second loop below measures the WIDER population and reports it as a DENOM field —
# never as a FINDING. It asserts nothing and fails nothing; its whole job is to keep B1's
# empty in-scope population from reading as an empty corpus. It emits no finding code, so
# the group-Y inventory is untouched and it needs no must-fire arm of its own. Its honesty
# does not rest on an arm either: unlike B1's zero, a non-zero is self-evidencing, and arm
# CTL-B1-WIDE nonetheless plants the code-spanned form B1 cannot see and requires this loop
# to find it — otherwise a wide count that merely echoed `hits` would look identical here.
{ if ($0 != "") FILES[++nf] = $0 }
END {
  hits = 0; whits = 0
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
      wide = rest
      while (match(rest, /[A-Za-z0-9_.\/-]+\.[A-Za-z0-9]+:[0-9]+/)) {
        tok = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        hits++
        printf "FINDING B1 %s %d %s\n", rel, ln, tok
      }
      # The out-of-scope measurement, over the SAME line after the SAME URL blanking, so the
      # two populations differ by the predicate alone. `wide` is a separate cursor because the
      # loop above consumes `rest`. The delimiter class admits the code span and the emphasis
      # runs either side of the colon, which is the whole of the difference; it can match empty,
      # so this population CONTAINS B1's rather than sitting beside it.
      while (match(wide, /[A-Za-z0-9_.\/-]+\.[A-Za-z0-9]+[`*_]*:[`*_]*[0-9]+/)) {
        wide = substr(wide, RSTART + RLENGTH)
        whits++
      }
    }
    close(f)
  }
  printf "DENOM %d %d %d\n", nf, hits, whits
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
# F1, DATE half. ADR-013 admits "the commit, revision or DATE the count was probed at".
# Until this arm, an ISO date was exempted ACCIDENTALLY by exempt_f1's hex arm above: the
# normalisation strips hyphens, so `2026-09-20` arrives as `20260920` — eight characters, all
# [0-9a-f], carrying a digit — and is read as a commit sha. That coverage was real, undeclared,
# and evaporates on any tightening of the hex window. Reads the RAW sentence, because the
# normalisation strips the hyphens a date is written with; exempt_arith reads s for the same
# reason. ISO is the form this corpus writes a date in — measured 179 ISO occurrences across 52
# of 130 files against 15 long-form and zero US-format, with zero live instances of a
# long-form-anchored count. A long-form recogniser would therefore be an assertion with no
# population able to falsify it, so the long forms are a DECLARED EXCLUSION rather than an
# oversight: a date written any other way does not anchor, and an author wanting the exemption
# writes ISO. The optional day group is load-bearing rather than stylistic — see
# CTL-C-SPEC-YEAR-ANCHOR, whose fixture is month-granular for exactly that reason.
function exempt_f1date(s) { return (s ~ /(19|20)[0-9][0-9]-[0-1][0-9](-[0-3][0-9])?/) }
# A year, price or version is "a value that happens to be a numeral" — ADR-013's own words, and
# a claim about the TOKEN. Each is therefore skipped WHERE IT STANDS, at the subject test in
# grade(), so the sentence around it is still graded. The sentence-scoped exempt_yv these
# replace returned on the whole sentence, so a year, price or version ANYWHERE in a sentence
# admitted a basis-free count beside it: a year in a path (`examples/tokyo-2026/`), in unrelated
# prose, or inside a larger numeral (`198,329` collapses to `198329`, which carries `1983`).
# All three classes carry the IDENTICAL scoping; none of them is sentence-scoped any more.
function is_year(t) { return (t ~ /^(19|20)[0-9][0-9]$/) }
# The HEAD of a price or version value. `$12.50` normalises to `money12 50` and `v1.2` to
# `v1 2`, so the head is never a bare numeral and was already no subject; the MINOR parts ARE
# bare numerals and were reachable only through the sentence-scoped arm. The value run in
# grade() is what marks them.
function is_value_head(t) { return (t ~ /^money[0-9]*$/ || t ~ /^v[0-9]+$/) }
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
function grade(rel, s, o,   pad, low, i, j, nt, tk, hit, val, run) {
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
  pad = low
  gsub(/[^0-9a-z]+/, " ", pad)
  pad = " " pad " "
  # Every arm below RETURNS with no side effect, so the exempt set is their UNION and the order
  # here is semantically inert — it is chosen for readability. Measured: moving the former year
  # arm from the head of this ladder to its foot produced byte-identical output over 130 files
  # and 29,134 sentences, against a sensitivity arm of 332 sites. The year arm sat at the head
  # and read as a precedence it never had; that apparent precedence is NOT what widened this
  # gate, and a reordering on its own would have been a no-op.
  if (exempt_f1(pad))      return
  if (exempt_f1date(s))    return
  if (exempt_past(pad))    return
  if (exempt_thresh(pad))  return
  if (exempt_locator(pad)) return
  if (exempt_arith(s))     return
  nt = split(pad, tk, / +/)
  # VALUE TOKENS, marked before the subject test reads them. `run` carries across the dotted
  # parts of one value, so `v1.2.3` marks both `2` and `3`, and the first token that is not a
  # bare numeral clears it. val[] and run are extra parameters and so are local to this call —
  # a file-scope array would leak marks from one sentence into the next.
  run = 0
  for (i = 1; i <= nt; i++) {
    if (is_value_head(tk[i])) { run = 1; val[i] = 1; continue }
    if (run && tk[i] ~ /^[0-9]+$/) { val[i] = 1; continue }
    run = 0
  }
  for (i = 1; i <= nt; i++) {
    if (!(tk[i] ~ /^[0-9]+$/) && !CARD[tk[i]]) continue
    # THE TOKEN-SCOPE TEST. A year, or the minor part of a price or version, is a VALUE and
    # never a cardinal governing the noun beside it. It is skipped here rather than exempting
    # its whole sentence, so every other numeral in that sentence is still graded.
    if (is_year(tk[i]) || val[i]) continue
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

# ── d.awk — class D, the ADR record-number scan ──────────────────────────────────
cat > "$WORK/d.awk" <<'AWK'
# ARGV[1] the declared-gap TSV, already extracted from the index by fence.awk — the SAME
# reader class C drives, so the corpus's declaring device has one parser and not two.
# ARGV[2] a newline-separated relative path list. -v ROOT=<dir> -v ADRDIR=<dir>
# -v INDEX=<relpath> -v DECFILE=<path of ARGV[1]>
#
# THE TWO INPUTS ARE SPLIT BY FILENAME, NOT BY `FNR == NR`, AND THE DIFFERENCE IS LOAD-
# BEARING. That idiom is sound only while the first file is non-empty: an empty declaration
# leaves NR and FNR equal for every record of the SECOND file too, so the entire path list is
# consumed as declaration rows and the walk reports an empty corpus — a zero that reads like
# a clean tree. A fixture carrying no declaring fence is the ORDINARY case here, not an edge
# one, so this was measured rather than reasoned about: with the idiom in place, four control
# arms below went red and a fifth passed for the wrong reason.
#
# Emits one FINDING per defect, and ALWAYS a DENOM carrying the records walked, the index
# rows read, the gaps declared, the gaps a declaration actually holds open, and the span's
# upper bound — the denominators that make a zero a measurement rather than an empty walk.
FILENAME == DECFILE {
  split($0, d, "\t")
  if (d[1] == "") next
  if (d[1] ~ /^[0-9]+$/) { DECL[d[1] + 0] = d[2]; ndecl++ }
  else                     BADROW[++nbad] = d[1] " " d[2]
  next
}
{ if ($0 != "") FILES[++nf] = $0 }
END {
  # ── The records on disk. The recogniser is the BASENAME SHAPE and the number is the digit
  # run inside it, NOT a fixed width: a width-anchored recogniser would make a mis-padded
  # record invisible to every assertion below, which is the one answer a numbering gate must
  # not give. What it costs is that the padding itself is ungraded, which the banner declares.
  for (i = 1; i <= nf; i++) {
    rel = FILES[i]
    if (index(rel, ADRDIR "/") != 1) continue
    b = rel; sub(/^.*\//, "", b)
    if (b !~ /^ADR-[0-9]+-.+\.md$/) continue
    nrec++
    n = numof(b)
    if (n > maxn) maxn = n
    if (n in FBYNUM) printf "FINDING D1 record %s %s %s\n", pad(n), FBYNUM[n], b
    else             FBYNUM[n] = b
    HASFILE[b] = 1
  }

  # ── The index rows. A row's record is the FIRST record-file link in it — the key cell of
  # the table — so a citation in a later cell is a reference and not a second row. Fenced
  # blocks are skipped, which is also what keeps the declaring fence in that same document
  # from being read as a table of rows.
  idx = ROOT "/" INDEX
  while ((getline line < idx) > 0) {
    t = line; sub(/^[ \t]+/, "", t)
    if (substr(t, 1, 3) == "```") { infence = !infence; continue }
    if (infence) continue
    if (substr(t, 1, 1) != "|") continue
    if (!match(t, /\([^()]*ADR-[0-9]+-[^()]*\.md[^()]*\)/)) continue
    tgt = substr(t, RSTART + 1, RLENGTH - 2)
    sub(/[ \t].*$/, "", tgt)      # a link title
    sub(/#.*$/, "", tgt)          # an anchor
    sub(/^.*\//, "", tgt)         # any qualification; the index writes the sibling name
    nrow++
    n = numof(tgt)
    if (n in RBYNUM) printf "FINDING D1 index %s %s %s\n", pad(n), RBYNUM[n], tgt
    else             RBYNUM[n] = tgt
    HASROW[tgt] = 1
  }
  close(idx)

  # ── Index against directory, in BOTH directions. A number collision routes to D1 and an
  # existence mismatch to D3, so one event is never counted under two codes.
  for (b in HASFILE) if (!(b in HASROW))  printf "FINDING D3 orphan-record %s\n", b
  for (b in HASROW)  if (!(b in HASFILE)) printf "FINDING D3 orphan-row %s\n", b

  # ── The sequence.
  for (n = 1; n <= maxn; n++) {
    if (n in FBYNUM) continue
    if (n in DECL)   { nheld++; continue }
    printf "FINDING D2 %s\n", pad(n)
  }

  # ── The declaration, in the other direction, on class C's warrant: a declaration that
  # outlives the gap it excepts is a standing exemption for whatever next takes that number.
  for (k in DECL) {
    kn = k + 0
    if (k in FBYNUM)           { printf "FINDING D4 %s %s occupied-by-%s\n", pad(kn), DECL[k], FBYNUM[k]; continue }
    if (kn < 1 || kn > maxn)     printf "FINDING D4 %s %s outside-the-span\n", pad(kn), DECL[k]
  }
  for (i = 1; i <= nbad; i++) printf "FINDING D4 %s not-a-number\n", BADROW[i]

  # D0 is emitted BY THE EXTRACTOR rather than decided by the group, so it enters the group-Y
  # inventory on the same terms as every other code. A surface that came back empty is a
  # broken probe or a relocated corpus; reporting it as clean numbering is the one answer
  # that must not be reachable.
  if (nf == 0 || nrec == 0 || nrow == 0)
    printf "FINDING D0 files=%d records=%d rows=%d\n", nf + 0, nrec + 0, nrow + 0
  printf "DENOM %d %d %d %d %d\n", nrec + 0, nrow + 0, ndecl + 0, nheld + 0, maxn + 0
}
function numof(b,   k) { k = b; sub(/^ADR-/, "", k); sub(/-.*$/, "", k); return k + 0 }
function pad(n) { return sprintf("%03d", n + 0) }
AWK

# ── f.awk — class F, the short-circuit reader scan ─────────────────────────────
cat > "$WORK/f.awk" <<'AWK'
# ARGV[1] a newline-separated list of relative paths: every tracked file. Which of them are
# read is decided here, not by the caller. -v ROOT=<dir>. Emits, in the order found:
#   SCAN <path> shell                         a shell file it lexed
#   SCAN <path> run=<key> lines=<a>-<b>       a run: value it lexed, and the lines it read: <a>
#                                             is the first line after the key — the key line
#                                             itself for a one-line value — and <b> the last
#                                             NON-EMPTY line of the value
#   FINDING F1 <path> <line> <class> <reader> a pipe into a reader that can stop early, at the
#                                             line of the reader's command word
#   FINDING F2 <path> <line> <form>           a run: value this line reader cannot place
#   FINDING F0 <path> <line> <reason>         a unit that ended inside a construct, opened at
#                                             <line>; or, as `- 0 empty-surface`, nothing to lex
#   DENOM <shell-files> <workflow-files> <run-values> <pipes>
# The DENOM line is what makes a zero a measurement rather than an empty walk.
#
# THE RUN: READER IS A LINE READER WITH A DECLARED BOUNDARY, NOT A YAML PARSER. A plain scalar
# is one line of shell. A literal block (| |- |+) is every line after its key up to the first
# NON-EMPTY line indented at or less than the key: an empty or whitespace-only line inside it
# is content and keeps its number, as a parser keeps it. The block's indentation — that of its
# first non-empty line — is removed before lexing, so a heredoc delimiter inside it matches. A
# quoted scalar that closes on its own line is lexed as the raw text between its quotes. Every
# other form is REFUSED as F2 with its form named: a folded block, an explicit indentation
# indicator, a block header carrying a comment, a quoted scalar that does not close on its
# line, a plain scalar continued on the next line, an empty value, an alias, an anchor or a
# tag, a flow collection as the value, a quoted run key, and a run key inside a flow mapping.
# The content of every other block scalar is passed over, so text inside it is never a key.
#
# THE LEXER keeps one frame per open construct: quoting ('', "", $'', a backslash, a
# backslash-newline), comments, heredocs (the body starts when the line ends, at any depth; a
# quoted delimiter's body is skipped, an unquoted one is read for substitutions only), the code
# contexts — $( ), backticks, <( ), >( ), ( ), a case body — and the contexts that are not code
# — arithmetic, ${ }, [[ ]], a case pattern — each read only for the substitutions inside it.
# A double bar is a list operator; a bar and a bar-ampersand are pipes, and a pipe continues
# across a newline and across comment lines.
#
# THE READER is the first simple command after a pipe, read past NAME=value words,
# redirections and the wrappers command, env, exec, nice, stdbuf and timeout — their options,
# option arguments, env's NAME=value words and timeout's duration. A compound command as the
# reader — { }, ( ), if, case, a loop — is not graded. The command word's basename decides:
#   head                          always, unless its count is negative
#   grep egrep fgrep rg ugrep ag  q, --quiet or --silent in its options is grep-q; m or
#                                 --max-count is grep-m
#   sed                           a q or Q command in its script is sed-q
#   awk gawk mawk nawk            exit or nextfile in its program, once strings, regular
#                                 expressions, comments and every END block are removed, is
#                                 awk-exit
{ if ($0 != "") FILES[++nf] = $0 }
END {
  f_init()
  for (fi = 1; fi <= nf; fi++) {
    urel = FILES[fi]; upath = ROOT "/" urel
    if (urel ~ /^\.github\/workflows\/[^\/]+\.ya?ml$/) { nwf++; f_workflow(urel, upath); continue }
    if (f_isshell(urel, upath)) { nsh++; printf "SCAN %s shell\n", urel; f_shellfile(urel, upath) }
  }
  # F0 is emitted BY THE EXTRACTOR, as A0 and D0 are, so it enters the group-Y inventory on the
  # same terms as every other code. A surface with no unit to lex is a broken probe or a relocated
  # corpus, never a clean one.
  if (nsh + nrun == 0) printf "FINDING F0 - 0 empty-surface\n"
  printf "DENOM %d %d %d %d\n", nsh, nwf, nrun, npipe
}

function f_init(   n, a, i) {
  n = split("{ while until if for case select function [[", a, " ")
  for (i = 1; i <= n; i++) COMPOUND[a[i]] = 1
  n = split("if then else elif do while until ! time { } fi done esac", a, " ")
  for (i = 1; i <= n; i++) TRANSP[a[i]] = 1
  n = split("command env exec nice stdbuf timeout", a, " ")
  for (i = 1; i <= n; i++) WRAP[a[i]] = 1
  n = split("grep egrep fgrep rg ugrep ag", a, " ")
  for (i = 1; i <= n; i++) GREPS[a[i]] = 1
  n = split("awk gawk mawk nawk", a, " ")
  for (i = 1; i <= n; i++) AWKS[a[i]] = 1
  n = split("TOP CS BT SUB CASE", a, " ")
  for (i = 1; i <= n; i++) CODE[a[i]] = 1
  NAME["SQ"] = "single-quote"; NAME["DQ"] = "double-quote"; NAME["AQ"] = "dollar-quote"
  NAME["CS"] = "command-substitution"; NAME["BT"] = "backtick"; NAME["SUB"] = "subshell"
  NAME["CASE"] = "case"; NAME["PE"] = "parameter-expansion"; NAME["AR"] = "arithmetic"
  NAME["CB"] = "conditional"; NAME["HD"] = "heredoc"
}

# ── the scan set ──────────────────────────────────────────────────────────────────
function f_isshell(rel, path,   l, n, w, b, i) {
  if (rel ~ /\.sh$/) return 1
  l = ""
  if ((getline l < path) <= 0) { close(path); return 0 }
  close(path)
  if (substr(l, 1, 2) != "#!") return 0
  l = substr(l, 3); sub(/^[ \t]+/, "", l)
  n = split(l, w, " ")
  if (n == 0) return 0
  b = w[1]; sub(/^.*\//, "", b)
  if (b == "env") {
    for (i = 2; i <= n; i++) {
      if (substr(w[i], 1, 1) == "-" || index(w[i], "=") > 0) continue
      b = w[i]; sub(/^.*\//, "", b); break
    }
  }
  return (b == "sh" || b == "bash" || b == "dash" || b == "ksh" || b == "zsh")
}

function f_shellfile(rel, path,   line, ln) {
  lex_begin(rel); ln = 0
  while ((getline line < path) > 0) { ln++; lex_line(line, ln) }
  close(path)
  lex_end()
}

function f2(rel, ln, form) { printf "FINDING F2 %s %d %s\n", rel, ln, form }

# ── the run: reader ───────────────────────────────────────────────────────────────
function f_workflow(rel, path,   n, line, i, t, col, v, c1, endi, j, l, t2, cind, last, k, m, inner) {
  n = 0
  while ((getline line < path) > 0) WL[++n] = line
  close(path)
  i = 1
  while (i <= n) {
    line = WL[i]; t = line; sub(/^[ \t]+/, "", t)
    if (t == "" || substr(t, 1, 1) == "#") { i++; continue }
    while (t ~ /^-[ ]/) sub(/^-[ ]+/, "", t)
    col = length(line) - length(t)
    if (t ~ /^("run"|'run')[ ]*:/) { nrun++; f2(rel, i, "quoted-key"); i = wf_skip(i, col, n, t); continue }
    if (t !~ /^run[ ]*:([ ]|$)/) {
      if (t ~ /[{]([^}]*,)?[ ]*("run"|'run'|run)[ ]*:/) { nrun++; f2(rel, i, "flow-mapping"); i++; continue }
      i = wf_skip(i, col, n, t); continue
    }
    nrun++
    v = t; sub(/^run[ ]*:[ ]*/, "", v); sub(/[ \t]+$/, "", v)
    c1 = substr(v, 1, 1)
    if (v == "" || c1 == "#") { f2(rel, i, "empty-value"); i++; continue }
    if (c1 == ">") { f2(rel, i, "folded-block"); i = wf_block_end(i, col, n); continue }
    if (c1 == "|") {
      if (v !~ /^[|][+-]?$/) {
        if (v ~ /^[|][+-]?[ \t]+#/) f2(rel, i, "block-header-comment")
        else if (v ~ /[0-9]/)        f2(rel, i, "indentation-indicator")
        else                         f2(rel, i, "block-header")
        i = wf_block_end(i, col, n); continue
      }
      endi = wf_block_end(i, col, n)
      cind = -1; last = 0
      for (j = i + 1; j < endi; j++) {
        l = WL[j]; t2 = l; sub(/^[ \t]+/, "", t2)
        if (t2 == "") continue
        if (cind < 0) cind = length(l) - length(t2)
        last = j
      }
      if (last == 0) { f2(rel, i, "empty-value"); i = endi; continue }
      printf "SCAN %s run=%d lines=%d-%d\n", rel, i, i + 1, last
      lex_begin(rel)
      for (j = i + 1; j <= last; j++) {
        l = WL[j]; m = l; sub(/^[ ]+/, "", m); k = length(l) - length(m)
        if (k > cind) k = cind
        lex_line(substr(l, k + 1), j)
      }
      lex_end()
      i = endi; continue
    }
    if (c1 == "*") { f2(rel, i, "alias"); i++; continue }
    if (c1 == "&" || c1 == "!") { f2(rel, i, "anchor-or-tag"); i = wf_block_end(i, col, n); continue }
    if (c1 == "{" || c1 == "[") { f2(rel, i, "flow-value"); i++; continue }
    if (c1 == "\"" || c1 == "'") {
      inner = wf_unquote(v, c1)
      if (!WQ_OK) { f2(rel, i, "quoted-continues"); i = wf_block_end(i, col, n); continue }
      printf "SCAN %s run=%d lines=%d-%d\n", rel, i, i, i
      lex_begin(rel); lex_line(inner, i); lex_end()
      i++; continue
    }
    # A plain scalar is one line of shell: a non-comment line indented deeper than the key on the
    # line after it continues the scalar, which this reader does not join.
    j = i + 1
    while (j <= n) { t2 = WL[j]; sub(/^[ \t]+/, "", t2); if (t2 != "") break; j++ }
    if (j <= n && substr(t2, 1, 1) != "#" && length(WL[j]) - length(t2) > col) {
      f2(rel, i, "plain-continues"); i = wf_block_end(i, col, n); continue
    }
    printf "SCAN %s run=%d lines=%d-%d\n", rel, i, i, i
    lex_begin(rel); lex_line(v, i); lex_end()
    i++
  }
}
# wf_block_end — the first line index after the block whose header is line i: the first NON-EMPTY
# line indented at or less than column col.
function wf_block_end(i, col, n,   j, l, t2) {
  for (j = i + 1; j <= n; j++) {
    l = WL[j]; t2 = l; sub(/^[ \t]+/, "", t2)
    if (t2 == "") continue
    if (length(l) - length(t2) <= col) return j
  }
  return n + 1
}
# wf_skip — a line that is not a run key: pass over the content of any block scalar it opens.
function wf_skip(i, col, n, t) {
  if (t ~ /(^|:[ ]+)[|>][0-9+-]*[ ]*(#.*)?$/) return wf_block_end(i, col, n)
  return i + 1
}
# wf_unquote — the raw text between a quoted scalar's quotes. WQ_OK is 1 only when the scalar
# closes on this line and nothing but a comment follows it.
function wf_unquote(v, q,   i, n, c, out) {
  WQ_OK = 0; n = length(v); i = 2; out = ""
  while (i <= n) {
    c = substr(v, i, 1)
    if (q == "'" && c == "'") {
      if (substr(v, i + 1, 1) == "'") { out = out "''"; i += 2; continue }
      break
    }
    if (q == "\"" && c == "\\") { out = out substr(v, i, 2); i += 2; continue }
    if (q == "\"" && c == "\"") break
    out = out c; i++
  }
  if (i > n) return ""
  if (substr(v, i + 1) ~ /^[ \t]*(#.*)?$/) WQ_OK = 1
  return out
}

# ── the lexer: one frame per open construct ───────────────────────────────────────
# T[d] is the frame type. Code frames (TOP CS BT SUB CASE) carry the command state: the word
# being read, how many words the command has, and — after a pipe — the reader's words. Every
# other frame belongs to the word of the nearest code frame below it (OWN), or to none (0) when
# it sits inside arithmetic, a [[ ]] or a heredoc body, whose text is not a command.
function lex_begin(rel) {
  UNIT = rel; D = 0; LN = 0; cont = 0; hq_n = 0; hq_h = 1; hd_on = 0; f0done = 0
  push("TOP")
}
function push(t,   p) {
  p = D; D++
  T[D] = t; OPEN[D] = LN
  if (t in CODE) {
    OWN[D] = D; inw[D] = 0; wb[D] = ""; wq[D] = 0; wl[D] = 0
    cmdw[D] = 0; coll[D] = 0; ccw[D] = 0; casehdr[D] = 0; forkw[D] = 0; cstate[D] = ""; psub[D] = 0
  } else if (t == "AR" || t == "CB" || t == "HD") OWN[D] = 0
  else OWN[D] = OWN[p]
  if (t == "AR") { ardepth[D] = 0; ardollar[D] = 0 }
  if (t == "CB") cbw[D] = 1
  if (t == "PE") pedq[D] = (T[p] == "DQ" || T[p] == "HD" || (T[p] == "PE" && pedq[p])) ? 1 : 0
}
function pop(   t, d) {
  t = T[D]; d = D; D--
  if (t == "CS" || t == "BT") addw("$()", 1)
  else if (t == "SUB") { if (psub[d]) addw("<()", 1) }
  else if (t == "AR") { if (ardollar[d]) addw("$(())", 1) }
  else if (t == "PE") addw("}", 1)
  else if (t == "CB" && OWN[D] == D) { inw[D] = 0; wb[D] = ""; cmdw[D] = 1 }
}
# addw — append text to the word of the code frame that owns the current frame. The text is kept
# only where it can matter: the reader's words, a command's first word, and case syntax.
function addw(x, q,   o) {
  o = OWN[D]
  if (o == 0) return
  if (!inw[o]) { inw[o] = 1; wq[o] = q; wl[o] = LN; wb[o] = "" }
  if (coll[o] || cmdw[o] == 0 || casehdr[o] || cstate[o] == "pat") wb[o] = wb[o] x
}
function endword(   d, w, q, l) {
  d = D
  if (OWN[d] != d || !inw[d]) return
  w = wb[d]; q = wq[d]; l = wl[d]
  inw[d] = 0; wb[d] = ""; wq[d] = 0
  if (T[d] == "CASE" && cstate[d] == "pat") { if (!q && w == "esac") pop(); return }
  if (casehdr[d]) { if (!q && w == "in") { casehdr[d] = 0; push("CASE"); cstate[D] = "pat" } return }
  if (coll[d]) {
    if (ccw[d] == 0 && !q && (w in COMPOUND)) coll[d] = 0
    else if (!(ccw[d] == 0 && !q && (w == "!" || w == "time"))) {
      ccw[d]++; RW[d, ccw[d]] = w; RQ[d, ccw[d]] = q; RL[d, ccw[d]] = l
    }
  }
  if (cmdw[d] == 0 && !q) {
    if (T[d] == "CASE" && w == "esac") { pop(); return }
    if (w == "case") { casehdr[d] = 1; cmdw[d] = 1; return }
    if (w == "[[") { cmdw[d] = 1; push("CB"); return }
    if (w in TRANSP) return
    if (w == "for" || w == "select") forkw[d] = 1
  }
  cmdw[d]++
}
function endcmd(   d) {
  endword(); d = D
  if (OWN[d] != d) return
  if (coll[d]) { classify(d); coll[d] = 0 }
  ccw[d] = 0; cmdw[d] = 0; forkw[d] = 0
}
function dopipe(   d) {
  endword(); d = D
  if (OWN[d] != d) return
  if (coll[d]) classify(d)
  npipe++
  coll[d] = 1; ccw[d] = 0; cmdw[d] = 0; forkw[d] = 0
}
function f0(ln, why) {
  if (f0done) return
  f0done = 1
  printf "FINDING F0 %s %d %s\n", UNIT, ln, why
}

function lex_line(s, ln,   t) {
  LN = ln
  if (hd_on) {
    t = s
    if (hq_t[hq_h]) sub(/^\t+/, "", t)
    if (t == hq_d[hq_h]) {
      if (!hq_q[hq_h]) {
        while (D > 1 && T[D] != "HD") { f0(OPEN[D], "unterminated-" NAME[T[D]] "-inside-heredoc"); D-- }
        if (T[D] == "HD") D--
      }
      hq_h++
      if (hq_h > hq_n) { hd_on = 0; hq_n = 0; hq_h = 1 }
      else if (!hq_q[hq_h]) push("HD")
      return
    }
    if (hq_q[hq_h]) return
    lex_text(s); lex_newline()
    return
  }
  lex_text(s); lex_newline()
}
function lex_end() {
  if (hd_on || hq_n >= hq_h) { f0(hq_l[hq_h], "unterminated-heredoc"); return }
  if (D > 1) { f0(OPEN[2], "unterminated-" NAME[T[2]]); return }
  endcmd()
}
function lex_newline(   t, d) {
  if (cont) { cont = 0; return }
  t = T[D]
  if (t == "SQ" || t == "DQ" || t == "AQ" || t == "PE") { addw("\n", 1); return }
  if (t == "AR" || t == "HD") return
  if (t == "CB") { cbw[D] = 1; return }
  if ((t == "CASE" && cstate[D] == "pat") || casehdr[D]) endword()
  else {
    endword(); d = D
    if (OWN[d] == d && !(coll[d] && ccw[d] == 0)) endcmd()
  }
  if (hq_n >= hq_h && !hd_on && (T[D] in CODE)) { hd_on = 1; if (!hq_q[hq_h]) push("HD") }
}
function lex_text(s,   t) {
  REST = s
  while (REST != "") {
    t = T[D]
    if (t == "SQ") lex_sq()
    else if (t == "DQ") lex_dq()
    else if (t == "PE") lex_pe()
    else if (t == "AR") lex_ar()
    else if (t == "CB") lex_cb()
    else if (t == "HD") lex_hd()
    else if (t == "AQ") lex_aq()
    else if (t == "CASE" && cstate[D] == "pat") lex_pat()
    else lex_code()
  }
}
# nextsp — the position of the first character in REST matching re, or of the first backslash,
# whichever comes first; 0 when there is neither. Kept out of the bracket expressions, the
# backslash needs no escaping that the awks could read differently.
function nextsp(re,   p, b) {
  p = match(REST, re) ? RSTART : 0
  b = index(REST, "\\")
  if (b > 0 && (p == 0 || b < p)) return b
  return p
}
# sqword — a single-quoted string starting at REST's first character, closed on this line or not.
function sqword(q,   i) {
  i = index(substr(REST, 2), "'")
  if (i > 0) { addw(substr(REST, 2, i - 1), q); REST = substr(REST, i + 2); return }
  addw(substr(REST, 2), q); REST = ""; push("SQ")
}
function lex_dollar(   c3, c2) {
  c3 = substr(REST, 1, 3); c2 = substr(REST, 1, 2)
  if (c3 == "$((") { addw("", 1); push("AR"); ardollar[D] = 1; REST = substr(REST, 4); return }
  if (c2 == "$(")  { addw("", 1); push("CS"); REST = substr(REST, 3); return }
  if (c2 == "${")  { addw("${", 1); push("PE"); REST = substr(REST, 3); return }
  addw("$", 0); REST = substr(REST, 2)
}
function lex_code(   c, c2, c3) {
  if (match(REST, /^[ \t]+/)) { REST = substr(REST, RLENGTH + 1); endword(); return }
  if (match(REST, /^[A-Za-z0-9_.\/:,%+@^~=!*?{}-]+/)) {
    addw(substr(REST, 1, RLENGTH), 0); REST = substr(REST, RLENGTH + 1); return
  }
  c = substr(REST, 1, 1); c2 = substr(REST, 1, 2); c3 = substr(REST, 1, 3)
  if (c == "#") {
    if (!inw[D]) { REST = ""; return }
    addw("#", 0); REST = substr(REST, 2); return
  }
  if (c == "\\") {
    if (length(REST) == 1) { cont = 1; REST = ""; return }
    addw(substr(REST, 2, 1), 1); REST = substr(REST, 3); return
  }
  if (c == "'") { sqword(1); return }
  if (c == "\"") { addw("", 1); push("DQ"); REST = substr(REST, 2); return }
  if (c == "`") {
    REST = substr(REST, 2)
    if (T[D] == "BT") { endcmd(); pop(); return }
    addw("", 1); push("BT"); return
  }
  if (c == "$") {
    if (c2 == "$'") { addw("", 1); push("AQ"); REST = substr(REST, 3); return }
    if (c2 == "$\"") { addw("", 1); push("DQ"); REST = substr(REST, 3); return }
    lex_dollar(); return
  }
  if (c == "|") {
    if (c2 == "||") { REST = substr(REST, 3); endcmd(); return }
    if (c2 == "|&") { REST = substr(REST, 3); dopipe(); return }
    REST = substr(REST, 2); dopipe(); return
  }
  if (c == "&") {
    if (c2 == "&&") { REST = substr(REST, 3); endcmd(); return }
    if (c2 == "&>") { addw("&>", 0); REST = substr(REST, 3); return }
    REST = substr(REST, 2); endcmd(); return
  }
  if (c == ";") {
    if (c3 == ";;&") { REST = substr(REST, 4); endcmd(); if (T[D] == "CASE") cstate[D] = "pat"; return }
    if (c2 == ";;" || c2 == ";&") { REST = substr(REST, 3); endcmd(); if (T[D] == "CASE") cstate[D] = "pat"; return }
    REST = substr(REST, 2); endcmd(); return
  }
  if (c == "(") {
    if (c2 == "((" && !inw[D] && (cmdw[D] == 0 || forkw[D])) {
      if (coll[D] && ccw[D] == 0) coll[D] = 0
      REST = substr(REST, 3); cmdw[D] = 1; forkw[D] = 0; push("AR"); return
    }
    if (c2 == "()") { REST = substr(REST, 3); return }
    REST = substr(REST, 2)
    if (!inw[D]) { if (coll[D] && ccw[D] == 0) coll[D] = 0; cmdw[D] = 1 }
    push("SUB"); return
  }
  if (c == ")") {
    REST = substr(REST, 2)
    endword()
    if (T[D] == "CS" || T[D] == "SUB") { endcmd(); pop() }
    return
  }
  if (c == "<") {
    if (c3 == "<<<") { addw("<<<", 0); REST = substr(REST, 4); return }
    if (c2 == "<<") { lex_heredoc(); return }
    if (c2 == "<(") { addw("", 1); push("SUB"); psub[D] = 1; REST = substr(REST, 3); return }
    if (c2 == "<&" || c2 == "<>") { addw(c2, 0); REST = substr(REST, 3); return }
    addw("<", 0); REST = substr(REST, 2); return
  }
  if (c == ">") {
    if (c2 == ">(") { addw("", 1); push("SUB"); psub[D] = 1; REST = substr(REST, 3); return }
    if (c2 == ">&" || c2 == ">|" || c2 == ">>") { addw(c2, 0); REST = substr(REST, 3); return }
    addw(">", 0); REST = substr(REST, 2); return
  }
  addw(c, 0); REST = substr(REST, 2)
}
# lex_heredoc — <<WORD and <<-WORD: the delimiter is read off this line, and the body starts
# after the line ends. Any quoting in the delimiter makes the body literal.
function lex_heredoc(   tabs, delim, q, c, i) {
  REST = substr(REST, 3); tabs = 0; q = 0; delim = ""
  if (substr(REST, 1, 1) == "-") { tabs = 1; REST = substr(REST, 2) }
  sub(/^[ \t]+/, "", REST)
  while (REST != "") {
    c = substr(REST, 1, 1)
    if (c == "'" || c == "\"") {
      i = index(substr(REST, 2), c); q = 1
      if (i == 0) { delim = delim substr(REST, 2); REST = ""; break }
      delim = delim substr(REST, 2, i - 1); REST = substr(REST, i + 2); continue
    }
    if (c == "\\") { delim = delim substr(REST, 2, 1); REST = substr(REST, 3); q = 1; continue }
    if (c == " " || c == "\t" || c == ";" || c == "&" || c == "|" || c == "(" || c == ")" || c == "<" || c == ">") break
    delim = delim c; REST = substr(REST, 2)
  }
  if (delim == "") return
  hq_n++; hq_d[hq_n] = delim; hq_t[hq_n] = tabs; hq_q[hq_n] = q; hq_l[hq_n] = LN
}
function lex_pat(   d, c, c2) {
  d = D
  if (match(REST, /^[ \t]+/)) { REST = substr(REST, RLENGTH + 1); endword(); return }
  if (match(REST, /^[A-Za-z0-9_.\/:,%+@^~=!*?{}-]+/)) {
    addw(substr(REST, 1, RLENGTH), 0); REST = substr(REST, RLENGTH + 1); return
  }
  c = substr(REST, 1, 1); c2 = substr(REST, 1, 2)
  if (c == "#" && !inw[D]) { REST = ""; return }
  if (c == ")") {
    endword(); if (D != d) return
    REST = substr(REST, 2); cstate[D] = "body"; cmdw[D] = 0; coll[D] = 0; ccw[D] = 0; return
  }
  if (c == "|" || c == "(" || c == ";" || c == "&") { endword(); if (D != d) return; REST = substr(REST, 2); return }
  if (c == "\\") {
    if (length(REST) == 1) { cont = 1; REST = ""; return }
    addw(substr(REST, 2, 1), 1); REST = substr(REST, 3); return
  }
  if (c == "'") { sqword(1); return }
  if (c == "\"") { addw("", 1); push("DQ"); REST = substr(REST, 2); return }
  if (c == "`") { addw("", 1); push("BT"); REST = substr(REST, 2); return }
  if (c == "$") {
    if (c2 == "$'") { addw("", 1); push("AQ"); REST = substr(REST, 3); return }
    lex_dollar(); return
  }
  addw(c, 0); REST = substr(REST, 2)
}
function lex_sq(   i) {
  i = index(REST, "'")
  if (i == 0) { addw(REST, 1); REST = ""; return }
  addw(substr(REST, 1, i - 1), 1); REST = substr(REST, i + 1); D--
}
function lex_aq(   p, c) {
  p = nextsp("'")
  if (p == 0) { addw(REST, 1); REST = ""; return }
  addw(substr(REST, 1, p - 1), 1); c = substr(REST, p, 1)
  if (c == "\\") { addw(substr(REST, p, 2), 1); REST = substr(REST, p + 2); return }
  REST = substr(REST, p + 1); D--
}
function lex_dq(   p, c, x) {
  p = nextsp("[\"$`]")
  if (p == 0) { addw(REST, 1); REST = ""; return }
  if (p > 1) { addw(substr(REST, 1, p - 1), 1); REST = substr(REST, p); return }
  c = substr(REST, 1, 1)
  if (c == "\"") { REST = substr(REST, 2); D--; return }
  if (c == "\\") {
    if (length(REST) == 1) { cont = 1; REST = ""; return }
    x = substr(REST, 2, 1)
    if (x == "$" || x == "`" || x == "\"" || x == "\\") addw(x, 1); else addw("\\" x, 1)
    REST = substr(REST, 3); return
  }
  if (c == "`") { REST = substr(REST, 2); push("BT"); return }
  lex_dollar()
}
function lex_pe(   p, c) {
  p = nextsp("[}\"'$`]")
  if (p == 0) { addw(REST, 1); REST = ""; return }
  if (p > 1) { addw(substr(REST, 1, p - 1), 1); REST = substr(REST, p); return }
  c = substr(REST, 1, 1)
  if (c == "}") { REST = substr(REST, 2); pop(); return }
  if (c == "\\") {
    if (length(REST) == 1) { cont = 1; REST = ""; return }
    addw(substr(REST, 1, 2), 1); REST = substr(REST, 3); return
  }
  if (c == "\"") { REST = substr(REST, 2); push("DQ"); return }
  if (c == "'") {
    if (pedq[D]) { addw("'", 1); REST = substr(REST, 2); return }
    sqword(1); return
  }
  if (c == "`") { REST = substr(REST, 2); push("BT"); return }
  lex_dollar()
}
function lex_ar(   p, c) {
  p = nextsp("[()\"'$`]")
  if (p == 0) { REST = ""; return }
  if (p > 1) { REST = substr(REST, p); return }
  c = substr(REST, 1, 1)
  if (c == "(") { ardepth[D]++; REST = substr(REST, 2); return }
  if (c == ")") {
    if (ardepth[D] > 0) { ardepth[D]--; REST = substr(REST, 2); return }
    if (substr(REST, 2, 1) == ")") { REST = substr(REST, 3); pop(); return }
    # One closing parenthesis at depth zero: this was never arithmetic but a command
    # substitution or a subshell whose first command is itself a subshell. Read on as code.
    REST = substr(REST, 2)
    T[D] = (ardollar[D] ? "CS" : "SUB"); OWN[D] = D; inw[D] = 0; wb[D] = ""; wq[D] = 0
    cmdw[D] = 1; coll[D] = 0; ccw[D] = 0; casehdr[D] = 0; forkw[D] = 0; cstate[D] = ""; psub[D] = 0
    return
  }
  if (c == "\\") { REST = substr(REST, 3); return }
  if (c == "\"") { REST = substr(REST, 2); push("DQ"); return }
  if (c == "'") { sqword(1); return }
  if (c == "`") { REST = substr(REST, 2); push("BT"); return }
  lex_dollar()
}
function lex_cb(   p, c, a) {
  if (match(REST, /^[ \t]+/)) { REST = substr(REST, RLENGTH + 1); cbw[D] = 1; return }
  if (cbw[D] && substr(REST, 1, 2) == "]]") {
    a = substr(REST, 3, 1)
    if (a == "" || a == " " || a == "\t" || a == ";" || a == "&" || a == "|" || a == ")") {
      REST = substr(REST, 3); pop(); return
    }
  }
  cbw[D] = 0
  p = nextsp("[ \t\"'$`]")
  if (p == 0) { REST = ""; return }
  if (p > 1) { REST = substr(REST, p); return }
  c = substr(REST, 1, 1)
  if (c == "\\") { REST = substr(REST, 3); return }
  if (c == "\"") { REST = substr(REST, 2); push("DQ"); return }
  if (c == "'") { sqword(1); return }
  if (c == "`") { REST = substr(REST, 2); push("BT"); return }
  lex_dollar()
}
function lex_hd(   p, c) {
  p = nextsp("[$`]")
  if (p == 0) { REST = ""; return }
  if (p > 1) { REST = substr(REST, p); return }
  c = substr(REST, 1, 1)
  if (c == "\\") { REST = substr(REST, 3); return }
  if (c == "`") { REST = substr(REST, 2); push("BT"); return }
  lex_dollar()
}

# ── the reader ────────────────────────────────────────────────────────────────────
function isredir(w) { return (w ~ /^[0-9]*[<>]/ || substr(w, 1, 2) == "&>") }
function classify(d,   n, i, w, b, guard, k, na, cls) {
  n = ccw[d]; i = 1; guard = 0; b = ""
  while (i <= n && guard < 16) {
    guard++
    w = RW[d, i]
    if (!RQ[d, i]) {
      if (w ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/) { i++; continue }
      if (isredir(w)) { i += (w ~ /^[0-9]*[<>&|]+$/) ? 2 : 1; continue }
    }
    b = w; sub(/^.*\//, "", b)
    if (b in WRAP) { i = skipwrap(d, b, i + 1, n); continue }
    break
  }
  if (i > n) return
  na = 0
  for (k = i + 1; k <= n; k++) {
    w = RW[d, k]
    if (!RQ[d, k] && isredir(w)) { if (w ~ /^[0-9]*[<>&|]+$/) k++; continue }
    A[++na] = w
  }
  cls = ""
  if (b == "head") { if (!headneg(na)) cls = "head" }
  else if (b in GREPS) cls = grepcls(na)
  else if (b == "sed") { if (sedhasq(na)) cls = "sed-q" }
  else if (b in AWKS) { if (awkhasexit(na)) cls = "awk-exit" }
  if (cls != "") printf "FINDING F1 %s %d %s %s\n", UNIT, RL[d, i], cls, b
}
function skipwrap(d, b, i, n,   w) {
  while (i <= n) {
    w = RW[d, i]
    if (substr(w, 1, 1) != "-") break
    i++
    if (w == "--") break
    if (b == "nice" && (w == "-n" || w == "--adjustment")) i++
    else if (b == "timeout" && (w == "-s" || w == "--signal" || w == "-k" || w == "--kill-after")) i++
    else if (b == "stdbuf" && (w == "-i" || w == "-o" || w == "-e" || w == "--input" || w == "--output" || w == "--error")) i++
    else if (b == "env" && (w == "-u" || w == "--unset" || w == "-C" || w == "--chdir" || w == "-S" || w == "--split-string")) i++
    else if (b == "exec" && w == "-a") i++
  }
  if (b == "timeout") i++
  return i
}
function headneg(na,   k, w) {
  for (k = 1; k <= na; k++) {
    w = A[k]
    if (w ~ /^-[nc]-[0-9]/ || w ~ /^--(lines|bytes)=-[0-9]/) return 1
    if (k < na && (w == "-n" || w == "-c" || w == "--lines" || w == "--bytes") && A[k + 1] ~ /^-[0-9]/) return 1
  }
  return 0
}
function grepcls(na,   k, w, j, c, quiet, maxc) {
  quiet = 0; maxc = 0
  for (k = 1; k <= na; k++) {
    w = A[k]
    if (w == "--") break
    if (substr(w, 1, 2) == "--") {
      if (w == "--quiet" || w == "--silent") quiet = 1
      else if (w == "--max-count") { maxc = 1; k++ }
      else if (w ~ /^--max-count=/) maxc = 1
      else if (w == "--regexp" || w == "--file" || w == "--after-context" || w == "--before-context" || w == "--context") k++
      continue
    }
    if (substr(w, 1, 1) != "-" || w == "-") continue
    for (j = 2; j <= length(w); j++) {
      c = substr(w, j, 1)
      if (c == "q") quiet = 1
      else if (c == "m") { maxc = 1; if (j == length(w)) k++; break }
      else if (index("efABCdD", c) > 0) { if (j == length(w)) k++; break }
    }
  }
  if (quiet) return "grep-q"
  if (maxc) return "grep-m"
  return ""
}
# sedhasq — the script is each -e/--expression argument, or else the first operand.
function sedhasq(na,   k, w, j, c, ns) {
  ns = 0
  for (k = 1; k <= na; k++) {
    w = A[k]
    if (w == "--") { k++; break }
    if (w == "--expression") { ns++; if (k < na && sedq(A[k + 1])) return 1; k++; continue }
    if (w ~ /^--expression=/) { ns++; if (sedq(substr(w, 14))) return 1; continue }
    if (w == "--file") { ns++; k++; continue }
    if (substr(w, 1, 2) == "--") { if (w ~ /^--file=/) ns++; continue }
    if (substr(w, 1, 1) == "-" && length(w) > 1) {
      for (j = 2; j <= length(w); j++) {
        c = substr(w, j, 1)
        if (c == "e") {
          ns++
          if (j < length(w)) { if (sedq(substr(w, j + 1))) return 1 }
          else { if (k < na && sedq(A[k + 1])) return 1; k++ }
          break
        }
        if (c == "f" || c == "l") { if (c == "f") ns++; if (j == length(w)) k++; break }
        if (c == "i") break
      }
      continue
    }
    if (ns == 0) return sedq(w)
    return 0
  }
  if (ns == 0 && k <= na) return sedq(A[k])
  return 0
}
# sedq — a q or Q command in one sed script. Addresses, s/// and y/// operands, and the text,
# label and file-name arguments of the other commands are not commands.
function sedq(s,   i, n, c, d) {
  n = length(s); i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == " " || c == "\t" || c == "\n" || c == ";" || c == "{" || c == "}" || c == "!") { i++; continue }
    if (c ~ /[0-9$,~+]/) { i++; continue }
    if (c == "/") { i = sedskip(s, i + 1, "/"); while (substr(s, i, 1) == "I" || substr(s, i, 1) == "M") i++; continue }
    if (c == "\\") { d = substr(s, i + 1, 1); i = sedskip(s, i + 2, d); continue }
    if (c == "q" || c == "Q") return 1
    if (c == "s" || c == "y") {
      d = substr(s, i + 1, 1); i = sedskip(s, i + 2, d); i = sedskip(s, i, d)
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == ";" || c == "\n" || c == "}") break
        if (c == "w") { i = sedtext(s, i); break }
        i++
      }
      continue
    }
    if (c == "a" || c == "i" || c == "c") { i = sedtext(s, i); continue }
    if (c == "r" || c == "R" || c == "w" || c == "W" || c == "#") { i = sedeol(s, i); continue }
    if (c == "b" || c == "t" || c == "T" || c == ":") {
      i++
      while (i <= n) { c = substr(s, i, 1); if (c == ";" || c == "\n" || c == "}") break; i++ }
      continue
    }
    i++
  }
  return 0
}
# sedskip — the index just past the next unescaped delimiter d; a bracket expression may hold d.
function sedskip(s, i, d,   n, c, j) {
  n = length(s)
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == d) return i + 1
    if (c == "[") {
      j = i + 1
      if (substr(s, j, 1) == "^") j++
      if (substr(s, j, 1) == "]") j++
      while (j <= n && substr(s, j, 1) != "]") j++
      i = j + 1; continue
    }
    i++
  }
  return n + 1
}
function sedeol(s, i,   j) { j = index(substr(s, i), "\n"); return (j == 0) ? length(s) + 1 : i + j }
# sedtext — a/i/c text runs to the end of a line that does not end in a backslash.
function sedtext(s, i,   j) {
  while (1) {
    j = index(substr(s, i), "\n")
    if (j == 0) return length(s) + 1
    if (substr(s, i + j - 2, 1) != "\\") return i + j
    i = i + j
  }
}
function awkhasexit(na,   k, w) {
  for (k = 1; k <= na; k++) {
    w = A[k]
    if (w == "--") { k++; break }
    if (w == "-f" || w == "--file" || w ~ /^-f./ || w ~ /^--file=/) return 0
    if (w == "-F" || w == "-v" || w == "--field-separator" || w == "--assign" || w == "-W") { k++; continue }
    if (substr(w, 1, 1) == "-" && length(w) > 1) continue
    return awkexit(w)
  }
  if (k <= na) return awkexit(A[k])
  return 0
}
# awkexit — exit or nextfile in an awk program, once string literals, regular-expression
# literals, comments and every END block are removed. A slash opens a regular expression where
# an operand is expected, and is a division elsewhere.
function awkexit(p,   rest, out, prev, chunk, t, c, j, depth, res) {
  rest = p; out = " "; prev = ""
  while (rest != "") {
    if (!match(rest, /[#"\/]/)) { out = out rest; break }
    chunk = substr(rest, 1, RSTART - 1); c = substr(rest, RSTART, 1); rest = substr(rest, RSTART + 1)
    out = out chunk
    t = chunk; sub(/[ \t]+$/, "", t)
    if (t != "") prev = substr(t, length(t), 1)
    if (c == "#") { j = index(rest, "\n"); rest = (j == 0) ? "" : substr(rest, j); continue }
    if (c == "\"") { rest = awkskip(rest, "\""); out = out " S "; prev = "S"; continue }
    if (prev == "" || index("(,{};!~&|?:=+-*%<>[\n", prev) > 0) { rest = awkskip(rest, "/"); out = out " R "; prev = "R"; continue }
    out = out "/"; prev = "/"
  }
  res = ""
  while (match(out, /[^A-Za-z0-9_]END[ \t\n]*[{]/)) {
    res = res substr(out, 1, RSTART)
    out = substr(out, RSTART + RLENGTH)
    depth = 1
    while (depth > 0 && match(out, /[{}]/)) {
      if (substr(out, RSTART, 1) == "{") depth++; else depth--
      out = substr(out, RSTART + 1)
    }
    if (depth > 0) out = ""
  }
  res = res out " "
  return (res ~ /[^A-Za-z0-9_](exit|nextfile)[^A-Za-z0-9_]/)
}
# awkskip — the text after the next unescaped d; a bracket expression inside a regular
# expression may hold d.
function awkskip(r, d,   n, i, c, j) {
  n = length(r); i = 1
  while (i <= n) {
    c = substr(r, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == d) return substr(r, i + 1)
    if (d == "/" && c == "[") {
      j = i + 1
      if (substr(r, j, 1) == "^") j++
      if (substr(r, j, 1) == "]") j++
      while (j <= n && substr(r, j, 1) != "]") j++
      i = j + 1; continue
    }
    i++
  }
  return ""
}
AWK

# ── g.awk — class G, the release check's census against the declaration ─────────────
cat > "$WORK/g.awk" <<'AWK'
# ARGV[1] the declaration TSV "<tag>\t<limb>:<reason>", already extracted by fence.awk — the
# SAME reader classes C and D drive. ARGV[2] the census scripts/check-release-tag.sh printed.
# -v RC=<that census's exit status> -v DECFILE=<path of ARGV[1]>
# -v SHALLOW=<what `git rev-parse --is-shallow-repository` printed in that repository>
#
# The two inputs are split BY FILENAME, for the reason d.awk records: an empty declaration is a
# case this group must report, and `FNR == NR` would read the whole census as declaration rows.
#
# Grades nothing about a tag. The verdict on each tag is the release check's own TAG line; this
# program compares the failing ones with the declaration, in both directions, and always emits a
# DENOM line carrying the tags the check read, the tags failing a limb and the rows declared.
FILENAME == DECFILE {
  split($0, d, "\t")
  if (d[1] != "" && d[2] != "") { DECL[d[1] " " d[2]] = 1; DTAG[d[1]] = 1; ndecl++ }
  next
}
$1 == "TAG" { nline++; SEEN[$2] = 1; if ($4 == "FAIL") { OBS[$2 " " $3 ":" $5] = 1; if (!($2 in FAILED)) { FAILED[$2] = 1; nfail++ } } }
$1 == "READ" { nread = $2 + 0; sawread = 1 }
$1 == "NOT-EVALUATED:" { notev = 1 }
END {
  # G0 first, and alone: a census that did not run, a declaration that is empty while tags fail,
  # or a census that is only a sample of the tags, makes every comparison below it a statement
  # about nothing, so only the cause is named.
  #
  # THE SHALLOW LIMB NEEDS BOTH CONDITIONS. SEEN holds every tag the census printed a line for,
  # passing or failing, and nabsent counts the DECLARED tags that are not among them. In a
  # shallow repository a declared tag that is absent was never fetched, so the census is a
  # sample and the tag is not stale: reporting it as G2 would send the reader to remove a row
  # the full history still needs. Shallowness alone is not the finding, because a shallow clone
  # can carry every tag; and where the repository is NOT shallow an absent declared tag is G2,
  # as it always was — there the tag really is gone.
  nabsent = 0
  for (t in DTAG) if (!(t in SEEN)) nabsent++
  why = ""
  if (RC != 0 && RC != 1)                 why = "the release check exited " RC (notev ? " NOT-EVALUATED" : "")
  else if (!sawread || nread == 0 || nline == 0) why = "the release check printed no verdict for any tag"
  else if ((RC == 1) != (nfail > 0))      why = "the release check exited " RC " against " nfail " failing tag(s)"
  else if (ndecl == 0 && nfail > 0)       why = "the declaration fence yielded zero rows while " nfail " tag(s) fail"
  else if (SHALLOW == "true" && nabsent > 0) why = "this repository is shallow and " nabsent " declared tag(s) are absent from the census: fetch the tags, or re-clone without --depth"
  if (why != "") printf "FINDING G0 %s\n", why
  else {
    for (k in OBS)  if (!(k in DECL)) printf "FINDING G1 %s\n", k
    for (k in DECL) if (!(k in OBS))  printf "FINDING G2 %s\n", k
  }
  printf "DENOM %d %d %d\n", nread + 0, nfail + 0, ndecl + 0
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
# The tag defaults to class C's, so every existing caller is unchanged; classes D and G pass
# their own. ONE fence reader serves every declaring fence — a second parser for the same on-disk
# shape would be a second place for that shape to drift.
ch_fence()  { awk -v TAG="${2:-$CH_FENCE_TAG}" -f "$WORK/fence.awk" "$1"; }

# ch_scan_d <root> <listfile> — the class-D scan, shaped like ch_scan_a: the declaration is
# extracted first, then handed to the walker as a file, so the control arms drive exactly the
# code the real tree does.
ch_scan_d() {
  if [ -r "$1/$CH_ADR_INDEX" ]; then ch_fence "$1/$CH_ADR_INDEX" "$CH_ADR_TAG" > "$WORK/adrdec.tsv"
  else : > "$WORK/adrdec.tsv"; fi
  awk -v ROOT="$1" -v ADRDIR="$CH_ADR_DIR" -v INDEX="$CH_ADR_INDEX" \
    -v DECFILE="$WORK/adrdec.tsv" -f "$WORK/d.awk" "$WORK/adrdec.tsv" "$2"
}

# Class F's listers name EVERY file, not only markdown: f.awk decides what is shell from the
# name and the first line, so a shell script without the suffix is not left out by the caller.
ch_list_f_real() { ( cd "$1" && git ls-files ); }
ch_list_f_dir()  { ( cd "$1" && find . -type f | sed 's|^\./||' | sort ); }
# ch_scan_f <root> <listfile> — class F over one tree, shaped like ch_scan_b: the real tree and
# every control arm drive this one function, so an arm grades the code the tree is graded by.
ch_scan_f() { awk -v ROOT="$1" -f "$WORK/f.awk" "$2"; }

# g_run <repo> <arg> — the release check, run in <repo> exactly as the release procedure runs
# it. A FIXTURE repository is read with every configuration outside it switched off, so nothing
# on the machine running the suite can change what a fixture says.
g_run() {
  local repo="$1"; shift
  ( cd "$repo" || exit 2
    case "$repo" in "$WORK"/*) export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ;; esac
    "$ROOT/$CH_G_SCRIPT" "$@" )
}
# g_shallow <repo> — what `git rev-parse --is-shallow-repository` prints in <repo>: `true` in a
# depth-limited clone and `false` otherwise. Asked in the repository being scanned and under the
# same isolation as the census, so a fixture answers for itself. Where git cannot answer — the
# directory is no repository — it prints nothing, and g.awk's shallow limb stays silent: the
# census has already said NOT-EVALUATED there, which is G0 by its exit status.
g_shallow() {
  ( cd "$1" 2>/dev/null || exit 0
    case "$1" in "$WORK"/*) export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ;; esac
    git rev-parse --is-shallow-repository 2>/dev/null )
}
# ch_scan_g <root> — class G over one repository: the census by the release check itself, the
# declaration from that repository's own CONTRIBUTING.md, whether that repository is shallow,
# and the comparison. The real tree and every fixture arm go through this one function.
ch_scan_g() {
  local rc=0
  ( cd "$1" || exit 2
    case "$1" in "$WORK"/*) export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ;; esac
    "$ROOT/$CH_G_SCRIPT" --all ) > "$WORK/g.scan" 2>&1 || rc=$?
  if [ -r "$1/$CH_G_DOC" ]; then ch_fence "$1/$CH_G_DOC" "$CH_G_TAG" > "$WORK/g.decl"
  else : > "$WORK/g.decl"; fi
  awk -v RC="$rc" -v SHALLOW="$(g_shallow "$1")" -v DECFILE="$WORK/g.decl" -f "$WORK/g.awk" "$WORK/g.decl" "$WORK/g.scan"
}

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
B_NWIDE="$(awk '$1 == "DENOM" { print $4 }' <<<"$B_OUT")"
B_NOOS=$(( ${B_NWIDE:-0} - ${B_NHIT:-0} ))
printf '  SURFACE: %s tracked markdown file(s) walked for path:line locators — %s in this group'"'"'s IN-SCOPE bare spelling, %s in either spelling, so %s sit OUTSIDE this predicate and are reported rather than counted as clean.\n' \
  "$B_NFILE" "$B_NHIT" "$B_NWIDE" "$B_NOOS"
echo "B1" >> "$SURF_LOG"

if [ "${B_NHIT:-0}" -eq 0 ]; then
  VACUOUS "B1: the IN-SCOPE population is EMPTY — $B_NFILE file(s) walked, no BARE path:line locator found. This group proves nothing about this tree by itself and says so rather than reporting a bare PASS; what it rests on is arm CTL-B1, which plants two locators in a fixture and requires both to be found. READ THIS AS THE PREDICATE'S VERDICT AND NOT THE CORPUS'S: $B_NWIDE locator(s) are present in either spelling and $B_NOOS of them are out of scope here by declaration — a code-spanned path or emphasised digits put a markdown delimiter between the extension and the colon, which B1's pattern does not cross. The banner's class-B entry carries the boundary and why widening it is not this gate's call; arm CTL-B1-WIDE is what makes the out-of-scope figure a measurement"
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
echo "D — ADR record numbering: used once, no undeclared gap, index agrees with the directory"
# ═════════════════════════════════════════════════════════════════════════════════
D_OUT="$(ch_scan_d "$ROOT" "$WORK/list.real")"
D_NREC="$(awk '$1 == "DENOM" { print $2 }' <<<"$D_OUT")"
D_NROW="$(awk '$1 == "DENOM" { print $3 }' <<<"$D_OUT")"
D_NDECL="$(awk '$1 == "DENOM" { print $4 }' <<<"$D_OUT")"
D_NHELD="$(awk '$1 == "DENOM" { print $5 }' <<<"$D_OUT")"
D_MAXN="$(awk '$1 == "DENOM" { print $6 }' <<<"$D_OUT")"
D_NDUP="$(n_code "$D_OUT" D1)"
D_NGAP="$(n_code "$D_OUT" D2)"
D_NMIS="$(n_code "$D_OUT" D3)"
D_NROT="$(n_code "$D_OUT" D4)"
printf '  SURFACE: %s record file(s) under %s/ and %s index row(s) in %s, over a span reaching %s; %s declared number(s), %s of them holding a gap open.\n' \
  "$D_NREC" "$CH_ADR_DIR" "$D_NROW" "$CH_ADR_INDEX" "$D_MAXN" "$D_NDECL" "$D_NHELD"
for c in D0 D1 D2 D3 D4; do echo "$c" >> "$SURF_LOG"; done

# The vacuity guard is written so an unrun extractor resolves to the LOUD answer: an unset
# denominator reads 0 and lands on the FAIL limb, where a code-presence test would have read
# an absent finding as a clean tree.
if [ "${D_NREC:-0}" -gt 0 ] && [ "${D_NROW:-0}" -gt 0 ]; then
  PASS "D0: the class-D surface is non-empty — $D_NREC record file(s) read from $CH_ADR_DIR/ and $D_NROW index row(s) from $CH_ADR_INDEX, so every verdict below is a measurement rather than a walk over nothing"
else
  FAIL "D0: the class-D surface came back EMPTY (records=$D_NREC rows=$D_NROW) — a zero here is a broken probe or a relocated corpus, never clean numbering, and D1/D2/D3 below would be verdicts over the empty set"
fi

if [ "${D_NDUP:-0}" -eq 0 ]; then
  PASS "D1: no ADR number is carried by two record files or by two index rows — $D_NREC record(s) and $D_NROW row(s) resolve to distinct numbers on each surface separately. The zero is a measurement: arms CTL-D1, CTL-D1-FILE and CTL-D1-ROW plant a collision on both surfaces and on each alone, and require every one to be found"
else
  FAIL "D1: $D_NDUP ADR number collision(s). A number is spent when it is published — the convention in $CH_ADR_INDEX forbids reuse and renumbering, so a collision that reaches the default branch cannot be repaired by renaming and has to be resolved before the merge:"
  grep '^FINDING D1 ' <<<"$D_OUT" | awk '{ printf "      %s surface, ADR-%s: %s and %s\n", $3, $4, $5, $6 }'
fi

if [ "${D_NGAP:-0}" -eq 0 ]; then
  PASS "D2: every number up to $D_MAXN is either carried by a record or DECLARED a deliberate gap — $D_NHELD held open by a row in the \`$CH_ADR_TAG\` fence in $CH_ADR_INDEX. A declared gap PASSING is the whole point of declaring it, and it is also what makes this zero a measurement in the other direction: a fence this scan failed to read would leave that gap undeclared and turn this verdict red rather than quietly green. Arm CTL-D2 plants an undeclared gap and requires it to fail; arm CTL-D2-DECL declares the same gap and requires silence"
else
  FAIL "D2: $D_NGAP number(s) up to $D_MAXN are carried by no record and declared by no row. Either the record is missing, or the gap is deliberate and belongs in the \`$CH_ADR_TAG\` fence in $CH_ADR_INDEX — a row there needs BOTH columns, the number and a reason token, and a row carrying only a number declares nothing:"
  grep '^FINDING D2 ' <<<"$D_OUT" | awk '{ printf "      ADR-%s\n", $3 }'
fi

if [ "${D_NMIS:-0}" -eq 0 ]; then
  PASS "D3: the index and the directory agree in BOTH directions — each of $D_NREC record file(s) is named by a row, and each of $D_NROW row(s) names a record file that exists. This is the comparison nothing in this repository made before; arms CTL-D3-FILE and CTL-D3-ROW plant a mismatch in each direction, because a one-way walk is blind to whichever side it starts from"
else
  FAIL "D3: $D_NMIS disagreement(s) between $CH_ADR_INDEX and $CH_ADR_DIR/. A record with no row is invisible to every reader of the index; a row with no record is a link that does not resolve:"
  grep '^FINDING D3 ' <<<"$D_OUT" | awk '{ printf "      %s: %s\n", $3, $4 }'
fi

if [ "${D_NROT:-0}" -eq 0 ]; then
  PASS "D4: every row in the \`$CH_ADR_TAG\` fence still excepts a real gap — $D_NDECL declared number(s), none occupied by a record, none outside the span, none unreadable as a number. A declaration that outlives its gap is a standing exemption for whatever next takes that number, which is why this direction is asserted at all; arms CTL-D4, CTL-D4-SPAN and CTL-D4-BAD plant one of each"
else
  FAIL "D4: $D_NROT row(s) in the \`$CH_ADR_TAG\` fence in $CH_ADR_INDEX no longer except a gap. Remove the row in the same change that filled or corrected it — do not leave it standing:"
  grep '^FINDING D4 ' <<<"$D_OUT" | awk '{ printf "      %s (%s): %s\n", $3, $4, $5 }'
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "F — short-circuit readers: no shell file or workflow run: value pipes into a reader that can stop before end of input"
# ═════════════════════════════════════════════════════════════════════════════════
ch_list_f_real "$ROOT" > "$WORK/list.f"
F_OUT="$(ch_scan_f "$ROOT" "$WORK/list.f")"
F_NSH="$(awk '$1 == "DENOM" { print $2 }' <<<"$F_OUT")"
F_NWF="$(awk '$1 == "DENOM" { print $3 }' <<<"$F_OUT")"
F_NRUN="$(awk '$1 == "DENOM" { print $4 }' <<<"$F_OUT")"
F_NPIPE="$(awk '$1 == "DENOM" { print $5 }' <<<"$F_OUT")"
F_N0="$(n_code "$F_OUT" F0)"
F_NHIT="$(n_code "$F_OUT" F1)"
F_N2="$(n_code "$F_OUT" F2)"
# THE MEASUREMENT STATE, decided ONCE and read by every line this group prints, on group G's rule.
# The scan is a measurement only when each of its four denominators is non-zero AND the extractor
# reported no F0. An unrun extractor resolves to the LOUD answer — an unset denominator reads 0 and
# lands on the unmeasured side — and there nothing below prints a counter: a count of short-circuit
# readers over a scan that did not finish is a lower bound, and a lower bound printed as a count
# reads as a measured zero. F_WHY is the one cause, as G_WHY is group G's.
F_WHY="$(awk '$1 == "FINDING" && $2 == "F0" && n++ == 0 { print $3 ":" $4 " " $5 }' <<<"$F_OUT")"
[ -n "$F_WHY" ] || F_WHY="a denominator is zero: shell files ${F_NSH:-unread}, workflow files ${F_NWF:-unread}, run values ${F_NRUN:-unread}, pipes ${F_NPIPE:-unread}"
if [ "${F_NSH:-0}" -gt 0 ] && [ "${F_NWF:-0}" -gt 0 ] && [ "${F_NRUN:-0}" -gt 0 ] && [ "${F_NPIPE:-0}" -gt 0 ] && [ "${F_N0:-1}" -eq 0 ]; then F_MEASURED=1; else F_MEASURED=0; fi
if [ "$F_MEASURED" -eq 1 ]; then
  printf '  SURFACE: %s tracked shell file(s) and %s run value(s) in %s workflow file(s) lexed, %s pipe(s) read. The scan set, derived from the tracked tree on this run:\n' \
    "$F_NSH" "$F_NRUN" "$F_NWF" "$F_NPIPE"
else
  printf '  SURFACE: NOT-EVALUATED — %s — this is not a clean result. What was read:\n' "$F_WHY"
fi
awk '$1 == "SCAN" { $1 = ""; printf "    %s\n", substr($0, 2) }' <<<"$F_OUT"
for c in F0 F1 F2; do echo "$c" >> "$SURF_LOG"; done

if [ "$F_MEASURED" -eq 1 ]; then
  PASS "F0: the class-F surface is non-empty and every unit was lexed to its end — $F_NSH shell file(s) and $F_NRUN run value(s), $F_NPIPE pipe(s) read — so every verdict below is a measurement. Arms CTL-F0, CTL-F0-QUOTE and CTL-F0-HEREDOC require an empty surface, and a unit ending inside a construct, to fail here"
else
  FAIL "F0: class F is NOT a measurement on this run — a zero here is a broken probe, a relocated corpus or a unit the lexer could not finish, never a clean tree, and F1 and F2 are withheld:"
  grep '^FINDING F0 ' <<<"$F_OUT" | awk '{ printf "      %s:%s  %s\n", $3, $4, $5 }'
fi

if [ "$F_MEASURED" -ne 1 ]; then
  FAIL "F1/F2: withheld — F0 above names the cause, and a count of short-circuit readers over a scan that did not finish is a lower bound, never a measurement"
else
  if [ "${F_NHIT:-0}" -eq 0 ]; then
    PASS "F1: none of the $F_NPIPE pipe(s) feeds a reader that can stop before end of input. The zero is a measurement: the CTL-F arms below plant one per reader class, carrier and pipe shape and require each at its line, and arm CTL-F-RETRO requires the defect this repository shipped"
  else
    FAIL "F1: $F_NHIT pipe(s) feed a reader that can stop before end of input. The writer's broken-pipe failure becomes the pipeline's status under pipefail, so a successful match can read as a failure — 1, not 141, on a runner that ignores SIGPIPE. Replace the reader: a here-string where one variable feeds it, a draining awk 'NR <= N' everywhere else:"
    grep '^FINDING F1 ' <<<"$F_OUT" | awk '{ printf "      %s:%s  %s  %s\n", $3, $4, $5, $6 }'
  fi
  if [ "${F_N2:-0}" -eq 0 ]; then
    PASS "F2: all $F_NRUN run value(s) were placed by the line reader and lexed, none refused. The CTL-F2 arms plant every form it refuses and require the refusal, so a form it cannot read fails here instead of going unread"
  else
    FAIL "F2: $F_N2 run value(s) in a form this suite's line reader cannot place. Write each as a one-line value or a literal block (|), or the shell inside it goes ungraded:"
    grep '^FINDING F2 ' <<<"$F_OUT" | awk '{ printf "      %s:%s  %s\n", $3, $4, $5 }'
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "G — release tags carry their own CHANGELOG entry, graded by the check the release runs"
# ═════════════════════════════════════════════════════════════════════════════════
# Every ref and the working tree, read BEFORE the release check first runs on this repository.
# Arm CTL-G-READONLY compares against this after every run of it here, so a write made by ANY
# run is seen — a snapshot taken around one later run would miss a write an earlier run already
# made, because the same write repeated changes nothing.
G_REF0="$(git -C "$ROOT" for-each-ref --format='%(refname) %(objectname)')"
G_ST0="$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)"
G_OUT="$(ch_scan_g "$ROOT")"
G_NREAD="$(awk '$1 == "DENOM" { print $2 }' <<<"$G_OUT")"
G_NFAIL="$(awk '$1 == "DENOM" { print $3 }' <<<"$G_OUT")"
G_NDECL="$(awk '$1 == "DENOM" { print $4 }' <<<"$G_OUT")"
G_N0="$(n_code "$G_OUT" G0)"
G_N1="$(n_code "$G_OUT" G1)"
G_N2="$(n_code "$G_OUT" G2)"
# THE MEASUREMENT STATE, decided ONCE and read by every line this group prints. The census is a
# measurement only when the release check read at least one tag AND the comparator reported no
# G0. The guard resolves an unrun census to the LOUD answer, as D0's does: an unset denominator
# reads 0 and lands on the unmeasured side. On that side nothing below prints a count — G_WHY is
# the one cause g.awk named, the SURFACE line and the RELEASE-TAGS summary line say NOT-EVALUATED
# with that cause, and G1 and G2 are withheld. A counter printed beside a withheld comparison
# reads as a measured zero, which is the one thing an unmeasured census must never be taken for.
G_WHY="$(awk '$1 == "FINDING" && $2 == "G0" { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' <<<"$G_OUT")"
if [ "${G_NREAD:-0}" -gt 0 ] && [ "${G_N0:-1}" -eq 0 ]; then G_MEASURED=1; else G_MEASURED=0; fi
[ -n "$G_WHY" ] || G_WHY='the comparator printed no result'
if [ "$G_MEASURED" -eq 1 ]; then
  printf '  SURFACE: %s release tag(s) read by %s, %s of them failing a limb, against %s row(s) declared in the `%s` fence in %s.\n' \
    "$G_NREAD" "$CH_G_SCRIPT" "$G_NFAIL" "$G_NDECL" "$CH_G_TAG" "$CH_G_DOC"
else
  printf '  SURFACE: NOT-EVALUATED — %s — this is not a clean result\n' "$G_WHY"
fi
for c in G0 G1 G2; do echo "$c" >> "$SURF_LOG"; done

if [ "$G_MEASURED" -eq 1 ]; then
  PASS "G0: the release check read $G_NREAD tag(s) and printed a verdict for each, so every comparison below is a measurement — a census over no tag is what a checkout below fetch-depth: 0 produces, and arm CTL-G0 requires that state to fail"
else
  FAIL "G0: group G is NOT a measurement on this run — a zero here is a shallow checkout, an unreadable tag or an empty declaration, never a clean release history, and G1 and G2 are withheld. CI must check out with fetch-depth: 0, which is what fetches the tags:"
  grep '^FINDING G0 ' <<<"$G_OUT" | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); printf "      %s\n", $0 }'
fi

if [ "$G_MEASURED" -ne 1 ]; then
  FAIL "G1/G2: withheld — G0 above names the cause, and a comparison over a census that did not run would report every declared tag as stale"
else
  if [ "${G_N1:-0}" -eq 0 ]; then
    PASS "G1: every tag that fails the release check is declared — $G_NFAIL failing tag(s), each named in the \`$CH_G_TAG\` fence with the reason the check gives. The zero is a measurement: arm CTL-G1 ships a tag without its entry and requires it to be found"
  else
    FAIL "G1: $G_N1 tag(s) fail the release check and are not declared. If \`git ls-remote --tags origin <tag>\` prints nothing, the tag exists only in this clone — delete it locally and do not declare it. A declaration row is the remedy for a pushed tag only: a pushed tag is not rewritten, so the remedy is a row in the \`$CH_G_TAG\` fence in $CH_G_DOC, beside a sentence saying how the tag came to lack its entry — and the release procedure's step 6 is the check that should have refused it:"
    grep '^FINDING G1 ' <<<"$G_OUT" | awk '{ printf "      %s  %s\n", $3, $4 }'
  fi
  if [ "${G_N2:-0}" -eq 0 ]; then
    PASS "G2: every declared row still names a failing tag with the reason the check gives — $G_NDECL row(s), none stale. Arms CTL-G2, CTL-G2-ABSENT and CTL-G2-REASON plant a row that passes, one naming no tag and one naming the wrong reason"
  else
    FAIL "G2: $G_N2 declared row(s) no longer match a failing tag — the tag passes now, no longer exists, or fails for a different reason. Tags are not protected on this host; find what moved the tag, and correct or remove the row in the same change:"
    grep '^FINDING G2 ' <<<"$G_OUT" | awk '{ printf "      %s  %s\n", $3, $4 }'
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "CTL — the control arms: a fixture tree built on every run, plus the real regressions whose ids end -RETRO"
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

# CTL-B1-WIDE — the arm that measures the DECLARED SCOPE BOUNDARY itself, in both directions
# at once. The fixture carries only code-spanned locators, which is the form this corpus
# actually writes. B1 must not see them (that is the declared narrowness) and the DENOM's wide
# field must (that is what makes the out-of-scope figure a measurement). One comparison asserts
# both: a wide count that merely echoed `hits`, or a second copy of B1's own pattern, cannot be
# greater than it on this input. It registers NO arm code — it emits no finding and asserts no
# code — so the group-Y inventory is unchanged by it.
D="$(ctl_mk b1wide)"
printf 'Declared at `scripts/publish-trip-site.sh`:2232, contract `reference/x.md`:**1924**.\n' > "$D/docs/notes.md"
ctl_fence "$D" '1  docs/notes.md'
O="$(ch_scan_b "$D" "$(ctl_list "$D")")"
BW_NARROW="$(n_code "$O" B1)"
BW_WIDE="$(awk '$1 == "DENOM" { print $4 }' <<<"$O")"
if [ "${BW_WIDE:-0}" -gt "${BW_NARROW:-0}" ]; then
  PASS "CTL-B1-WIDE: the scope boundary is a measurement in both directions — two code-spanned locators are planted, B1's in-scope pattern reports $BW_NARROW of them and the out-of-scope measurement reports $BW_WIDE. The strict inequality is the assertion: it convicts B1's declared blindness to the delimiter AND proves the wider loop is not an echo of the narrower one"
else
  FAIL "CTL-B1-WIDE: the out-of-scope measurement reported $BW_WIDE against B1's $BW_NARROW on a fixture carrying ONLY code-spanned locators. Without a strict inequality here the figure reported beside B1's verdict cannot be told from a copy of B1's own pattern, and the scope note it supports would be unfounded"
fi

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
# The break falls BEFORE the cardinal, between `all` and `twelve`, so `twelve places` lands
# intact on the second line. That is the shape the defect took, which is why the fixture is
# kept verbatim — but it does NOT discriminate on the unit: a line-anchored reader grades
# the second line on its own, finds the pair adjacent there, and fires too. The arm that
# discriminates is CTL-C-WRAP-PAIR below; this one holds the historical shape.
D="$(ctl_mk cwrap)"
mkdir -p "$D/docs"
{ printf '# Fixture\n\n'
  printf '  All three now carry the prefix, so this document names that file one way in all\n'
  printf '  twelve places. No decision is changed.\n'
} > "$D/docs/notes.md"
ctl_fence "$D" '0  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-WRAP" C1 "$O" "the sentence is WRAPPED, with the break before the cardinal exactly as the motivating defect shipped it — the historical shape, graded whole; the pair lands together on the second line, so the unit-discrimination is CTL-C-WRAP-PAIR's assertion and not this one's" 1

# CTL-C-WRAP-PAIR — the same defect with the break moved BETWEEN the cardinal and its noun,
# which is the position that makes the unit observable. `twelve` ends one line and `places`
# begins the next, so a line-anchored reader grades a cardinal governing nothing and a noun
# governed by nothing, and returns clean. The shipped reader joins the continuation before
# grading and fires. Nothing else about the two implementations differs, so this arm's
# verdict is a measurement OF THE UNIT rather than of the exemption ladder around it.
D="$(ctl_mk cwrappair)"
mkdir -p "$D/docs"
{ printf '# Fixture\n\n'
  printf '  This document now names that same file one way in all twelve\n'
  printf '  places. No decision is changed.\n'
} > "$D/docs/notes.md"
ctl_fence "$D" '0  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-WRAP-PAIR" C1 "$O" "the cardinal and its noun sit on OPPOSITE SIDES of a line break — a line-anchored reading of this identical rule reports this fixture clean, so this is the arm that tells the sentence unit from the line" 1

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

# ── the VALUE-TOKEN arms: year, price and version ────────────────────────────────
# Before these, the year/price/version exemption was the ONE class of the ladder's eight with
# no control arm at all — F1, F2, F3, determiners, threshold, locator and past-tense each
# carry a CTL-C-SPEC-* arm and this one carried none, which is how it stayed sentence-scoped
# against its own justification without any arm going red.
#
# GROUP MD OPT-OUT, declared per clause 6 rather than left silent. The subject of all six arms
# below is an awk function inside the GENERATED c.awk, not a shell function, so `unset -f` is
# inapplicable and md_flips has nothing to remove; registering them would grade the oracle
# rather than the assertion. The compensating positive control is the executed mutation matrix
# recorded in the card — each arm below was observed red under a named mutation of its own
# subject at its real call site, including an ADDITION-only mutation that leaves every existing
# rule in place. An unregistered arm with no stated opt-out is what clause 6 forbids; this is
# the statement.

# CTL-C-SPEC-YEAR-ANCHOR — the F1 DATE half.
D="$(ctl_mk cyanch)"
ctl_c_doc "$D" docs/notes.md 'Measured in 2026-09, the guard walks 12 files.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-YEAR-ANCHOR" C3 "$O" "the sentence names the DATE the count was probed at — the F1 date half. The fixture is MONTH-granular ON PURPOSE and simplifying it to a full date silently re-opens the hole: a YYYY-MM-DD date survives the normalisation as an eight-character all-hex token exempt_f1's sha arm cannot tell from a commit, so a day-granular fixture would pass with exempt_f1date deleted. Stripped, YYYY-MM is six characters and falls below that arm's seven-character floor, so only exempt_f1date can carry this silence"

# CTL-C-SPEC-YEAR-TOKEN — the discriminating arm for is_year itself.
D="$(ctl_mk cytok)"
ctl_c_doc "$D" docs/notes.md 'The 2026 workflows run on every push.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-YEAR-TOKEN" C3 "$O" "a year sits immediately before a corpus noun — it is a value that happens to be a numeral, never a cardinal governing that noun, and this is the arm that says so"

# CTL-C-YEAR-UNRELATED — the COMPLEMENT arm for the year narrowing, and the one an
# addition-blind rule-presence check could not supply: re-adding a sentence-scoped year clause
# leaves every existing rule present and still turns this arm red.
D="$(ctl_mk cyunrel)"
ctl_c_doc "$D" docs/notes.md \
  'The 2026 season is busy and the guard walks 12 files.' \
  'Each of the ten files in `examples/tokyo-2026/` is pinned by hash.' \
  'The tree holds 198,329 bytes across the 2 bearer files.'
ctl_fence "$D" '0  docs/notes.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-YEAR-UNRELATED" C1 "$O" "three basis-free counts each sit beside a year that anchors nothing — one in ordinary prose, one inside a PATH, and one inside a larger numeral (198,329 collapses to 198329, which carries 1983) — and a sentence-scoped year exemption admits all three" 1

# CTL-C-SPEC-PRICE-TOKEN — price carries the IDENTICAL token-scoping as the year, so it carries
# its own arm. The fixture uses a price with a MINOR part, because that is the only part of a
# price that is a bare numeral: `$12.50` normalises to `money12 50`, and the `money12` head was
# never a subject, so a whole-currency fixture would pass with the scoping deleted.
D="$(ctl_mk cprtok)"
ctl_c_doc "$D" docs/notes.md 'Each row carries a $12.50 line.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-PRICE-TOKEN" C3 "$O" "a price's minor part sits immediately before a corpus noun — a price is a value that happens to be a numeral, exactly as a year is, and the cents are not a count of lines"

# CTL-C-SPEC-VERSION-TOKEN — version's own arm, on the same reasoning and the same shape:
# `v1.2` normalises to `v1 2`, and only the `2` is a bare numeral a subject test can reach.
D="$(ctl_mk cvrtok)"
ctl_c_doc "$D" docs/notes.md 'The v1.2 schema files are pinned by hash.'
ctl_fence "$D" '1  docs/other.md'
ctl_c_doc "$D" docs/other.md 'The guard walks 12 files.'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustnot "CTL-C-SPEC-VERSION-TOKEN" C3 "$O" "a version's minor part sits immediately before a corpus noun — the 2 of v1.2 is part of a version string and never a count of schema files"

# CTL-C-PRICE-VERSION-UNRELATED — the COMPLEMENT arm for both, arity-asserted at 2 so it
# discriminates the two classes separately: if either token-scoping regresses to sentence
# scope, that class's file goes silent, the arity drops to 1, and this arm goes red.
D="$(ctl_mk cpvunrel)"
ctl_c_doc "$D" docs/price.md 'The suite costs $40 to run and the guard walks 12 files.'
ctl_c_doc "$D" docs/version.md 'The v2.1 release ships 12 files.'
ctl_fence "$D" '0  docs/price.md' '0  docs/version.md'
O="$(ch_compare_c "$D" "$D/$CH_FENCE_DOC" "$(ctl_list "$D")")"
ctl_mustfire "CTL-C-PRICE-VERSION-UNRELATED" C1 "$O" "a basis-free count sits beside a price in one file and beside a version in the other, and neither value anchors the count — the same widening the year arm carried, in the two classes that kept it. The arity is the assertion: one finding per class, so a regression in either is visible on its own" 2

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

# CTL-RETRO — the real historical blob. Every other class-C arm tests a fixture this file wrote;
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
    PASS "CTL-RETRO: C1 fired on the real historical revision of $CH_RETRO_PATH — $RETRO_N site(s), including the wrapped \"…one way in all / twelve places\" claim that passed every required check green on the day it shipped. This is the only class-C arm that tests a defect the repository actually carried"
  fi
fi

# ── D ────────────────────────────────────────────────────────────────────────────
# Each fixture is a whole small ADR corpus — a record directory, an index, and where the arm
# needs one a declaring fence — graded by the SAME ch_scan_d that graded the tree above. A
# control running different code would prove nothing about the gate.
ctl_adr_rec() {  # ctl_adr_rec <root> <basename...> — the record files on disk
  local d="$1"; shift
  local b; for b in "$@"; do printf 'A fixture record.\n' > "$d/$CH_ADR_DIR/$b"; done
}
ctl_adr_idx() {  # ctl_adr_idx <root> <basename...> — the index, one row per basename
  local d="$1"; shift
  { printf '# Architecture Decision Records\n\n## Index\n\n'
    printf '| ADR | Title | Status |\n|-----|-------|--------|\n'
    local b n
    for b in "$@"; do
      n="${b#ADR-}"; n="${n%%-*}"
      printf '| [ADR-%s](%s) | Fixture | Accepted |\n' "$n" "$b"
    done
  } > "$d/$CH_ADR_INDEX"
}
ctl_adr_decl() {  # ctl_adr_decl <root> <row...> — append the declaring fence to that index
  local d="$1"; shift
  { printf '\n## Number declarations\n\n'
    printf '```%s\n' "$CH_ADR_TAG"
    printf '# number  reason\n'
    local r; for r in "$@"; do printf '%s\n' "$r"; done
    printf '```\n'
  } >> "$d/$CH_ADR_INDEX"
}

D="$(ctl_mk d1)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md ADR-002-gamma.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md ADR-002-gamma.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D1" D1 "$O" "two records carry ONE number and the index keeps a row for each — the exact state two concurrent branches shipped, where the differing filenames leave the merge nothing to conflict on. The arity is the assertion: the collision is graded on the directory AND on the index, so an implementation reading only one surface is caught here rather than after a merge" 2

D="$(ctl_mk d1file)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md ADR-002-gamma.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D1-FILE" D1 "$O" "the DIRECTORY carries two records at one number while the index keeps a single row — the merge resolution that drops a row instead of keeping both, which leaves the collision on disk and the index reading clean" 1

D="$(ctl_mk d1row)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md ADR-002-gamma.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D1-ROW" D1 "$O" "the INDEX carries two rows at one number while the directory carries a single record — the collision graded on the index alone, so neither surface's verdict rests on the other's" 1

D="$(ctl_mk d2)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-003-gamma.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-003-gamma.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D2" D2 "$O" "a number inside the span is carried by no record and declared by no row — the lost-number case, which on inspection is indistinguishable from a gap somebody decided to carry" 1

D="$(ctl_mk d2decl)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-003-gamma.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-003-gamma.md
ctl_adr_decl "$D" '002  deliberate-withdrawal'
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-D2-DECL" D2 "$O" "the SAME gap is declared by a row in the fence — the arm that tells a correct gate from a merely strict one, because a gate failing here fails on the live corpus too, where a withdrawn record's number is a permanent and deliberate hole"

D="$(ctl_mk d3file)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_idx "$D" ADR-001-alpha.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D3-FILE" D3 "$O" "a record file exists that no index row names — the direction nothing in this repository compared, and the one that catches a collision whose merge resolution kept a single row" 1

D="$(ctl_mk d3row)"
ctl_adr_rec "$D" ADR-001-alpha.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D3-ROW" D3 "$O" "an index row names a record file that does not exist — the other direction, which a walk starting from the directory cannot see at all" 1

D="$(ctl_mk d4)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_decl "$D" '002  stale-row'
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D4" D4 "$O" "a declared number is OCCUPIED by a record — the gap was filled and the row did not come out, which is how a declaration turns into a standing exemption for whatever next takes that number" 1

D="$(ctl_mk d4span)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md
ctl_adr_decl "$D" '009  never-reached'
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D4-SPAN" D4 "$O" "a declared number sits OUTSIDE the span — it excepts a gap the sequence does not have, so it asserts nothing today and would silently except a real one the day the sequence reaches it" 1

D="$(ctl_mk d4bad)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-003-gamma.md
ctl_adr_idx "$D" ADR-001-alpha.md ADR-003-gamma.md
ctl_adr_decl "$D" 'ADR-002  written-as-an-identifier'
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D4-BAD" D4 "$O" "a declaring row writes the full identifier where the number belongs — the likeliest authoring slip on this fence, and one that declares nothing while LOOKING like a declaration" 1
ctl_mustfire "CTL-D4-BAD-GAP" D2 "$O" "and the same malformed row does NOT hold its gap open — the number it meant to except is still reported undeclared, so a row that reads like a declaration and is not cannot silently except anything. This is the pair that makes the fence fail-closed rather than fail-quiet" 1

D="$(ctl_mk d0)"
ctl_adr_idx "$D"
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustfire "CTL-D0" D0 "$O" "the index carries no row and the directory no record — an empty ADR surface, which is a broken probe or a relocated corpus and must never read as clean numbering" 1

D="$(ctl_mk dspec)"
ctl_adr_rec "$D" ADR-001-alpha.md ADR-002-beta.md
printf 'notes, not a record\n' > "$D/$CH_ADR_DIR/notes.md"
printf 'a draft carrying no number\n' > "$D/$CH_ADR_DIR/ADR-draft-thoughts.md"
ctl_adr_idx "$D" ADR-001-alpha.md ADR-002-beta.md
O="$(ch_scan_d "$D" "$(ctl_list "$D")")"
ctl_mustnot "CTL-D-SPEC" D3 "$O" "the record directory also holds its own index, a notes file and a draft carrying no number — none of the three is a record, so none may be reported as a record the index forgot"
ctl_mustnot "CTL-D-SPEC-DUP" D1 "$O" "none of those three resolves to a number either, so none can collide with a record or with another of them"
ctl_mustnot "CTL-D-SPEC-GAP" D2 "$O" "and none shifts the span, so none manufactures a gap under the highest number a real record carries"

# ── F ────────────────────────────────────────────────────────────────────────────
# Each fixture is a small tree — one shell file, or one workflow — graded by the SAME ch_scan_f
# that graded the tracked tree above. Every pipe a fixture plants is written @P@ and every tab
# @T@, spliced in as the fixture is written, so no planted shape is spelled out in this file.
# A must-fire arm requires its findings at the PREDICTED lines and nowhere else. A must-not-fire
# arm plants its near-miss and then a sentinel site after it, and requires the sentinel alone and
# the exact number of pipes the fixture holds: a lexer that went quiet because the near-miss
# derailed it, or that read a pipe out of the near-miss's text, reads red here and not green.
ctl_f_mk() {  # ctl_f_mk <name> — an empty fixture root; its path on stdout
  local d="$WORK/fx/$1"
  mkdir -p "$d/scripts" "$d/.github/workflows"
  printf '%s\n' "$d"
}
ctl_f_fx() {  # ctl_f_fx <file> — write stdin to <file>, a pipe for each @P@ and a tab for each @T@
  sed -e "s/@P@/$F_P/g" -e "s/@T@/$F_T/g" > "$1"
}
ctl_f_scan() { ch_list_f_dir "$1" > "$WORK/list.ffx"; ch_scan_f "$1" "$WORK/list.ffx"; }
# f_seen <output> — the F1 findings, in the order found, as "<line>:<class>:<reader>".
f_seen() { awk '$1 == "FINDING" && $2 == "F1" { printf "%s%s:%s:%s", s, $4, $5, $6; s = " " } END { print "" }' <<<"$1"; }
ctl_f_fire() {  # ctl_f_fire <label> <output> <want> <what-was-planted>
  local label="$1" out="$2" want="$3" what="$4" got z
  ctl_arm F1
  got="$(f_seen "$out")"; z="$(n_code "$out" F0)"
  if [ "$got" = "$want" ] && [ "$z" -eq 0 ]; then
    PASS "$label: F1 fired at $want and nowhere else — $what"
  else
    FAIL "$label: MUST FIRE at exactly $want — $what; the scanner reported F1 at '${got:-nothing}' and F0 $z time(s)"
  fi
}
ctl_f_spec() {  # ctl_f_spec <label> <output> <sentinel-line> <pipes> <near-miss>
  local label="$1" out="$2" line="$3" np="$4" what="$5" got z p
  got="$(f_seen "$out")"; z="$(n_code "$out" F0)"
  p="$(awk '$1 == "DENOM" { print $5 }' <<<"$out")"
  if [ "$got" = "$line:head:head" ] && [ "$z" -eq 0 ] && [ "${p:-none}" = "$np" ]; then
    PASS "$label: F1 stayed silent on $what — and still found the sentinel planted after it, at line $line, having read exactly $np pipe(s): the silence is the lexer's verdict, and no pipe was read out of the near-miss's text"
  else
    FAIL "$label: MUST NOT FIRE on $what, must still find the sentinel at line $line, and must read exactly $np pipe(s); the scanner reported F1 at '${got:-nothing}', F0 $z time(s) and ${p:-no} pipe(s)"
  fi
}
ctl_f_refuse() {  # ctl_f_refuse <label> <output> <line> <form> <what-was-planted>
  local label="$1" out="$2" line="$3" form="$4" what="$5" got
  ctl_arm F2
  got="$(awk '$1 == "FINDING" && $2 == "F2" { printf "%s%s:%s", s, $4, $5; s = " " } END { print "" }' <<<"$out")"
  if [ "$got" = "$line:$form" ]; then
    PASS "$label: F2 refused line $line as $form — $what"
  else
    FAIL "$label: MUST REFUSE line $line as $form, and nothing else — $what; the scanner reported F2 at '${got:-nothing}'"
  fi
}

# The reader classes, one plant each.
D="$(ctl_f_mk f1head)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ head -1
FX
ctl_f_fire "CTL-F1-HEAD" "$(ctl_f_scan "$D")" "2:head:head" "a pipe into head, which stops reading once it has its lines"

D="$(ctl_f_mk f1grepq)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
set -uo pipefail
printf x @P@ grep -q x
FX
ctl_f_fire "CTL-F1-GREP-Q" "$(ctl_f_scan "$D")" "3:grep-q:grep" "a pipe into a quiet grep, which exits on its first match"

D="$(ctl_f_mk f1grepm)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ grep -m1 x
FX
ctl_f_fire "CTL-F1-GREP-M" "$(ctl_f_scan "$D")" "2:grep-m:grep" "a pipe into grep -m1, which stops after its first matching line"

D="$(ctl_f_mk f1grepmax)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ grep --max-count=1 x
FX
ctl_f_fire "CTL-F1-GREP-MAXCOUNT" "$(ctl_f_scan "$D")" "2:grep-m:grep" "the long spelling, --max-count=1"

D="$(ctl_f_mk f1sedq)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ sed -n '/x/{p;q;}'
FX
ctl_f_fire "CTL-F1-SED-Q" "$(ctl_f_scan "$D")" "2:sed-q:sed" "a sed whose script quits at its first match"

D="$(ctl_f_mk f1sedexpr)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ sed -e 's/a/b/' -e '/x/Q'
FX
ctl_f_fire "CTL-F1-SED-EXPR" "$(ctl_f_scan "$D")" "2:sed-q:sed" "a Q in the second -e expression, behind one that only substitutes"

D="$(ctl_f_mk f1awkexit)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk '{ print; exit }'
FX
ctl_f_fire "CTL-F1-AWK-EXIT" "$(ctl_f_scan "$D")" "2:awk-exit:awk" "an awk that exits after its first record"

D="$(ctl_f_mk f1awkbegin)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk 'BEGIN { exit }'
FX
ctl_f_fire "CTL-F1-AWK-BEGIN" "$(ctl_f_scan "$D")" "2:awk-exit:awk" "an awk that exits in BEGIN, before it reads a byte"

D="$(ctl_f_mk f1awkfam)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ gawk '{ exit }'
printf x @P@ mawk '{ exit }'
printf x @P@ nawk 'FNR == 2 { nextfile }'
FX
ctl_f_fire "CTL-F1-AWK-FAMILY" "$(ctl_f_scan "$D")" "2:awk-exit:gawk 3:awk-exit:mawk 4:awk-exit:nawk" "every other awk the reader rule names, and nextfile as well as exit"

D="$(ctl_f_mk f1grepfam)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ egrep -q x
printf x @P@ fgrep -q x
printf x @P@ rg -q x
printf x @P@ ugrep --quiet x
printf x @P@ ag -m1 x
FX
ctl_f_fire "CTL-F1-GREP-FAMILY" "$(ctl_f_scan "$D")" "2:grep-q:egrep 3:grep-q:fgrep 4:grep-q:rg 5:grep-q:ugrep 6:grep-m:ag" "every other grep-like program the reader rule names, each in a quiet or a max-count form"

# The carriers — the reader inside each construct that carries a command.
D="$(ctl_f_mk f1fail)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
FAIL "X: $(printf '%s' "$O" @P@ head -3 @P@ tr '\n' ' ')"
FX
ctl_f_fire "CTL-F1-IN-FAIL" "$(ctl_f_scan "$D")" "2:head:head" "the reader inside a command substitution inside a FAIL message"

D="$(ctl_f_mk f1backtick)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
x=`printf a @P@ head -1`
FX
ctl_f_fire "CTL-F1-IN-BACKTICK" "$(ctl_f_scan "$D")" "2:head:head" "the reader inside backticks"

D="$(ctl_f_mk f1cond)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
if [[ "$(printf a @P@ head -1)" = a ]]; then :; fi
if [[ $(printf a @P@ head -1) = a ]]; then :; fi
FX
ctl_f_fire "CTL-F1-IN-CONDITIONAL" "$(ctl_f_scan "$D")" "2:head:head 3:head:head" "the reader inside a substitution inside [[ ]], quoted and bare"

D="$(ctl_f_mk f1default)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
y="${x:-$(printf a @P@ head -1)}"
FX
ctl_f_fire "CTL-F1-IN-DEFAULT" "$(ctl_f_scan "$D")" "2:head:head" "the reader inside a substitution inside a parameter expansion's default"

D="$(ctl_f_mk f1heredoc)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
cat <<EOF
value: $(printf a @P@ head -1)
EOF
FX
ctl_f_fire "CTL-F1-IN-HEREDOC" "$(ctl_f_scan "$D")" "3:head:head" "the reader inside a substitution in an UNQUOTED heredoc body, which the shell expands"

D="$(ctl_f_mk f1case)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
case "$x" in
  a) printf a @P@ head -1 ;;
esac
FX
ctl_f_fire "CTL-F1-IN-CASE" "$(ctl_f_scan "$D")" "3:head:head" "the reader in a case body"

# The pipe itself, split or prefixed.
D="$(ctl_f_mk f1awkmulti)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk '
  NR == 1 { print; exit }
'
FX
ctl_f_fire "CTL-F1-AWK-MULTILINE" "$(ctl_f_scan "$D")" "2:awk-exit:awk" "an awk program spanning lines, its exit on a later line than its reader"

D="$(ctl_f_mk f1cont)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x \
  @P@ head -1
FX
ctl_f_fire "CTL-F1-CONTINUED" "$(ctl_f_scan "$D")" "3:head:head" "a backslash-continued line opening with the pipe"

D="$(ctl_f_mk f1lineend)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@
  head -1
FX
ctl_f_fire "CTL-F1-LINE-END" "$(ctl_f_scan "$D")" "3:head:head" "a pipe at the end of its line, its reader on the next"

D="$(ctl_f_mk f1commentline)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@
  # a comment line between the pipe and its reader
  head -1
FX
ctl_f_fire "CTL-F1-COMMENT-LINE" "$(ctl_f_scan "$D")" "4:head:head" "a comment line between a pipe and its reader, which the pipe continues across"

D="$(ctl_f_mk f1pipeamp)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@& head -1
FX
ctl_f_fire "CTL-F1-PIPE-STDERR" "$(ctl_f_scan "$D")" "2:head:head" "the pipe that carries stderr too"

D="$(ctl_f_mk f1assign)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ LC_ALL=C head -1
FX
ctl_f_fire "CTL-F1-ASSIGN" "$(ctl_f_scan "$D")" "2:head:head" "a NAME=value word ahead of the reader"

D="$(ctl_f_mk f1redir)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ 2>/dev/null head -1
FX
ctl_f_fire "CTL-F1-REDIRECT" "$(ctl_f_scan "$D")" "2:head:head" "a redirection ahead of the reader"

D="$(ctl_f_mk f1wrappers)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ command head -1
printf x @P@ env LC_ALL=C head -1
printf x @P@ exec head -1
printf x @P@ nice -n 5 head -1
printf x @P@ stdbuf -oL head -1
printf x @P@ timeout 5 head -1
FX
ctl_f_fire "CTL-F1-WRAPPERS" "$(ctl_f_scan "$D")" "2:head:head 3:head:head 4:head:head 5:head:head 6:head:head 7:head:head" "each wrapper the reader rule names, with its options and operands — nice's -n 5 and timeout's duration among them"

D="$(ctl_f_mk f1aftercond)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
[[ "$t" =~ ^x([[:space:]]|$) ]] && printf y @P@ head -1
FX
ctl_f_fire "CTL-F1-AFTER-CONDITIONAL" "$(ctl_f_scan "$D")" "2:head:head" "a reader on the same line after a [[ ]] whose bracket expression holds its own ]] — code resumes at the true close"

# The scan set. A shell file is one by its name or by its first line; nothing else is lexed.
D="$(ctl_f_mk f1shebang)"
mkdir -p "$D/bin"
ctl_f_fx "$D/bin/tool" <<'FX'
#!/usr/bin/env bash
printf x @P@ head -1
FX
ctl_f_fx "$D/bin/tool2" <<'FX'
#!/bin/sh

printf x @P@ head -1
FX
ctl_f_fire "CTL-F1-SHEBANG" "$(ctl_f_scan "$D")" "2:head:head 3:head:head" "two files with no .sh suffix, each a shell file by its first line — one through env, one directly"

D="$(ctl_f_mk fsnotshell)"
mkdir -p "$D/bin" "$D/docs"
ctl_f_fx "$D/bin/tool.py" <<'FX'
#!/usr/bin/env python3
printf x @P@ head -1
FX
ctl_f_fx "$D/docs/notes.md" <<'FX'
printf x @P@ head -1
FX
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-NOT-SHELL" "$(ctl_f_scan "$D")" 2 1 "the shape in a Python script and in a markdown file, neither of which is shell"

# run: values. Each workflow's steps start at line 7.
D="$(ctl_f_mk f1runliteral)"
ctl_f_fx "$D/.github/workflows/fx.yml" <<'FX'
name: fx
on: push
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: |
          set -euo pipefail
          printf x @P@ head -1
FX
ctl_f_fire "CTL-F1-RUN-LITERAL" "$(ctl_f_scan "$D")" "9:head:head" "the reader in a literal-block run: value, at its line in the workflow"

D="$(ctl_f_mk f1runforms)"
ctl_f_fx "$D/.github/workflows/fx.yml" <<'FX'
name: fx
on: push
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: printf x @P@ head -1
      - run: 'printf x @P@ head -1'
      - run: |-
          printf x @P@ head -1
FX
ctl_f_fx "$D/.github/workflows/fy.yaml" <<'FX'
jobs:
  j:
    steps:
      - run: printf x @P@ head -1
FX
O="$(ctl_f_scan "$D")"
ctl_f_fire "CTL-F1-RUN-FORMS" "$O" "7:head:head 8:head:head 10:head:head 4:head:head" "the reader in a one-line plain value, a one-line quoted value and a stripped literal block, and in a second workflow named .yaml"
ctl_mustnot "CTL-F2-SPEC" F2 "$O" "the same three forms — each one the line reader places and lexes, so none is refused"

# THE LITERAL-BLOCK EXTENT. An empty line is content: a reader that ended the block at its first
# empty line read one line of the two largest blocks this repository ships and nothing after it.
D="$(ctl_f_mk f1runblank)"
ctl_f_fx "$D/.github/workflows/fx.yml" <<'FX'
name: fx
on: push
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo one

          printf x @P@ head -1

      - name: after
FX
O="$(ctl_f_scan "$D")"
ctl_f_fire "CTL-F1-RUN-BLANK" "$O" "10:head:head" "a site after an empty line inside a literal block"
F_EXT="$(awk '$1 == "SCAN" && $3 == "run=7" { print $4 }' <<<"$O")"
if [ "$F_EXT" = "lines=8-10" ]; then
  PASS "CTL-F-EXTENT: the SCAN line prints the block's extent as lines=8-10 — from the line after its key to its last non-empty line, across the empty one — so a truncated block shows in the printed scan set"
else
  FAIL "CTL-F-EXTENT: the SCAN line for the block at line 7 printed '${F_EXT:-no extent}' rather than lines=8-10 — the printed scan set no longer shows how much of a block was read"
fi

D="$(ctl_f_mk f1runheredoc)"
ctl_f_fx "$D/.github/workflows/fx.yml" <<'FX'
name: fx
on: push
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: |
          cat <<EOF
          first

          $(printf x @P@ head -1)
          EOF
FX
ctl_f_fire "CTL-F1-RUN-HEREDOC" "$(ctl_f_scan "$D")" "11:head:head" "a site inside an unquoted heredoc that spans an empty line of a literal block"

D="$(ctl_f_mk fsotherblock)"
ctl_f_fx "$D/.github/workflows/fx.yml" <<'FX'
name: fx
on: push
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - uses: some/action@v1
        with:
          script: |
            run: printf x @P@ head -1
      - run: printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-OTHER-BLOCK" "$(ctl_f_scan "$D")" 11 1 "a line reading like a run key inside ANOTHER key's block scalar, which is that key's text"

# The near-misses. Each fixture plants one, then the sentinel site on the line after it.
D="$(ctl_f_mk fsherestring)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
head -1 <<<"$x"
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-HERESTRING" "$(ctl_f_scan "$D")" 3 1 "a here-string into head — the first remedy form, with no writer process to signal"

D="$(ctl_f_mk fsdrain)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk 'NR <= 3'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-DRAIN" "$(ctl_f_scan "$D")" 3 2 "a draining awk 'NR <= N' — the second remedy form, which reads to end of input"

D="$(ctl_f_mk fscount)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ grep -c x
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-COUNT" "$(ctl_f_scan "$D")" 3 2 "grep -c, which counts to end of input"

D="$(ctl_f_mk fsor)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
false || head -1 /dev/null
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-OR-LIST" "$(ctl_f_scan "$D")" 3 1 "an OR-list, whose double bar is not a pipe"

D="$(ctl_f_mk fscomment)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
# printf x @P@ head -1
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-COMMENT" "$(ctl_f_scan "$D")" 3 1 "the shape inside a comment"

D="$(ctl_f_mk fsawkend)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk '{ n++ } END { print n; exit }'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-AWK-END" "$(ctl_f_scan "$D")" 3 2 "an exit inside END, which runs only after the input is read"

D="$(ctl_f_mk fsawktext)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk '/exit/ { print "exit" }'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-AWK-TEXT" "$(ctl_f_scan "$D")" 3 2 "the word exit inside an awk regular expression and an awk string"

D="$(ctl_f_mk fsawkv)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ awk -v e=exit '{ print e }'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-AWK-ASSIGN" "$(ctl_f_scan "$D")" 3 2 "an awk -v assignment whose value is the word exit — data handed to the program, not the program"

D="$(ctl_f_mk fsseds)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ sed 's/q/Q/'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-SED-SUBST" "$(ctl_f_scan "$D")" 3 2 "a q inside the operands of s///, which is text and not a command"

D="$(ctl_f_mk fssedp)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ sed -n 1p
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-SED-PRINT" "$(ctl_f_scan "$D")" 3 2 "sed -n 1p, which prints the first line and reads on"

D="$(ctl_f_mk fstail)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ tail -1
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-TAIL" "$(ctl_f_scan "$D")" 3 2 "tail, which reads to end of input"

D="$(ctl_f_mk fsheadneg)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ head -n -2
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-HEAD-NEGATIVE" "$(ctl_f_scan "$D")" 3 2 "head -n -2, a negative count, which reads to end of input"

D="$(ctl_f_mk fscontargs)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ head \
  -n -2
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-CONTINUED-ARGS" "$(ctl_f_scan "$D")" 4 2 "head with its negative count on a backslash-continued line, which reads to end of input"

D="$(ctl_f_mk fsgrepe)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ grep -e q x
printf x @P@ grep -eq x
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-GREP-PATTERN" "$(ctl_f_scan "$D")" 4 3 "grep -e q and grep -eq, where q is the pattern -e takes and not a flag"

D="$(ctl_f_mk fsgreps)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
printf x @P@ grep -s x
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-GREP-SILENT-ERRORS" "$(ctl_f_scan "$D")" 3 2 "grep -s, which silences errors and reads on"

D="$(ctl_f_mk fsnopipe)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
awk '{ print; exit }' file
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-NO-PIPE" "$(ctl_f_scan "$D")" 3 1 "an early-exiting awk that reads a file, with no pipe to close"

D="$(ctl_f_mk fsquoted)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
echo "printf x @P@ head -1" 'printf x @P@ head -1'
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-QUOTED" "$(ctl_f_scan "$D")" 3 1 "the shape as text inside double and single quotes"

D="$(ctl_f_mk fsqheredoc)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
cat <<'EOF'
printf x @P@ head -1
EOF
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-QUOTED-HEREDOC" "$(ctl_f_scan "$D")" 5 1 "the shape inside a QUOTED heredoc body, which the shell never expands"

D="$(ctl_f_mk fstabheredoc)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
cat <<-EOF
@T@printf x @P@ head -1
@T@EOF
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-TAB-HEREDOC" "$(ctl_f_scan "$D")" 5 1 "the shape as text in a <<- body, whose tab-indented delimiter still closes it"

D="$(ctl_f_mk fsregex)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
[[ $x =~ a|head ]] && :
[[ $x =~ ^[[:space:]]|head ]] && :
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-REGEX-BAR" "$(ctl_f_scan "$D")" 4 1 "an alternation bar in a [[ =~ ]] regular expression, one of them right after a bracket expression holding its own ]]"

D="$(ctl_f_mk fscond)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
[[ "$t" =~ ^x([[:space:]]|$) ]] && :
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-CONDITIONAL" "$(ctl_f_scan "$D")" 3 1 "a [[ ]] whose bracket expression holds its own ]], alone on its line"

D="$(ctl_f_mk fspgform)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
[[ "$ln" =~ [^[:space:]]+\.(html|md):[0-9]+ ]] && return 0
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-CONDITIONAL-RETURN" "$(ctl_f_scan "$D")" 3 1 "the publish-guard suite's own [[ ]] shape, an alternation inside it and a return after it"

D="$(ctl_f_mk fsforarith)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
for (( i = 0; i < 2; i++ )); do
  [[ "$x" =~ (a|b) ]] && :
done
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-FOR-ARITHMETIC" "$(ctl_f_scan "$D")" 5 1 "an arithmetic for header followed by a [[ =~ ]] alternation"

D="$(ctl_f_mk fscasepat)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
case "$x" in
  tail|head) : ;;
esac
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-CASE-PATTERN" "$(ctl_f_scan "$D")" 5 1 "a bar between case patterns, which separates patterns and pipes nothing"

D="$(ctl_f_mk fsarith)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
y=$(( x | head ))
(( x | head ))
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-ARITHMETIC" "$(ctl_f_scan "$D")" 4 1 "a bitwise bar in arithmetic, ahead of a variable named head"

D="$(ctl_f_mk fspe)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
y="${v//a|head/b}"
y=${v//x/a|head }
printf %s sentinel @P@ head -1
FX
ctl_f_spec "CTL-F1-SPEC-PARAMETER" "$(ctl_f_scan "$D")" 4 1 "a bar inside a parameter expansion, quoted and unquoted"

# F0 — the vacuity guard and the unfinished unit.
D="$(ctl_f_mk f0empty)"
printf 'nothing to lex here\n' > "$D/README.md"
O="$(ctl_f_scan "$D")"
ctl_mustfire "CTL-F0" F0 "$O" "a tree with no shell file and no workflow — nothing to lex, which is a broken probe or a relocated corpus and never a clean tree" 1

D="$(ctl_f_mk f0quote)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
echo "a quote that never closes
printf x @P@ head -1
FX
O="$(ctl_f_scan "$D")"
ctl_mustfire "CTL-F0-QUOTE" F0 "$O" "a shell file ending inside a double quote — every line after the quote was text to the lexer, so its silence there is no measurement" 1

D="$(ctl_f_mk f0heredoc)"
ctl_f_fx "$D/scripts/fx.sh" <<'FX'
#!/usr/bin/env bash
cat <<EOF
a body whose delimiter never comes
FX
O="$(ctl_f_scan "$D")"
ctl_mustfire "CTL-F0-HEREDOC" F0 "$O" "a shell file ending inside a heredoc body — the state a literal block cut short in mid-heredoc would leave" 1

# F2 — every run: form the line reader refuses, each with its key at line 7.
ctl_f_wfx() {  # ctl_f_wfx <root> — .github/workflows/fx.yml: a header whose steps open at line 7, then stdin
  { printf 'name: fx\non: push\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n'; cat; } | ctl_f_fx "$1/.github/workflows/fx.yml"
}
D="$(ctl_f_mk f2folded)"
ctl_f_wfx "$D" <<'FX'
      - run: >
          echo x
FX
ctl_f_refuse "CTL-F2-FOLDED" "$(ctl_f_scan "$D")" 7 folded-block "a folded block, whose lines a parser joins with spaces"

D="$(ctl_f_mk f2indent)"
ctl_f_wfx "$D" <<'FX'
      - run: |2
          echo x
FX
ctl_f_refuse "CTL-F2-INDENT" "$(ctl_f_scan "$D")" 7 indentation-indicator "an explicit indentation indicator, which moves where the block's content starts"

D="$(ctl_f_mk f2comment)"
ctl_f_wfx "$D" <<'FX'
      - run: | # a note
          echo x
FX
ctl_f_refuse "CTL-F2-HEADER-COMMENT" "$(ctl_f_scan "$D")" 7 block-header-comment "a block header carrying a trailing comment"

D="$(ctl_f_mk f2qcont)"
ctl_f_wfx "$D" <<'FX'
      - run: "echo x
          y"
FX
ctl_f_refuse "CTL-F2-QUOTED-CONTINUES" "$(ctl_f_scan "$D")" 7 quoted-continues "a quoted value that does not close on its own line"

D="$(ctl_f_mk f2pcont)"
ctl_f_wfx "$D" <<'FX'
      - run: echo x
          y
FX
ctl_f_refuse "CTL-F2-PLAIN-CONTINUES" "$(ctl_f_scan "$D")" 7 plain-continues "a plain value continued on a deeper-indented next line, which a parser joins to it"

D="$(ctl_f_mk f2empty)"
ctl_f_wfx "$D" <<'FX'
      - run:
      - name: y
FX
ctl_f_refuse "CTL-F2-EMPTY" "$(ctl_f_scan "$D")" 7 empty-value "a run key with nothing on its line"

D="$(ctl_f_mk f2alias)"
ctl_f_wfx "$D" <<'FX'
      - run: *step
FX
ctl_f_refuse "CTL-F2-ALIAS" "$(ctl_f_scan "$D")" 7 alias "an alias, whose text lives at its anchor"

D="$(ctl_f_mk f2anchor)"
ctl_f_wfx "$D" <<'FX'
      - run: &step echo x
FX
ctl_f_refuse "CTL-F2-ANCHOR" "$(ctl_f_scan "$D")" 7 anchor-or-tag "an anchor ahead of the value"

D="$(ctl_f_mk f2flowvalue)"
ctl_f_wfx "$D" <<'FX'
      - run: [echo, x]
FX
ctl_f_refuse "CTL-F2-FLOW-VALUE" "$(ctl_f_scan "$D")" 7 flow-value "a flow collection as the value"

D="$(ctl_f_mk f2qkey)"
ctl_f_wfx "$D" <<'FX'
      - "run": echo x
FX
ctl_f_refuse "CTL-F2-QUOTED-KEY" "$(ctl_f_scan "$D")" 7 quoted-key "a quoted run key"

D="$(ctl_f_mk f2flowmap)"
ctl_f_wfx "$D" <<'FX'
      - { name: x, run: echo x }
FX
ctl_f_refuse "CTL-F2-FLOW-MAPPING" "$(ctl_f_scan "$D")" 7 flow-mapping "a run key inside a flow mapping"

# CTL-F-RETRO — the real defect. Before the validator's readers were converted to drain, its
# revision at CH_F_RETRO_REV piped into early-exiting awk readers. This arm reads that blob from
# history, so it needs the full-history checkout, and an unreachable blob FAILS it.
ctl_arm F1
D="$(ctl_f_mk fretro)"
F_RETRO_OK=1
git -C "$ROOT" show "$CH_F_RETRO_REV:$CH_F_RETRO_PATH" > "$D/$CH_F_RETRO_PATH" 2>/dev/null || F_RETRO_OK=0
if [ "$F_RETRO_OK" -eq 0 ] || [ ! -s "$D/$CH_F_RETRO_PATH" ]; then
  FAIL "CTL-F-RETRO: the historical blob at $CH_F_RETRO_REV is unreachable, so the one class-F arm that tests the detector against a defect this repository actually shipped did not run. This is a hole, not a skip — CI must check out with fetch-depth: 0"
else
  O="$(ctl_f_scan "$D")"
  F_RETRO_N="$(n_code "$O" F1)"
  F_RETRO_AWK="$(awk '$1 == "FINDING" && $2 == "F1" && $5 == "awk-exit" { n++ } END { print n + 0 }' <<<"$O")"
  F_RETRO_Z="$(n_code "$O" F0)"
  if [ "$F_RETRO_N" -eq 8 ] && [ "$F_RETRO_AWK" -eq 8 ] && [ "$F_RETRO_Z" -eq 0 ]; then
    PASS "CTL-F-RETRO: F1 fired on the real historical revision of $CH_F_RETRO_PATH — its 8 pipes into an early-exiting awk, and nothing else. This is the one class-F arm graded against a defect this repository shipped"
  else
    FAIL "CTL-F-RETRO: MUST FIRE exactly 8 times, all awk-exit, on the revision of $CH_F_RETRO_PATH at $CH_F_RETRO_REV — it reported F1 $F_RETRO_N time(s), $F_RETRO_AWK of them awk-exit, and F0 $F_RETRO_Z time(s)"
  fi
fi

# ── G ────────────────────────────────────────────────────────────────────────────
# Each fixture is a small repository with its own tags and, where the arm needs one, its own
# declaring fence — graded by the SAME ch_scan_g, and so by the same release check, that graded
# the real tags above. Every git call that BUILDS a fixture runs with all outside configuration
# switched off and a synthetic identity, so no signing key, hook, default branch or address on
# the machine running the suite can reach a fixture.
ctl_g_git() {
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
  GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
  GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid \
    git -c init.defaultBranch=main -c commit.gpgSign=false -c tag.gpgSign=false "$@"
}
ctl_g_repo() {  # ctl_g_repo <name> — an empty repository; its path on stdout
  local d="$WORK/fx/$1"
  mkdir -p "$d" && ctl_g_git -C "$d" init -q && printf '%s\n' "$d"
}
ctl_g_release() {  # ctl_g_release <repo> <tag> <CHANGELOG text, or - for none> — commit, then tag
  local d="$1" tag="$2" text="$3"
  if [ "$text" = "-" ]; then rm -f "$d/CHANGELOG.md"; else printf '%s\n' "$text" > "$d/CHANGELOG.md"; fi
  ctl_g_git -C "$d" add -A . && ctl_g_git -C "$d" commit -q --allow-empty -m "$tag" && ctl_g_git -C "$d" tag "$tag"
}
ctl_g_decl() {  # ctl_g_decl <repo> <row...> — that repository's CONTRIBUTING.md, carrying the fence
  local d="$1"; shift
  { printf '# Contributing\n\n### Why earlier tags look different\n\n'
    printf '```%s\n' "$CH_G_TAG"
    printf '# tag  limb:reason\n'
    local r; for r in "$@"; do printf '%s\n' "$r"; done
    printf '```\n'
  } > "$d/$CH_G_DOC"
}

D="$(ctl_g_repo g0)"
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G0" G0 "$O" "a repository carrying no v* tag — what a checkout below fetch-depth: 0 looks like to the release check, which says NOT-EVALUATED; group G must report that as no measurement, never as a clean history" 1

D="$(ctl_g_repo g0decl)"
ctl_g_release "$D" v1.0.0 '-'
ctl_g_decl "$D"
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G0-DECL" G0 "$O" "a tag fails and the declaring fence is present with ZERO rows — a declaration gone missing is reported as one cause, not as every failing tag read as a new one" 1

# CTL-G0-SHALLOW and CTL-G-SPEC-SHALLOW — ONE shallow fixture, graded twice, because the limb
# needs both of its conditions and each grading holds one of them fixed. The source repository
# carries three tagged releases; the fixture is a depth-limited clone of it, which holds the tip
# commit alone and so cannot carry the two older tags. The clone is made over file:// because
# git ignores --depth for a plain local path, and with --no-tags so that the one tag it carries
# is the one created on the next line, whatever tag-following would have brought.
#   First grading: a declared tag is ABSENT from the census. It must be G0 and not G2 — the tag
#   was never fetched, so the row is not stale, and removing it would turn the full-history run
#   red.
#   Second grading: every declared tag is PRESENT. G0 must stay silent — shallowness alone is
#   not the finding, because a shallow clone can carry every tag.
# The other half of the rule has its arm already: CTL-G2-ABSENT, below, is a repository that is
# NOT shallow, and there an absent declared tag stays G2. A fixture that failed to build cannot
# pass both gradings: no clone, no tag, or a clone that is not shallow each turns one of them red.
S="$(ctl_g_repo gshallowsrc)"
ctl_g_release "$S" v1.0.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$S" v1.1.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$S" v1.2.0 '-'
D="$WORK/fx/gshallow"
ctl_g_git clone -q --depth 1 --no-tags "file://$S" "$D"
ctl_g_git -C "$D" tag v1.2.0
ctl_g_decl "$D" 'v1.1.0  changelog:no-entry' 'v1.2.0  changelog:no-changelog'
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G0-SHALLOW" G0 "$O" "a shallow clone whose census lacks a declared tag — a depth-limited clone carries only the tags its truncated history reaches, so that census is a sample of the release history; it is reported as no measurement, never as a stale row whose remedy would break the full-history run" 1
ctl_g_decl "$D" 'v1.2.0  changelog:no-changelog'
O="$(ch_scan_g "$D")"
ctl_mustnot "CTL-G-SPEC-SHALLOW" G0 "$O" "the same shallow clone with every declared tag present — shallowness alone is not the finding, because a shallow clone can carry every tag, and a gate firing here would fire in every such clone"

D="$(ctl_g_repo g1)"
ctl_g_release "$D" v1.0.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$D" v1.1.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$D" v1.2.0 '-'
ctl_g_decl "$D" 'v1.2.0  changelog:no-changelog'
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G1" G1 "$O" "a tag was cut on a tree whose newest entry is the release before it, and nothing declares it — the shape v0.34.0 shipped in, which this group exists to catch the next time a release bypasses the check" 1

D="$(ctl_g_repo g2)"
ctl_g_release "$D" v1.0.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$D" v1.1.0 '-'
ctl_g_decl "$D" 'v1.1.0  changelog:no-changelog' 'v1.0.0  changelog:no-entry'
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G2" G2 "$O" "a row declares a tag that carries its entry — a declaration that outlived its failure is a standing exemption for that tag, which is why this direction is asserted" 1
ctl_g_decl "$D" 'v1.1.0  changelog:no-changelog' 'v9.9.9  changelog:no-entry'
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G2-ABSENT" G2 "$O" "a row names a tag the repository does not carry — moved, deleted or mistyped, and on this host nothing prevents the first two" 1
ctl_g_decl "$D" 'v1.1.0  changelog:no-entry'
O="$(ch_scan_g "$D")"
ctl_mustfire "CTL-G2-REASON" G2 "$O" "a row names a failing tag with a reason the check does not give — the row and the tag disagree, so the row is stale" 1
ctl_mustfire "CTL-G1-REASON" G1 "$O" "and the same tag's real reason is undeclared — one disagreement is reported in BOTH directions, because a row matches a tag only with its reason" 1

D="$(ctl_g_repo gspec)"
ctl_g_release "$D" v1.0.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$D" v1.1.0 '## [1.0.0] — 2026-01-01 — first'
ctl_g_release "$D" v1.2.0 '-'
ctl_g_decl "$D" 'v1.1.0  changelog:no-entry' 'v1.2.0  changelog:no-changelog'
O="$(ch_scan_g "$D")"
ctl_mustnot "CTL-G-SPEC" G1 "$O" "every failing tag is declared with the reason the check gives — the state the real history is in, so a gate firing here fires on every pull request"
ctl_mustnot "CTL-G-SPEC-STALE" G2 "$O" "and every row still names a failing tag — a passing tag beside them is not a stale declaration"
ctl_mustnot "CTL-G-SPEC-G0" G0 "$O" "and the census is a measurement — tags read, a verdict for each, a declaration present"

# The predicate itself — the release check's own verdicts, graded by EXACT exit status. These arms
# emit no finding code: they grade the script group G drives, not the comparison, so the group-Y
# inventory is unchanged by them.
D="$(ctl_g_repo gpred)"
ctl_g_release "$D" v1.0.0 '## [1.0.0] — 2020-01-01 — dated long before its tag'
ctl_g_release "$D" v1.1.0 "$(printf '## [Unreleased]\n\n- drafted\n\n## [1.1.0] — 2026-01-02 — second\n\n## [1.0.0] — 2020-01-01 — first')"
ctl_g_release "$D" v1.2.0 "$(printf '## [1.3.0] — 2026-01-04 — a newer entry\n\n## [1.2.0] — 2026-01-03 — third')"
ctl_g_release "$D" v1.3.0 "$(printf '```\n## [1.3.0] — sample text inside a fence\n```\n\n## [1.2.0] — 2026-01-03 — third')"
ctl_g_release "$D" v0.4.0 '## [0.40.0] — 2026-01-05 — a longer version sharing the prefix'
ctl_g_release "$D" v1.4.0 '-'
ctl_g_git -C "$D" tag v1.5.0 "$(ctl_g_git -C "$D" rev-parse 'HEAD^{tree}')"
expect_rc 0 "CTL-G-SPEC-DATE" "an entry dated long before its tag passes — its date is the day it was written, and the check reads the version alone" -- g_run "$D" v1.0.0
expect_rc 0 "CTL-G-SPEC-UNRELEASED" "an Unreleased heading above the version's own entry is passed over" -- g_run "$D" v1.1.0
expect_rc 1 "CTL-G-NEWEST" "a newer version's heading above the tag's own entry is refused — the version moved and the heading did not" -- g_run "$D" v1.2.0
expect_rc 1 "CTL-G-FENCE" "a heading inside a fenced block is sample text, not an entry" -- g_run "$D" v1.3.0
expect_rc 1 "CTL-G-PREFIX" "an entry for 0.40.0 does not stand in for 0.4.0" -- g_run "$D" v0.4.0
expect_rc 1 "CTL-G-NOFILE" "a tagged tree with no CHANGELOG at all is refused" -- g_run "$D" v1.4.0
expect_rc 1 "CTL-G-NOCOMMIT" "a tag that peels to a tree rather than a commit is refused" -- g_run "$D" v1.5.0
expect_rc 2 "CTL-G-ABSENT" "a tag that does not exist is NOT-EVALUATED — never a finding and never a pass" -- g_run "$D" v9.9.9
expect_rc 2 "CTL-G-NAME" "an argument that is not vX.Y.Z is NOT-EVALUATED" -- g_run "$D" next

# CTL-G-RETRO — the real defect. v0.34.0 was the first release cut after the release procedure was
# rewritten, and it was tagged on its release merge before its entry landed. This arm reads the
# real tags, so it needs the full-history checkout, and a missing tag FAILS it rather than skipping.
G_RO="$(g_run "$ROOT" "$CH_G_RETRO_FAIL" 2>&1)"; G_RRC=$?
G_RWHY="$(awk -v t="$CH_G_RETRO_FAIL" '$1 == "TAG" && $2 == t && $4 == "FAIL" { print $3 ":" $5 }' <<<"$G_RO")"
if [ "$G_RRC" -eq 1 ] && [ "$G_RWHY" = "changelog:no-entry" ]; then
  PASS "CTL-G-RETRO: the release check refuses $CH_G_RETRO_FAIL, a tag this repository actually shipped without its own entry — exit 1, changelog:no-entry. It is the one arm that grades the check against a tag the repository published without its entry"
else
  FAIL "CTL-G-RETRO: MUST REFUSE $CH_G_RETRO_FAIL with exit 1 and changelog:no-entry; got exit $G_RRC and '${G_RWHY:-no verdict}'. Exit 2 means the tag is absent from this checkout — CI must check out with fetch-depth: 0"
fi
G_SO="$(g_run "$ROOT" "$CH_G_RETRO_PASS" 2>&1)"; G_SRC=$?
G_SWHY="$(awk -v t="$CH_G_RETRO_PASS" '$1 == "TAG" && $2 == t { print $3 ":" $4 }' <<<"$G_SO")"
if [ "$G_SRC" -eq 0 ] && [ "$G_SWHY" = "changelog:PASS" ]; then
  PASS "CTL-G-SPEC-RETRO: the release check passes $CH_G_RETRO_PASS, a tag this repository shipped carrying its own entry as the newest — exit 0. Without this arm, a check that refused every tag would pass CTL-G-RETRO"
else
  FAIL "CTL-G-SPEC-RETRO: MUST PASS $CH_G_RETRO_PASS with exit 0; got exit $G_SRC and '${G_SWHY:-no verdict}'"
fi

# CTL-G-READONLY — the check rewrites nothing. Every ref and the working tree, read before the
# check first ran on this repository (group G, above), must be identical after every run of it
# here — the group's census, the two -RETRO arms and one more census — and must not be empty.
g_run "$ROOT" --all > /dev/null 2>&1
G_REF1="$(git -C "$ROOT" for-each-ref --format='%(refname) %(objectname)')"
G_ST1="$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)"
if [ -n "$G_REF0" ] && [ "$G_REF0" = "$G_REF1" ] && [ "$G_ST0" = "$G_ST1" ]; then
  PASS "CTL-G-READONLY: every run of the release check on this repository left every ref and the working tree exactly as they were before its first run — it reads and never writes"
else
  FAIL "CTL-G-READONLY: the refs or the working tree differ from their state before the release check first ran here, or no ref was read — the release check must never write"
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


# ═════════════════════════════════════════════════════════════════════════════════
# Group PF — no verdict in this file is decided by a pipeline's exit status.
#
# A verdict site whose writer pipes into an early-exiting `grep -q` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on
# first match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed
# although the match succeeded. Measured on an unchanged tree in the taxonomy suite before
# it was fixed: 10 red runs in 30, across two arms sharing nothing but the shape.
#
# THIS SUITE ALREADY STATED THE RULE AND DID NOT ASSERT IT. The comment above has_code
# spells the mechanism out in full — the here-string is load-bearing, a pipeline would kill
# the writer with SIGPIPE, pipefail would report the successful match as a failure. It was
# the only one of the five suites then in place carrying that reasoning as prose with no
# standing arm behind it, and prose does not fail a run. This group is that paragraph made executable;
# nothing about the convention changes, only whether it is checked.
#
# The direction matters here for the same reason it does elsewhere. This suite routes its
# code checks through one has_code() helper, and its callers include the INVERTED form —
# `if has_code …; then FAIL` — where a spurious non-zero resolves toward the quiet answer:
# the finding goes unreported and the arm records a pass on a state that carries it. A
# false RED costs a re-run and announces itself; this direction announces nothing.
#
# This suite sources nothing, so its scan set is correctly this file alone.
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
    PASS "PF1: ${PF_GOOD} here-string grep -q site(s) in this file, 0 of them pipelines — no verdict here, and none of the arms routed through has_code, can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
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
# left that suite exiting 0. But the population is not concentrated there — 59 sites carried
# the shape across the five suites that existed when this group was installed, and this suite
# carries 2 of them. A guard installed only where the defect
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
# publish-guard suite plus this oracle in each of the five suites that existed when that
# scope was locked; a 59-site sweep across all of them is exactly the blind bulk edit this
# repository's own discipline forbids. They are declared
# here rather than left silent, and the diff below runs in BOTH directions — an undeclared
# site FAILS, and a declared site that no longer scans FAILS too, so remediating one
# obliges removing its line. The list can only shrink; it cannot quietly absorb a new
# defect.
#   A0 and the ctl_mustnot wrapper (whose id is the runtime $label) both call has_code
#   as their condition: an absent has_code exits 127 and lands on the PASS limb
MD_LEGACY='A0 $label'

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

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m, \033[1;36m%d vacuous\033[0m\n' \
  "$pass" "$fail" "$skip" "$vacuous"
printf 'CITATION: %s markdown citation(s) read over %s tracked file(s); %s bare where a unique durable home exists.\n' \
  "$A_NCITE" "$A_NFILE" "$A_NBARE"
printf 'LOCATOR: %s in-scope (bare) path:line locator(s) over %s tracked file(s); %s in either spelling, %s out of scope by declaration.\n' \
  "$B_NHIT" "$B_NFILE" "$B_NWIDE" "$B_NOOS"
printf 'COUNT-ASSERTION: %s residual site(s) in %s file(s) over %s sentence(s) graded; %s declared row(s).\n' \
  "$C_NSITE" "$C_NDIRTY" "$C_NSENT" "$C_NROW"
printf 'ADR-NUMBERING: %s record file(s) and %s index row(s) over a span reaching %s; %s collision(s), %s undeclared gap(s), %s index/directory disagreement(s), %s stale declaration(s); %s gap(s) held open by declaration.\n' \
  "$D_NREC" "$D_NROW" "$D_MAXN" "$D_NDUP" "$D_NGAP" "$D_NMIS" "$D_NROT" "$D_NHELD"
# The measurement state class F decided above: under F0 the line carries the cause and no counter.
if [ "$F_MEASURED" -eq 1 ]; then
  printf 'SHORT-CIRCUIT: %s pipe(s) lexed over %s shell file(s) and %s run value(s) in %s workflow file(s); %s into a reader that can stop before EOF.\n' \
    "$F_NPIPE" "$F_NSH" "$F_NRUN" "$F_NWF" "$F_NHIT"
else
  printf 'SHORT-CIRCUIT: NOT-EVALUATED — %s — this is not a clean result\n' "$F_WHY"
fi
# The same measurement state group G decided above: under G0 the line carries the cause and no
# counter, so nobody reading the summary takes a withheld comparison for a measured zero.
if [ "$G_MEASURED" -eq 1 ]; then
  printf 'RELEASE-TAGS: %s tag(s) read by the release check, %s failing a limb; %s row(s) declared, %s undeclared failing tag(s), %s stale row(s).\n' \
    "$G_NREAD" "$G_NFAIL" "$G_NDECL" "$G_N1" "$G_N2"
else
  printf 'RELEASE-TAGS: NOT-EVALUATED — %s — this is not a clean result\n' "$G_WHY"
fi
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
