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
#     B5 the command component fails N1 · B6 ambiguity-set well-formedness
#     B8 a disposition member's reason, or a set offering no verb at all
#
#   K   the coverage bijection, which REPLACES forward/reverse/injectivity (group K)
#     K1  RESOLVABILITY — every ADDRESSED cell covers a non-empty set and every member
#         resolves (file AND declaration AND region)
#     K2  TOTALITY      — every coverage unit of the surface is covered by an ADDRESSED cell
#     K3  EXCLUSIVITY   — no unit covered twice BY ADDRESSED CELLS; no command carrying
#         both a verbless and a verbed ADDRESSED cell
#     K4  SET RESOLVABILITY — every member of a declared ambiguity set covers exactly one
#         coverage unit
#     K5  SET EXCLUSIVITY   — nothing named twice inside one set, and no two sets denoting
#         the same options. Its quantifier is BOTH member kinds: a unit member by the
#         coverage unit it resolves to, a disposition member by its reason. K4's is not —
#         a disposition never reaches AMBPARTS, so K4 cannot see one.
#
#     THE THREE CELL CLASSES, and why admitting the third weakens neither K2 nor K3.
#     A Step-1 Command cell takes exactly one of three forms. ADDRESSED — a single code
#     span naming a command and at most one verb. EXCLUDED — the marker, then reasons from
#     the closed enum. AMBIGUOUS — the marker, then two or more MEMBERS joined by the set
#     separator. A set is DECLARED by its marker and is never inferred from a parse failure:
#     two code spans in one cell with no marker is a hard failure (B6), so the accident and
#     the intent are different outcomes rather than the same one.
#
#     A MEMBER is one of two kinds, dispatched in that order and disjoint by construction.
#     A DISPOSITION member carries the exclusion marker and exactly one reason from the same
#     closed enum; a UNIT member is a FULL-KEY code span matching the UNCHANGED cell grammar.
#     The dispatch tests the disposition marker FIRST, on a marker the member carries, so a
#     disposition is DECLARED rather than read off a failed CELL_RE match — the same "declared,
#     never inferred" property the set itself has. The two kinds cannot overlap: a CELL_RE
#     match opens with a backtick and the disposition marker opens with 'E'. A set whose
#     members are ALL dispositions is refused (B8): a row that routes to no command is an
#     exclusion with prose, not a choice.
#
#     The identity is restated by NARROWING ITS QUANTIFIER, not by weakening its predicate.
#     K2 and K3 read ADDRPARTS records only and their code is untouched: a set's unit
#     members travel on AMBPARTS and its disposition members on a third channel, DISPPARTS,
#     which neither K2's nor K3's `case` arm reads. So a unit covered twice BY ADDRESSED CELLS is still K3, byte for
#     byte the detector that shipped before the class existed; a unit reachable ONLY through
#     a set is still K2, because set membership never satisfies totality; and a unit named
#     in a declared set BESIDE its own ADDRESSED cell is a CHOICE, not a double cover. The
#     tolerance is therefore STRUCTURAL — it lives in which record a member travels on —
#     rather than a branch inside K3 that a later slice could widen.
#
#     COVERAGE, and why this CONTAINS the retired assertion rather than weakening it.
#     A verbed cell covers exactly the pair it names. A verbless cell covers every
#     declared verb of its command — and, where a command declares NO verb, the command
#     itself. That last clause is what preserves the degeneracy argument: at zero declared
#     verbs every coverage unit is a command, every cell is verbless, and K1/K2/K3
#     collapse TERM FOR TERM into the retired forward / reverse / injectivity. The retired
#     assertion is the zero-verb special case of this one. The door against a VANISHED
#     requirement table is V0, which fires per file and never degrades, so the fallback
#     cannot hide a table that disappeared.
#
#     WHAT THE FALLBACK IS REACHABLE ON. NOT "a file that legitimately declares a table
#     with no rows" — that state is precisely what V0's ZERO-ROWS clause forbids, so it is
#     neither legitimate nor green. Every path to a file that emits no declaration emits a
#     finding on the way: A0 where the file is unreadable; V0's ANCHOR clause where the
#     requirement-table header row is not unique at fence depth 0; V0's ZERO-ROWS clause
#     where that header row has no rows beneath it; V1 where every row fails the field
#     count or declares an empty identity; X2 where every identity carries whitespace. The
#     fallback therefore contributes a coverage unit only on a run that is ALREADY RED. It
#     is a degeneracy this guard REPORTS, never one it can pass through. Arm GZV builds the
#     zero-verb world and checks both halves on it — that the collapse holds there, and
#     that the world is red. This replaces an earlier sentence that named the branch
#     reachable on a legitimate empty table; the code that sentence justified is unchanged
#     and the zero-rows clause is intact. What fell was the justification, not the repair.
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
#   Q   the GRANT TABLES — each row paired with an allowed-tools entry, each entry with a row
#       (group Q). A separate reader from F's TOOL-GRANT class, which classifies a body-table
#       grant token and compares nothing
#     Q0 a table whose header carries a Grant-stemmed column or the Use column and is not the
#        derivation key, the key with no delimiter row, or a graded verb's allowed-tools value
#        continued onto a following line · Q1 a grant-table row naming no allowed-tools entry
#        of its verb · Q2 an allowed-tools entry of a graded verb that no grant-table row names
#
#   R   the DECLARED read-only key set and its membership-delta sentinel   (group R)
#     R1 a fenced invocation of ANY engine script in a read-only region · R2 sentinel fired
#        R1 carried a second, pre-execution limb until the carrier it tested was retired
#        corpus-wide, leaving it quantifying over a permanently empty population. It was
#        retired rather than kept as a green establishing nothing. Its successor is group I
#        below, which grades every verb file and the carrier rather than the read-only regions
#        alone. The suite this line named as the successor before does not catch such a line —
#        a plant in a read-only region and a plant in the carrier each left it green.
#
#   I   the RETIRED PRE-EXECUTION CARRIER stays retired                      (group I)
#     I1 a line opening with a bang and a backtick at fence depth 0, in a verb file or in the
#        guided-entry carrier at the engine root
#
#   C   THE INFERENCE LINE — the entry-class marker joined to the source it states (group C)
#     C0 population, the three component counts, and the recogniser's own three arms
#     C1 THE JOIN — side(unit) derived from the verb's own read-declaration block must equal
#        the marker § Step 1 renders, as a set difference empty in BOTH directions
#     C2 a retained arm standing behind neither a confirm gate DECLARED in its own
#        read-declaration block nor the typed-only posture
#     C3 the PER-LIMB REPORT — never fails on its counts; it is what keeps C2 readable, by
#        naming a limb VACUOUS when it carried zero arms
#     C4 TOTALITY — every coverage unit resolves to exactly one side
#     C5 the standing confirm rule is PRESENT in every verb file and stated alike, read from the
#        files' own text — PRESENCE ONLY: the rule is dormant, and C5 says nothing of behaviour
#     C6 SET COMPOSITION — the same line quantified over a declared set's MEMBERSHIP rather than
#        over an arm. A disposition member declares nothing, so under ADR-007 § 1's fail-closed
#        rule it retains declared intent and the set with it; a set carrying one therefore names
#        at least one unit member that retains it too. What is refused is the set whose readings
#        DISAGREE — all units admitted beside a disposition — which was authorable with every
#        assertion in this file green
#
#   L   the LANDING SURFACE — the guided-entry carrier at the engine root      (group L)
#     L1 the carrier names a verb token · L2 it carries disable-model-invocation
#     L3 it does not declare all three negatives
#     The carrier sits OUTSIDE the verb directory every other per-file group globs, which is
#     why these are net-new rather than an extension of an existing group's quantifier.
#
#   S   the charter's two enumerations of the verb set agree               (group S)
#     S1 a key in one enumeration and not the other · S2 SINGLE-SOURCE
#
#   H   the PICKER SURFACE — what a reader is shown before they read a file (group H)
#     H1 a RESOLVE-role file declares no argument-hint · H2 a hint names a token the
#     file does not declare (a bare placeholder is the degenerate case) · H3 a hint
#     omits a declared verb AND the description points at no reference · H4 the command
#     reference is absent, unreadable, or its derived-region markers are not unique ·
#     H5 the derived region disagrees with the live requirement tables
#
#     WHAT THIS GROUP GRADES, AND WHAT IT DELIBERATELY DOES NOT. It grades VERB-SET
#     AGREEMENT between a hint and its file, and the TOTALITY of the reference doc's
#     derived region. It does NOT grade LENGTH. The rendering budget is a property of a
#     CLI this repository does not own, does not version and cannot pin, so a committed
#     length constant would be an assertion about someone else's release with no owner
#     here — it would go stale silently and fail for a reason no contributor could act
#     on. Front-loading a hint so its visible prefix is the useful part is therefore an
#     AUTHORING rule, carried in the reference doc, and not an assertion. The residual
#     is named rather than closed: a hint whose SET is right and whose ORDER has rotted
#     passes this group.
#
#     H1/H2/H3 are scoped by the ROLE record the charter already emits, never by a
#     filename test. A CREATE-role file's "verb" is a branch label rather than a typed
#     token, so verb-enumeration rules do not apply to it and the discriminator is the
#     repo's own declaration rather than one invented here.
#
#     H4 and H5 have NO SKIP PATH. An absent reference doc is an A0-class FAIL, not a
#     vacuous pass: GUARD_EXPECTED_SKIPS is empty by design, and declaring this group as
#     an expected skip would convert a red into a silent pass over an unshipped surface.
#
#   TD  a verb declaring the roster block as a read disposes of the count in it
#                                                                          (group TD)
#     TD0 population, region coverage, and BOTH matchers' sensitivity + specificity arms
#     TD1 a verb declares `## Group` in its own read line and never says what it does
#         with `- **Total travelers:**`. Graded OUTSIDE the read declaration, because
#         naming a field among a cited read's purposes is not discharging it — which is
#         the defect that paid for the group. It grades that the question is ANSWERED,
#         never which answer is taken.
#   J   every file an agent writes is named in its agent-roster row         (group J)
#     J0 the join cannot be measured — the roster header, a roster row, the § 1.1 class
#        table, its declared count or a prompt's writer id is absent, ambiguous or unread
#     J1 a file an agent writes — as § 1.1's W column assigns it, or as the agent's own
#        prompt declares it in a frontmatter block or an Output heading — is not named in
#        that agent's roster row
#     J2 a roster row joins to a writer id that no § 1.1 W cell names
#   G   controls: must-NOT-fire arms first, the two live differential arms, one must-fire
#       arm per emittable id, the grammar control, the derivation mutation pair, and GZV —
#       the ZERO-VERB world, which exercises the collapse argument above and is the only
#       arm reaching V0's zero-rows clause
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
# green here is not a privilege guarantee. What a `disallowed-tools` line does is SETTLED:
# ADR-007 § 1's 2026-09-11 amendment arbitrated it against the published contract — the
# named tools leave the pool for the turn that invoked the file and return at the next
# message, and a restriction that has to outlive the turn is a permission-settings deny
# rule. This guard does not restate that account as an assertion and needs no position on
# it: every assertion below is about what a file DECLARES and none is about what a
# declaration enforces, so each holds whatever the runtime does. Whether anything in this
# repository READS such a line is not claimed here in either direction — this guard does
# not scan for a reader, so it has no evidence to offer and offers none.
#
# OUT OF SCOPE — PROSE-RENDERED INVOCATIONS. Where a command file renders an invocation
# as prose across a hard wrap, with a forbidden flag named inside a NEGATING sentence in
# the same paragraph, no per-line, per-paragraph or whole-section literal scan separates
# use from mention. The flag and arm limbs reach the FENCED rendering only. That is a
# declared uncovered region, not an omission, and this guard prints the count of
# invocations it attributed so a reader can see what it did and did not reach.
#
# OUT OF SCOPE — PER-VERB ARM BINDING. That verb A does not invoke verb B's granted arm
# is a rule a file follows, not a property this guard can derive: of the surfaces this
# guard reads — the charter, the command files, ADR-007 and the publish script — none
# carries a per-verb arm source, and this guard looks for one nowhere else. Declared as a
# residual rather than checked by something that pretends to.
#
# ── THE VACUITY DOORS, AND THE THIRD ONE ─────────────────────────────────────────
# GUARD_STRICT_SKIPS closes the door where a GROUP vanishes. This suite reads the repo,
# so it has doors that mechanism does not watch: a POPULATION vanishing. Group A closes
# three — the Step-1 slice, the command directory, and the COVERAGE-UNIT enumeration that
# K quantifies over — and its verdict is FAIL, never SKIP: a missing input IS the failure,
# not the absence of evidence about one. GUARD_EXPECTED_SKIPS is correctly EMPTY: this
# suite has no dependency-gated group, so every skip fails the run.
#
# There is exactly one SKIP call site, and it is B5's zero-dotted-cell branch. That is a
# POPULATION vacuity, not a dependency gate, so it is correctly UNDECLARED and correctly
# fails a strict run: an unexercised widening obligation is a gap, not a legitimate skip.
# It is also what makes the strict-skip contract live — the helper was defined and reached
# by nothing, so the whole mechanism graded a call set that was empty.
#
# NO FROZEN DENOMINATOR. No count in this file is asserted against a literal. Every
# population is derived when it is graded and printed with its derivation rule. Three of
# the enumerations this guard HOLDS rather than derives — the publish invocation forms
# (sentinel E3), the dispatch arms (E6), and the declared read-only key set (R2) — each
# carry a live membership-delta sentinel that diffs them AS A SET, because a count holds
# while membership churns. THOSE THREE, AND NOT A CENSUS OF WHAT IS HELD: this guard also
# holds ALLOWED_SUBS, REASON_ENUM and REQ_COLS, and each of those is graded in ONE
# direction only — a live value must be a member of the held set, while a held value that
# has gone dead on the live surface is not detected. That is a stated residual, not
# coverage.
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
# subject S, removing S must flip X specifically. Group Q's three verdicts are the first
# assertions this suite registers — see the registration block at the end of group MD, which
# also says why the pre-existing declared residual stays unregistered until it is remediated.
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
  'rotate' 'rotate --passphrase' 'unpublish' 'confirm'
)

# main()'s dispatch arms, excluding the '*)' catch-all. Diffed as a SET in both
# directions: an arm added AND an arm removed is a membership change a count would miss.
EXPECTED_ARMS=( 'publish' 'update' 'confirm' 'rotate' 'list|status' 'unpublish' '-h|--help|help|""' )

# Subcommand tokens a delivered command file may invoke.
ALLOWED_SUBS=( 'list' 'status' 'update' 'unpublish' )

# The DECLARED read-only key set, and the verb set of its command as adjudicated when the
# set was last decided. This guard derives no live predicate for "reads and does not
# write" from the surfaces it reads: the read declaration is a total body-line convention
# while the write one is not, so the set cannot yet be derived here. It is therefore
# declared, and sentinel R2 makes it DETECTED-stale rather than silently stale. Its
# LIVE non-vacuity is a separate question, reported on the R1 line rather than assumed
# here — see the vacuity branches there. What re-arms it is a `**Writes:**`
# body-line contract mirroring the read one; at that point the set becomes derived and
# this holding is deleted rather than maintained.
#
# The LITERAL reading of "carries no write instruction" is NOT asserted. One read-only
# region NAMES both output paths it must not write, inside an explicit negation. A
# path-mention test red-lights that section, which is the exact defect the use-not-mention
# rule exists to prevent. The path test is declined rather than weakened into one that
# passes.
# `schema` is in the ADJUDICATED set and deliberately NOT in READONLY_KEYS. R2 is a
# set-difference sentinel in both directions, so a live verb missing from the adjudicated
# set turns this suite red — that membership is mandatory. R1's predicate is a different
# one, and it is the reason the key is withheld: R1 asserts that a declared read-only
# region carries NO EXECUTABLE INSTRUCTION, and the `schema` region carries a fenced
# invocation by design. That the invocation is of a different script — so R1's INV records,
# which are publish-script-only, cannot currently see it — is an argument AGAINST the
# declaration rather than for it. A declaration the guard happens to be unable to falsify
# is still a false declaration, and it would turn red for the right reason at the wrong
# time the moment a later slice widened INV to every script. The verb writes nothing; it
# does not follow that it executes nothing.
READONLY_KEYS=( '/trip:status' '/trip:check' )
READONLY_OF_COMMAND='/trip'
READONLY_ADJUDICATED=( 'status' 'plan' 'replan' 'reorder' 'research' 'check' 'ideas' 'site' 'schema' )

SCRIPT_REL='scripts/publish-trip-site.sh'

# ── The engine root, held as ONE literal, spelled once.
#
# Under the installable layout a verb file sits at <engine-root>/skills/<verb>/SKILL.md, so the
# engine root is the skill directory's grandparent and every engine path a verb hands to a tool
# is this token followed by the repository-relative path. The harness substitutes the variable
# before the permission check and also inside the prose body, so what a grant pattern and a
# fenced invocation carry is the same string after substitution — which is exactly why ONE
# spelling is asserted rather than assumed. A permission pattern is matched as a string: a
# second spelling of the same directory is a second string, and a rooted permit beside a bare
# prohibition is an escalation no existing check could see. Group P asserts the uniformity.
#
# It is deliberately NOT registered in NEEDLES below. That registry asserts norm(needle) ==
# needle because its needles are matched against a whitespace-COLLAPSED haystack; this token is
# only ever compared against a TRIMMED line, so the property the registry buys does not apply
# to it and registering it would assert something that is not the reason it is safe.
ENGINE_ROOT_TOK='${CLAUDE_SKILL_DIR}/../../'

# ── The command reference, and the two markers that delimit its DERIVED region.
# The document is hand-written prose around one region this guard recomputes from the
# live requirement tables and compares. The markers are held as literals here and
# registered as needles below, so a rendering that would not survive the normalisation
# applied to the haystack is a build error rather than a silent non-match; group H
# additionally asserts each is UNIQUE in the document, because a duplicated opener would
# make "the region" ambiguous and a partial match would grade the wrong bytes.
DOC_REL='reference/command-reference.md'
DOC_MARK_OPEN='<!-- command-surface: derived — regenerate by running scripts/test-command-taxonomy.sh -->'
DOC_MARK_CLOSE='<!-- /command-surface -->'

# ── The needle registry. Every literal this parser holds is asserted to round-trip its
# own normalisation — norm(needle) == needle — before it is used. A needle that fails and
# is not registered UNTRIMMED is a build error, not a runtime one, because a needle that
# does not survive the normalisation applied to the haystack cannot match what it names.
# The HAYSTACK is whitespace-collapsed where a scan needs it; the NEEDLE never is.
NEEDLES=( '### Step 1:' '### Step 2:' '**Reads:**' 'trip-contract-header'
          'population-role:' 'main()' 'allowed-tools:' 'disallowed-tools:'
          'argument-hint:' 'description:'
          "$DOC_MARK_OPEN" "$DOC_MARK_CLOSE" )
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

# verb_id <path-to-a-verb-file> — the verb's identity, derived in ONE place.
#
# Under the skill layout the identity is the verb DIRECTORY's name, never the file's: every
# verb file is named SKILL.md, so a file-basename identity resolves all five verbs to the
# single name "SKILL" and every per-verb assertion in this suite silently collapses onto one
# key. That is a PASSING failure — the joins still find a match, they just all find the same
# one — which is why the derivation is a named function with one definition rather than an
# expression repeated at each site. A later slice adding a verb inherits it by calling it.
verb_id() { local d="${1%/*}"; printf '%s' "${d##*/}"; }

# strip_engine_root <trimmed-line> — removes the sanctioned engine-root prefix, and ONLY that
# prefix, spelled character-for-character.
#
# It is called at the TWO sites that decide whether a fenced line is an invocation of the publish
# script — the region-attribution emitter and the classifier — so a rooted invocation is parsed by
# the same code that parses a bare one and keeps reaching F1/F2/F3 over its argv. Patching one site
# and not the other is a silent F6: the classifier would resolve the invocation while the emitter
# produced no record to attribute it to.
#
# The narrowness IS the anti-widening property, and it is what keeps the admission from becoming
# "any variable resolves". Any other prefix — a second spelling of the same directory, a local
# assignment, an alias — survives this function unchanged, fails both the invocation test and the
# prose test, and lands on F5, which this guard treats as a failure rather than a skip. Arm GF5r
# is the must-fire proof of that, and arm GF1r is its converse: a SANCTIONED root still reaches the
# privilege grading, so the admission cannot have been implemented by skipping rooted lines.
strip_engine_root() { local s="$1"; printf '%s' "${s#"$ENGINE_ROOT_TOK"}"; }

# Membership is tested ELEMENT BY ELEMENT against a haystack passed as separate arguments
# — never by joining the population into one string and matching a substring, which fails
# in BOTH directions once a key can carry a space. The call convention is to pass the
# haystack as "${ARR[@]+"${ARR[@]}"}", which is quoted and empty-safe under `set -u`.
# SCOPE: that is a convention this file FOLLOWS, not one it asserts. No assertion in this
# guard reads its own call sites, so a site added with an unquoted word-split haystack
# would not be reported here. Group Y's inventory is the one place that used the
# word-split form; it no longer does.
in_list() { local n="$1"; shift; local e; for e in "$@"; do [ "$e" = "$n" ] && return 0; done; return 1; }

is_sep() { [[ "$1" =~ ^\|[-:[:space:]|]+\|[[:space:]]*$ ]]; }

getcount() { printf '%s\n' "$1" | sed -n "s/^COUNT $2 //p" | head -1; }
# ── THE HERE-STRING IS LOAD-BEARING, NOT A STYLE CHOICE. Read this before "simplifying"
# it back into a pipeline.
#
# `grep -q` exits the instant it matches, by specification. Feeding it from a pipeline
# whose writer has not finished writing kills that writer with SIGPIPE, and `pipefail`
# — set at the top of this file — then reports the PIPELINE as failed even though the
# match succeeded. The result is a test verdict that depends on process scheduling.
#
# This was measured, not theorised: on an unchanged tree, 10 of 30 consecutive runs of
# this suite went red, on TWO different arms (GR2 x8, GX1b x2). Both are `if <test>;
# then PASS` sites, so the spurious status showed up as a false RED.
#
# Three isolations, because the first two do not explain the sites that actually failed:
#   * plain variable, payload under the pipe capacity  -> 0 of 300. Never fires.
#   * plain variable, payload OVER it                  -> 300 of 300. The transition is
#     exactly 65536 bytes: 0 of 200 at 65535, 189 of 200 at 65536, 100% above. That is
#     the pipe's capacity, and it is the same default on Linux as here.
#   * COMMAND SUBSTITUTION on the left of the pipe, payload only a few hundred bytes
#     -> 35 of 400, intermittent. THIS is the shape that shipped, and the nested
#     subshell is what makes it fire far below the capacity threshold.
# Same three under `set +o pipefail`: 0. Same three in the here-string form: 0.
#
# The polarity of THIS helper is the inverted one, and it is the dangerous half. Its
# callers read `if has_finding …; then FAIL; else PASS`, so a spurious non-zero here
# does not go red — it reports PASS on a state that carries the finding. That direction
# has never been observed and is the reason this is closed at the shape rather than at
# the two arms where it happened to surface. Arm PF1 keeps it closed.
#
# A here-string is a redirection on a SIMPLE COMMAND, not a pipeline, so `pipefail` has
# no second exit status to aggregate and there is no second process to signal. The bytes
# grep reads are identical: bash appends exactly one newline, which is what the
# `printf '%s\n'` it replaced did.
has_finding() { grep -qE "^FINDING ($2) " <<<"$1"; }
# `getcount` keeps its pipeline deliberately. It ENDS in `head`, which also exits early —
# but its exit status is never consulted: it is called inside a command substitution for its
# OUTPUT, so there is no verdict for a spurious status to corrupt. The defect is a pipeline
# whose STATUS is read, not a pipeline.
#
# ── `show` CAPS ITS LIST, AND A CAPPED LIST NOW SAYS SO. This is the count-whose-denominator-
# is-not-the-one-the-sentence-names defect — the family this suite spends its prose on —
# displaced out of prose and into tooling. `show` printed the first SHOW_CAP matches and
# stopped, silently: a world failing with sixteen findings of one id displayed eight, and a
# reader who counted the display got eight. No verdict and no pass/fail count was ever
# affected; what was affected is the EVIDENCE a failing run offers, which is the whole reason
# a reporting group prints findings at all. Measured cost, not hypothetical: one acceptance
# reviewer and one probe each read a capped list as a complete one.
#
# THE RESIDUAL IS COMPUTED FROM THE MATCHED SET, BEFORE THE CAP IS APPLIED, so the total this
# prints is the population's and never the display's — printing `SHOW_CAP + (what head let
# through)` would reproduce the same defect one level down. The cap itself is retained: the
# list is a reader's aid and an unbounded one buries the verdict lines around it.
#
# The `| head` pipeline is gone with it, which is incidental rather than the point: `head` now
# reads a here-string, so there is no writer for it to SIGPIPE and no second status for
# `pipefail` to aggregate — the shape has_finding's note above describes, arrived at here for
# a different reason. `show`'s status was never read either way; it returns 0 explicitly so
# the trailing test cannot become one.
SHOW_CAP=8
show() {
  local matched shown
  matched="$(grep -E "^FINDING ($2) " <<<"$1" | sed 's/^FINDING /       /')"
  [ -n "$matched" ] || return 0
  shown="$(grep -c '' <<<"$matched")"
  head -"$SHOW_CAP" <<<"$matched"
  if [ "$shown" -gt "$SHOW_CAP" ]; then
    printf '       … and %d more — %d finding(s) matched this id, %d shown. The list is capped; the count is not\n' \
      "$(( shown - SHOW_CAP ))" "$shown" "$SHOW_CAP"
  fi
  return 0
}

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

# ── The ambiguity-set cell class. A set is DECLARED by its marker, exactly as an exclusion
# is, never inferred from a parse failure: two code spans in one cell with no marker is a
# hard failure (B6). Members are FULL KEYS matching CELL_RE UNCHANGED — the single-target
# grammar is not widened, so ADR-007 §4's "parses under the same cell grammar" statement and
# E8 are untouched, and arm G-GR asserts both set-shaped cells are still rejected by it.
#
# The separator is the one this corpus already uses for a pure list of code spans in a table
# cell. ' + ' was declined because it already serves CONJUNCTIVE reason lists in this very
# column, and an escaped pipe was declined on a measured ground: charter_check splits rows
# with IFS='|', so a pipe inside a cell changes the field count and the row reads as B1.
AMB_MARK='AMBIGUOUS: '
AMB_SEP=' · '
# Registered as needles here rather than in the array literal above, and the ordering is
# forced rather than stylistic: the registry is declared before these constants exist, and
# naming an unset variable under `set -u` is an error. needle_check runs long after both.
NEEDLES_UNTRIMMED+=( "$AMB_MARK" "$AMB_SEP" )

# ── The DISPOSITION-MEMBER marker. The SAME literal the cell-level classifier routes an
# EXCLUDED cell on, named here so the member-level test and the cell-level test are the
# identical string comparison and cannot disagree about what the token means. One
# vocabulary for one concept in two positions: a new spelling ('NONE: ', '!') would be a
# second name for a disposition this corpus already names, and the member's reason is
# graded against REASON_ENUM rather than against a literal for the same reason — ADR-007
# §4 states the vocabulary is shared across both surfaces, so a sixth value participates
# with no grammar edit and no drift seam.
#
# DELIBERATELY NOT re-registered as a needle: 'EXCLUDED: ' is already a member of
# NEEDLES_UNTRIMMED above, so the normalisation assertion already covers this exact string
# and a second registration would assert the same fact twice under two names.
#
# ACCEPTED COST, named rather than discovered: a rendered cell reads
# 'AMBIGUOUS: EXCLUDED: <reason> · `/verb`', which is two markers in one cell and is
# genuinely awkward to read. The readability is traded for the single vocabulary.
DISP_MARK='EXCLUDED: '
# Reasons are conjoined on a row by ' + ' — independent GROUNDS for one exclusion. As a
# MEMBER the token names WHICH OPTION the reader is picking, and a conjunction of grounds
# is not a distinguishable option, so a member carrying this separator is B8.
DISP_CONJ=' + '

# ── The ENTRY-CLASS marker. A RENDERING, not a third vocabulary: the two tokens are
# uppercase spellings of ADR-007 § 1's own `inference-admitted` and of its declared-intent side,
# and the charter records the class rather than deciding it. What B7 grades is that an ADDRESSED
# row CARRIES one — never that the token equals the derivation over the verb sections.
#
# THAT SECOND CLAIM IS NOW MADE, by C1, and the division of labour between the two is the point:
# B7 grades that a marker is THERE and in the right field, C1 grades that it is RIGHT. Between
# them there is no gap — a row with no marker is B7, a row whose marker contradicts its source is
# C1 — and neither subsumes the other, because a correct marker in the wrong field still fails B7
# and a well-formed marker on the wrong side still fails C1.
#
# It is read from FIELD 3, the Action cell, and the field index is the whole of the test: arm GB7
# plants a correctly-spelled marker in the EXAMPLE cell of an ungraded row, so a row-wide scan
# passes that arm and a field-indexed one fails it. Registered UNTRIMMED for the same reason the
# exclusion marker is — each prefix ends in a space and cannot round-trip its own normalisation.
GRADE_ADMIT='**INFERENCE-ADMITTED**'
GRADE_RETAIN='**DECLARED-INTENT**'
GRADE_SEP=" ${EMDASH} "
NEEDLES_UNTRIMMED+=( "${GRADE_ADMIT}${GRADE_SEP}" "${GRADE_RETAIN}${GRADE_SEP}" )

# ── THE THREE NEGATIVES — the SOURCE side of the join group C performs.
#
# ADR-007 § 1's rule is fail-closed and is quoted here as it is written: all three declared
# admits the arm; anything else, INCLUDING an arm that declares none of them, retains declared
# intent. A property nobody has declared is not one this rule may assume, so the third limb is
# STRICT — it must be declared — and is never read as absent-unless-contradicted.
#
# THE THIRD LIMB IS AN EFFECT PREDICATE, NOT A RUNS-NO-SCRIPT ONE, and that distinction decides
# the admitted set rather than decorating it. § 1 states it as "performs no act whose effect
# lands outside the trip's own files". Measured over the live blocks both ways: the effect
# formulation admits FIVE arms, the runs-no-script reading admits ONE. A guard built on the
# narrow reading would grade a corpus that declares its negatives in the record's own words and
# call four of them undeclared.
#
# ONLY THE EFFECT FORMULATIONS ARE CARRIED. "Runs no script", "invokes no script" and "reaches no
# network" are each narrower than the effect predicate, so a block saying only one of them has not
# declared the third negative, and under a fail-closed rule an undeclared negative retains the arm.
# The recogniser carried them once, and that was the superseded reading living on in the code
# after the prose above had retired it: a block declaring writes-nothing and dispatches-no-agent
# beside "runs no script", with no effect clause at all, was ADMITTED. C0's no-effect arm is that
# block, and it must derive the first two limbs and not the third.
#
# The alternation is a RECOGNISER for declarations the corpus actually writes, and it is a lower
# bound by construction: a negative spelled some other way reads as undeclared and RETAINS the
# arm, which is the safe direction under a fail-closed rule. C0 prints all three component counts
# so a reader re-derives the admitted set without trusting this recogniser.
#
# TOKEN-BOUNDED, both edges, and the leading edge is the one that matters: without it the
# writes-nothing limb reads a longer word ending in its first word — "overwrites nothing" — as
# the negative, which is the unsafe direction, because it would ADMIT. C0's specificity arm
# carries exactly that near-miss. The boundary is a non-letter or the end of the text; neg_norm
# has already lowercased what it tests, so no capital can stand in for a letter here.
NEG_W_RE='(^|[^a-z])writes? (nothing|no byte|no line)([^a-z]|$)'
NEG_D_RE='(^|[^a-z])dispatch(es)? no agent([^a-z]|$)'
NEG_O_RE='(^|[^a-z])(performs no act whose effect lands outside|acts? nowhere outside|no effect (that lands )?outside)([^a-z]|$)'

# ── The CONFIRM DECLARATION — the arm-scoped limb of C2's obligation, and a DECLARATION rather
# than a mention. The gate is declared inside the arm's own read-declaration block, by the form
# below, and that block is the only place this limb reads: the same block, bounded the same way,
# that C0 reads the three negatives from.
#
# WHY THE LIMB NO LONGER SCANS THE REGION. It used to match the bare phrase anywhere in an arm's
# region, and a region can MENTION the confirmation without standing behind it — two live arms
# say in terms that their path returns BEFORE the typed confirmation, and both were counted as
# gated. A count that cannot tell a use from a mention is the failure this suite exists to
# refuse, so the limb now reads a declaration and nothing else. Two properties, each armed by
# GC3b: SCOPE — a gate-shaped sentence outside the block is not a declaration; and SHAPE — a
# sentence inside the block that names the confirmation without standing the arm behind it
# ("returns before the typed confirmation") is not one either.
#
# It is deliberately a CLOSED LIST of declared forms rather than a loose match on the word
# "confirm": that word appears on more than sixty lines across these files, nearly all of them
# describing a read taken to confirm a file exists. Token-bounded on both edges, matched over the
# block after neg_norm. C3 reports what the limb actually carries, so its emptiness is a
# measurement rather than a hidden default. Residual, stated: a block that NEGATES a form
# ("nothing here stands behind…") matches it — the same limit every phrase recogniser in this
# group has, and the reason the forms live in the one block that exists to declare.
#
# WHY THE CLASS IS FOUR SHAPES AND NOT ONE. It credited the typed confirmation alone, and over all
# 37 arms exactly one arm declares one — while others carry a confirmation of a different shape on
# their own path. The class was widened by operator decision to the shapes the corpus names, on the
# ground that the per-limb report is evidence for this release's central criterion and evidence
# describing a confirmed arm as unconfirmed is wrong in the direction that matters. ALL FOUR names
# below are the CORPUS'S OWN: the standing confirm rule each verb file states names an echoed
# outgoing-to-incoming pair, a preview over a source's own answered set, a typed identifier and a
# display name beside a member count — those four and no other — and C5 grades that rule's
# presence in all five files. So the class is read off the rule rather than invented here. TWO
# departures from the rule's wording are deliberate and are stated rather than left to be found:
# the typed shape keeps the spelling the limb already shipped ("a typed confirmation" rather than
# the rule's "a typed identifier"), because changing it would rewrite a live declaration for no
# verdict; and the preview shape drops the rule's possessive ("a preview over the answered set"),
# because an apostrophe inside this single-quoted pattern buys a quoting seam for no
# discrimination.
#
# WHY IT IS NOT FIVE, AND THE TWO GATED ARMS IT DOES NOT CREDIT. A fifth shape, "a gated branch",
# was credited and then dropped by operator decision: it is not one of the rule's four, and the one
# declaration it matched stands only part of its arm behind the gate, which a count stated as a
# lower bound on gated arms cannot credit. So two arms that DO gate are not credited — one of them
# never was — and both are named here so the residual is read rather than rediscovered. `link`
# declares a gate on two of its paths — the repoint, and a non-empty survey — and where the survey
# is empty it writes with no confirmation at all; its declaration is accurate and stays in its own
# block, and it is simply not a whole-arm gate. `group-expand` gates before its first write on
# every path, with one confirmation over its consolidated member preview, but that is not a shape
# the rule enumerates and its own block declares none. While their file carries the typed-only
# posture, C2 is satisfied for both by that limb and C3 counts both there; widening the class to
# reach either is a separate ruling, not an edit to this list. Residual, stated: the recogniser
# reads WHICH shape a declaration names, never HOW MUCH of its arm stands behind it, so a
# declaration placing only some of an arm's paths behind one of these four would still be
# counted. None of the four live declarations does — each stands its arm's whole act behind its
# gate — and that, not the recogniser, is what keeps C3's lower bound true.
#
# THE LIST IS THE RECOGNISER'S ONLY SOURCE. The pattern is BUILT from the array below rather than
# spelled beside it, so the class a reader can enumerate and the class the limb matches cannot
# disagree. GC3c walks the same array and requires every member to be admitted behind the stem;
# GC3d requires none of them to be admitted WITHOUT it, which is the declaration-versus-mention
# boundary re-armed once per shape rather than once for the list.
CONFIRM_SHAPES=( 'a typed confirmation'
                 'an echoed outgoing-to-incoming pair'
                 'a preview over the answered set'
                 'a display name beside a member count' )
confirm_alt() { local a='' s; for s in "${CONFIRM_SHAPES[@]}"; do [ -n "$a" ] && a="$a|"; a="$a$s"; done; printf '%s' "$a"; }
CONFIRM_DECL_RE='(^|[^a-z])stands? behind ('"$(confirm_alt)"')([^a-z]|$)'

# ── The STANDING CONFIRM RULE's LOCATOR — C5 reads, and never holds, the rule itself.
#
# Every verb file states the rule once, in its own standing-bounds section and in that file's own
# form, and its lead is a bold sentence. This literal is the rule's SUBJECT CLAUSE only — what the
# rule governs — and it is used for one thing: finding where the bold statement opens. What the
# rule REQUIRES is read from each file, up to the bold statement's close, and C5 compares the files
# with each other. So a file that states the rule differently is a finding, a file that omits it is
# a finding, and an edit that changes the rule in every file at once is not — the guard holds no
# copy of the requirement to fall out of date. A file that rewords the subject clause itself reads
# here as omitting the rule, loudly, and this is the one line to change when that is deliberate.
CONFIRM_RULE_LOCATOR='An act on a verb the operator did not type'
NEEDLES+=( "$CONFIRM_RULE_LOCATOR" )

# neg_norm <text> — the normalisation both the block scan and its control arms apply.
# Emphasis markers, code-span backticks and underscores are stripped and whitespace is collapsed
# BEFORE matching, because the corpus carries inline emphasis inside these sentences: a declaration
# rendered "**writes nothing**" and one rendered "writes nothing" are the same declaration.
neg_norm() { local s="$1"; s="${s//\*/}"; s="${s//$BT/}"; s="${s//_/}"; lower "$(collapse "$s")"; }

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

  # --- the TYPED-ONLY posture, the file-scoped half of C2's obligation.
  # BOTH limbs are required and the conjunction is the point: the frontmatter flag withholds the
  # file from the model, and the standing clause says the verb is the one the user typed. Either
  # alone is a weaker claim than the posture C2 accepts — a flag with no clause leaves the file
  # silent on where a verb comes from, and a clause with no flag is a sentence the runtime never
  # reads. A CREATE-role file takes an argument rather than a verb, so it carries no such clause
  # and is expected to fail this test; C2 quantifies over the DECLARED-INTENT side, and C3 reports
  # which limb carried each arm, so a file resting on neither is visible rather than assumed.
  local posture='-' has_flag=0 has_clause=0 pnorm i
  for (( i=0; i<n; i++ )); do
    [ "$(trim "${L[$i]}")" = 'disable-model-invocation: true' ] && has_flag=1
    [ "${FD[$i]}" -eq 0 ] || continue
    pnorm="$(neg_norm "${L[$i]}")"
    case "$pnorm" in *'the verb is the one the user typed'*) has_clause=1 ;; esac
  done
  # Three values rather than two: TYPED is both halves; FLAG is the frontmatter flag with no
  # clause, which is the whole posture for a CREATE-role file and half of it for any other; '-'
  # is neither. inference_check applies the role scope, so this record states what the file
  # carries and leaves the question of what suffices to the one function that knows the role.
  if [ "$has_flag" -eq 1 ] && [ "$has_clause" -eq 1 ]; then posture='TYPED'
  elif [ "$has_flag" -eq 1 ]; then posture='FLAG'; fi
  printf 'POSTURE %s %s\n' "$cmd" "$posture"

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
    # The ROW record carries the four REMAINING requirement-table columns, so the
    # command reference is derived from THIS parser rather than from a second one. A
    # second verb extractor is a second place for the silent plausible zero the banner
    # describes to be reborn, which is why the columns are emitted here instead. The
    # fields cannot contain a pipe: they were produced by splitting on one.
    printf 'ROW %s|%s|%s|%s|%s|%s\n' "$cmd" "$ident" \
      "$(trim "${F[2]//$BT/}")" "$(trim "${F[3]//$BT/}")" \
      "$(trim "${F[4]//$BT/}")" "$(trim "${F[5]//$BT/}")"
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
      # The ARGUMENT SIGNATURE, which is the remainder of the heading the first-token
      # matcher just split. It is emitted from the SAME split that resolves the region,
      # so the signature and the region can never disagree about where the verb ends.
      # This is the column G-D4's differential already measures the existence of.
      printf 'SIG %s|%s|%s\n' "$cmd" "$first" "$(trim "${SH[$i]#"$first"}")"
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
  #
  # The same walk emits the NEG record — the per-arm SOURCE side of group C's join. The block
  # boundary is the one #614 pinned: the read-declaration line through to the next blank line.
  #
  # ONE BLOCK PER REGION, AND THE FIRST, which is a correctness requirement rather than a
  # convenience. A region may carry the read-declaration token at column 0 more than once, and the
  # second occurrence is not always a second declaration: one live region opens a SENTENCE with the
  # token, referring to its own declaration in prose. Counting every occurrence conflates a USE with
  # a MENTION — it inflates the denominator by one and adds a phantom arm that declares no negative.
  # Taking the first per region is what makes the population the ARMS rather than the occurrences.
  # READS_<short> below still counts every occurrence, because V4's question is about occurrences.
  local owner reads_n=0 unclaimed_n=0 bi bend blk
  local -a NEGSEEN=()
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
      continue
    fi
    in_list "$owner" "${NEGSEEN[@]+"${NEGSEEN[@]}"}" && continue
    NEGSEEN+=( "$owner" )
    blk=""; bend=$i
    while [ "$bend" -lt "$n" ] && [ -n "$(trim "${L[$bend]}")" ]; do
      blk="$blk ${L[$bend]}"; bend=$((bend+1))
    done
    blk="$(neg_norm "$blk")"
    bi=0
    [[ "$blk" =~ $NEG_W_RE ]] && bi=$((bi+4))
    [[ "$blk" =~ $NEG_D_RE ]] && bi=$((bi+2))
    [[ "$blk" =~ $NEG_O_RE ]] && bi=$((bi+1))
    printf 'NEG %s %s %d\n' "$cmd" "$owner" "$bi"
    # The CONFIRM record — the ARM-scoped half of C2's obligation, read from the arm's OWN
    # read-declaration block, the same normalised block the three negatives were just read from.
    # Per arm, so one destructive arm never inherits a neighbour's gate; and from the block alone,
    # so a sentence elsewhere in the region that mentions the confirmation — including one saying
    # the arm's path returns before it — is never read as the arm standing behind it.
    [[ "$blk" =~ $CONFIRM_DECL_RE ]] && printf 'CONFIRM %s %s\n' "$cmd" "$owner"
  done
  printf 'COUNT READS_%s %d\n' "$short" "$reads_n"
  printf 'COUNT UNCLAIMED_%s %d\n' "$short" "$unclaimed_n"

  # --- the STANDING CONFIRM RULE, read in this file's own words (C5's source) ---
  #
  # A paragraph is a maximal run of non-blank lines at fence depth 0, joined and whitespace-
  # collapsed so a hard wrap cannot split the statement. Where one carries a bold statement opening
  # with the locator, the statement is read up to its closing emphasis marker — the locator is the
  # only part held, and the rest is the file's own text. Emphasis is KEPT here, unlike neg_norm,
  # because the bold span is what bounds the statement. The glob is a fork-free pre-filter.
  local pbuf='' pcol rrest
  for (( i=0; i<=n; i++ )); do
    if [ "$i" -lt "$n" ] && [ "${FD[$i]}" -eq 0 ] && [[ "${L[$i]}" =~ [^[:space:]] ]]; then
      pbuf="$pbuf ${L[$i]}"; continue
    fi
    case "$pbuf" in
      *'**'*'confirmation'*)
        pcol="$(collapse "$pbuf")"
        while [[ "$pcol" == *"**${CONFIRM_RULE_LOCATOR}"* ]]; do
          rrest="${pcol#*"**${CONFIRM_RULE_LOCATOR}"}"
          printf 'RULE %s %s\n' "$cmd" "$(trim "${CONFIRM_RULE_LOCATOR}${rrest%%\*\**}")"
          pcol="$rrest"
        done ;;
    esac
    pbuf=''
  done

  # --- invocation records, attributed to the containing region ---
  #
  # TWO RECORD TYPES, deliberately not one widened type. INV is the publish script's invocation
  # and nothing else: group F consumes it for owner lookup and F1/F2/F3 grade its subcommands, so
  # a record naming any other script would put non-publish invocations into a population three
  # assertions read. ANYINV is ANY engine script invoked on a fenced line, and it is read by the
  # read-only limb alone — a region declared read-only runs no script at all, not merely not the
  # publish one. A publish invocation therefore emits both, which is correct: it is both.
  #
  # THE PRE-EXECUTION RECORD IS RETIRED FROM THIS LOOP. It used to emit one for a line opening
  # with a bang and a backtick at fence depth 0. That carrier was retired corpus-wide — the
  # charter states there is no pre-execution status left to abort anything — and measured across
  # every tracked markdown file the population is zero. Its only consumer was a read-only limb
  # quantifying over it, so that limb could establish nothing. A reintroduced line is caught by
  # group I, whose preexec_check reads every verb file AND the carrier at the engine root, which no
  # region-attributed record here could reach: the question is whether the line exists at all, not
  # which region owns it.
  local t
  for (( i=0; i<n; i++ )); do
    owner='-'
    for (( j=0; j<${#RV[@]}; j++ )); do
      if [ "$i" -gt "${RS[$j]}" ] && [ "$i" -lt "${RE_[$j]}" ]; then owner="${RV[$j]}"; break; fi
    done
    [ "${FD[$i]}" -eq 1 ] || continue
    t="$(trim "${L[$i]}")"; t="${t#\$ }"; t="${t#./}"; t="$(strip_engine_root "$t")"
    if [ "$t" = "$SCRIPT_REL" ] || [[ "$t" == "$SCRIPT_REL "* ]]; then
      printf 'INV %s %s %d %s\n' "$cmd" "$owner" $((i+1)) "$(trim "${t#"$SCRIPT_REL"}")"
    fi
    if [[ "$t" =~ ^scripts/[A-Za-z0-9_.-]+\.sh([[:space:]]|$) ]]; then
      printf 'ANYINV %s %s %d %s\n' "$cmd" "$owner" $((i+1)) "${t%%[[:space:]]*}"
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
    # left-trim in pure bash: this runs once per line of the whole surface, so a
    # command substitution here would fork thousands of times for nothing
    t="${line#"${line%%[![:space:]]*}"}"
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
    printf 'COUNT S1_ROWS 0\nCOUNT S1_ADDR 0\nCOUNT S1_AMB 0\nCOUNT S1_EXCL 0\nCOUNT S1_GRADED 0\nCOUNT S1_ADMITTED 0\nCOUNT S2_KEYS 0\nCOUNT CONS_ROWS 0\nCOUNT DOTTED 0\nCOUNT UNWIDENED_FAIL 0\n'
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

  local n_rows=${#R1[@]} n_addr=0 n_excl=0 n_amb=0 n_dot=0 n_unwid=0 n_graded=0 n_admit=0
  if [ "$n_rows" -eq 0 ]; then
    printf 'FINDING A0 the Step-1 slice is empty or absent — no data rows extracted\n'; rc=1
  fi

  local row cell inner rt cmdpart verbpart key rest r
  # Declared in their own statement, never beside a name they reference: every word of a
  # `local` builtin is expanded BEFORE the builtin runs, so a same-statement back-reference
  # takes the OUTER value or trips `set -u`. The convention this file already follows.
  local amb_rest amb_m amb_bad act_cell
  # The disposition-member accumulator is its OWN variable rather than a second use of
  # amb_bad, because its findings carry a different id: B6 is "this is not a member", B8
  # is "this IS a disposition member and its reason is wrong". Folding them would make the
  # id depend on which predicate happened to append last.
  local disp_bad disp_r n_unit_m n_disp_m
  local -a F=() SEEN=() AMBM=() AMBU=() AMBD=()
  for row in "${R1[@]+"${R1[@]}"}"; do
    IFS='|' read -r -a F <<< "$row"
    if [ "${#F[@]}" -ne 6 ]; then
      printf 'FINDING B1 MALFORMED Step-1 row — expected 5 columns (6 pipe fields), got %d: %.60s\n' "${#F[@]}" "$row"; rc=1; continue
    fi
    cell="$(trim "${F[5]}")"

    # ── The AMBIGUITY-SET class, routed on its marker exactly as the exclusion below is.
    # Members are graded by the UNCHANGED cell grammar, one per member, so the third class
    # reuses the single-target form rather than widening it. A malformed set is B6 and
    # `continue`s WITHOUT emitting AMBPARTS, so K4/K5 never quantify over a cell whose
    # members did not parse — but n_amb is already incremented, so B4's arithmetic still
    # accounts for the row rather than reporting a silent gap beside a named failure.
    if [[ "$cell" == "$AMB_MARK"* ]]; then
      n_amb=$((n_amb+1))
      AMBM=()
      amb_rest="${cell#"$AMB_MARK"}"
      while : ; do
        if [[ "$amb_rest" == *"$AMB_SEP"* ]]; then
          AMBM+=( "${amb_rest%%"$AMB_SEP"*}" ); amb_rest="${amb_rest#*"$AMB_SEP"}"
        else AMBM+=( "$amb_rest" ); break; fi
      done
      amb_bad=""; disp_bad=""; n_unit_m=0; n_disp_m=0; AMBU=(); AMBD=()
      [ "${#AMBM[@]}" -ge 2 ] || amb_bad="it declares ${#AMBM[@]} member(s); a set names two or more, because a choice between one thing and nothing is not a choice"
      # ── MEMBER DISPATCH. The disposition test comes FIRST and keys on a marker the member
      # CARRIES, so a disposition is declared rather than inferred from a CELL_RE failure —
      # the same property the set itself has. The two kinds are disjoint by construction: a
      # CELL_RE match opens with a backtick, this marker opens with 'E'. A member reaching
      # neither arm is B6, exactly as it was before this branch existed.
      for amb_m in "${AMBM[@]}"; do
        if [[ "$amb_m" == "$DISP_MARK"* ]]; then
          n_disp_m=$((n_disp_m+1))
          disp_r="$(trim "${amb_m#"$DISP_MARK"}")"
          AMBD+=( "$disp_r" )
          if [ -z "$disp_r" ]; then
            disp_bad="${disp_bad:+$disp_bad; }a disposition member carries the marker and no reason"
          elif [[ "$disp_r" == *"$DISP_CONJ"* ]]; then
            disp_bad="${disp_bad:+$disp_bad; }disposition member \"$disp_r\" conjoins reasons; on a ROW conjoined reasons are independent grounds, but as an OPTION a member names which one the reader is picking and a conjunction is not a distinguishable option"
          elif ! in_list "$disp_r" "${REASON_ENUM[@]}"; then
            disp_bad="${disp_bad:+$disp_bad; }disposition member reason \"$disp_r\" is not in the closed five-value enum"
          fi
          continue
        fi
        if [[ "$amb_m" =~ $CELL_RE ]]; then
          n_unit_m=$((n_unit_m+1)); AMBU+=( "$amb_m" ); continue
        fi
        amb_bad="${amb_bad:+$amb_bad; }member \"$amb_m\" is neither a single-target cell under the cell grammar nor a declared disposition"
      done
      # A set offering no verb at all routes nowhere. That is an EXCLUDED row with prose
      # rather than a choice, and refusing it closes the one hole this widening could
      # otherwise open: a row that passes every check and dispatches nothing. Conservative
      # on purpose — a later slice can relax this far more cheaply than it could tighten it.
      if [ "$n_disp_m" -gt 0 ] && [ "$n_unit_m" -eq 0 ]; then
        disp_bad="${disp_bad:+$disp_bad; }every member is a disposition, so the row offers no command at all; a choice that routes nowhere is an exclusion rather than a set"
      fi
      if [ -n "$amb_bad" ]; then
        printf 'FINDING B6 MALFORMED ambiguity set — %s: "%s"\n' "$amb_bad" "$cell"; rc=1
      fi
      if [ -n "$disp_bad" ]; then
        printf 'FINDING B8 MALFORMED disposition member — %s: "%s"\n' "$disp_bad" "$cell"; rc=1
      fi
      # The `continue` is what keeps K4 and K5 out of a set whose members did not parse —
      # neither AMBPARTS nor DISPPARTS is emitted below it. Unchanged in force; it now
      # guards two ids rather than one.
      if [ -n "$amb_bad" ] || [ -n "$disp_bad" ]; then continue; fi
      for amb_m in "${AMBU[@]+"${AMBU[@]}"}"; do
        inner="${amb_m//$BT/}"
        cmdpart="${inner%% *}"; cmdpart="${cmdpart#/}"
        if [ "$inner" = "${inner%% *}" ]; then verbpart=""; else verbpart="${inner#* }"; fi
        printf 'AMBPARTS %d /%s %s\n' "$n_amb" "$cmdpart" "${verbpart:--}"
      done
      # ── DISPPARTS — a THIRD channel beside ADDRPARTS and AMBPARTS, not a flag on either.
      # That separation IS the K2/K3 tolerance: widening it later means adding DISPPARTS to
      # K2's or K3's `case` arm, which is a visible act, rather than relaxing a boolean.
      #
      # Two fields, read into two variables downstream, and the LAST one absorbing the
      # remainder is REQUIRED here rather than tolerated: one enum reason carries an
      # internal space, so a reason read into a non-final variable would arrive truncated.
      # The inverse of the transport warning this file states at invocation_check, for the
      # inverse reason — there the remainder would silently widen a field, here it IS one.
      for disp_r in "${AMBD[@]+"${AMBD[@]}"}"; do
        printf 'DISPPARTS %d %s\n' "$n_amb" "$disp_r"
      done
      continue
    fi

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

    if [[ "$cell" == 'EXCLUDED'* ]] || [[ "$cell" == 'AMBIGUOUS'* ]]; then
      printf 'FINDING B1 MALFORMED Command cell — a classification marker is malformed, expected the marker then a colon and a space: "%s"\n' "$cell"; rc=1; continue
    fi
    if [[ "$cell" != "$BT"* ]]; then
      printf 'FINDING B1 MALFORMED Command cell — none of the three cell classes: neither a code span, nor an exclusion marker, nor an ambiguity-set marker: "%s"\n' "$cell"; rc=1; continue
    fi

    n_addr=$((n_addr+1))
    # ── The UNDECLARED-SET guard. This shape reaches V6 without it — "the code-span strip
    # did not round-trip" — which is TRUE and misdirects the author, because the defect is
    # not a broken span but an undeclared set. Naming it here is what makes "declared, not
    # inferred" legible at the point of failure: the accident and the intent take different
    # branches, and the accident stays a hard failure.
    if [[ "$cell" == *"${BT}${AMB_SEP}${BT}"* ]]; then
      printf 'FINDING B6 UNDECLARED ambiguity set — the cell joins two or more code spans with the set separator and carries no "%s" marker; declare the set or split the row: "%s"\n' "$AMB_MARK" "$cell"; rc=1; continue
    fi
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

    # ── B7 — the ENTRY-CLASS grade, read from FIELD 3 and from nowhere else in the row.
    # ADDRESSED rows ONLY: an EXCLUDED or an AMBIGUOUS row reached its own `continue` far above
    # this line, which is the quantifier D-5 fixed — a set is a choice BETWEEN arms and is not
    # itself one, so it carries no class and is not graded for the absence of one. Arm GB7b is
    # the must-NOT-fire half of exactly that claim.
    #
    # The marker has to OPEN the cell. A cell merely CONTAINING one is not graded: the class is
    # a property of the row, so it leads, the way every other classification token in this
    # corpus's table cells leads.
    act_cell="$(trim "${F[3]}")"
    # The GRADE record is the MARKER side of group C's join, and it is emitted from THIS read —
    # the field-indexed one — rather than from a second scan of the row. One extraction, so the
    # marker C1 joins against is byte-for-byte the marker B7 graded: a second reader could
    # disagree with this one and the join would grade a marker B7 never saw.
    case "$act_cell" in
      "${GRADE_ADMIT}${GRADE_SEP}"*)  n_graded=$((n_graded+1)); n_admit=$((n_admit+1))
                                      printf 'GRADE %s %s ADMIT\n' "/${cmdpart}" "${verbpart:--}" ;;
      "${GRADE_RETAIN}${GRADE_SEP}"*) n_graded=$((n_graded+1))
                                      printf 'GRADE %s %s RETAIN\n' "/${cmdpart}" "${verbpart:--}" ;;
      *) printf 'FINDING B7 UNGRADED ADDRESSED row — the Action cell must OPEN with "%s" or "%s", and this one opens "%.40s": %s\n' "${GRADE_ADMIT}${GRADE_SEP}" "${GRADE_RETAIN}${GRADE_SEP}" "$act_cell" "$key"; rc=1 ;;
    esac
  done

  if [ $((n_addr + n_amb + n_excl)) -ne "$n_rows" ]; then
    printf 'FINDING B4 exhaustiveness — %d ADDRESSED + %d AMBIGUOUS + %d EXCLUDED does not account for %d rows; a row reached none of the three classifications\n' "$n_addr" "$n_amb" "$n_excl" "$n_rows"; rc=1
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
  printf 'COUNT S1_AMB %d\n' "$n_amb"
  printf 'COUNT S1_EXCL %d\n' "$n_excl"
  printf 'COUNT S1_GRADED %d\n' "$n_graded"
  printf 'COUNT S1_ADMITTED %d\n' "$n_admit"
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
  local rc=0 line t1 t2 t3 t4 t5
  local -a DK=() DKC=() FILES=() AK=() AKC=() AKV=() RG=() KEYS=()
  # The ambiguity-set channel, parallel-indexed like every other transport here: set
  # ordinal · command · verb-or-'-'. It is a SEPARATE channel from ADDRPARTS on purpose —
  # that separation IS the K2/K3 tolerance, so it cannot later be widened by editing a
  # predicate. Bash 3.2 has no associative arrays and a silent degradation to an empty map
  # is the shape this suite exists to refuse.
  local -a MS=() MC=() MV=()
  # The DISPOSITION channel: set ordinal · reason. A THIRD transport, for the same reason
  # AMBPARTS is a second one — K2 and K3 never read it, so a disposition can neither
  # satisfy totality nor look like a double cover, and that is a property of the reader
  # rather than of a condition inside a predicate. It is read by K5 alone.
  local -a DS=() DR=()

  # KEY is read into TWO variables deliberately: the last one absorbs the remainder, so a
  # key that carries whitespace arrives whole and X2 can see it. Every other record is
  # read into one variable per field, because there the remainder would silently widen a
  # field that a later comparison keys on.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'DECL '*)      IFS=' ' read -r t1 t2 t3 <<< "$line"; DK+=( "$t2:$t3" ); DKC+=( "$t2" ) ;;
      'KEY '*)       IFS=' ' read -r t1 t2 <<< "$line"; KEYS+=( "$t2" ) ;;
      'FILE '*)      IFS=' ' read -r t1 t2 <<< "$line"; FILES+=( "$t2" ) ;;
      'REGION '*)    IFS=' ' read -r t1 t2 t3 t4 t5 <<< "$line"; RG+=( "$t2:$t3" ) ;;
      'ADDRPARTS '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; AKC+=( "$t2" ); AKV+=( "$t3" )
                     if [ "$t3" = '-' ]; then AK+=( "$t2" ); else AK+=( "$t2:$t3" ); fi ;;
      # Four fields, read into four variables — the transport rule this file states at
      # invocation_check: the LAST read variable absorbs the remainder, so a record read
      # into fewer variables than it has fields silently widens the last one it names.
      'AMBPARTS '*)  IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; MS+=( "$t2" ); MC+=( "$t3" ); MV+=( "$t4" ) ;;
      # THREE fields read into THREE variables, and here the last one absorbing the
      # remainder is the requirement rather than the hazard: a reason may carry an internal
      # space, so the reason field is the remainder by design.
      'DISPPARTS '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; DS+=( "$t2" ); DR+=( "$t3" ) ;;
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
  # The same pass derives what the RETIRED keying would have emitted on this data. The
  # re-key from the command to the pair is thereby DEMONSTRATED on live rows rather than
  # asserted: the command-keyed comparator's collision count must strictly exceed the
  # pair-keyed one, and if the two ever converge the arm that reads this reports itself
  # as no longer differential rather than as passing. The differential is a property of
  # the DATA, not of the key rule, so it can drain away with the rule untouched.
  local c nvl nvb j cmdkeyed=0
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
    [ $((nvl+nvb)) -gt 1 ] && cmdkeyed=$(( cmdkeyed + nvl + nvb - 1 ))
    if [ "$nvl" -gt 0 ] && [ "$nvb" -gt 0 ]; then
      printf 'FINDING K3 EXCLUSIVITY — %s carries both a verbless and a verbed ADDRESSED cell\n' "$c"; rc=1
    fi
    if [ "$nvl" -gt 1 ]; then
      printf 'FINDING K3 EXCLUSIVITY — %s carries %d verbless ADDRESSED cells\n' "$c" "$nvl"; rc=1
    fi
  done

  # --- K4 / K5: the DECLARED ambiguity sets.
  #
  # NOTHING ABOVE THIS LINE CHANGED, and that is the design rather than an accident of
  # editing. K1, K2, K3 and the CMDKEYED/DBLCOVER differential read ADDRPARTS only; a set's
  # members arrive on AMBPARTS. So the tolerance for a declared choice is a property of
  # WHICH CHANNEL A MEMBER TRAVELS ON, not a branch inside an identity predicate — which is
  # what makes "K3 still catches the accident" checkable rather than promised.
  #
  # K4 computes a member's cover exactly as K1 computes an ADDRESSED cell's, so the two
  # cannot disagree about what a cell covers. No region clause is needed: K2 forces every
  # member's unit to carry its own ADDRESSED cell, and K1 already grades that cell's region.
  local mdisp mkey
  local -a SETU=() SETQ=() ALLSETS=()
  for (( i=0; i<${#MC[@]}; i++ )); do
    ncov=0; mkey=''
    in_list "${MS[$i]}" "${ALLSETS[@]+"${ALLSETS[@]}"}" || ALLSETS+=( "${MS[$i]}" )
    if [ "${MV[$i]}" = '-' ]; then
      mdisp="${MC[$i]}"
      for u in "${UNITS[@]+"${UNITS[@]}"}"; do
        case "$u" in "${MC[$i]}"|"${MC[$i]}":*) ncov=$((ncov+1)); mkey="$u" ;; esac
      done
    else
      mdisp="${MC[$i]} ${MV[$i]}"
      mkey="${MC[$i]}:${MV[$i]}"
      for u in "${UNITS[@]+"${UNITS[@]}"}"; do [ "$u" = "$mkey" ] && ncov=$((ncov+1)); done
    fi
    if [ "$ncov" -eq 0 ]; then
      printf 'FINDING K4 the ambiguity-set member %s of set %s resolves to no coverage unit — an option offered to a reader must be a verb that exists\n' "$mdisp" "${MS[$i]}"; rc=1
    elif [ "$ncov" -gt 1 ]; then
      printf 'FINDING K4 the ambiguity-set member %s of set %s covers %d coverage units; a member names exactly one verb, because a whole command is ITSELF a choice and nesting one inside another leaves the set with no readable options\n' "$mdisp" "${MS[$i]}" "$ncov"; rc=1
    else
      SETU+=( "$mkey" ); SETQ+=( "${MS[$i]}" )
    fi
  done

  # ── The K5 QUANTIFIER WIDENING, and it is load-bearing in the PERMISSIVE direction.
  #
  # K4's quantifier is AMBPARTS and stays there: a disposition never reaches that channel,
  # so K4's predicate needs no edit and gets none. K5's is the set's OPTIONS, and a
  # disposition IS one — so its identities join SETU/SETQ under a namespace-disjoint key,
  # 'DISP:<reason>', which no coverage unit can collide with because a unit key opens '/'.
  #
  # Omitting them is the naive implementation and it FAILS OPEN INTO A FALSE POSITIVE, not
  # into silence: two sets whose unit members coincide and whose dispositions differ would
  # compare equal — equal cardinality plus mutual membership — and limb 2 would report two
  # distinct rows as one. Arm GK5e is the must-NOT-fire arm over exactly that shape.
  #
  # The PREDICATES below are unchanged; only the domain they range over grows.
  local di
  for (( di=0; di<${#DR[@]}; di++ )); do
    in_list "${DS[$di]}" "${ALLSETS[@]+"${ALLSETS[@]}"}" || ALLSETS+=( "${DS[$di]}" )
    SETU+=( "DISP:${DR[$di]}" ); SETQ+=( "${DS[$di]}" )
  done

  # K5 limb 1 — an option named twice INSIDE one set.
  local -a K5SEEN=()
  for (( i=0; i<${#SETU[@]}; i++ )); do
    if in_list "${SETQ[$i]}:${SETU[$i]}" "${K5SEEN[@]+"${K5SEEN[@]}"}"; then
      printf 'FINDING K5 the declared ambiguity set %s names the option %s more than once — a choice between a thing and itself is not a choice\n' "${SETQ[$i]}" "${SETU[$i]}"; rc=1
    else
      K5SEEN+=( "${SETQ[$i]}:${SETU[$i]}" )
    fi
  done

  # K5 limb 2 — two sets denoting the SAME options. Compared AS SETS — equal cardinality plus
  # mutual membership through in_list — never by string equality, so member ORDER is not
  # graded here. Rendering order is a different surface's question.
  local sa sb same
  local -a SETIDS=() LA=() LB=()
  for (( i=0; i<${#SETQ[@]}; i++ )); do
    in_list "${SETQ[$i]}" "${SETIDS[@]+"${SETIDS[@]}"}" || SETIDS+=( "${SETQ[$i]}" )
  done
  for (( i=0; i<${#SETIDS[@]}; i++ )); do
    for (( j=i+1; j<${#SETIDS[@]}; j++ )); do
      sa="${SETIDS[$i]}"; sb="${SETIDS[$j]}"
      LA=(); LB=()
      for (( k=0; k<${#SETU[@]}; k++ )); do
        [ "${SETQ[$k]}" = "$sa" ] && { in_list "${SETU[$k]}" "${LA[@]+"${LA[@]}"}" || LA+=( "${SETU[$k]}" ); }
        [ "${SETQ[$k]}" = "$sb" ] && { in_list "${SETU[$k]}" "${LB[@]+"${LB[@]}"}" || LB+=( "${SETU[$k]}" ); }
      done
      [ "${#LA[@]}" -gt 0 ] || continue
      [ "${#LA[@]}" -eq "${#LB[@]}" ] || continue
      same=1
      for (( k=0; k<${#LA[@]}; k++ )); do in_list "${LA[$k]}" "${LB[@]+"${LB[@]}"}" || same=0; done
      for (( k=0; k<${#LB[@]}; k++ )); do in_list "${LB[$k]}" "${LA[@]+"${LA[@]}"}" || same=0; done
      if [ "$same" -eq 1 ]; then
        printf 'FINDING K5 the declared ambiguity set %s denotes the same options as set %s — two rows offering the same options are one row; fold the intents together rather than stating the choice twice\n' "$sb" "$sa"; rc=1
      fi
    done
  done

  printf 'COUNT ADDRCELLS %d\n' "${#AK[@]}"
  printf 'COUNT AMBCELLS %d\n' "${#ALLSETS[@]}"
  printf 'COUNT AMBMEMBERS %d\n' "${#MC[@]}"
  # Counted SEPARATELY from AMBMEMBERS, and that separation is the vacuity guard: AMBCELLS
  # is non-zero whether or not any disposition member exists, so a note keyed on it would
  # print "quantified over LIVE data" on a line whose disposition limb had nothing at all.
  printf 'COUNT DISPMEMBERS %d\n' "${#DR[@]}"
  printf 'COUNT DBLCOVER %d\n' "$dbl"
  printf 'COUNT CMDKEYED %d\n' "$cmdkeyed"
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
#   INVOCATION  the line sits INSIDE a fence and BEGINS with the script path, optionally
#               prefixed by the ONE sanctioned engine-root token (see ENGINE_ROOT_TOK). The
#               admission is a single literal and not a class of variables: the rooted form is
#               stripped to the bare form and then parsed by the SAME code, so F1/F2/F3 still
#               grade its subcommand and its argv. That is the whole of the narrowing — a
#               rooted EXCLUDED form is still an F1, which arm GF1r proves, and any OTHER
#               variable-bearing prefix still reaches F5, which arm GF5r proves. Widening this
#               to "a variable" would retire the privilege grading on every rooted line at once
#               and the suite would stay green while doing it
#   TOOL-GRANT  the mention is enclosed in a Bash(...) grant token — on a frontmatter
#               grant line, OR rendered as a code span in a grant-inventory table. This
#               class is defined by the GRANT TOKEN and not by the frontmatter region, so
#               a grant token rendered in a body table is classified rather than reported
#               as unresolved, as a frontmatter-only rule would report it. No delivered
#               table renders one today, because the grant tables name the script and its
#               arm and spell the grant only in the frontmatter. The table half is kept for
#               a verb that renders a token there again, and arm G0f keeps it exercised
#               on a synthetic body-table row
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

  local line t1 t2 t3 t4 t5
  local -a IL=() IO=()
  # The record's LAST read variable absorbs the whole remainder of the line, so a record
  # with N fields must be read into N variables — one more than the field you want, when
  # a tail follows it. Reading the 5-field INV record into four made the line-number field
  # carry the argv tail, the region lookup never matched, and every correctly-attributed
  # invocation on committed state was reported as file-granular. That is the same shape
  # as the retired transport's defect: a field silently carrying more than it names.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'INV '*) IFS=' ' read -r t1 t2 t3 t4 t5 <<< "$line"; IL+=( "$t2:$t4" ); IO+=( "$t3" ) ;;
    esac
  done <<< "$recs"

  local f base cmd fd lno t bare rest sub tok found=0 i owner
  local -a ARGV=()
  for f in "$cdir"/*/SKILL.md; do
    [ -e "$f" ] || continue
    found=1
    base="$(verb_id "$f")"; cmd="/$base"
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

      bare="$t"; bare="${bare#\$ }"; bare="${bare#./}"; bare="$(strip_engine_root "$bare")"
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
# parity_check <commands_dir>
#
# PRIVILEGE PARITY OVER THE GRANT DECLARATIONS. Three properties, every one of them about what
# a file DECLARES and none about what a declaration enforces at runtime — which is the line
# this guard's own scope note draws and declines to cross. Parity of declaration is a
# declaration property, so asserting it leaves the runtime dispute exactly where it was and
# puts no gate on the open question.
#
# WHY THIS GROUP EXISTS. Nothing in this repository graded the DENYING half of a grant
# declaration. The parse-coverage classifier counts a `disallowed-tools:` line as a grant and
# says nothing whatever about its content, so a deny pattern could name a path nothing
# resolves, or be dropped outright, and every suite here would stay green. Rooting the grants
# is what made that gap load-bearing rather than theoretical: the permitting and the denying
# halves are now two strings that have to agree, and a permission matcher treats a second
# spelling of one directory as a second directory.
#
#   P1  ROOT UNIFORMITY — every frontmatter grant pattern naming a script carries the
#       sanctioned engine-root prefix, character-for-character. The denominator is DERIVED
#       from the files on every run; no count and no path is held here, so a sixth verb
#       arrives inside the population rather than outside it.
#   P2  SPELLING CLOSURE — within ONE file, across its permitting and its denying line, at
#       most one prefix spelling appears. This is why P1 alone does not close the group: a
#       partial rewrite can be green on the permitting half while the prohibition beside it
#       matches nothing, and a verb whose permit resolves and whose prohibition does not is a
#       verb with a reachable destructive arm.
#   P3  PER-VERB PARITY — the subcommand UNIVERSE for a script is the union of the subcommands
#       any verb names for it, derived from the files. For each verb carrying a grant on that
#       script, every member of the universe the verb does not PERMIT must be DENIED by that
#       verb, at the same prefix. A whole-script deny — the form carrying no subcommand —
#       satisfies every member at once. The cascade is the property worth having: a subcommand
#       entering the universe through one verb immediately obliges every other verb, so a new
#       destructive arm cannot be permitted to one and left unmentioned by the rest.
#
# EVERY VERDICT THIS GROUP REPORTS IS GATED ON A COUNT THIS FUNCTION PRODUCED, never on the
# absence of a finding. An absent population is the one outcome a finding-absence reading
# cannot distinguish from a clean one, and this group's population is exactly the thing a
# relocation of the verb surface empties.
# ─────────────────────────────────────────────────────────────────────────────────
parity_check() {
  local cdir="$1"
  local rc=0
  local n_pat=0 n_root=0 n_files=0 n_oblig=0 n_gap=0 n_mixed=0 n_univ=0

  # Pass 1 — extract every (file, role, prefix, script, subcommand) tuple the frontmatter
  # grant lines declare. Parallel indexed arrays rather than one associative array: this file
  # runs under bash 3.2 on at least one host, and a silent degradation to an empty map is the
  # shape this suite exists to refuse.
  local -a TF=() TR=() TP=() TS=() TB=()
  local f base line t infm nfence piece spec pfx rest scr sub role touches
  local -a FILES=()
  for f in "$cdir"/*/SKILL.md; do
    [ -e "$f" ] || continue
    n_files=$((n_files+1))
    base="$(verb_id "$f")"
    FILES+=( "$base" )
    infm=0; nfence=0
    while IFS= read -r line || [ -n "$line" ]; do
      if [ "$line" = '---' ]; then
        nfence=$((nfence+1))
        if [ "$nfence" -eq 1 ]; then infm=1; continue; fi
        break
      fi
      [ "$infm" -eq 1 ] || continue
      t="$(trim "$line")"
      case "$t" in
        'allowed-tools:'*)    role='allow' ;;
        'disallowed-tools:'*) role='deny' ;;
        *) continue ;;
      esac
      while [[ "$line" == *'Bash('* ]]; do
        line="${line#*Bash(}"
        piece="$line"
        spec="${piece%%)*}"
        case "$spec" in *scripts/*) ;; *) continue ;; esac
        pfx="${spec%%scripts/*}"
        rest="scripts/${spec#*scripts/}"
        rest="${rest%:\*}"
        scr="${rest%% *}"
        sub='-'
        [ "$rest" != "$scr" ] && sub="$(trim "${rest#"$scr"}")"
        [ -n "$pfx" ] || pfx='(bare)'
        TF+=( "$base" ); TR+=( "$role" ); TP+=( "$pfx" ); TS+=( "$scr" ); TB+=( "$sub" )
        n_pat=$((n_pat+1))
        [ "$pfx" = "$ENGINE_ROOT_TOK" ] && n_root=$((n_root+1))
      done
    done < "$f"
  done

  # ── P1. Reported per pattern, so the finding names the verb and the spelling rather than a
  # count the reader then has to locate.
  local i
  for (( i=0; i<n_pat; i++ )); do
    if [ "${TP[$i]}" != "$ENGINE_ROOT_TOK" ]; then
      printf 'FINDING P1 ROOT UNIFORMITY — /%s declares a %s grant on %s under the prefix "%s", not the sanctioned engine root. A bare or alternately-spelled path follows the invoking working directory, which is arbitrary\n' \
        "${TF[$i]}" "${TR[$i]}" "${TS[$i]}" "${TP[$i]}"
      rc=1
    fi
  done

  # ── P2. One prefix spelling per FILE, across both roles. A file carrying two is the
  # escalation shape: the permitting spelling and the denying spelling cannot both resolve.
  local v p
  local -a SEEN=()
  for v in "${FILES[@]+"${FILES[@]}"}"; do
    SEEN=()
    for (( i=0; i<n_pat; i++ )); do
      [ "${TF[$i]}" = "$v" ] || continue
      in_list "${TP[$i]}" "${SEEN[@]+"${SEEN[@]}"}" || SEEN+=( "${TP[$i]}" )
    done
    if [ "${#SEEN[@]}" -gt 1 ]; then
      n_mixed=$((n_mixed+1))
      printf 'FINDING P2 SPELLING CLOSURE — /%s carries %d distinct grant-prefix spellings (%s). A permission pattern is matched as a string, so a rooted permit beside a differently-spelled prohibition is a verb whose permit resolves and whose prohibition matches nothing\n' \
        "$v" "${#SEEN[@]}" "$(printf '%s ' "${SEEN[@]}")"
      rc=1
    fi
  done

  # ── P3. The universe is derived per script from every verb's declarations, then each verb
  # carrying a grant on that script owes a deny for each member it does not permit.
  local -a SCRIPTS=() UNIV_S=() UNIV_B=()
  for (( i=0; i<n_pat; i++ )); do
    in_list "${TS[$i]}" "${SCRIPTS[@]+"${SCRIPTS[@]}"}" || SCRIPTS+=( "${TS[$i]}" )
    if [ "${TB[$i]}" != '-' ]; then
      in_list "${TS[$i]}:${TB[$i]}" "${UNIV_S[@]+"${UNIV_S[@]}"}" || {
        UNIV_S+=( "${TS[$i]}:${TB[$i]}" ); UNIV_B+=( "${TB[$i]}" ); n_univ=$((n_univ+1));
      }
    fi
  done

  local s k whole permits denies
  for s in "${SCRIPTS[@]+"${SCRIPTS[@]}"}"; do
    for v in "${FILES[@]+"${FILES[@]}"}"; do
      # does this verb declare anything at all about this script?
      touches=0
      for (( i=0; i<n_pat; i++ )); do
        [ "${TF[$i]}" = "$v" ] && [ "${TS[$i]}" = "$s" ] && touches=1
      done
      [ "$touches" -eq 1 ] || continue
      # a whole-script deny satisfies every member of the universe at once
      whole=0
      for (( i=0; i<n_pat; i++ )); do
        [ "${TF[$i]}" = "$v" ] && [ "${TS[$i]}" = "$s" ] && [ "${TR[$i]}" = 'deny' ] && [ "${TB[$i]}" = '-' ] && whole=1
      done
      for (( k=0; k<${#UNIV_S[@]}; k++ )); do
        [ "${UNIV_S[$k]}" = "$s:${UNIV_B[$k]}" ] || continue
        permits=0; denies=0
        for (( i=0; i<n_pat; i++ )); do
          [ "${TF[$i]}" = "$v" ] && [ "${TS[$i]}" = "$s" ] && [ "${TB[$i]}" = "${UNIV_B[$k]}" ] && {
            [ "${TR[$i]}" = 'allow' ] && permits=1
            [ "${TR[$i]}" = 'deny' ]  && denies=1
          }
        done
        [ "$permits" -eq 1 ] && continue
        n_oblig=$((n_oblig+1))
        if [ "$denies" -eq 0 ] && [ "$whole" -eq 0 ]; then
          n_gap=$((n_gap+1))
          printf 'FINDING P3 PRIVILEGE PARITY — /%s does not permit "%s %s" and does not deny it either, while another verb on this surface names that subcommand. An unnamed arm of a script a verb can reach is a reachable arm\n' \
            "$v" "$s" "${UNIV_B[$k]}"
          rc=1
        fi
      done
    done
  done

  printf 'COUNT PFILES %d\n' "$n_files"
  printf 'COUNT PPAT %d\n' "$n_pat"
  printf 'COUNT PROOT %d\n' "$n_root"
  printf 'COUNT PMIXED %d\n' "$n_mixed"
  printf 'COUNT PUNIV %d\n' "$n_univ"
  printf 'COUNT POBLIG %d\n' "$n_oblig"
  printf 'COUNT PGAP %d\n' "$n_gap"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# grant_table_check <commands_dir>
#
# GROUP Q — THE GRANT TABLES. A verb that carries a grant table states, row by row, what each
# of its grants is held for (ADR-007 § 2 bound 2: every command's allowed-tools is the minimum
# for its function). Nothing graded that the table's Grant column and the frontmatter still
# name the same set: the invocation classifier's TOOL-GRANT class classifies a body-table grant
# token so that it is not reported as unresolved, and it compares nothing. This is a SEPARATE
# READER. The classifier is not touched and does not read these records.
#
# THE DERIVATION KEY. The graded set is every verb file under the verb root that carries, at
# fence depth 0, a table whose header row is `| Grant | The use that holds it |` with its
# delimiter row beneath it. The header is matched STRUCTURALLY on its two column names —
# trimmed, backtick-stripped, whitespace-collapsed and case-folded — for the reason banner rule 1
# gives for the requirement table: a re-spacing of the row must not unhook the locator. No verb
# is listed here, so a verb that adds such a table is graded on the next run with no edit to
# this file. A header row that is a CANDIDATE and not the key is Q0: that table's rows would
# otherwise be graded by nothing, and the graded set would shrink in silence. A row is a
# candidate when, in ANY column, a cell's first word BEGINS WITH the stem `grant` — `Grant`,
# `Grants`, `Grant:`, `Grant(s)`, `Granted …` — or a cell reads `The use that holds it`, so a
# header renamed, re-ordered, widened, pluralized or punctuated in either column still reaches
# Q0 through the other. The key with no delimiter row beneath it is Q0 too. Empty cells after
# the last pipe are not columns, so trailing whitespace on a header row neither unhooks the key
# nor reads as a near miss. What the recognizer CANNOT see is a header that renames BOTH
# columns away from those two forms: nothing then marks the table as a grant table, its verb
# leaves the graded set, and Q0's printed population is the only place that shows it.
#
# GQ_KEY_COLS is a HELD pair of column names, like REQ_COLS, and unlike the one-direction
# holdings the banner lists it is graded both ways: a live header is compared against it, and a
# key no live table carries any more is Q0's VACUITY rather than a pass.
#
# THE TWO SIDES, AND WHAT IS NOT PAIRED.
#   a ROW   is a data row of a graded table, from the delimiter row to the first line that does
#           not open with a pipe. Its key is the FIRST cell only, trimmed, with one enclosing
#           code span removed. A data row's Use cell is never read, so rewriting it cannot move
#           a verdict; the header's Use cell is read only to recognize the table (above).
#   a GRANT is one entry of the frontmatter's allowed-tools line(s), split on commas outside
#           parentheses, read the way group P reads the same line. A frontmatter line after
#           it that is not blank, not a comment and opens no new key continues that value; it
#           is NOT joined, and it is reported rather than read (below).
#   disallowed-tools entries are DENIALS. A denial is not held for a use, the header names the
#           use that holds a grant, and the live tables carry no row for any denial, so they are
#           read by nothing here. A row naming a denied tool is a row that pairs with no grant,
#           which is Q1.
#
# THE NORMALIZATION — stated once, here, and applied to the GRANT side only.
#   A row pairs with a grant G when the row's key equals G exactly, OR when G is a PATH-BEARING
#   Bash grant and the row's key equals key(G). G is path-bearing when it reads `Bash(<spec>)`
#   and the first word of <spec>, after a trailing `:*` is removed, contains a slash. Then
#       key(G) = <that word's last path component> [ + one space + the rest of <spec> ]
#   so `Bash(${CLAUDE_SKILL_DIR}/../../scripts/publish-trip-site.sh unpublish:*)` keys as
#   `publish-trip-site.sh unpublish`: the script and its arm, the rendering both live tables
#   use and state in their own words ("named here by script and arm, and spelled only in the
#   frontmatter above"). The row side is NEVER normalized. That one-sidedness is load-bearing: a
#   row spelling a held grant under a path the frontmatter does not carry — the bare
#   `Bash(scripts/publish-trip-site.sh update:*)` cell the corrective-residuals release removed —
#   equals neither the grant nor its key, so it is Q1 rather than silently paired. Arm GQ1 is
#   that row. A row spelling the full rooted token pairs by exact equality, so this arm grades
#   PAIRING and never prefers one rendering over the other.
#
# WHAT A GREEN DOES NOT ESTABLISH. It is a SET pairing per verb: a duplicated row, or a
#   duplicated grant, pairs; two rows whose Grant cells are swapped pair; and whether a Use
#   cell describes its own grant is not read at all. A row that does not open with a pipe at
#   column 0 — indented, or in the pipe-less form — is not a row, the convention every table
#   reader in this suite applies; the verb files carry neither form today. Two path-bearing
#   grants that share a script file name and arm under different directories pair with one
#   row. The allowed-tools value is read from the allowed-tools line itself, in its flow form.
#   A continuation — a wrapped value, or the items of a YAML block sequence — is a Q0 finding
#   and withholds Q2 rather than being read, so an entry there is reported, never paired and
#   never silently absent; whether the harness itself honours such a line is not established
#   here. A header renaming both columns away from the recognizer's two forms is not read as a
#   grant table (THE DERIVATION KEY, above). The guided-entry carrier at the engine root is not
#   a verb and declares no grant.
# ─────────────────────────────────────────────────────────────────────────────────
GQ_KEY_COLS=( 'grant' 'the use that holds it' )

# gq_cell <raw cell> — the header-cell normalization: trimmed, backtick-stripped, whitespace
# collapsed, case-folded. Forks twice, so it runs only on rows that already carry the word.
gq_cell() { local s; s="$(trim "$1")"; s="${s//$BT/}"; lower "$(collapse "$s")"; }

# gq_prefilter <row> — 0 when the row, its backticks removed, carries `grant` or `holds` in any
# case. Every row gq_header_kind can call a candidate carries one of the two, so this is a
# fork-free SUPERSET test: only a row that passes it pays for the classifier's forks.
gq_prefilter() {
  local r="${1//$BT/}"
  case "$r" in *[Gg][Rr][Aa][Nn][Tt]*|*[Hh][Oo][Ll][Dd][Ss]*) return 0 ;; esac
  return 1
}

# gq_header_kind <row> — KEY, NEAR or NONE. The row is a CANDIDATE when, in any column, a cell's
# first word begins with the stem `grant` (grant, grants, grant:, grant(s), granted …) or a cell
# reads `the use that holds it`, so a header renamed in EITHER column still reaches Q0 through the
# other. A candidate is KEY only when its cells are exactly GQ_KEY_COLS, in order, and NEAR
# otherwise. Cells after the last non-empty one are dropped, so trailing whitespace is not a column.
gq_header_kind() {
  local row="$1" c w i has=0 last=-1
  local -a F=() C=()
  if ! gq_prefilter "$row"; then printf 'NONE'; return 0; fi
  IFS='|' read -r -a F <<< "$row"
  for (( i=1; i<${#F[@]}; i++ )); do
    c="$(gq_cell "${F[$i]}")"; C+=( "$c" )
    [ -n "$c" ] && last=$(( ${#C[@]} - 1 ))
    w="${c%% *}"
    case "$w" in grant*) has=1 ;; esac
    if [ "$c" = "${GQ_KEY_COLS[1]}" ]; then has=1; fi
  done
  if [ "$has" -eq 0 ]; then printf 'NONE'; return 0; fi
  if [ "$last" -eq 1 ] && [ "${C[0]}" = "${GQ_KEY_COLS[0]}" ] && [ "${C[1]}" = "${GQ_KEY_COLS[1]}" ]; then
    printf 'KEY'
  else
    printf 'NEAR'
  fi
}

# gq_split_tools <value> — one entry per line; a comma inside parentheses does not split. One
# enclosing pair of square brackets is removed first, the flow-sequence form disallowed-tools uses.
gq_split_tools() {
  local v cur='' ch i depth=0
  v="$(trim "$1")"
  case "$v" in '['*']') v="${v#\[}"; v="${v%\]}" ;; esac
  for (( i=0; i<${#v}; i++ )); do
    ch="${v:i:1}"
    case "$ch" in
      '(') depth=$((depth+1)); cur="$cur$ch" ;;
      ')') [ "$depth" -gt 0 ] && depth=$((depth-1)); cur="$cur$ch" ;;
      ',') if [ "$depth" -eq 0 ]; then
             cur="$(trim "$cur")"; [ -n "$cur" ] && printf '%s\n' "$cur"; cur=''
           else cur="$cur$ch"; fi ;;
      *)   cur="$cur$ch" ;;
    esac
  done
  cur="$(trim "$cur")"; [ -n "$cur" ] && printf '%s\n' "$cur"
  return 0
}

# gq_key <grant> — key(G) per the banner, or nothing when G is not a path-bearing Bash grant.
gq_key() {
  local g="$1" spec word rest=''
  case "$g" in 'Bash('*')') ;; *) return 0 ;; esac
  spec="${g#Bash(}"; spec="${spec%\)}"; spec="$(trim "$spec")"; spec="${spec%:\*}"
  word="${spec%% *}"
  case "$word" in */*) ;; *) return 0 ;; esac
  [ "$word" != "$spec" ] && rest="$(trim "${spec#"$word"}")"
  word="${word##*/}"
  if [ -n "$rest" ]; then printf '%s %s' "$word" "$rest"; else printf '%s' "$word"; fi
}

grant_table_check() {
  local cdir="$1"
  local f cmd line next kind cell g k i j n fd infm nfence hit ntab inat t
  local n_files=0 n_unread=0 n_verbs=0 n_rows=0 n_grants=0 n_unrow=0 n_ungrant=0 n_near=0 n_cont=0
  local -a L=() RK=() RL=() GE=() GK=()
  for f in "$cdir"/*/SKILL.md; do
    # The glob matched nothing: bash hands back the pattern itself, which is neither a file
    # nor a link. A dangling link IS a verb entry that cannot be read, and is counted as one.
    if [ ! -e "$f" ] && [ ! -L "$f" ]; then continue; fi
    cmd="/$(verb_id "$f")"
    if [ ! -r "$f" ]; then
      n_unread=$((n_unread+1)); printf 'GQUNREAD %s\n' "$cmd"; continue
    fi
    n_files=$((n_files+1))
    L=()
    while IFS= read -r line || [ -n "$line" ]; do L+=( "$line" ); done < "$f"
    n=${#L[@]}

    # ── the rows of every graded table in this file, and the header near-misses
    RK=(); RL=(); fd=0; ntab=0
    for (( i=0; i<n; i++ )); do
      line="${L[$i]}"
      if [[ "$line" == '```'* ]]; then fd=$((1-fd)); continue; fi
      [ "$fd" -eq 0 ] || continue
      [[ "$line" == '|'* ]] || continue
      # the fork-free pre-filter, so only a row carrying either word pays for the classifier
      gq_prefilter "$line" || continue
      kind="$(gq_header_kind "$line")"
      [ "$kind" != 'NONE' ] || continue
      next=''; [ $((i+1)) -lt "$n" ] && next="${L[$((i+1))]}"
      if [ "$kind" = 'NEAR' ]; then
        if is_sep "$next"; then
          n_near=$((n_near+1))
          printf 'FINDING Q0 %s:%d carries a table whose header names a Grant-stemmed column or the Use column and is not the derivation key, so its rows are graded by nothing: "%.90s"\n' "$cmd" $((i+1)) "$line"
        fi
        continue
      fi
      if ! is_sep "$next"; then
        n_near=$((n_near+1))
        printf 'FINDING Q0 %s:%d carries the grant-table header with no delimiter row beneath it, so no table is read and its rows are graded by nothing: "%.90s"\n' "$cmd" $((i+1)) "$line"
        continue
      fi
      ntab=$((ntab+1))
      for (( j=i+2; j<n; j++ )); do
        [[ "${L[$j]}" == '|'* ]] || break
        cell="${L[$j]#|}"; cell="${cell%%|*}"; cell="$(trim "$cell")"
        case "$cell" in
          "$BT"*"$BT") k="${cell#"$BT"}"; k="${k%"$BT"}"
                       case "$k" in *"$BT"*) ;; *) cell="$k" ;; esac ;;
        esac
        RK+=( "$cell" ); RL+=( $((j+1)) )
      done
      i=$((j-1))
    done
    [ "$ntab" -gt 0 ] || continue
    n_verbs=$((n_verbs+1))

    # ── the grants: every allowed-tools line of the frontmatter, read as group P reads it. A line
    # after one that is not blank, not a comment and opens no new key at column 0 CONTINUES that
    # value — a wrapped line, or a YAML block sequence's items. It is NOT joined: it is Q0, and its
    # count withholds Q2, whose grant population it leaves unfinished.
    GE=(); GK=(); infm=0; nfence=0; inat=0
    for (( i=0; i<n; i++ )); do
      line="${L[$i]}"
      if [ "$line" = '---' ]; then
        nfence=$((nfence+1))
        if [ "$nfence" -eq 1 ]; then infm=1; continue; fi
        break
      fi
      [ "$infm" -eq 1 ] || continue
      if [ "$inat" -eq 1 ] && ! [[ "$line" =~ ^[[:alnum:]_-]+: ]]; then
        t="$(trim "$line")"
        case "$t" in
          ''|'#'*) ;;
          *) n_cont=$((n_cont+1))
             printf 'FINDING Q0 %s:%d continues its allowed-tools value on a following line, which this reader does not join, so a grant there is read by nothing and the grant-to-row direction is withheld: "%.90s"\n' "$cmd" $((i+1)) "$t" ;;
        esac
        continue
      fi
      inat=0
      line="$(trim "$line")"
      case "$line" in 'allowed-tools:'*) inat=1 ;; *) continue ;; esac
      while IFS= read -r g || [ -n "$g" ]; do
        [ -n "$g" ] || continue
        GE+=( "$g" ); GK+=( "$(gq_key "$g")" )
      done <<< "$(gq_split_tools "${line#allowed-tools:}")"
    done

    # ── Q1: every row pairs with some grant
    for (( i=0; i<${#RK[@]}; i++ )); do
      hit=0
      for (( j=0; j<${#GE[@]}; j++ )); do
        if [ "${RK[$i]}" = "${GE[$j]}" ]; then hit=1; break; fi
        if [ -n "${GK[$j]}" ] && [ "${RK[$i]}" = "${GK[$j]}" ]; then hit=1; break; fi
      done
      if [ "$hit" -eq 0 ]; then
        n_unrow=$((n_unrow+1))
        printf 'FINDING Q1 %s:%d the grant-table row "%s" names no allowed-tools entry of this verb — a row pairs with an entry it spells exactly, or with a path-bearing Bash entry by that script'"'"'s file name and arm\n' "$cmd" "${RL[$i]}" "${RK[$i]}"
      fi
    done

    # ── Q2: every grant pairs with some row
    for (( j=0; j<${#GE[@]}; j++ )); do
      hit=0
      for (( i=0; i<${#RK[@]}; i++ )); do
        if [ "${RK[$i]}" = "${GE[$j]}" ]; then hit=1; break; fi
        if [ -n "${GK[$j]}" ] && [ "${RK[$i]}" = "${GK[$j]}" ]; then hit=1; break; fi
      done
      if [ "$hit" -eq 0 ]; then
        n_ungrant=$((n_ungrant+1))
        if [ -n "${GK[$j]}" ]; then
          printf 'FINDING Q2 %s the allowed-tools entry "%s" has no grant-table row — a row naming "%s" (its script and arm) or the entry itself would pair it\n' "$cmd" "${GE[$j]}" "${GK[$j]}"
        else
          printf 'FINDING Q2 %s the allowed-tools entry "%s" has no grant-table row naming it\n' "$cmd" "${GE[$j]}"
        fi
      fi
    done

    n_rows=$((n_rows + ${#RK[@]})); n_grants=$((n_grants + ${#GE[@]}))
    printf 'GTAB %s %d %d\n' "$cmd" "${#RK[@]}" "${#GE[@]}"
  done
  printf 'COUNT GQFILES %d\n' "$n_files"
  printf 'COUNT GQUNREAD %d\n' "$n_unread"
  printf 'COUNT GQVERBS %d\n' "$n_verbs"
  printf 'COUNT GQROWS %d\n' "$n_rows"
  printf 'COUNT GQGRANTS %d\n' "$n_grants"
  printf 'COUNT GQUNROW %d\n' "$n_unrow"
  printf 'COUNT GQUNGRANT %d\n' "$n_ungrant"
  printf 'COUNT GQNEAR %d\n' "$n_near"
  printf 'COUNT GQCONT %d\n' "$n_cont"
  return 0
}

# gq_tables <grant_table_check output> — "/verb (R rows, G grants)" joined, for a PASS line.
gq_tables() {
  local out="$1" line t1 t2 t3 t4 acc=''
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'GTAB '*) IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; acc="${acc:+$acc, }$t2 ($t3 rows, $t4 grants)" ;;
    esac
  done <<< "$out"
  printf '%s' "$acc"
}

# ── The three verdicts. Each renders EXACTLY ONE verdict and calls grant_table_check ITSELF, so
# removing that function removes the evidence and must flip the verdict to one FAIL — the
# property md_flips grades at the end of group MD. Every limb before the PASS is a FAIL, and
# every PASS is gated on counts the subject produced, never on the absence of a finding.
gq_assert_anchor() {   # Q0 — the graded set, derived from the tree
  local out nf nu nv nn nc tabs
  out="$(grant_table_check "$1")"
  nf="$(getcount "$out" GQFILES)"; nu="$(getcount "$out" GQUNREAD)"
  nv="$(getcount "$out" GQVERBS)"; nn="$(getcount "$out" GQNEAR)"; nc="$(getcount "$out" GQCONT)"
  tabs="$(gq_tables "$out")"
  if [ -z "$nf" ] || [ -z "$nu" ] || [ -z "$nv" ] || [ -z "$nn" ] || [ -z "$nc" ]; then
    FAIL "Q0: NO SUBJECT — grant_table_check emitted no population count, so no verb file was read for a grant table"
  elif [ "$nu" -ne 0 ]; then
    FAIL "Q0: DEGRADED — ${nu} verb file(s) could not be read, so the graded set is UNMEASURED rather than derived. This is not a clean result"
  elif [ "$nf" -le 0 ]; then
    FAIL "Q0: VACUITY — the verb root holds no readable verb file, so no grant table can be found and neither direction below grades anything"
  elif [ "$nn" -ne 0 ]; then
    FAIL "Q0: ${nn} table(s) whose header carries a Grant-stemmed column or the Use column are not the derivation key, or carry no delimiter row — their rows are graded by nothing and the graded set shrinks in silence. Render the header as | Grant | The use that holds it | with its delimiter row"
    show "$out" 'Q0'
  elif [ "$nc" -ne 0 ]; then
    FAIL "Q0: ${nc} frontmatter line(s) continue a graded verb's allowed-tools value past the allowed-tools line, and this reader does not join them — a grant there pairs with nothing and is checked by nothing, so Q2 is withheld. Keep each verb's allowed-tools value on its one line"
    show "$out" 'Q0'
  elif [ "$nv" -le 0 ]; then
    FAIL "Q0: VACUITY — ${nf} verb file(s) read and none carries a table headed | Grant | The use that holds it |, so there is no pairing to grade. A release that retires the grant tables retires this group with them; it does not leave it reading as coverage"
  else
    PASS "Q0: DERIVED — ${nv} of ${nf} verb file(s) carry a table headed | Grant | The use that holds it | at fence depth 0 [ ${tabs} ]; the set is read off the tree on this run, and a verb that adds such a table is graded with no edit to this file. WHAT WAS CHECKED, AND NO MORE: at fence depth 0 no row opening with a pipe, with a delimiter row beneath it, carries a cell whose first word begins with 'grant' or a cell reading 'the use that holds it' without being the key; the key never stands without its delimiter row; and no graded verb's allowed-tools value runs onto a following line. A header renaming BOTH columns away from those two forms is not recognized as a grant table, so its verb would leave this count rather than fail it"
  fi
}

gq_assert_rows() {     # Q1 — every row pairs with a grant
  local out nu nv nr ng nx
  out="$(grant_table_check "$1")"
  nu="$(getcount "$out" GQUNREAD)"; nv="$(getcount "$out" GQVERBS)"
  nr="$(getcount "$out" GQROWS)";   ng="$(getcount "$out" GQGRANTS)"; nx="$(getcount "$out" GQUNROW)"
  if [ -z "$nu" ] || [ -z "$nv" ] || [ -z "$nr" ] || [ -z "$ng" ] || [ -z "$nx" ]; then
    FAIL "Q1: NO SUBJECT — grant_table_check emitted no pairing counts, so no row was compared"
  elif [ "$nu" -ne 0 ]; then
    FAIL "Q1: VERDICT WITHHELD — ${nu} verb file(s) could not be read (Q0 names the cause); a pairing verdict over the readable remainder would state the clean result over an unmeasured population"
  elif [ "$nv" -le 0 ] || [ "$nr" -le 0 ]; then
    FAIL "Q1: VACUITY — ${nv} graded verb(s) and ${nr} grant-table row(s): the row-to-grant direction quantified over nothing"
  elif [ "$nx" -ne 0 ]; then
    FAIL "Q1: ${nx} of ${nr} grant-table row(s) name no allowed-tools entry of their own verb"
    show "$out" 'Q1'
  else
    PASS "Q1: ROW -> GRANT — all ${nr} grant-table row(s) across ${nv} verb(s) pair with an allowed-tools entry of their own verb, against ${ng} entries read. A row pairs by exact spelling, or a path-bearing Bash grant by its script's file name and arm; the row side is never normalized. Controls: GQ1, GQ4, GQ6 and GQ9 fire in group GQ, and GQ7 stays silent"
  fi
}

gq_assert_grants() {   # Q2 — every grant pairs with a row
  local out nu nv nr ng nx nc
  out="$(grant_table_check "$1")"
  nu="$(getcount "$out" GQUNREAD)"; nv="$(getcount "$out" GQVERBS)"
  nr="$(getcount "$out" GQROWS)";   ng="$(getcount "$out" GQGRANTS)"; nx="$(getcount "$out" GQUNGRANT)"
  nc="$(getcount "$out" GQCONT)"
  if [ -z "$nu" ] || [ -z "$nv" ] || [ -z "$nr" ] || [ -z "$ng" ] || [ -z "$nx" ] || [ -z "$nc" ]; then
    FAIL "Q2: NO SUBJECT — grant_table_check emitted no pairing counts, so no grant was compared"
  elif [ "$nu" -ne 0 ]; then
    FAIL "Q2: VERDICT WITHHELD — ${nu} verb file(s) could not be read (Q0 names the cause); a pairing verdict over the readable remainder would state the clean result over an unmeasured population"
  elif [ "$nc" -ne 0 ]; then
    FAIL "Q2: VERDICT WITHHELD — ${nc} line(s) continue a graded verb's allowed-tools value and are unread (Q0 names them), so the grant population is unfinished; a grant-to-row verdict over the entries that were read would state the clean result over an unmeasured one"
  elif [ "$nv" -le 0 ] || [ "$ng" -le 0 ]; then
    FAIL "Q2: VACUITY — ${nv} graded verb(s) and ${ng} allowed-tools entr(ies): the grant-to-row direction quantified over nothing"
  elif [ "$nx" -ne 0 ]; then
    FAIL "Q2: ${nx} of ${ng} allowed-tools entr(ies) of a graded verb have no grant-table row"
    show "$out" 'Q2'
  else
    PASS "Q2: GRANT -> ROW — all ${ng} allowed-tools entr(ies) of ${nv} graded verb(s) are named by a row of their own verb's grant table (${nr} rows read). The grant side is read in full — every entry of every allowed-tools line, with no graded verb continuing that value onto a line this reader would not join — so a grant added with nothing removed is found. disallowed-tools entries are denials and are not paired. Controls: GQ2, GQ3, GQ4 and GQ6 fire in group GQ, GQ8 withholds, and GQ7 stays silent"
  fi
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

  local rc=0 line k v t1 t2 t3 t4 t5
  local -a INVK=() LIVE=()
  # See the note in invocation_check: the last read variable absorbs the remainder, so an
  # invocation record must be read into one variable PER FIELD, or the owner field holds the
  # owner plus everything after it. DECL has exactly three fields.
  #
  # The limb reads ANYINV — ANY engine script on a fenced line — not INV, which is the publish
  # script alone. A region declared read-only runs no script at all, so an invocation of any of
  # them in one is the finding; narrowing the population to one script would let every other
  # script through the very region this limb exists to keep clean.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'ANYINV '*) IFS=' ' read -r t1 t2 t3 t4 t5 <<< "$line"; [ "$t3" != '-' ] && INVK+=( "$t2:$t3" ) ;;
      'DECL '*)   IFS=' ' read -r t1 t2 t3 <<< "$line"; [ "$t2" = "$READONLY_OF_COMMAND" ] && LIVE+=( "$t3" ) ;;
    esac
  done <<< "$recs"

  for k in "${KEYS[@]+"${KEYS[@]}"}"; do
    if in_list "$k" "${INVK[@]+"${INVK[@]}"}"; then
      printf 'FINDING R1 the declared read-only key %s carries a fenced script invocation in its own region\n' "$k"; rc=1
    fi
  done

  for v in "${LIVE[@]+"${LIVE[@]}"}"; do
    in_list "$v" "${ADJ[@]+"${ADJ[@]}"}" || { printf 'FINDING R2 MEMBERSHIP-DELTA SENTINEL — %s declares the verb "%s", which was not present when the read-only set was adjudicated. Required action: re-adjudicate the read-only set.\n' "$READONLY_OF_COMMAND" "$v"; rc=1; }
  done
  for v in "${ADJ[@]+"${ADJ[@]}"}"; do
    in_list "$v" "${LIVE[@]+"${LIVE[@]}"}" || { printf 'FINDING R2 MEMBERSHIP-DELTA SENTINEL — the verb "%s" was present when the read-only set was adjudicated and %s no longer declares it. Required action: re-adjudicate the read-only set.\n' "$v" "$READONLY_OF_COMMAND"; rc=1; }
  done

  # --- the CANDIDATE population, so R1's non-vacuity is DERIVED rather than assumed.
  # A limb can only fire where a region-attributed record shares its command with the
  # declared read-only key set; records of any other command are not near-misses, they are
  # outside the quantifier. Counting all records instead would report a limb as live while
  # nothing it could match exists — which is how this arm read as covered while both of
  # its limbs were vacuous on committed state.
  local rocinv=0
  for k in "${INVK[@]+"${INVK[@]}"}"; do
    case "$k" in "$READONLY_OF_COMMAND":*) rocinv=$((rocinv+1)) ;; esac
  done

  printf 'COUNT ROKEYS %d\n' "${#KEYS[@]}"
  printf 'COUNT ROLIVE %d\n' "${#LIVE[@]}"
  printf 'COUNT ROCINV %d\n' "$rocinv"
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# preexec_check <file...>
#
# GROUP I — THE RETIRED PRE-EXECUTION CARRIER STAYS RETIRED. A line opening with a bang and a
# backtick is the harness pre-execution rendering — ADR-007's § Context describes it as running
# before the model sees the prompt — and it is the carrier the charter retired corpus-wide. R1's
# pre-execution limb used to test for it, over read-only regions
# only, and was retired when its population fell to zero; the successor it named did not catch the
# line at all. This is the successor that does, over a wider surface than that limb had: EVERY
# line of every verb file, and the guided-entry carrier at the engine root — the one surface the
# model can reach unprompted, and one that sits outside the verb directory every per-file glob in
# this suite reads.
#
# The predicate is the retired limb's, byte for byte: column 0, fence depth 0, a bang then a
# backtick. A fenced line is an example, as it is for every other depth-0 rule here.
#
# SCOPE, stated rather than left to be inferred from a green: the line-opening rendering is what
# the retired carrier used and what is graded. The same two characters mid-line or inside a fence
# are not graded here, and this assertion claims nothing about whether the harness expands them.
#
# It reads files and writes nothing. Unreadable inputs are COUNTED rather than skipped, so a path
# that vanished reads as a subject that was not examined rather than as a clean one.
# ─────────────────────────────────────────────────────────────────────────────────
preexec_check() {
  local f line fd lno rel scanned=0 files=0 missing=0 hits=0
  for f in "$@"; do
    if [ ! -r "$f" ]; then missing=$((missing+1)); continue; fi
    files=$((files+1)); fd=0; lno=0
    rel="${f#"$ROOT"/}"
    while IFS= read -r line || [ -n "$line" ]; do
      lno=$((lno+1))
      if [[ "$line" == '```'* ]]; then fd=$((1-fd)); continue; fi
      [ "$fd" -eq 0 ] || continue
      scanned=$((scanned+1))
      if [[ "$line" == '!'"$BT"* ]]; then
        hits=$((hits+1))
        printf 'FINDING I1 %s:%d opens with a bang and a backtick at fence depth 0 — the harness pre-execution rendering this corpus retired. Re-express it as a read the agent runs under the charter contract, or delete it\n' "$rel" "$lno"
      fi
    done < "$f"
  done
  printf 'COUNT PXFILES %d\n' "$files"
  printf 'COUNT PXMISSING %d\n' "$missing"
  printf 'COUNT PXLINES %d\n' "$scanned"
  printf 'COUNT PXHITS %d\n' "$hits"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────
# inference_check <records> <carrier-path>
#
# GROUP C — THE JOIN. Three surfaces in this repository each state an arm's side, and until
# this function existed NO assertion bound any pair of them: the verb's own read-declaration
# block states the three declared negatives (the SOURCE); the charter's Step-1 Action cell
# renders the entry-class marker; and B7 grades that a marker is THERE without grading that it
# is RIGHT. C1 closes that gap — for every coverage unit, the side derived from the source must
# equal the marker rendered in the routing map, as a set difference empty in BOTH directions.
#
# NO LIST ON EITHER SIDE. Both sides are read live from the record stream. A held membership
# list on either side would make the join agree with whatever it was handed, which is the exact
# failure this assertion exists to detect, and it would break under verb growth.
#
# GROUP CE — THE CARRIER. The guided-entry surface sits at the ENGINE ROOT, outside the verb
# directory both suites glob, so no pre-existing group reads it at all. Its assertions are
# net-new rather than an extension of an existing group's quantifier.
# ─────────────────────────────────────────────────────────────────────────────────
inference_check() {
  local recs="$1" carrier="$2"
  local rc=0 line t1 t2 t3 t4 rrec
  local -a NK=() NB=() GK=() GC=() PC=() PV=() CFK=() DK=() DKC=() FILES=() RLC=() RLV=() RUC=() RUT=()
  # ── The two SET channels, read here for C6 and for nothing else. They are the same records
  # coverage_check reads, off the same stream, parsed field for field the same way — the set
  # ordinal, then the member. This function does not re-derive them and holds no second copy:
  # what it adds is the SIDE of each unit member, which it already derives for C1 and C2 from
  # NK/NB, so the composition rule is the existing side function quantified over a set's
  # membership rather than a second notion of what a member is.
  local -a MS=() MC=() MV=() DS=()

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'RULE '*)    rrec="${line#RULE }"; RUC+=( "${rrec%% *}" ); RUT+=( "${rrec#* }" ) ;;
      'NEG '*)     IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; NK+=( "$t2:$t3" ); NB+=( "$t4" ) ;;
      'GRADE '*)   IFS=' ' read -r t1 t2 t3 t4 <<< "$line"
                   if [ "$t3" = '-' ]; then GK+=( "$t2" ); else GK+=( "$t2:$t3" ); fi; GC+=( "$t4" ) ;;
      'POSTURE '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; PC+=( "$t2" ); PV+=( "$t3" ) ;;
      'CONFIRM '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; CFK+=( "$t2:$t3" ) ;;
      'DECL '*)    IFS=' ' read -r t1 t2 t3 <<< "$line"; DK+=( "$t2:$t3" ); DKC+=( "$t2" ) ;;
      'FILE '*)    IFS=' ' read -r t1 t2 <<< "$line"; FILES+=( "$t2" ) ;;
      'ROLE '*)    IFS=' ' read -r t1 t2 t3 <<< "$line"; RLC+=( "$t2" ); RLV+=( "$t3" ) ;;
      # Four fields into four variables, three into three — the transport rule this file states
      # at invocation_check, applied here exactly as coverage_check applies it to the same two
      # records. C6 reads a disposition member's SET ORDINAL and never its reason, so the reason
      # field is discarded rather than read into a variable that nothing consults.
      'AMBPARTS '*)  IFS=' ' read -r t1 t2 t3 t4 <<< "$line"; MS+=( "$t2" ); MC+=( "$t3" ); MV+=( "$t4" ) ;;
      'DISPPARTS '*) IFS=' ' read -r t1 t2 t3 <<< "$line"; DS+=( "$t2" ) ;;
    esac
  done <<< "$recs"

  # --- the coverage-unit enumeration, derived by the SAME rule coverage_check applies:
  # a command declaring no verb is itself a unit, and every declared verb is one.
  local -a UNITS=()
  local f has i j k
  for f in "${FILES[@]+"${FILES[@]}"}"; do
    has=0
    for (( i=0; i<${#DKC[@]}; i++ )); do [ "${DKC[$i]}" = "$f" ] && has=1; done
    [ "$has" -eq 0 ] && UNITS+=( "$f" )
  done
  for k in "${DK[@]+"${DK[@]}"}"; do UNITS+=( "$k" ); done

  # ── C0 — the population, the three component counts, and BOTH control arms.
  # This is the denominator every later assertion reports against, so it is computed and
  # printed BEFORE anything branches on the side function.
  local nblocks="${#NK[@]}" nw=0 nd=0 no=0 nadm=0 nret=0
  for (( i=0; i<nblocks; i++ )); do
    [ $(( NB[i] & 4 )) -ne 0 ] && nw=$((nw+1))
    [ $(( NB[i] & 2 )) -ne 0 ] && nd=$((nd+1))
    [ $(( NB[i] & 1 )) -ne 0 ] && no=$((no+1))
    if [ "${NB[$i]}" -eq 7 ]; then nadm=$((nadm+1)); else nret=$((nret+1)); fi
  done

  # The ARMS. The recogniser is run over a synthetic block that declares all three, over a
  # near-miss that declares the POSITIVE of each beside a word carrying a negative only as its
  # SUFFIX, and over a block declaring the first two negatives beside "runs no script" with NO
  # effect clause — in the same process and through the same normalisation the live scan uses. A
  # sensitivity arm that does not fire makes every count above unusable, and the group reports the
  # probe broken rather than the corpus clean. The third arm is the must-NOT-ADMIT one: it has to
  # derive the first two limbs and not the third, because an arm that never declared the effect is
  # retained under the fail-closed rule, and a recogniser admitting it is reading the superseded
  # runs-no-script predicate.
  local sens_blk sens_bi=0 spec_blk spec_bi=0 noef_blk noef_bi=0 nb
  sens_blk="$(neg_norm '**Reads:** nothing. It **writes nothing**, **dispatches no agent**, and performs no act whose effect lands outside the trip own files.')"
  [[ "$sens_blk" =~ $NEG_W_RE ]] && sens_bi=$((sens_bi+4))
  [[ "$sens_blk" =~ $NEG_D_RE ]] && sens_bi=$((sens_bi+2))
  [[ "$sens_blk" =~ $NEG_O_RE ]] && sens_bi=$((sens_bi+1))
  spec_blk="$(neg_norm '**Reads:** the log. It writes the file, dispatches an agent, reaches the network, and overwrites nothing it did not create.')"
  [[ "$spec_blk" =~ $NEG_W_RE ]] && spec_bi=$((spec_bi+4))
  [[ "$spec_blk" =~ $NEG_D_RE ]] && spec_bi=$((spec_bi+2))
  [[ "$spec_blk" =~ $NEG_O_RE ]] && spec_bi=$((spec_bi+1))
  noef_blk="$(neg_norm '**Reads:** the file. It writes nothing, runs no script and dispatches no agent.')"
  [[ "$noef_blk" =~ $NEG_W_RE ]] && noef_bi=$((noef_bi+4))
  [[ "$noef_blk" =~ $NEG_D_RE ]] && noef_bi=$((noef_bi+2))
  [[ "$noef_blk" =~ $NEG_O_RE ]] && noef_bi=$((noef_bi+1))

  if [ "$nblocks" -eq 0 ]; then
    printf 'FINDING C0 the per-arm read-declaration population is EMPTY — the side function has nothing to quantify over and every later assertion in this group would be vacuously true\n'; rc=1
  fi
  if [ "$sens_bi" -ne 7 ]; then
    printf 'FINDING C0 BROKEN PROBE — the sensitivity arm ran the three-negative recogniser over a block declaring all three and derived %d of 7. The recogniser does not recognise its own subject, so the admitted set below is unusable and is NOT a statement that the corpus declares nothing\n' "$sens_bi"; rc=1
  fi
  if [ "$spec_bi" -ne 0 ]; then
    printf 'FINDING C0 BROKEN PROBE — the specificity arm ran the recogniser over a block declaring the POSITIVE of each negative, beside a word carrying a negative only as its suffix, and derived %d rather than 0. A recogniser that matches the affirmation, or reads a longer word as the negative it ends in, cannot separate an admitted arm from a writing one\n' "$spec_bi"; rc=1
  fi
  if [ "$noef_bi" -ne 6 ]; then
    printf 'FINDING C0 the recogniser derived %d of 7 over a block declaring writes-nothing, runs-no-script and dispatches-no-agent with NO effect clause, where 6 is required — the first two limbs and not the third. At 7 it reads runs-no-script as the third negative, which ADR-007 § 1 states as an effect predicate, so the admitted set below would hold arms that never declared the effect\n' "$noef_bi"; rc=1
  fi

  printf 'COUNT CNOEFF %d\n' "$noef_bi"
  printf 'COUNT CBLOCKS %d\n' "$nblocks"
  printf 'COUNT CNEGW %d\n' "$nw"
  printf 'COUNT CNEGD %d\n' "$nd"
  printf 'COUNT CNEGO %d\n' "$no"
  printf 'COUNT CADMIT %d\n' "$nadm"
  printf 'COUNT CRETAIN %d\n' "$nret"
  printf 'COUNT CSENS %d\n' "$sens_bi"
  printf 'COUNT CSPEC %d\n' "$spec_bi"
  printf 'COUNT CUNITS %d\n' "${#UNITS[@]}"

  # ── C4 — TOTALITY. Every coverage unit must resolve to exactly one side, which requires the
  # side function to be DEFINED on it: a unit carrying no read-declaration block has no source
  # to derive a side from, and a unit carrying more than one record would resolve to two.
  local n_nosrc=0 hits
  for k in "${UNITS[@]+"${UNITS[@]}"}"; do
    hits=0
    for (( i=0; i<nblocks; i++ )); do [ "${NK[$i]}" = "$k" ] && hits=$((hits+1)); done
    if [ "$hits" -eq 0 ]; then
      n_nosrc=$((n_nosrc+1))
      printf 'FINDING C4 the coverage unit "%s" carries no read-declaration block, so the side function is UNDEFINED on it — it resolves to neither side rather than to exactly one\n' "$k"; rc=1
    elif [ "$hits" -gt 1 ]; then
      printf 'FINDING C4 the coverage unit "%s" carries %d read-declaration records — it resolves to more than one side\n' "$k" "$hits"; rc=1
    fi
  done
  printf 'COUNT CNOSRC %d\n' "$n_nosrc"

  # ── C1 — THE JOIN, as a set difference in BOTH directions.
  local n_j1=0 n_j2=0 gi src
  for (( i=0; i<${#GK[@]}; i++ )); do
    src=''
    for (( j=0; j<nblocks; j++ )); do
      if [ "${NK[$j]}" = "${GK[$i]}" ]; then
        if [ "${NB[$j]}" -eq 7 ]; then src='ADMIT'; else src='RETAIN'; fi
        break
      fi
    done
    [ -n "$src" ] || continue
    if [ "$src" = 'ADMIT' ] && [ "${GC[$i]}" != 'ADMIT' ]; then
      n_j1=$((n_j1+1))
      printf 'FINDING C1 "%s" declares all three negatives in its own block, so the rule ADMITS it — and the routing map renders it %s. The marker disagrees with its source\n' "${GK[$i]}" "${GC[$i]}"; rc=1
    elif [ "$src" = 'RETAIN' ] && [ "${GC[$i]}" = 'ADMIT' ]; then
      n_j2=$((n_j2+1))
      printf 'FINDING C1 the routing map renders "%s" INFERENCE-ADMITTED, and its own block does NOT declare all three negatives. A property nobody has declared is not one this rule may assume\n' "${GK[$i]}"; rc=1
    fi
  done
  printf 'COUNT CJ1 %d\n' "$n_j1"
  printf 'COUNT CJ2 %d\n' "$n_j2"

  # ── C6 — SET COMPOSITION, FAIL-CLOSED. The inference line quantified over a SET's membership
  # rather than over an arm.
  #
  # WHAT WAS AUTHORABLE BEFORE IT. A declared ambiguity set holds members of two kinds and only
  # one of them carries an entry class: a UNIT member's class is its own verb's, and a DISPOSITION
  # member has none — it is not an arm and owns no read-declaration block to declare one in.
  # Nothing said which side it counted on, so a set pairing a disposition with unit members that
  # are ALL inference-admitted could be authored with this entire suite green. Measured, not
  # supposed: rewriting one live set's verb to an inference-admitted one left every verdict line
  # of this suite byte-identical, while K1 still counted the row's member and the set arms still
  # fired in the same run.
  #
  # THE RULE IS THE CORPUS'S, NOT THIS FILE'S. ADR-007 § 3's set-obligations bullet composes a
  # set's entry class FAIL-CLOSED from its members' own sides, by applying § 1's own line to a
  # member: a member declaring none of the negatives retains declared intent — silence included —
  # so a set carrying a disposition member retains it too, and names at least one unit member that
  # does the same. This function holds no copy of that requirement and no list on either side: it
  # derives each unit member's side from NK/NB, live, exactly as C1 and C2 already derive an arm's.
  #
  # WHY THE PREDICATE IS "EVERY UNIT MEMBER ADMITTED" RATHER THAN "THE SET IS RETAINED". The second
  # is a tautology under the rule and has no failing shape — a set with a disposition member is
  # retained by construction, so an assertion of it could never go red. What is refusable is the set
  # whose two readings DISAGREE: membership reading admitted, rule reading retained. That is exactly
  # the all-admitted composition, and it is the one shape in which the fail-closed side is legible
  # from the rule alone and not from the row. A set carrying a retained unit member reads retained
  # under either reading and is not a finding; arm GC6b is that near-miss — an admitted unit member
  # standing BESIDE a retained one — and it must stay green or this predicate is a blanket ban on
  # admitted members rather than a composition rule.
  #
  # FAIL-CLOSED IN THE OTHER DIRECTION TOO. A member whose side cannot be derived — no
  # read-declaration record for the unit it resolves to — counts RETAINED here, so an underived
  # side can never manufacture a C6. That state is already a C4 and the run is red before this
  # line is read; this clause decides only which finding gets to name it.
  local -a C6SETS=()
  local ci cj cm cu c6_sets=0 c6_hits=0 c6_units=0 c6_ret=0 c6_key c6_side c6_names
  for (( ci=0; ci<${#DS[@]}; ci++ )); do
    in_list "${DS[$ci]}" "${C6SETS[@]+"${C6SETS[@]}"}" || C6SETS+=( "${DS[$ci]}" )
  done
  c6_sets=${#C6SETS[@]}
  for (( ci=0; ci<c6_sets; ci++ )); do
    c6_units=0; c6_ret=0; c6_names=''
    for (( cj=0; cj<${#MC[@]}; cj++ )); do
      [ "${MS[$cj]}" = "${C6SETS[$ci]}" ] || continue
      c6_units=$((c6_units+1))
      # The member's coverage unit, computed by the SAME rule coverage_check computes it, so the
      # two cannot disagree about which unit a member names.
      c6_key=''
      if [ "${MV[$cj]}" = '-' ]; then
        for cu in "${UNITS[@]+"${UNITS[@]}"}"; do
          case "$cu" in "${MC[$cj]}"|"${MC[$cj]}":*) c6_key="$cu" ;; esac
        done
      else
        c6_key="${MC[$cj]}:${MV[$cj]}"
      fi
      [ -n "$c6_key" ] || c6_key='UNRESOLVED'
      c6_side='RETAIN'
      for (( cm=0; cm<nblocks; cm++ )); do
        if [ "${NK[$cm]}" = "$c6_key" ]; then
          if [ "${NB[$cm]}" -eq 7 ]; then c6_side='ADMIT'; else c6_side='RETAIN'; fi
          break
        fi
      done
      [ "$c6_side" = 'RETAIN' ] && c6_ret=$((c6_ret+1))
      c6_names="$c6_names${c6_names:+, }$c6_key=$c6_side"
    done
    if [ "$c6_units" -gt 0 ] && [ "$c6_ret" -eq 0 ]; then
      c6_hits=$((c6_hits+1))
      printf 'FINDING C6 the declared ambiguity set %s carries a disposition member beside unit member(s) that are ALL inference-admitted [ %s ] — a member that declares nothing retains declared intent, so this set retains it while its own membership reads admitted. Name a unit member that retains declared intent, or drop the disposition member: a set whose side is legible only from the rule and not from the row is how resolving a set by inference gets authored with every check green\n' "${C6SETS[$ci]}" "$c6_names"; rc=1
    fi
  done
  printf 'COUNT CDISPSETS %d\n' "$c6_sets"
  printf 'COUNT CCOMPOSE %d\n' "$c6_hits"

  # ── C2 / C3 — the per-arm confirm obligation, and the per-limb report that makes it readable.
  # C2 quantifies over the DECLARED-INTENT side derived from the source, not over the marker:
  # the obligation is a property of an arm that retains declared intent, and deriving the side
  # here keeps C2 answerable even on a tree where the marker and the source disagree.
  #
  # THE TYPED-ONLY LIMB IS SCOPED BY ROLE, and the scope is the charter's, not this guard's. The
  # posture's second half is a clause saying the verb is the one the user typed. A CREATE-role
  # file takes an ARGUMENT rather than a verb — its "verb" is a branch label, never a typed token —
  # so that clause would be a false declaration there, and requiring it would ask a file to state
  # something untrue in order to pass. For a CREATE-role file the frontmatter flag alone is the
  # posture. The discriminator is the ROLE record the charter already emits, exactly as group H
  # scopes H1/H2/H3; no filename test and no list is introduced to make the distinction.
  local n_conf=0 n_typed=0 n_neither=0 cmdof postr rolr
  for (( i=0; i<nblocks; i++ )); do
    [ "${NB[$i]}" -eq 7 ] && continue
    cmdof="${NK[$i]%%:*}"
    postr='-'
    for (( j=0; j<${#PC[@]}; j++ )); do [ "${PC[$j]}" = "$cmdof" ] && postr="${PV[$j]}"; done
    rolr='RESOLVE'
    for (( j=0; j<${#RLC[@]}; j++ )); do [ "${RLC[$j]}" = "$cmdof" ] && rolr="${RLV[$j]}"; done
    if [ "$rolr" = 'CREATE' ] && [ "$postr" = 'FLAG' ]; then postr='TYPED'; fi
    if in_list "${NK[$i]}" "${CFK[@]+"${CFK[@]}"}"; then
      n_conf=$((n_conf+1))
    elif [ "$postr" = 'TYPED' ]; then
      n_typed=$((n_typed+1))
    else
      n_neither=$((n_neither+1))
      printf 'FINDING C2 "%s" retains declared intent and carries NEITHER limb — no confirm gate declared in its own read-declaration block, and its file does not carry both halves of the typed-only posture. An arm on this side must stand behind one of them\n' "${NK[$i]}"; rc=1
    fi
  done
  printf 'COUNT CLIMBCONF %d\n' "$n_conf"
  printf 'COUNT CLIMBTYPED %d\n' "$n_typed"
  printf 'COUNT CLIMBNONE %d\n' "$n_neither"

  # ── C5 — the STANDING CONFIRM RULE is present in every verb file, and stated alike.
  #
  # PRESENCE, NOT BEHAVIOUR. The rule governs an act on a verb the operator did not type, and it is
  # dormant while every verb file carries the frontmatter flag that withholds it from the model — so
  # this grades that the text is THERE and says nothing about whether it is followed. It is not a
  # third C2 limb and C2 does not read it: a dormant rule counted as a gate would be the conflation
  # C3 exists to keep visible. The comparand is read from the files and compared across them; this
  # guard holds only the locator, never the requirement. The flag count is reported beside it, read
  # off the POSTURE records, so the dormancy the verdict states is measured on the same run.
  local -a RDIST=()
  local nrf=0 ncarry=0 nflag=0 hitsr ru rcar
  for f in "${FILES[@]+"${FILES[@]}"}"; do
    nrf=$((nrf+1))
    hitsr=0
    for (( i=0; i<${#RUC[@]}; i++ )); do [ "${RUC[$i]}" = "$f" ] && hitsr=$((hitsr+1)); done
    if [ "$hitsr" -eq 0 ]; then
      printf 'FINDING C5 %s carries no statement of the standing confirm rule — no bold statement opening "%s" at fence depth 0, where the other verb files state it\n' "$f" "$CONFIRM_RULE_LOCATOR"; rc=1
    else
      ncarry=$((ncarry+1))
    fi
    for (( j=0; j<${#PC[@]}; j++ )); do
      if [ "${PC[$j]}" = "$f" ] && [ "${PV[$j]}" != '-' ]; then nflag=$((nflag+1)); fi
    done
  done
  for (( i=0; i<${#RUT[@]}; i++ )); do
    in_list "${RUT[$i]}" "${RDIST[@]+"${RDIST[@]}"}" || RDIST+=( "${RUT[$i]}" )
  done
  if [ "${#RDIST[@]}" -gt 1 ]; then
    for ru in "${RDIST[@]}"; do
      rcar=''
      for (( i=0; i<${#RUT[@]}; i++ )); do [ "${RUT[$i]}" = "$ru" ] && rcar="$rcar${RUC[$i]} "; done
      printf 'FINDING C5 the standing confirm rule is stated in %d different renderings across the verb files — [ %s] state it as: "%s"\n' "${#RDIST[@]}" "$rcar" "$ru"
    done
    rc=1
  fi
  printf 'COUNT CRULEFILES %d\n' "$nrf"
  printf 'COUNT CRULECARRY %d\n' "$ncarry"
  printf 'COUNT CRULEFORMS %d\n' "${#RDIST[@]}"
  printf 'COUNT CRULEFLAG %d\n' "$nflag"

  # ── CE1/CE2/CE3 — the carrier at the engine root.
  if [ ! -f "$carrier" ]; then
    printf 'FINDING L1 the guided-entry carrier is absent or unreadable at the engine root — the surface every other assertion in this group assumes is not there\n'; rc=1
    printf 'COUNT LVERBS -1\n'
    return "$rc"
  fi
  local cline cfd=0 cnorm cverbs=0 cflag=0 cw=0 cd=0 co=0 vtok
  local -a CL=()
  while IFS= read -r cline || [ -n "$cline" ]; do CL+=( "$cline" ); done < "$carrier"
  local whole=''
  for (( i=0; i<${#CL[@]}; i++ )); do
    cline="${CL[$i]}"
    [ "$(trim "$cline")" = 'disable-model-invocation: true' ] && cflag=1
    case "$(trim "$cline")" in 'disable-model-invocation:'*) cflag=1 ;; esac
    whole="$whole $cline"
  done
  cnorm="$(neg_norm "$whole")"
  [[ "$cnorm" =~ $NEG_W_RE ]] && cw=1
  [[ "$cnorm" =~ $NEG_D_RE ]] && cd=1
  [[ "$cnorm" =~ $NEG_O_RE ]] && co=1

  # CE1 — the carrier holds no verb token of any command. The population is the live declared
  # verb set, read from the record stream; no list is held here in either direction.
  for k in "${DK[@]+"${DK[@]}"}"; do
    vtok="${k#*:}"
    [ "$vtok" = "$k" ] && continue
    [ -n "$vtok" ] || continue
    case "$cnorm" in
      *" ${k%%:*} $vtok"*)
        cverbs=$((cverbs+1))
        printf 'FINDING L1 the carrier names the verb token "%s %s". It is specified to hold no verb list: a second enumeration of the verb set on the one page a new reader meets first is the drift surface the inverted dependency exists to remove\n' "${k%%:*}" "$vtok"; rc=1 ;;
    esac
  done
  printf 'COUNT LVERBS %d\n' "$cverbs"

  if [ "$cflag" -eq 1 ]; then
    printf 'FINDING L2 the carrier carries a disable-model-invocation key. Its ABSENCE is the whole mechanism — setting it would withhold this surface from the model and silently disable guided entry while every other assertion in this suite stayed green\n'; rc=1
  fi
  if [ "$cw" -ne 1 ] || [ "$cd" -ne 1 ] || [ "$co" -ne 1 ]; then
    printf 'FINDING L3 the carrier does not declare all three negatives (writes=%d dispatch=%d outside-effect=%d). It is the one surface in this engine that is NOT withheld from the model, so what it may do is required to be written down rather than assumed\n' "$cw" "$cd" "$co"; rc=1
  fi
  printf 'COUNT LNEG %d\n' $(( cw*4 + cd*2 + co ))
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# derive_surface_block <records>
#
# The command reference's DERIVED region, recomputed from the record stream. This is the
# single producer: group H compares the committed region against it, and the fixture
# generator writes its document from it, so a fixture can never be "correct" by a rule
# the live check does not apply.
#
# ORDERING IS PART OF THE VALUE and is fixed here rather than inherited: commands in
# LC_ALL=C order, rows in the order their file declares them. A glob's order is the
# runner's collation, which is not a property of this repository — deriving the order
# from one would make the same tree pass on one machine and fail on another.
#
# Only the FOUR non-verb requirement columns come from ROW; the argument signature comes
# from SIG, and a verb with no signature renders an em dash rather than an empty cell, so
# "takes no argument" is stated rather than left as whitespace a reader must interpret.
# ─────────────────────────────────────────────────────────────────────────────────
derive_surface_block() {
  local recs="$1"
  local line t c v s i
  local -a RC=() RV=() R1=() R2=() R3=() R4=() SC=() SV=() SS_=()
  local -a F=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'ROW '*)
        IFS='|' read -r -a F <<< "${line#ROW }"
        [ "${#F[@]}" -eq 6 ] || continue
        RC+=( "${F[0]}" ); RV+=( "${F[1]}" )
        R1+=( "${F[2]}" ); R2+=( "${F[3]}" ); R3+=( "${F[4]}" ); R4+=( "${F[5]}" )
        ;;
      'SIG '*)
        # Parsed by prefix rather than by a field split, so a signature that itself
        # contains a pipe survives transport intact.
        t="${line#SIG }"
        c="${t%%|*}"; t="${t#*|}"
        v="${t%%|*}"; s="${t#*|}"
        SC+=( "$c" ); SV+=( "$v" ); SS_+=( "$s" )
        ;;
    esac
  done <<< "$recs"

  printf '| Command | Verb | Arguments | Lifecycle | Mode | Destination | Depth |\n'
  printf '|---|---|---|---|---|---|---|\n'

  local -a ORDER=()
  local cn
  while IFS= read -r cn || [ -n "$cn" ]; do
    [ -n "$cn" ] && ORDER+=( "$cn" )
  done <<< "$(printf '%s\n' "${RC[@]+"${RC[@]}"}" | LC_ALL=C sort -u)"

  local args k
  for cn in "${ORDER[@]+"${ORDER[@]}"}"; do
    for (( i=0; i<${#RC[@]}; i++ )); do
      [ "${RC[$i]}" = "$cn" ] || continue
      s=''
      for (( k=0; k<${#SC[@]}; k++ )); do
        if [ "${SC[$k]}" = "$cn" ] && [ "${SV[$k]}" = "${RV[$i]}" ]; then s="${SS_[$k]}"; break; fi
      done
      if [ -n "$s" ]; then args="${BT}${s}${BT}"; else args="$EMDASH"; fi
      printf '| %s%s%s | %s%s%s | %s | %s | %s | %s | %s |\n' \
        "$BT" "$cn" "$BT" "$BT" "${RV[$i]}" "$BT" "$args" \
        "${R1[$i]}" "${R2[$i]}" "${R3[$i]}" "${R4[$i]}"
    done
  done
}

# ─────────────────────────────────────────────────────────────────────────────────
# picker_check <records> <doc-path> <command-dir>
#
# Group H's producer. Two independent limbs:
#
#   H1/H2/H3 — the per-file PICKER DECLARATION. `parse_command_file` reads no frontmatter
#   at all, which is exactly why the taxonomy suite never saw this defect: a file could
#   declare a bare placeholder hint, or none, and every existing assertion stayed green.
#   These three read the frontmatter and nothing else from it.
#
#   H4/H5 — the command reference's DERIVED REGION, compared against derive_surface_block.
#
# WHAT A HINT IS TAKEN TO ENUMERATE, stated because a looser rule would silently pass the
# defect this group exists to catch. The verb list is the hint's FIRST whitespace-
# delimited word, split on '|'. Everything after the first space is argument syntax
# (`[--trip <slug>]`, a continuation marker) and is not read as a verb claim. That rule is
# what makes a bare `<verb>` fail rather than pass: it is the first word, it splits to one
# token, and that token is not a declared verb — the degenerate case of H2 rather than a
# special case beside it.
#
# H1/H2/H3 fire only on a RESOLVE-role file. The role comes from the ROLE record the
# charter emits, read LIVE, so the carve-out moves when the charter moves; it is never a
# filename test. A file with no ROLE record defaults to RESOLVE, which is the same default
# the record-collection path already applies.
# ─────────────────────────────────────────────────────────────────────────────────
picker_check() {
  local recs="$1" doc="$2" cdir="$3"
  local rc=0 line t f base cmd role hint desc word tok v i
  local n_res=0 n_verbs=0 n_rows=0
  local -a DECLV=() ROLEC=() ROLER=()

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      'ROLE '*) t="${line#ROLE }"; ROLEC+=( "${t%% *}" ); ROLER+=( "${t##* }" ) ;;
    esac
  done <<< "$recs"

  for f in "$cdir"/*/SKILL.md; do
    [ -e "$f" ] || continue
    base="$(verb_id "$f")"; cmd="/$base"
    role='RESOLVE'
    for (( i=0; i<${#ROLEC[@]}; i++ )); do
      [ "${ROLEC[$i]}" = "$cmd" ] && { role="${ROLER[$i]}"; break; }
    done
    [ "$role" = 'RESOLVE' ] || continue

    DECLV=()
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in "DECL $cmd "*) DECLV+=( "${line##* }" ) ;; esac
    done <<< "$recs"
    # A file with no declared verb is already reported by V0/V1; quantifying the hint
    # rules over an empty declared set would turn that into a second, misleading finding.
    [ "${#DECLV[@]}" -gt 0 ] || continue
    n_res=$((n_res+1)); n_verbs=$(( n_verbs + ${#DECLV[@]} ))

    hint=''; desc=''
    local infm=0 nfence=0
    while IFS= read -r line || [ -n "$line" ]; do
      if [ "$line" = '---' ]; then
        nfence=$((nfence+1))
        if [ "$nfence" -eq 1 ]; then infm=1; continue; fi
        break
      fi
      [ "$infm" -eq 1 ] || continue
      case "$line" in
        'argument-hint:'*) hint="$(trim "${line#argument-hint:}")" ;;
        'description:'*)   desc="$(trim "${line#description:}")" ;;
      esac
    done < "$f"

    if [ -z "$hint" ]; then
      printf 'FINDING H1 %s declares no argument-hint — the one surface that renders at the moment a verb is chosen names nothing\n' "$cmd"
      rc=1
      continue
    fi

    word="${hint%% *}"
    local -a TOKS=()
    local rest="$word"
    while :; do
      tok="${rest%%|*}"
      TOKS+=( "$tok" )
      [ "$rest" = "$tok" ] && break
      rest="${rest#*|}"
    done

    local missing='' ghost=''
    for tok in "${TOKS[@]}"; do
      if [ -z "$tok" ]; then
        printf 'FINDING H2 %s argument-hint carries an empty verb token — the pipe-joined list is malformed: "%s"\n' "$cmd" "$hint"
        rc=1
        continue
      fi
      in_list "$tok" "${DECLV[@]+"${DECLV[@]}"}" || ghost="$ghost$tok "
    done
    if [ -n "$ghost" ]; then
      printf 'FINDING H2 %s argument-hint names token(s) the file declares no verb for: %s— outward drift, and a bare placeholder is its degenerate case\n' "$cmd" "$ghost"
      rc=1
    fi

    for v in "${DECLV[@]}"; do
      in_list "$v" "${TOKS[@]+"${TOKS[@]}"}" || missing="$missing$v "
    done
    if [ -n "$missing" ]; then
      case "$desc" in
        *"$DOC_REL"*) ;;
        *)
          printf 'FINDING H3 %s argument-hint omits declared verb(s) %s and its description points at no reference — overflow is permitted, silence is not\n' "$cmd" "$missing"
          rc=1
          ;;
      esac
    fi
  done

  printf 'COUNT HRESOLVE %d\n' "$n_res"
  printf 'COUNT HVERBS %d\n' "$n_verbs"

  # ── H4/H5: the reference document.
  if [ ! -f "$doc" ] || [ ! -r "$doc" ]; then
    printf 'FINDING H4 the command reference is absent or unreadable: %s\n' "$DOC_REL"
    return 1
  fi
  local nopen=0 nclose=0 iopen=-1 iclose=-1 n=0
  local -a DL=()
  while IFS= read -r line || [ -n "$line" ]; do
    DL+=( "$line" )
    if [ "$line" = "$DOC_MARK_OPEN" ];  then nopen=$((nopen+1));  [ "$iopen"  -lt 0 ] && iopen=$n;  fi
    if [ "$line" = "$DOC_MARK_CLOSE" ]; then nclose=$((nclose+1)); [ "$iclose" -lt 0 ] && iclose=$n; fi
    n=$((n+1))
  done < "$doc"
  if [ "$nopen" -ne 1 ] || [ "$nclose" -ne 1 ]; then
    printf 'FINDING H4 %s carries %d opening and %d closing derived-region marker(s), expected exactly 1 of each — the derived region has no unambiguous bounds\n' "$DOC_REL" "$nopen" "$nclose"
    return 1
  fi
  if [ "$iclose" -le "$iopen" ]; then
    printf 'FINDING H4 %s closes its derived region before it opens it\n' "$DOC_REL"
    return 1
  fi

  local got='' want=''
  for (( i=iopen+1; i<iclose; i++ )); do got="$got${DL[$i]}"$'\n'; done
  want="$(derive_surface_block "$recs")"
  want="$want"$'\n'
  local wl
  while IFS= read -r wl || [ -n "$wl" ]; do
    case "$wl" in '| '*) n_rows=$((n_rows+1)) ;; esac
  done <<< "$want"
  # minus the header row; the separator does not match the '| ' prefix
  printf 'COUNT HROWS %d\n' "$(( n_rows - 1 ))"
  if [ "$got" != "$want" ]; then
    printf 'FINDING H5 %s derived region disagrees with the live requirement tables — the committed block is stale\n' "$DOC_REL"
    while IFS= read -r line || [ -n "$line" ]; do
      printf 'H5EXPECT %s\n' "$line"
    done <<< "$want"
    rc=1
  fi
  return "$rc"
}

# ═════════════════════════════════════════════════════════════════════════════════
# Group J — every file an agent writes is named in that agent's roster row.
#
# THE PROPERTY. `CLAUDE.md` § *Dispatching agents* carries the agent roster, and `/trip`'s
# dispatching verbs send each agent out "in the role or roles its roster row states, each
# writing exactly the file or files that row names". That sentence is true only while every
# file an agent writes is named in its row. This group reads what each agent writes from the
# two places that declare it, and fails for every written file its row does not name:
#
#   (a) `reference/data-architecture.md` § 1.1, the W (writer) column — the one declaration of
#       who writes each in-model class. A class is expected in a row when that row's writer id
#       occurs in the class's W cell as a whole token. A prose cell ("hub (primary); enrichment
#       seeds; `/trip-record event`") therefore expects the class in every row it names. A cell
#       naming no roster writer — a sentinel (`block-owned`), a human author, an operator verb,
#       `site-build`, or "the spoke that re-ran" — expects nothing here, and the run prints
#       that census rather than hiding it.
#   (b) The agent's own prompt — every `artifact:` value in a frontmatter block that the prompt
#       emits, and every path one of its Output headings names. A block counts for the prompt's
#       own row when it carries no `writer:` key, or when its writer (a bare id, or a bracketed
#       list) includes the prompt's own id. A block whose writer list excludes the prompt's id
#       is another writer's, quoted, and is skipped. An Output heading is a line at column 0
#       and fence depth 0 that opens `### Output: `, `### File: ` or `### Pre-Work Output <N>: `.
#       Its path is the first word after the colon, with a code span's backticks removed, and a
#       bare file name — the Pre-Work form — names a file under `outputs/`, where the prompt's
#       own frontmatter for that file writes it. A heading declares its own prompt's write: it
#       carries no writer that could exclude it. Those three forms are an ENUMERATION WITH A
#       STATED BOUNDARY, not a closed class: a heading at another depth, or one that renders an
#       output under another label, is not read, and a fenced or indented heading is an example.
#
# THE JOIN, AND WHERE IT COMES FROM. A roster row names its prompt (`Prompt File`), and the
# prompt's own frontmatter exemplars name its writer id — the same token § 1.1's W column
# uses. No map from display name to id is held here: the id is read from the prompt, the
# classes from § 1.1, the named files from the row. A prompt whose exemplars carry no bare
# writer id, or more than one, cannot be joined, and that is J0 rather than a guess. A row
# whose id no § 1.1 W cell names is J2: its § 1.1 limb would be empty, which is the silent
# shrink this group exists to prevent.
#
# WHAT "NAMED" MEANS. A file is named in a row when it is the whole content of a code span in
# that row's `Output File` cell. Prose mentions do not count — the roster renders every path
# it names as a code span, and `/trip research`'s key filter counts paths the same way.
#
# ONE DIRECTION, BY DESIGN. This group asserts expected ⊆ named. It does not assert the
# converse: the Enrichment row names `trip-context.md`, whose § 1.1 W cell is the
# `block-owned` sentinel that § 4.4 says no tool resolves to a writer — so a converse check
# would need an exception list, which is a second source of truth. Declared residual.
#
# A SPAN IS A NAME WHATEVER THE SENTENCE AROUND IT SAYS. A span inside a clause that denies
# the write still counts: the Validator row's "reads `event-status.md`, never writes it" is
# the live instance, and it names no expected path, because it carries no `outputs/` prefix.
# Grading the grammar around a span is not a structural check, so this is declared here
# rather than parsed away. Declared residual.
#
# A CLASS THAT LANDS BEFORE ITS WRITER IS NAMED AS DECLARED, NOT WRITTEN. From the commit that
# adds a § 1.1 class row, limb (a) expects the file in its writer's roster row — and that row is
# an instruction: the dispatching verbs send the agent out writing "exactly the file or files
# that row names". So where a class lands before the agent that writes it emits it, the row
# names it inside a clause that says so — "declares `outputs/<file>`, not written before <the
# landing that ships its writer>" — and the landing that ships the writer rewrites that clause
# to the verb that writes the file. J1 passes on either wording, by the residual above, and its
# failure text states this rule where the omission is met. The rule binds every such landing,
# not only the one that raised it; arm GJ0 keeps the declared wording passable.
#
# A QUOTED BLOCK CARRIES ITS WRITER IN LIST FORM. A prompt may quote another agent's frontmatter
# block — as the contract of a file it reads, say. Such a block carries its writer as a list,
# `writer: [enrichment]`, which is never read as the prompt's own id and, naming another id, is
# skipped. The other two shapes are read as the prompt's own declaration, and each fails closed
# where it is met: a bare foreign `writer:` gives the prompt two ids, which is J0, and a block
# with no `writer:` is attributed to the prompt, which is J1. Each finding names the list form.
# GJ0 plants the list form as a near miss; GJ6 and GJ7 build the two failing shapes.
#
# TWO READERS OF ONE CELL. `skills/trip/SKILL.md` § *research* derives `/trip research`'s agent
# key from this same `Output File` cell, admitting a row only when it names exactly one path
# under `outputs/`. This group makes that cell a complete write list, so its own remedy — name
# the file — can take a spoke out of that key, and nothing here observes the key set. J1's
# finding names that coupling whenever the row it flags names exactly one `outputs/` path, so
# the key is settled in the same change; arm GJ9 holds that, both ways. Deriving the key from
# § 1.1 rather than from a count of paths is the structural fix, and it is outside this group.
# Declared residual.
#
# PORTABILITY. No awk (so mawk and gawk cannot disagree), no bash-4-only syntax, and every
# character set is spelled out rather than written as a range, because a range is resolved
# against the locale's collation (see scripts/validate-artifacts.sh on the same hazard).
# ═════════════════════════════════════════════════════════════════════════════════
RJ_COLS='agent|prompt file|output file|when to dispatch'
RJ_ARCH_REL='reference/data-architecture.md'
RJ_CLASS_HEAD='### 1.1 '
RJ_DIGITS='0123456789'
RJ_SLUGSET='abcdefghijklmnopqrstuvwxyz0123456789-'
RJ_OUTDIR='outputs/'
RJ_HEAD_OUT='### Output: '
RJ_HEAD_FILE='### File: '
RJ_HEAD_PRE='### Pre-Work Output '

# rj_trimv <var> <s> — <s> with leading and trailing whitespace removed, into <var>. Fork-free:
# every helper below writes a variable rather than printing, because a command substitution per
# line is a fork per line, and the three inputs this reader walks are thousands of lines long.
rj_trimv() { local _rj_t="$2"; _rj_t="${_rj_t#"${_rj_t%%[![:space:]]*}"}"; _rj_t="${_rj_t%"${_rj_t##*[![:space:]]}"}"; printf -v "$1" '%s' "$_rj_t"; }

# rj_norm <cell> — code-span and bold markers removed, whitespace collapsed and trimmed,
# lower-cased. Only header candidates reach it, so the one `tr` it costs is bounded.
rj_norm() {
  local s="$1"
  s="${s//\`/}"; s="${s//\*\*/}"; s="${s//$'\t'/ }"
  while [[ "$s" == *'  '* ]]; do s="${s//  / }"; done
  rj_trimv s "$s"
  lower "$s"
}

# rj_spansv <var> <text> — the content of each single-backtick code span, newline-joined, into <var>.
rj_spansv() {
  local _rj_s="$2" _rj_span _rj_out=''
  while [[ "$_rj_s" == *'`'*'`'* ]]; do
    _rj_s="${_rj_s#*\`}"; _rj_span="${_rj_s%%\`*}"; _rj_s="${_rj_s#*\`}"
    _rj_out="$_rj_out$_rj_span"$'\n'
  done
  printf -v "$1" '%s' "$_rj_out"
}

# rj_tokensv <var> <text> — the maximal runs of lower-case letters, digits and '-', space-padded,
# so a membership test is `case "$toks" in *" id "*)`. Every other character becomes a space;
# upper case is not folded, because a writer id is a lower-case slug by § 4.4's schema.
rj_tokensv() {
  local _rj_k="$2"
  _rj_k="${_rj_k//[!abcdefghijklmnopqrstuvwxyz0123456789-]/ }"
  while [[ "$_rj_k" == *'  '* ]]; do _rj_k="${_rj_k//  / }"; done
  rj_trimv _rj_k "$_rj_k"
  printf -v "$1" ' %s ' "$_rj_k"
}

# rj_is_slug <s> — a bare writer id: a lower-case letter or digit, then letters, digits, '-'.
rj_is_slug() {
  case "$1" in
    ''|*[!abcdefghijklmnopqrstuvwxyz0123456789-]*) return 1 ;;
    [abcdefghijklmnopqrstuvwxyz0123456789]*) return 0 ;;
  esac
  return 1
}

# rj_headv <var> <line> — the path an Output heading declares, into <var>; empty when <line> is
# not one of the three forms at column 0. The path is the first word after the colon, with a code
# span's backticks removed, and a bare file name (the Pre-Work form) is a file under outputs/.
rj_headv() {
  local _rj_h="$2" _rj_n
  case "$_rj_h" in
    "$RJ_HEAD_OUT"*)  _rj_h="${_rj_h#"$RJ_HEAD_OUT"}" ;;
    "$RJ_HEAD_FILE"*) _rj_h="${_rj_h#"$RJ_HEAD_FILE"}" ;;
    "$RJ_HEAD_PRE"*': '*)
      _rj_n="${_rj_h#"$RJ_HEAD_PRE"}"; _rj_n="${_rj_n%%:*}"
      case "$_rj_n" in ''|*[!0123456789]*) printf -v "$1" '%s' ''; return 0 ;; esac
      _rj_h="${_rj_h#*: }" ;;
    *) printf -v "$1" '%s' ''; return 0 ;;
  esac
  rj_trimv _rj_h "$_rj_h"; _rj_h="${_rj_h%% *}"; _rj_h="${_rj_h//\`/}"
  case "$_rj_h" in ''|*/*) ;; *) _rj_h="$RJ_OUTDIR$_rj_h" ;; esac
  printf -v "$1" '%s' "$_rj_h"
}

# roster_write_check <root> — the subject. Emits FINDING J0|J1|J2 lines, one RJEXP line per
# expected (row, file) pair with its sources, one RJUNJOINED census line, and the COUNT lines
# the three assertions below read. It returns 0 always: its verdicts are carried by its output.
roster_write_check() {
  local root="$1" md arch lineno=0 line t depth=0 first
  md="$root/CLAUDE.md"; arch="$root/$RJ_ARCH_REL"
  local -a R_AGENT=() R_PROMPT=() R_OUT=() R_LINE=() R_ID=() C_N=() C_CLASS=() C_W=() C_TOK=()
  local anchors=0 anchor_line=0 degraded=0 rows=0 classes=0 declared='' heads=0 i j k near=''

  # ── 1. The roster. Anchored on its own header row, matched structurally and only at
  # fence depth 0, so a fenced example of the table is an example and not a second anchor.
  if [ ! -r "$md" ]; then
    printf 'FINDING J0 CLAUDE.md is absent or unreadable — the roster cannot be read\n'
    degraded=$((degraded+1))
  else
    local -a MDL=()
    while IFS= read -r line || [ -n "$line" ]; do MDL+=("$line"); done < "$md"
    for (( i=0; i<${#MDL[@]}; i++ )); do
      line="${MDL[$i]}"
      case "$line" in *'```'*|*'|'*) ;; *) continue ;; esac
      rj_trimv t "$line"
      case "$t" in '```'*) depth=$((1-depth)); continue ;; esac
      [ "$depth" -eq 0 ] || continue
      case "$t" in '|'*) ;; *) continue ;; esac
      first="${t#|}"; first="${first%%|*}"; first="${first//\`/}"; first="${first//\*\*/}"
      rj_trimv first "$first"
      case "$first" in [Aa][Gg][Ee][Nn][Tt]) ;; *) continue ;; esac
      local -a HC=(); local hn=''
      IFS='|' read -r -a HC <<< "${t%|}"
      for (( j=1; j<${#HC[@]}; j++ )); do hn="${hn:+$hn|}$(rj_norm "${HC[$j]}")"; done
      if [ "$hn" = "$RJ_COLS" ]; then
        anchors=$((anchors+1)); anchor_line=$i
      else
        near="${near:+$near; }line $((i+1)) reads \"$hn\""
      fi
    done
    if [ "$anchors" -ne 1 ]; then
      printf 'FINDING J0 CLAUDE.md carries %d roster header row(s) at fence depth 0, expected exactly 1 — at 0 the roster was renamed, reordered, widened or removed, at 2+ which table is the roster is ambiguous. Near misses opening with "Agent": %s\n' "$anchors" "${near:-none}"
    else
      i=$((anchor_line+1)); rj_trimv t "${MDL[$i]:-}"
      if ! is_sep "$t"; then
        printf 'FINDING J0 CLAUDE.md:%d the roster header has no delimiter row beneath it\n' "$((i+1))"
      else
        for (( i=anchor_line+2; i<${#MDL[@]}; i++ )); do
          rj_trimv t "${MDL[$i]}"
          case "$t" in '|'*) ;; *) break ;; esac
          local -a RC=()
          IFS='|' read -r -a RC <<< "${t%|}"
          if [ "${#RC[@]}" -ne 5 ]; then
            printf 'FINDING J0 CLAUDE.md:%d a roster row splits into %d cell(s), expected 4 — its files cannot be read from the right column\n' "$((i+1))" "$((${#RC[@]}-1))"
            continue
          fi
          local ag pr pc=0 s sp=''
          rj_trimv ag "${RC[1]//\*\*/}"
          pr=''
          rj_spansv sp "${RC[2]}"
          while IFS= read -r s; do
            [ -n "$s" ] || continue
            case "$s" in agents/*.md) pc=$((pc+1)); pr="$s" ;; esac
          done <<< "$sp"
          if [ "$pc" -ne 1 ]; then
            printf 'FINDING J0 CLAUDE.md:%d the roster row "%s" names %d prompt path(s) in its Prompt File cell, expected exactly one agents/<name>.md span\n' "$((i+1))" "$ag" "$pc"
            continue
          fi
          R_AGENT+=("$ag"); R_PROMPT+=("$pr"); R_OUT+=("${RC[3]}"); R_LINE+=("$((i+1))")
        done
      fi
    fi
  fi
  rows=${#R_AGENT[@]}
  [ "$anchors" -eq 1 ] && [ "$rows" -eq 0 ] && \
    printf 'FINDING J0 CLAUDE.md the roster header has no data rows beneath it — the population is empty\n'

  # ── 2. § 1.1. The section is located by its heading's section number, not by its title or
  # its class count, so adding a class moves nothing here; the count the heading declares is
  # then compared with the rows read, which is what makes a partial read a finding.
  if [ ! -r "$arch" ]; then
    printf 'FINDING J0 %s is absent or unreadable — the writer column cannot be read\n' "$RJ_ARCH_REL"
    degraded=$((degraded+1))
  else
    local inside=0 hdr='' rowre="^\\|[[:space:]]*[${RJ_DIGITS}]+[[:space:]]*\\|[[:space:]]*\`"
    depth=0; lineno=0
    while IFS= read -r line || [ -n "$line" ]; do
      lineno=$((lineno+1))
      case "$line" in *'```'*|'#'*|*'|'*) ;; *) continue ;; esac
      rj_trimv t "$line"
      case "$t" in '```'*) depth=$((1-depth)); continue ;; esac
      [ "$depth" -eq 0 ] || continue
      case "$line" in
        "$RJ_CLASS_HEAD"*) heads=$((heads+1)); inside=1; hdr="$line"; continue ;;
        '### '*|'## '*) inside=0; continue ;;
      esac
      [ "$inside" -eq 1 ] || continue
      [[ "$line" =~ $rowre ]] || continue
      local -a CC=()
      IFS='|' read -r -a CC <<< "${t%|}"
      if [ "${#CC[@]}" -ne 8 ]; then
        printf 'FINDING J0 %s:%d a class row splits into %d cell(s), expected 7 — its writer cell cannot be read from the right column\n' "$RJ_ARCH_REL" "$lineno" "$((${#CC[@]}-1))"
        continue
      fi
      local cn cl cw ctok
      rj_trimv cn "${CC[1]}"
      cl="${CC[2]#*\`}"; cl="${cl%%\`*}"
      cw="${CC[3]//\*\*/}"; cw="${cw//\`/}"; rj_trimv cw "$cw"
      rj_tokensv ctok "$cw"
      C_N+=("$cn"); C_CLASS+=("$cl"); C_W+=("$cw"); C_TOK+=("$ctok")
    done < "$arch"
    classes=${#C_N[@]}
    if [ "$heads" -ne 1 ]; then
      printf 'FINDING J0 %s carries %d heading line(s) opening "%s" at fence depth 0, expected exactly 1\n' "$RJ_ARCH_REL" "$heads" "$RJ_CLASS_HEAD"
    else
      declared="${hdr##*(}"; declared="${declared%%)*}"
      case "$declared" in
        ''|*[!0123456789]*) printf 'FINDING J0 %s the § 1.1 heading declares no class count in a trailing "(N)"\n' "$RJ_ARCH_REL"; declared='' ;;
        *) [ "$declared" -eq "$classes" ] || \
             printf 'FINDING J0 %s the § 1.1 heading declares %s class(es) and %d row(s) were read — a row this reader cannot see would expect nothing anywhere\n' "$RJ_ARCH_REL" "$declared" "$classes" ;;
      esac
      [ "$classes" -gt 0 ] || printf 'FINDING J0 %s the § 1.1 table has no class rows — the population is empty\n' "$RJ_ARCH_REL"
    fi
  fi

  # ── 3. Each row's prompt: its own writer id, the artifacts its own blocks declare, and the
  # paths its Output headings declare.
  local -a P_ART=() P_NW=() P_HEAD=()
  for (( i=0; i<rows; i++ )); do
    local pf="$root/${R_PROMPT[$i]}" ids='' nids=0 arts='' bw='' ba='' w m
    local own='' nwl='' nwo='' hl='' hp pl=0 fd=0
    if [ ! -r "$pf" ]; then
      printf 'FINDING J0 %s the prompt the roster row "%s" names is absent or unreadable — its writer id and declared outputs are UNMEASURED, never empty\n' "${R_PROMPT[$i]}" "${R_AGENT[$i]}"
      degraded=$((degraded+1)); R_ID+=(''); P_ART+=(''); P_NW+=(''); P_HEAD+=(''); continue
    fi
    # Pass 1: blocks, and headings. A block is bounded by a line whose trimmed text is `---` or
    # opens a fence. A heading is read at column 0 and at fence depth 0 only.
    local -a BW=() BA=(); bw=''; ba=''
    while IFS= read -r line || [ -n "$line" ]; do
      pl=$((pl+1))
      case "$line" in *'---'*|*'```'*|*'writer:'*|*'artifact:'*|'### '*) ;; *) continue ;; esac
      rj_trimv t "$line"
      case "$t" in
        '---'|'```'*)
          case "$t" in '```'*) fd=$((1-fd)) ;; esac
          BW+=("$bw"); BA+=("$ba"); bw=''; ba=''; continue ;;
        'writer:'*) rj_trimv bw "${t#writer:}" ;;
        'artifact:'*) rj_trimv m "${t#artifact:}"; m="${m%% *}"; ba="$ba$m"$'\n' ;;
      esac
      case "$line" in '### '*) ;; *) continue ;; esac
      [ "$fd" -eq 0 ] || continue
      rj_headv hp "$line"
      [ -n "$hp" ] || continue
      case $'\n'"$hl" in *$'\n'"$hp"$'\t'*) ;; *) hl="$hl$hp"$'\t'"$pl"$'\n' ;; esac
    done < "$pf"
    BW+=("$bw"); BA+=("$ba")
    for (( k=0; k<${#BW[@]}; k++ )); do
      w="${BW[$k]}"
      rj_is_slug "$w" || continue
      case " $ids " in *" $w "*) ;; *) ids="${ids:+$ids }$w"; nids=$((nids+1)) ;; esac
    done
    if [ "$nids" -ne 1 ]; then
      if [ "$nids" -gt 1 ]; then
        printf 'FINDING J0 %s declares %d bare writer id(s) in its frontmatter exemplars ("%s"), expected exactly one — the row "%s" cannot be joined to § 1.1. A block that quotes the artifact of another agent carries its writer in list form, writer: [<id>], which is never read as the id of this prompt\n' "${R_PROMPT[$i]}" "$nids" "$ids" "${R_AGENT[$i]}"
      else
        printf 'FINDING J0 %s declares %d bare writer id(s) in its frontmatter exemplars ("%s"), expected exactly one — the row "%s" cannot be joined to § 1.1\n' "${R_PROMPT[$i]}" "$nids" "$ids" "${R_AGENT[$i]}"
      fi
      R_ID+=(''); P_ART+=(''); P_NW+=(''); P_HEAD+=(''); continue
    fi
    R_ID+=("$ids")
    # Pass 2: the blocks that are this prompt's own, de-duplicated in first-seen order. An
    # artifact that only a block with no writer declares is remembered as such, so a finding it
    # causes can name the list form a quoted block carries.
    for (( k=0; k<${#BW[@]}; k++ )); do
      [ -n "${BA[$k]}" ] || continue
      w="${BW[$k]}"
      if [ -n "$w" ]; then
        w="${w#\[}"; w="${w%\]}"; w=" ${w//,/ } "
        case "$w" in *" $ids "*) ;; *) continue ;; esac
      fi
      while IFS= read -r m; do
        [ -n "$m" ] || continue
        if [ -n "${BW[$k]}" ]; then own="$own$m"$'\n'; else nwl="$nwl$m"$'\n'; fi
        case $'\n'"$arts" in *$'\n'"$m"$'\n'*) continue ;; esac
        arts="$arts$m"$'\n'
      done <<< "${BA[$k]}"
    done
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      case $'\n'"$own" in *$'\n'"$m"$'\n'*) continue ;; esac
      case $'\n'"$nwo" in *$'\n'"$m"$'\n'*) continue ;; esac
      nwo="$nwo$m"$'\n'
    done <<< "$nwl"
    P_ART+=("$arts"); P_NW+=("$nwo"); P_HEAD+=("$hl")
  done

  # ── 4. The join and the comparison.
  local exp=0 fromc=0 fromp=0 fromh=0 joined=0 unjoined='' named path srcs p m2
  for (( j=0; j<classes; j++ )); do
    m2=0
    for (( i=0; i<rows; i++ )); do
      [ -n "${R_ID[$i]}" ] || continue
      case "${C_TOK[$j]}" in *" ${R_ID[$i]} "*) m2=1 ;; esac
    done
    if [ "$m2" -eq 1 ]; then joined=$((joined+1)); else unjoined="$unjoined C${C_N[$j]}"; fi
  done
  for (( i=0; i<rows; i++ )); do
    [ -n "${R_ID[$i]}" ] || continue
    rj_spansv named "${R_OUT[$i]}"
    local want='' hits=0 nout=0 sn hint
    while IFS= read -r sn; do case "$sn" in "$RJ_OUTDIR"*) nout=$((nout+1)) ;; esac; done <<< "$named"
    for (( j=0; j<classes; j++ )); do
      case "${C_TOK[$j]}" in *" ${R_ID[$i]} "*) ;; *) continue ;; esac
      hits=$((hits+1))
      want="$want${C_CLASS[$j]}"$'\t'"§ 1.1 C${C_N[$j]}"$'\n'
    done
    [ "$hits" -gt 0 ] || printf 'FINDING J2 CLAUDE.md:%s the roster row "%s" joins as writer id "%s" (read from %s), and no § 1.1 W cell names that id — its § 1.1 limb would be empty rather than checked\n' "${R_LINE[$i]}" "${R_AGENT[$i]}" "${R_ID[$i]}" "${R_PROMPT[$i]}"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case $'\n'"${P_NW[$i]}" in
        *$'\n'"$p"$'\n'*) want="$want$p"$'\t'"the frontmatter ${R_PROMPT[$i]} emits in a block with no writer"$'\n' ;;
        *) want="$want$p"$'\t'"the frontmatter ${R_PROMPT[$i]} emits"$'\n' ;;
      esac
    done <<< "${P_ART[$i]}"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      want="$want${p%%$'\t'*}"$'\t'"the Output heading ${R_PROMPT[$i]}:${p#*$'\t'}"$'\n'
    done <<< "${P_HEAD[$i]}"
    # One line per expected path, sources merged, in first-seen order.
    local seen=$'\n' line2 pth src
    while IFS= read -r line2; do
      [ -n "$line2" ] || continue
      pth="${line2%%$'\t'*}"
      case "$seen" in *$'\n'"$pth"$'\n'*) continue ;; esac
      seen="$seen$pth"$'\n'
      srcs=''
      while IFS= read -r src; do
        [ -n "$src" ] || continue
        [ "${src%%$'\t'*}" = "$pth" ] || continue
        srcs="${srcs:+$srcs; }${src#*$'\t'}"
        case "${src#*$'\t'}" in '§ 1.1'*) fromc=$((fromc+1)) ;; 'the Output heading'*) fromh=$((fromh+1)) ;; *) fromp=$((fromp+1)) ;; esac
      done <<< "$want"
      exp=$((exp+1))
      printf 'RJEXP %s\t%s\t%s\n' "${R_AGENT[$i]}" "$pth" "$srcs"
      case $'\n'"$named" in *$'\n'"$pth"$'\n'*) continue ;; esac
      hint=''
      case "$srcs" in *'in a block with no writer'*) hint="$hint. If that block quotes another agent's artifact rather than declaring this one's, it carries its writer in list form, writer: [<id>], and is then not read as this agent's" ;; esac
      [ "$nout" -eq 1 ] && hint="$hint. This row names exactly one path under outputs/, and that is the rule /trip research's agent key admits a spoke by (skills/trip/SKILL.md § research): naming a second path takes this agent out of that key, so settle the key in the same change"
      printf 'FINDING J1 CLAUDE.md:%s the roster row "%s" does not name "%s", which that agent writes (%s) — the Output File cell names a file only as the whole content of a code span%s\n' "${R_LINE[$i]}" "${R_AGENT[$i]}" "$pth" "$srcs" "$hint"
    done <<< "$want"
  done

  printf 'RJUNJOINED%s\n' "${unjoined:- none}"
  printf 'COUNT J_ROWS %d\n' "$rows"
  printf 'COUNT J_CLASSES %d\n' "$classes"
  printf 'COUNT J_DECLARED %s\n' "${declared:-0}"
  printf 'COUNT J_JOINED %d\n' "$joined"
  printf 'COUNT J_EXPECTED %d\n' "$exp"
  printf 'COUNT J_FROM_CLASS %d\n' "$fromc"
  printf 'COUNT J_FROM_PROMPT %d\n' "$fromp"
  printf 'COUNT J_FROM_HEADING %d\n' "$fromh"
  printf 'COUNT J_DEGRADED %d\n' "$degraded"
  return 0
}

# ── The three assertions. Each calls the subject itself and renders exactly one verdict, so
# `md_flips` can remove the subject and watch the verdict turn FAIL. Every limb before a PASS
# is a FAIL, in this order: NO SUBJECT (no census line) · DEGRADED (an input unread) ·
# VERDICT WITHHELD (J1 and J2 only: J0 has findings, so the population may be partial) ·
# VACUITY (an empty population) · the group's own findings. No PASS is reached on the absence
# of a finding alone: each is gated on counts the subject produced.
rj_counts() {  # rj_counts <out> -> sets RJ_ROWS RJ_CLASSES RJ_DECLARED RJ_JOINED RJ_EXP RJ_FC RJ_FP RJ_FH RJ_DEG RJ_N0 RJ_N1 RJ_N2
  RJ_ROWS="$(getcount "$1" J_ROWS)"; RJ_CLASSES="$(getcount "$1" J_CLASSES)"
  RJ_DECLARED="$(getcount "$1" J_DECLARED)"; RJ_JOINED="$(getcount "$1" J_JOINED)"
  RJ_EXP="$(getcount "$1" J_EXPECTED)"; RJ_FC="$(getcount "$1" J_FROM_CLASS)"
  RJ_FP="$(getcount "$1" J_FROM_PROMPT)"; RJ_FH="$(getcount "$1" J_FROM_HEADING)"
  RJ_DEG="$(getcount "$1" J_DEGRADED)"
  RJ_N0="$(grep -c '^FINDING J0 ' <<<"$1")"; RJ_N1="$(grep -c '^FINDING J1 ' <<<"$1")"
  RJ_N2="$(grep -c '^FINDING J2 ' <<<"$1")"
}

rj_assert_population() {
  local out; out="$(roster_write_check "$1" 2>/dev/null)"; rj_counts "$out"
  if [ -z "$RJ_ROWS" ] || [ -z "$RJ_CLASSES" ] || [ -z "$RJ_EXP" ]; then
    FAIL "J0: NO SUBJECT — the roster-write reader emitted no census, so it did not run and nothing below was measured"
  elif [ "${RJ_DEG:-0}" -ne 0 ]; then
    FAIL "J0: DEGRADED — ${RJ_DEG} input(s) could not be read; what they declare is UNMEASURED, not empty"; show "$out" 'J0'
  elif [ "$RJ_N0" -ne 0 ]; then
    FAIL "J0: ${RJ_N0} structural finding(s) — the roster, § 1.1 or a prompt could not be read into the join as written"; show "$out" 'J0'
  elif [ "$RJ_ROWS" -eq 0 ] || [ "$RJ_CLASSES" -eq 0 ] || [ "$RJ_EXP" -eq 0 ]; then
    FAIL "J0: VACUITY — ${RJ_ROWS} roster row(s), ${RJ_CLASSES} class row(s) and ${RJ_EXP} expected pair(s); a comparison over an empty side proves nothing"
  else
    PASS "J0: the join is measured — ${RJ_ROWS} roster row(s), each joined to its prompt's own writer id; ${RJ_CLASSES} § 1.1 class row(s) read, equal to the ${RJ_DECLARED} the heading declares, of which ${RJ_JOINED} name a roster writer and the rest name none ($(sed -n 's/^RJUNJOINED //p' <<<"$out")); ${RJ_EXP} expected (row, file) pair(s), ${RJ_FC} source line(s) from § 1.1, ${RJ_FP} from the prompts' own frontmatter and ${RJ_FH:-0} from their Output headings. Every figure is read from the tree on this run; none is held here"
  fi
}

rj_assert_named() {
  local out; out="$(roster_write_check "$1" 2>/dev/null)"; rj_counts "$out"
  if [ -z "$RJ_ROWS" ] || [ -z "$RJ_EXP" ]; then
    FAIL "J1: NO SUBJECT — the roster-write reader emitted no census, so no row was compared"
  elif [ "${RJ_DEG:-0}" -ne 0 ] || [ "$RJ_N0" -ne 0 ]; then
    FAIL "J1: VERDICT WITHHELD — J0 did not pass, so the rows and classes compared here may be a partial population. Resolve J0 first"
  elif [ "$RJ_EXP" -eq 0 ]; then
    FAIL "J1: VACUITY — no expected (row, file) pair was derived, so 'every file is named' would be a statement over the empty set"
  elif [ "$RJ_N1" -ne 0 ]; then
    FAIL "J1: ${RJ_N1} file(s) an agent writes are not named in its roster row — /trip's dispatch sentence 'each writing exactly the file or files that row names' is false for each. Name the file as a code span in the row's Output File cell, in the same change that made the agent write it. Where the file's class lands before the agent that writes it, name it in a clause that says so — declares \`outputs/<file>\`, not written before <the landing that ships its writer> — because the row is what the dispatched agent is told to write; the landing that ships the writer rewrites the clause"; show "$out" 'J1'
  else
    PASS "J1: all ${RJ_EXP} expected (row, file) pair(s) across ${RJ_ROWS} roster row(s) are named in their row's Output File cell — every file § 1.1's writer column assigns to a roster agent, and every file that agent's own prompt emits frontmatter for or names in an Output heading"
  fi
}

rj_assert_join() {
  local out; out="$(roster_write_check "$1" 2>/dev/null)"; rj_counts "$out"
  if [ -z "$RJ_ROWS" ] || [ -z "$RJ_JOINED" ]; then
    FAIL "J2: NO SUBJECT — the roster-write reader emitted no census, so no row was joined"
  elif [ "${RJ_DEG:-0}" -ne 0 ] || [ "$RJ_N0" -ne 0 ]; then
    FAIL "J2: VERDICT WITHHELD — J0 did not pass, so the join population may be partial. Resolve J0 first"
  elif [ "$RJ_ROWS" -eq 0 ] || [ "$RJ_JOINED" -eq 0 ]; then
    FAIL "J2: VACUITY — ${RJ_ROWS} row(s) and ${RJ_JOINED} joined class row(s); nothing was joined"
  elif [ "$RJ_N2" -ne 0 ]; then
    FAIL "J2: ${RJ_N2} roster row(s) join to a writer id that no § 1.1 W cell names — their § 1.1 limb is empty rather than checked"; show "$out" 'J2'
  else
    PASS "J2: every one of the ${RJ_ROWS} roster row(s) joins to § 1.1 — each row's prompt declares one writer id, and at least one § 1.1 W cell names it"
  fi
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
  local f="$d/skills/$name/SKILL.md"
  mkdir -p "$d/skills/$name"
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

  # The conforming hint: the file's own DISTINCT verb identities, pipe-joined. Built from
  # the same IDS the requirement table is emitted from, so the fixture cannot drift from
  # itself. A CREATE-role file takes an argument rather than a verb, which is why its hint
  # is a placeholder and why H1/H2/H3 do not quantify over it.
  local hint='' hid seen
  local -a HSEEN=()
  for (( i=0; i<n; i++ )); do
    hid="${IDS[$i]}"
    in_list "$hid" "${HSEEN[@]+"${HSEEN[@]}"}" && continue
    HSEEN+=( "$hid" )
    hint="${hint:+$hint|}$hid"
  done
  if [ "$role" = 'CREATE' ]; then hint='[fixture-argument]'; fi
  # hintshort drops the LAST verb, so the hint omits a declared verb while every token it
  # does carry stays valid — H3 without tripping H2, which is what makes the arm specific.
  if [ "$defect" = 'hintshort' ] && [ "$role" != 'CREATE' ] && [ "${#HSEEN[@]}" -gt 1 ]; then
    hint="${hint%|*}"
  fi
  if [ "$defect" = 'hintghost' ] && [ "$role" != 'CREATE' ]; then hint="$hint|ghostverb"; fi

  {
    printf -- '---\ndescription: fixture %s\n' "$name"
    if [ "$defect" != 'nohint' ] || [ "$role" = 'CREATE' ]; then
      printf -- 'argument-hint: %s\n' "$hint"
    fi
    # The grant lines carry the SANCTIONED engine root, because that is what the conforming
    # surface looks like after this slice and group P is run over every tree including this
    # fixture. Three defects live here, one per P-group id, and each is deliberately narrow:
    #   baregrant — BOTH lines bare. P1 fires; P2 does not, because one spelling is still one
    #               spelling. That separation is what makes P2's own arm mean something
    #   mixgrant  — rooted permit, bare prohibition. P2 fires on the escalation shape itself
    #   extrasub  — ONE file's permit gains a subcommand no verb denies, so the other files
    #               inherit an unmet obligation. P3 fires on the cascade rather than on a
    #               dropped line, which is the property worth asserting
    local GP="$ENGINE_ROOT_TOK"
    [ "$defect" = 'baregrant' ] && GP=''
    printf -- 'allowed-tools: Bash(ls:*), Bash(%s%s update:*)' "$GP" "$SCRIPT_REL"
    if [ "$defect" = 'extrasub' ] && [ "$name" = 'trip-publish' ]; then
      printf -- ', Bash(%s%s rotate:*)' "$GP" "$SCRIPT_REL"
    fi
    printf -- '\n'
    if [ "$defect" = 'mixgrant' ]; then
      printf -- 'disallowed-tools: [Bash(%s publish:*)]\n' "$SCRIPT_REL"
    else
      printf -- 'disallowed-tools: [Bash(%s%s publish:*)]\n' "$GP" "$SCRIPT_REL"
    fi
    printf -- '---\n\n# /%s\n\n' "$name"
    # The listing is an agent-run read, as the charter's evidence entries are. This section used to
    # carry the retired pre-execution rendering itself; group I now grades that rendering as a
    # finding, so a conforming world cannot carry it, and the two arms that need it plant it.
    printf -- '## Trips in this repo\n\nThe agent lists them with a tool call before it resolves one.\n\n'
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
        # 'norows' keeps the header row and its separator and emits NO data row: the
        # ZERO-VERB world. Distinct from 'notable', which removes the anchor itself.
        [ "$defect" = 'norows' ] && continue
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
    # uwplant — the planted UNIVERSAL arm UW0b grades, in this file's Zone A. The world's admitted
    # verb declares writes-nothing past the first physical line of its read block (below), which is
    # the shape a one-line oracle reads as a verb that states no negative.
    if [ "$defect" = 'uwplant' ] && [ "$name" = 'trip' ]; then
      printf -- 'Every verb of this command writes, and a write command never picks a write for you.\n\n'
    fi
    printf -- '## Selecting the verb\n\nAn example of what a section looks like:\n\n```\n## ghostverb\n**Reads:** an example read line.\n```\n\n'
    # The STANDING CONFIRM RULE, stated once per fixture file as each live verb file states its own.
    # Its wording is the fixture's and deliberately not the live rule's, so C5's green on this
    # world cannot rest on a string this guard holds: C5 reads the comparand from these files.
    #   norule   — the record-command file omits it; C5 must fire on the ABSENCE
    #   rulediff — that file states it in another rendering; C5 must fire on the DIVERGENCE
    case "$defect:$name" in
      norule:trip-record) ;;
      rulediff:trip-record) printf -- '## Standing rules\n\n- **%s runs whenever the model chooses.** A rule.\n\n' "$CONFIRM_RULE_LOCATOR" ;;
      *) printf -- '## Standing rules\n\n- **%s runs only after a fixture confirmation naming it.** A rule.\n\n' "$CONFIRM_RULE_LOCATOR" ;;
    esac
    for (( i=0; i<n; i++ )); do
      if [ "$role" = 'CREATE' ]; then continue; fi
      if [ "$defect" = 'nosection' ] && [ "$i" -eq 0 ]; then continue; fi
      printf -- '## %s%s\n\n' "${IDS[$i]}" "${HEADS[$i]}"
      # ── The read declaration, and the three-negative source group C joins against.
      # The conforming world declares all three on EXACTLY the key the charter marks admitted,
      # and on no other, so marker and source agree on every unit. Three defects live here, one
      # per direction the join must detect plus the totality hole:
      #   c1undeclared  — the admitted key declares NONE. Marker says admitted, source does not.
      #   c1source      — a RETAINED key declares ALL THREE. Source admits, marker does not.
      #                   The opposite direction, and without it half of C1 could be deleted
      #                   while every other arm stayed green.
      #   c4nosrc       — one region carries no read declaration at all, so the side function
      #                   is undefined on that unit.
      # The block is written WITHOUT its closing blank line, so the confirm declaration below lands
      # inside it — the one place C2's confirm limb reads.
      local rblk=1
      if [ "$defect" = 'c0empty' ]; then
        rblk=0
      elif [ "$defect" = 'c4nosrc' ] && [ "${IDS[$i]}" = 'check' ]; then
        rblk=0
      elif [ "/$name ${IDS[$i]}" = "$FIXTURE_ADMIT_KEY" ] && [ "$defect" = 'uwplant' ]; then
        # the same three negatives, with writes-nothing on the block's SECOND physical line
        printf -- '**Reads:** nothing beyond the blocks above.\nIt writes nothing, dispatches no agent, and performs no act whose effect lands outside this trip.\n'
      elif [ "/$name ${IDS[$i]}" = "$FIXTURE_ADMIT_KEY" ] && [ "$defect" != 'c1undeclared' ]; then
        printf -- '**Reads:** nothing beyond the blocks above. It writes nothing, dispatches no agent, and performs no act whose effect lands outside this trip.\n'
      elif [ "$defect" = 'c1source' ] && [ "$name" = 'trip-publish' ] && [ "${IDS[$i]}" = 'list' ]; then
        printf -- '**Reads:** nothing beyond the blocks above. It writes nothing, dispatches no agent, and performs no act whose effect lands outside this trip.\n'
      else
        printf -- '**Reads:** nothing beyond the blocks above.\n'
      fi
      # The arm-scoped confirm gate, DECLARED in the block. Present in the conforming world so every
      # RETAINED arm stands behind a limb. Two defects live here:
      #   noconfirm      — no gate text anywhere; drives GC2
      #   confirmoffpath — the confirmation is only MENTIONED: inside the block by a sentence placing
      #                    it off the arm's path, and outside the block by a gate-shaped sentence.
      #                    Neither is a declaration; drives GC2c and GC3b
      if [ "$rblk" -eq 1 ]; then
        case "$defect" in
          noconfirm)      ;;
          confirmoffpath) printf -- 'It returns before the typed confirmation, so nothing on this path is gated by it.\n' ;;
          *)              printf -- 'Its destructive work stands behind a typed confirmation.\n' ;;
        esac
        printf -- '\n'
      fi
      if [ "$defect" = 'confirmoffpath' ]; then
        printf -- 'Destructive work in this region stands behind a typed confirmation.\n\n'
      fi
      printf -- 'This region never passes %s--yes%s and never sets ALLOW_PLAINTEXT; it mentions %s%s%s and does not run it.\n\n' "$BT" "$BT" "$BT" "$SCRIPT_REL" "$BT"
      # preexec / preexecnear — group I's arms, planted in a VERB REGION: the retired pre-execution
      # line itself, and its must-NOT-fire near-miss with the two characters in the other order.
      if [ "$name" = 'trip' ] && [ "${IDS[$i]}" = 'status' ]; then
        case "$defect" in
          preexec)     printf -- '!%sls -1 trips%s\n\n' "$BT" "$BT" ;;
          preexecnear) printf -- '%s!ls -1 trips%s\n\n' "$BT" "$BT" ;;
        esac
      fi
      if [ "${INVS[$i]}" -eq 1 ]; then
        case "$defect" in
          rotate)      printf -- '```\n%s rotate trips/x\n```\n\n' "$SCRIPT_REL" ;;
          nounpubflag) printf -- '```\n%s unpublish trips/x\n```\n\n' "$SCRIPT_REL" ;;
          badflag)     printf -- '```\n%s update trips/x --passphrase secret\n```\n\n' "$SCRIPT_REL" ;;
          # rootrotate — a SANCTIONED-root invocation of an EXCLUDED form. It must still be an
          # F1: if the admission had been implemented by skipping rooted lines rather than by
          # stripping the prefix, this fixture would go quiet and nothing else would notice.
          rootrotate)  printf -- '```\n%s%s rotate trips/x\n```\n\n' "$ENGINE_ROOT_TOK" "$SCRIPT_REL" ;;
          # wrongroot — a DIFFERENT variable-bearing root. It must still be an F5: the admission
          # is one literal, not the class of things that look like a rooted path.
          wrongroot)   printf -- '```\n${ZZ_OTHER_ROOT}/%s update trips/x\n```\n\n' "$SCRIPT_REL" ;;
          *)           printf -- '```\n%s update trips/x\n```\n\n' "$SCRIPT_REL" ;;
        esac
      fi
      if [ "$defect" = 'twosections' ] && [ "$i" -eq 0 ]; then
        printf -- '## %s <other>\n\n**Reads:** nothing.\n\n' "${IDS[$i]}"
      fi
    done
    if [ "$role" = 'CREATE' ]; then
      printf -- '## Create\n\nThe body of this file is the region.\n\n'
      # A CREATE-role unit is on the retained side like any other, so it carries a limb too, declared
      # in its block under the same two defects as a verb section above.
      if [ "$defect" != 'c0empty' ]; then
        printf -- '**Reads:** the template it copies from.\n'
        case "$defect" in
          noconfirm)      ;;
          confirmoffpath) printf -- 'It returns before the typed confirmation, so nothing on this path is gated by it.\n' ;;
          *)              printf -- 'Its destructive work stands behind a typed confirmation.\n' ;;
        esac
        printf -- '\n'
      fi
      if [ "$defect" = 'confirmoffpath' ]; then
        printf -- 'Destructive work in this region stands behind a typed confirmation.\n\n'
      fi
    fi
    if [ "$defect" = 'orphaninv' ]; then printf -- '## Not a verb\n\n```\n%s update trips/x\n```\n\n' "$SCRIPT_REL"; fi
    if [ "$defect" = 'allowplain' ]; then printf -- '```\nALLOW_PLAINTEXT=1 x\n```\n\n'; fi
    if [ "$defect" = 'varmention' ]; then printf -- 'SCRIPT=%s\n\n' "$SCRIPT_REL"; fi
  } > "$f"
}

# The ONE key the fixture charter marks inference-admitted, held here because gen_charter renders
# the marker and gen_cmd declares the matching three negatives — group C's join grades precisely
# whether those two agree, so they read one literal rather than two.
FIXTURE_ADMIT_KEY='/trip status'

# gen_carrier <path> <defect> — the guided-entry carrier at a fixture engine root.
#
# Group L is the only reader of this surface, and no other generator produces it: the carrier sits
# OUTSIDE the verb directory every other fixture writes into, which is the whole point of it.
#
#   ok          — names no verb, carries no flag, declares all three negatives
#   verbtoken   — names a live verb token, which is the second enumeration the design forbids
#   flag        — carries the frontmatter key whose presence would disable guided entry silently
#   noneg       — declares none of the three negatives
#   preexec     — carries the retired pre-execution line, which group I must flag here as well
#   preexecnear — carries its near-miss, the two characters in the other order, which it must not
gen_carrier() {
  local p="$1" defect="${2:-ok}"
  mkdir -p "${p%/*}"
  {
    printf -- '---\nname: fixture-engine\ndescription: fixture landing surface for the guided-entry carrier.\n'
    [ "$defect" = 'flag' ] && printf -- 'disable-model-invocation: true\n'
    printf -- '---\n\n# The way in\n\n'
    printf -- 'Somebody has said in their own words what they want to do. This surface names the verb and hands over the command to type.\n\n'
    [ "$defect" = 'preexec' ] && printf -- '!%sls -1 trips%s\n\n' "$BT" "$BT"
    [ "$defect" = 'preexecnear' ] && printf -- '%s!ls -1 trips%s\n\n' "$BT" "$BT"
    if [ "$defect" != 'noneg' ]; then
      printf -- '## What this surface declares\n\n- it writes nothing;\n- it dispatches no agent;\n- it performs no act whose effect lands outside this trip.\n\n'
    fi
    printf -- '## Where the answer comes from\n\nRead the charter live at invocation. This file holds no verb list and no classification of its own.\n\n'
    [ "$defect" = 'verbtoken' ] && printf -- 'For orientation, type /trip status and read what it says.\n\n'
    printf -- '## Reaching the verb\n\nWork out which state the request lands in, then render only what that row says.\n\n'
  } > "$p"
}

gen_charter() {  # gen_charter <dir> <defect>
  local d="$1" defect="${2:-}"
  mkdir -p "$d"
  local -a KEYS=( '/trip status' '/trip check' '/trip-record profile' '/trip-record .publish-slug' '/trip-record log' '/trip-publish update' '/trip-publish list' '/trip-new' )
  if [ "$defect" = 'mut' ]; then
    KEYS=( '/trip status' '/trip checkx' '/trip-record profile' '/trip-record .publish-slug' '/trip-record log' '/trip-publish update' '/trip-publish list' '/trip-new' )
  fi
  # The ZERO-VERB world's charter: every Step-1 cell verbless, so K1/K2/K3 quantify over
  # commands rather than pairs. Paired with the 'norows' command defect by arm GZV.
  if [ "$defect" = 'verbless' ]; then
    KEYS=( '/trip' '/trip-record' '/trip-publish' '/trip-new' )
  fi
  local k gmark
  {
    if [ "$defect" = 'nostep1' ]; then printf '### Some other heading\n\n'
    else printf '### Step 1: Classify the request\n\n'; fi
    printf '| Type | Signal | Action | Example | Command |\n'
    printf '|------|--------|--------|---------|---------|\n'
    printf '| Direct edit | sig | act, and see %s/trip status%s for the current state | ex | EXCLUDED: lightest-weight-action |\n' "$BT" "$BT"
    for k in "${KEYS[@]}"; do
      if [ "$defect" = 'uncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
      if [ "$defect" = 'ambuncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
      if [ "$defect" = 'dispambuncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
      if [ "$defect" = 'step1drift' ] && [ "$k" = '/trip-record log' ]; then continue; fi
      # ── The UNGRADED row, planted by REPLACING a conforming row rather than by adding one.
      # An added ADDRESSED row necessarily carries a SECOND finding — a key already covered is
      # K3, a key nothing declares is K1 — so the arm could not say which predicate it reached.
      # Replacing one leaves B7 as the only defect in the world. The correctly-spelled marker
      # goes in the EXAMPLE cell: that is what makes the arm discriminate a FIELD-INDEXED read
      # from a row-wide one, which a bare absent-marker row cannot do.
      if [ "$defect" = 'b7none' ] && [ "$k" = '/trip check' ]; then
        printf '| X | sig | act | %sex | %s%s%s |\n' "${GRADE_RETAIN}${GRADE_SEP}" "$BT" "$k" "$BT"; continue
      fi
      # The conforming world grades EVERY addressed row and renders BOTH tokens. A world that
      # only ever wrote one of them would leave the other's branch unexercised under a green G0b.
      #
      # WHICH key is admitted is held in ONE place, FIXTURE_ADMIT_KEY, because gen_cmd has to
      # agree with it: the charter renders the marker here and the command file declares the
      # three negatives there, and group C's join grades exactly whether those two agree. Two
      # literals would let the fixture drift into a state where the conforming world is not
      # conforming — and the arm that would catch it is the one being built on top of it.
      if [ "$k" = "$FIXTURE_ADMIT_KEY" ]; then gmark="${GRADE_ADMIT}${GRADE_SEP}"; else gmark="${GRADE_RETAIN}${GRADE_SEP}"; fi
      printf '| %s | sig | %sact | ex | %s%s%s |\n' "$k" "$gmark" "$BT" "$k" "$BT"
    done
    # ── The CONFORMING ambiguity set, carried by every world except the zero-verb one.
    # Deliberately CROSS-COMMAND, which is the shape a factored in-span grammar could not
    # express; and deliberately avoiding `check`, so the GM mutation pair is untouched.
    # Both members keep their own ADDRESSED row above, which is what makes this a CHOICE
    # rather than a double cover — the claim G0i grades. It is also the second set every
    # two-set K5 arm needs, so those arms plant one row rather than two.
    if [ "$defect" != 'verbless' ]; then
      printf '| Ambiguous intent | sig | act | ex | %s%s/trip status%s%s%s/trip-publish list%s |\n' \
        "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"
      # ── The CONFORMING DISPOSITION-BEARING set — a SECOND set rather than a disposition
      # added to the one above, and the reason is measured rather than stylistic. GK5b's
      # world plants a set whose UNIT members are exactly the first set's; adding a
      # disposition to the first set would make the two differ in cardinality under the
      # widened K5 identity, and GK5b — an arm this change must leave firing — would go
      # silent. A second set keeps that arm on its original subject.
      #
      # Its units are deliberately `/trip-record profile` and `/trip-publish update`: both
      # cross-command like the set above, both keeping their own ADDRESSED row (which is
      # what makes G0j a CHOICE rather than a double cover), and neither touched by any
      # defect world here — `check` is removed by uncovered/ambuncovered and reserved by
      # the GM mutation pair, and `trip-record log` is removed by the two drift defects.
      printf '| Ambiguous disposition | sig | act | ex | %s%s%s%s%s/trip-record profile%s%s%s/trip-publish update%s |\n' \
        "$AMB_MARK" "$DISP_MARK" 'lightest-weight-action' "$AMB_SEP" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"
    fi
    # ── The disposition defect rows. Each plants ONE defect beside the two conforming sets
    # every world above already carries, so its arm grades the new predicate rather than the
    # fixture. dispdiff and dispmixed are the must-NOT-fire worlds here, read by GK5e and GC6b.
    #
    # ── THE SET-COMPOSITION PAIR, read by GC6 and GC6b. Both carry a disposition member beside
    # FIXTURE_ADMIT_KEY — the one key this fixture marks inference-admitted, and the one whose
    # command file gen_cmd gives all three negatives, so the two surfaces cannot drift apart about
    # which member is admitted. They differ in exactly ONE thing: whether a RETAINED unit member
    # stands beside the admitted one. That is the whole of what C6 grades, so the pair is the
    # whole of the evidence for it.
    #   dispalladmit — every unit member admitted beside a disposition. The refused composition:
    #                  its own membership reads admitted while the fail-closed rule retains it.
    #   dispmixed    — the same set plus one RETAINED unit member. Both readings now agree, so no
    #                  finding is owed; an implementation that objected to an admitted member
    #                  anywhere inside a disposition-bearing set fires here and fails GC6b while
    #                  passing GC6, which is the only thing that tells the rule from the ban.
    if [ "$defect" = 'dispalladmit' ];  then printf '| X | sig | act | ex | %s%slightest-weight-action%s%s%s%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$FIXTURE_ADMIT_KEY" "$BT"; fi
    if [ "$defect" = 'dispmixed' ];     then printf '| X | sig | act | ex | %s%slightest-weight-action%s%s%s%s%s%s/trip-record log%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$FIXTURE_ADMIT_KEY" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'dispoffenum' ];   then printf '| X | sig | act | ex | %s%sbecause I said so%s%s/trip status%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'dispconj' ];      then printf '| X | sig | act | ex | %s%srepo-creation + argv-secret%s%s/trip status%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'dispnounit' ];    then printf '| X | sig | act | ex | %s%slightest-weight-action%s%srepo-creation |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$DISP_MARK"; fi
    if [ "$defect" = 'dispbadmarker' ]; then printf '| X | sig | act | ex | %sEXCLUDED lightest-weight-action%s%s/trip status%s |\n' "$AMB_MARK" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'dispdup' ];       then printf '| X | sig | act | ex | %s%slightest-weight-action%s%slightest-weight-action%s%s/trip status%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT"; fi
    # Members REORDERED against the conforming disposition set AND carrying the SAME
    # disposition, so the collision is a genuine set-identity match rather than a string one.
    if [ "$defect" = 'dispsame' ];      then printf '| X | sig | act | ex | %s%s/trip-publish update%s%s%slightest-weight-action%s%s/trip-record profile%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT"; fi
    # dispdiff — the SPECIFICITY world. Unit members identical to the conforming disposition
    # set, disposition member DIFFERENT. Under the shipped K5 these are two sets; under the
    # naive implementation that drops dispositions from the identity they compare equal and
    # a spurious K5 is emitted. GK5e is the arm.
    if [ "$defect" = 'dispdiff' ];      then printf '| X | sig | act | ex | %s%srepo-creation%s%s/trip-record profile%s%s%s/trip-publish update%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    # The TOTALITY sensitivity arm's world, the ambuncovered shape with a disposition beside
    # the unit members: the verb is reachable ONLY as an option and must still be a K2.
    if [ "$defect" = 'dispambuncovered' ]; then printf '| X | sig | act | ex | %s%slightest-weight-action%s%s/trip check%s%s%s/trip status%s |\n' "$AMB_MARK" "$DISP_MARK" "$AMB_SEP" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambone' ];       then printf '| X | sig | act | ex | %s%s/trip status%s |\n' "$AMB_MARK" "$BT" "$BT"; fi
    if [ "$defect" = 'ambbadmember' ]; then printf '| X | sig | act | ex | %s%s/trip status%s%s%s/trip --.x%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambnomarker' ];  then printf '| X | sig | act | ex | %s/trip status%s%s%s/trip check%s |\n' "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambghost' ];     then printf '| X | sig | act | ex | %s%s/trip status%s%s%s/trip nosuchverb%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambwholecmd' ];  then printf '| X | sig | act | ex | %s%s/trip%s%s%s/trip-publish list%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambuncovered' ]; then printf '| X | sig | act | ex | %s%s/trip check%s%s%s/trip status%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambdup' ];       then printf '| X | sig | act | ex | %s%s/trip status%s%s%s/trip status%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'ambsame' ];      then printf '| X | sig | act | ex | %s%s/trip-publish list%s%s%s/trip status%s |\n' "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"; fi
    if [ "$defect" = 'dblcover2' ];    then printf '| X | sig | %sact | ex | %s/trip status%s |\n' "${GRADE_RETAIN}${GRADE_SEP}" "$BT" "$BT"; fi
    # ── The B7 SPECIFICITY world. Every row it adds is NON-ADDRESSED, and the marker is present
    # on some and absent on others, so the arm over it fails under a B7 that grades every row's
    # Action cell AND under one that objects to a marker where no class is owed.
    if [ "$defect" = 'b7excl' ]; then
      printf '| X | sig | %sact | ex | EXCLUDED: lightest-weight-action |\n' "${GRADE_ADMIT}${GRADE_SEP}"
      printf '| X | sig | act | ex | EXCLUDED: lightest-weight-action |\n'
      printf '| X | sig | %sact | ex | %s%s/trip check%s%s%s/trip-record log%s |\n' \
        "${GRADE_RETAIN}${GRADE_SEP}" "$AMB_MARK" "$BT" "$BT" "$AMB_SEP" "$BT" "$BT"
    fi
    if [ "$defect" = 'badcell' ];    then printf '| X | sig | act | ex | neither |\n'; fi
    if [ "$defect" = 'offenum' ];    then printf '| X | sig | act | ex | EXCLUDED: because I said so |\n'; fi
    if [ "$defect" = 'dupreason' ];  then printf '| X | sig | act | ex | EXCLUDED: repo-creation + repo-creation |\n'; fi
    if [ "$defect" = 'badgrammar' ]; then printf '| X | sig | act | ex | %s/trip --.x%s |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'badn1' ];      then printf '| X | sig | act | ex | %s/Trip status%s |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'badspan' ];    then printf '| X | sig | act | ex | %s/trip st%satus%s |\n' "$BT" "$BT" "$BT"; fi
    if [ "$defect" = 'ghostkey' ];   then printf '| X | sig | %sact | ex | %s/trip nosuchverb%s |\n' "${GRADE_RETAIN}${GRADE_SEP}" "$BT" "$BT"; fi
    if [ "$defect" = 'dblcover' ];   then printf '| X | sig | %sact | ex | %s/trip%s |\n' "${GRADE_RETAIN}${GRADE_SEP}" "$BT" "$BT"; fi
    printf '\n'
    if [ "$defect" != 'nostep2' ]; then
      printf '### Step 2: Read context (scaled to the request)\n\n'
      printf '| Request | Read scope | Class |\n|---|---|---|\n'
      for k in "${KEYS[@]}"; do
        if [ "$defect" = 'uncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
        # ambuncovered removes the key from BOTH enumerations, exactly as `uncovered` does:
        # the subject is K2's totality, and leaving it in Step 2 alone would fire S1 instead
        # and grade a different assertion.
        if [ "$defect" = 'ambuncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
        if [ "$defect" = 'dispambuncovered' ] && [ "$k" = '/trip check' ]; then continue; fi
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

# gen_doc <dir> <defect> — the fixture command reference.
#
# Its derived region is COMPUTED from the fixture's own record stream by the same
# producer the live check compares against, never hand-written here. A hand-written
# fixture region would be a second statement of the derivation rule, and the fixture
# would then pass or fail on whether the two statements agreed rather than on whether the
# guard works.
gen_doc() {  # gen_doc <dir> <defect>
  local d="$1" defect="${2:-}"
  mkdir -p "$d/reference"
  local doc="$d/reference/command-reference.md"
  if [ "$defect" = 'nodoc' ]; then rm -f "$doc"; return 0; fi
  local block
  block="$(derive_surface_block "$(collect_records "$d")")"
  # docdrift mutates ONE cell of the committed region, leaving the command files intact:
  # the divergence is in the document, which is the direction H5 exists to catch.
  if [ "$defect" = 'docdrift' ]; then block="${block/| ACTIVE |/| ARCHIVED |}"; fi
  {
    printf '# Fixture command reference\n\n'
    printf '%s\n' "$DOC_MARK_OPEN"
    printf '%s\n' "$block"
    printf '%s\n' "$DOC_MARK_CLOSE"
  } > "$doc"
}

gen_tree() {  # gen_tree <dir> <charter-defect> <cmd-defect> [world...]
  local d="$1" cdd="$2" mdd="$3"; shift 3
  local -a W=( "$@" )
  if [ "${#W[@]}" -eq 0 ]; then W=( "${WORLD_OK[@]}" ); fi
  # The skills ROOT, not a per-verb directory: this is also the `nocmds` fixture's whole
  # job — an empty verb root that group A must FAIL on rather than pass vacuously.
  mkdir -p "$d/skills"
  gen_charter "$d" "$cdd"
  if [ "$mdd" = 'nocmds' ]; then return 0; fi
  local t
  for t in "${W[@]}"; do gen_cmd "$d" "$t" "$mdd"; done
  # The document is generated LAST and from the finished tree, so a command-file defect
  # is reflected in the derivation rather than contradicted by a stale fixture document.
  gen_doc "$d" "$mdd"
}

# collect_records <dir> — the charter roll plus one parse per command file. Factored out
# of run_tree because gen_doc needs the identical stream: the fixture document and the
# assertion that grades it must be derived from one collection, not two.
collect_records() {
  local d="$1"
  local recs="" f base cmd role l2 croll
  croll="$(charter_check "$d/CLAUDE.md")"
  recs="$croll"
  for f in "$d/skills"/*/SKILL.md; do
    [ -e "$f" ] || continue
    base="$(verb_id "$f")"; cmd="/$base"
    role='RESOLVE'
    while IFS= read -r l2; do
      case "$l2" in "ROLE $cmd "*) role="${l2##* }" ;; esac
    done <<< "$croll"
    recs="$recs
FILE $cmd
$(parse_command_file "$f" "$cmd" "$role")"
  done
  printf '%s\n' "$recs"
}

# run_tree <dir> — drives the whole checker chain over a fixture tree and prints the
# concatenated record/finding stream. Used by every control arm.
run_tree() {
  local d="$1"
  local recs
  recs="$(collect_records "$d")"
  recs="$recs
$(coverage_check "$recs")
$(enum_agree_check "$recs")
$(invocation_check "$d/skills" "$recs")
$(parity_check "$d/skills")
$(picker_check "$recs" "$d/reference/command-reference.md" "$d/skills")"
  printf '%s\n' "$recs"
}

# ═════════════════════════════════════════════════════════════════════════════════
# Groups N–S — the real tree
# ═════════════════════════════════════════════════════════════════════════════════
MD="$ROOT/CLAUDE.md"
CDIR="$ROOT/skills"
ADR="$ROOT/reference/adr/ADR-007-command-entry-point.md"
PUB="$ROOT/$SCRIPT_REL"
WF="$ROOT/.github/workflows/command-taxonomy.yml"
DOC="$ROOT/$DOC_REL"
# The guided-entry carrier. It sits at the ENGINE ROOT, deliberately OUTSIDE the verb directory
# every other per-file group globs — that is what makes it reachable by the model when every verb
# file withholds itself. Group CE is the only reader of it, which is also why it has to join the
# Z watch set below: a surface this guard reads and does not watch is an unwatched write path.
CARRIER="$ROOT/SKILL.md"

# The Z-group watch set: every surface this guard READS — the command reference included,
# since group H reads it, and the architecture document and each agent prompt, since group J
# reads them — plus the workflow that runs it —
# that last one because a guard editing its own trigger is the one mutation a reader would
# least expect this group to miss. The set is those inputs and NOT the whole tree; the Z1
# line states that scope rather than claiming a tree-wide property this does not establish.
tree_state() {
  local p
  for p in "$MD" "$ADR" "$PUB" "$SELF" "$WF" "$DOC" "$CARRIER" "$ROOT/$RJ_ARCH_REL"; do [ -f "$p" ] && cksum < "$p"; done
  for p in "$CDIR"/*/SKILL.md; do [ -e "$p" ] && { printf '%s ' "$(verb_id "$p")"; cksum < "$p"; }; done
  for p in "$ROOT"/agents/*.md; do [ -e "$p" ] && { printf '%s ' "${p##*/}"; cksum < "$p"; }; done
}
STATE_BEFORE="$(tree_state)"
WATCHED="$(printf '%s\n' "$STATE_BEFORE" | grep -c .)"

echo
echo "── Group N — needle integrity. norm(needle) == needle, asserted before any read."
N_OUT="$(needle_check)"
if has_finding "$N_OUT" "$(surface N1)"; then FAIL "N1: a needle does not survive the normalisation applied to the haystack"; show "$N_OUT" 'N1'
else PASS "N1: all $(getcount "$N_OUT" NEEDLES) needles round-trip, or are registered UNTRIMMED and matched as prefixes (the haystack is collapsed; the needle never is)"; fi

CH_OUT="$(charter_check "$MD")"
S1_ROWS="$(getcount "$CH_OUT" S1_ROWS)"; S1_ADDR="$(getcount "$CH_OUT" S1_ADDR)"
S1_EXCL="$(getcount "$CH_OUT" S1_EXCL)"; S1_AMB="$(getcount "$CH_OUT" S1_AMB)"
DOTTED="$(getcount "$CH_OUT" DOTTED)"; UNWID="$(getcount "$CH_OUT" UNWIDENED_FAIL)"
S1_GRADED="$(getcount "$CH_OUT" S1_GRADED)"; S1_ADMITTED="$(getcount "$CH_OUT" S1_ADMITTED)"

RECS="$CH_OUT"
NFILES=0
for gf in "$CDIR"/*/SKILL.md; do
  [ -e "$gf" ] || continue
  NFILES=$((NFILES+1))
  gbase="$(verb_id "$gf")"; gcmd="/$gbase"
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
P_OUT="$(parity_check "$CDIR")"
R_OUT="$(readonly_check "$RECS" "${READONLY_KEYS[@]}" -- "${READONLY_ADJUDICATED[@]}")"
H_OUT="$(picker_check "$RECS" "$DOC" "$CDIR")"
C_OUT="$(inference_check "$RECS" "$CARRIER")"
I_OUT="$(preexec_check "$CDIR"/*/SKILL.md "$CARRIER")"
ALL="$RECS
$COV_OUT
$ENUM_OUT
$E_OUT
$F_OUT
$P_OUT
$R_OUT
$H_OUT
$C_OUT
$I_OUT"

echo
echo "── Group A — populations non-empty. FAIL, never SKIP."
if has_finding "$ALL" "$(surface A0)"; then FAIL "A1: a population or surface is empty"; show "$ALL" 'A0'
else PASS "A1: Step-1 slice ${S1_ROWS} rows; skills directory ${NFILES} verb file(s); coverage-unit enumeration $(getcount "$COV_OUT" UNITS) units — each derived, each non-empty, none skipped"; fi

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
if has_finding "$ALL" "$(surface B3 B5 B6 B7 B8)"; then FAIL "B3: an ADDRESSED cell fails the widened cell grammar or N1, an ambiguity set is malformed, a disposition member's reason is not a single value of the closed enum or the set offers no verb at all, or an ADDRESSED row carries no well-formed entry-class marker"; show "$ALL" 'B3|B5|B6|B7|B8'
else PASS "B3: all ${S1_ADDR} ADDRESSED cells match the widened (alternation) cell grammar, command component under N1; and every member of the ${S1_AMB} AMBIGUOUS cell(s) matches that SAME grammar, UNCHANGED — the third class reuses the single-target form rather than widening it, and an undeclared two-span cell stays a hard failure so a set is DECLARED and never inferred. ENTRY CLASS: ${S1_GRADED} of ${S1_ADDR} ADDRESSED row(s) open their Action cell with a well-formed marker, ${S1_ADMITTED} of them on the inference-admitted side — both figures are read off this run rather than held here, and the AMBIGUOUS and EXCLUDED rows are outside the quantifier by construction, never by an exemption"; fi
if has_finding "$ALL" "$(surface B4)"; then FAIL "B4: exhaustiveness broken"; show "$ALL" 'B4'
else PASS "B4: ${S1_ADDR} ADDRESSED + ${S1_AMB} AMBIGUOUS + ${S1_EXCL} EXCLUDED accounts for ${S1_ROWS} rows, no silent gap"; fi
if [ "${DOTTED:-0}" -gt 0 ]; then
  PASS "B5: DOTTED-CELL COUNT ${DOTTED:-0} — the leading-dot widening is exercised by LIVE data; ${UNWID:-0} live cell(s) fail the un-widened grammar, so the widened and un-widened forms are DISTINGUISHABLE on this population"
else
  # A SKIP, not a PASS. This branch reports the ABSENCE OF EVIDENCE, and a group that
  # returns PASS on both of its branches cannot fail — it contributes a guaranteed green
  # to the tally whatever the surface does. GUARD_EXPECTED_SKIPS is empty by design, so
  # under GUARD_STRICT_SKIPS this fails the run, and that is the intended reading: B5 is
  # not dependency-gated, so an unexercised widening obligation is a gap rather than a
  # legitimate skip. This is also the call site that makes the strict-skip contract live;
  # it was declared and never reached before.
  SKIP "B5: DOTTED-CELL COUNT 0 — VACUOUS, NOT PASSING. No live cell exercises the leading-dot widening, so this arm has no evidence either way and reports that rather than manufacturing a green. ${UNWID:-0} live cell(s) fail the un-widened grammar"
fi

echo
echo "── Group K — the coverage bijection. K1 resolvability, K2 totality, K3 exclusivity, K4/K5 the declared sets."
AMBCELLS="$(getcount "$COV_OUT" AMBCELLS)"; AMBMEMBERS="$(getcount "$COV_OUT" AMBMEMBERS)"
# The live ambiguity population is PRINTED on the K1 and K3 lines rather than implied,
# because a limb quantified over nothing must say so on the line a reader trusts. This is
# an assignment, not a verdict: it adds no PASS/FAIL site, so group MD's declared residual
# is unchanged by it.
if [ "${AMBCELLS:-0}" -eq 0 ]; then
  AMB_NOTE="LIVE AMBIGUITY POPULATION 0 — the set limbs of this line quantified over nothing on this commit and establish nothing about live data. This run's evidence for them is arms GB6 / GB6b / GB6c / GK4 / GK4b / GK5 / GK5b, each of which plants its defect and FAILS if the defect is not flagged, on every push. This is not the R1 shape: R1's population is empty for two structural reasons of the surface, while this one is empty only until the first set is authored, after which these same lines quantify over it with no edit"
else
  AMB_NOTE="The set limbs quantified over LIVE data on this commit, not over fixtures alone"
fi
# The DISPOSITION population is its OWN counter with its OWN note, never a clause inside
# AMB_NOTE. Borrowing AMB_NOTE would read "quantified over LIVE data" off a set population
# that is non-zero regardless of whether a single disposition member exists — the R1 shape
# this suite exists to refuse, one level down. Also an assignment, not a verdict: no site.
DISPMEMBERS="$(getcount "$COV_OUT" DISPMEMBERS)"
if [ "${DISPMEMBERS:-0}" -eq 0 ]; then
  DISP_NOTE="LIVE DISPOSITION-MEMBER POPULATION 0 — the disposition limb of this line quantified over nothing on this commit and establishes nothing about live data. This run's evidence for it is arms GB8 / GB8b / GB8c / GB6d / GK5c / GK5d / GK2c, each of which plants its defect and FAILS if the defect is not flagged, and the must-NOT-fire pair G0j / GK5e beside them"
else
  DISP_NOTE="The disposition limb quantified over ${DISPMEMBERS} LIVE disposition member(s) on this commit, not over fixtures alone"
fi
if has_finding "$ALL" "$(surface X1 X2)"; then FAIL "K0: the key channel is lossy"; show "$ALL" 'X1|X2'
else PASS "K0: every emitted key round-trips byte-identical through the record channel, and no key is empty or carries whitespace. SCOPE: X1 and X2 grade the KEY CHANNEL. How this guard's own membership tests quote their haystacks is a property of this file that no assertion here reads, so it is not claimed on this line — see the note at in_list()"; fi
if has_finding "$ALL" "$(surface K1 K4)"; then FAIL "K1: an ADDRESSED cell covers nothing, a covered member does not resolve, or an ambiguity-set member does not resolve to exactly one unit"; show "$ALL" 'K1|K4'
else PASS "K1: RESOLVABILITY — each of $(getcount "$COV_OUT" ADDRCELLS) ADDRESSED cells covers a non-empty set and every member resolves (file AND declaration AND region); and each of ${AMBMEMBERS} UNIT member(s) across ${AMBCELLS} declared ambiguity set(s) resolves to exactly one coverage unit, computed by the same rule K1 computes an ADDRESSED cell's cover. SCOPE: a set's members are of two kinds and K4's quantifier is the UNIT kind alone — a DISPOSITION member names a reason rather than a verb, mints no coverage unit and contributes no cover, so it is graded for its reason by B8 and for its distinctness by K5, and is not in the ${AMBMEMBERS} above. ${AMB_NOTE} ${DISP_NOTE}"; fi
if has_finding "$ALL" "$(surface K2)"; then FAIL "K2: a coverage unit is covered by no ADDRESSED cell"; show "$ALL" 'K2'
else PASS "K2: TOTALITY — all $(getcount "$COV_OUT" UNITS) coverage units are covered by an ADDRESSED cell; the uncovered set is empty, graded as a set difference and reported member by member. TOTALITY DOES NOT WEAKEN: set membership never satisfies it, so a verb reachable ONLY as an option inside a declared ambiguity set is still a K2 finding, and this line's quantifier is the one that ships today"; fi
if has_finding "$ALL" "$(surface K3 K5)"; then FAIL "K3: exclusivity violated, within the ADDRESSED cells or across the declared sets"; show "$ALL" 'K3|K5'
else PASS "K3: EXCLUSIVITY — no unit covered twice BY ADDRESSED CELLS; no command carrying both a verbless and a verbed ADDRESSED cell. K2 AND K3 give exactly one ADDRESSED cell per unit. Across ${AMBCELLS} declared set(s): no option named twice inside one set, and no two sets denoting the same options — quantified over BOTH member kinds, a unit member by the coverage unit it resolves to and each of ${DISPMEMBERS} disposition member(s) by its reason, so two sets differing only by a disposition are two sets. A unit named in a declared set BESIDE its own ADDRESSED cell is a CHOICE, not a double cover — and the accidental double cover is caught by the same predicate as before, because K3 reads ADDRESSED records only and reads neither of the set channels. ${AMB_NOTE} ${DISP_NOTE}"; fi

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

# ═════════════════════════════════════════════════════════════════════════════════
# Group P — privilege parity over the grant DECLARATIONS.
#
# EVERY VERDICT HERE IS GATED ON A COUNT parity_check PRODUCED, never on the absence of a
# finding, and the vacuity arm is graded FIRST. The reason is specific to this group rather
# than stylistic: its population is the verb files' frontmatter, which is precisely what a
# relocation of the verb surface empties — and a finding-absence reading cannot tell an empty
# population from a clean one. Three of this release's acceptance criteria exist because two
# required checks in this repository were measured passing while grading nothing.
#
# The ids are surfaced here and armed in group G (GP1 / GP2 / GP3), so group Y's two-direction
# mapping covers them on the same commit that introduces them.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group P — privilege parity: one root spelling, closed per file, denied per verb."
P_PAT="$(getcount "$P_OUT" PPAT)"; P_ROOT="$(getcount "$P_OUT" PROOT)"
P_MIXED="$(getcount "$P_OUT" PMIXED)"; P_UNIV="$(getcount "$P_OUT" PUNIV)"
P_OBLIG="$(getcount "$P_OUT" POBLIG)"; P_GAP="$(getcount "$P_OUT" PGAP)"
P_FILES="$(getcount "$P_OUT" PFILES)"
P1A="$(surface P1)"; P2A="$(surface P2)"; P3A="$(surface P3)"
if [ "${P_FILES:-0}" -le 0 ] || [ "${P_PAT:-0}" -le 0 ]; then
  FAIL "P1: VACUITY — ${P_FILES:-0} verb file(s) yielded ${P_PAT:-0} script-naming grant pattern(s). There is nothing to grade, so neither verdict below would mean anything. A verb surface that moved out from under this scan reads here as a failure rather than as a clean run"
elif [ "${P_ROOT:-0}" -ne "${P_PAT:-0}" ]; then
  FAIL "P1: ROOT UNIFORMITY — ${P_ROOT:-0} of ${P_PAT} script-naming grant pattern(s) carry the sanctioned engine root"; show "$P_OUT" "$P1A"
else
  PASS "P1: ROOT UNIFORMITY — all ${P_PAT} script-naming grant pattern(s) across ${P_FILES} verb file(s) carry the sanctioned engine root, character-for-character. Both the pattern population and the conforming count are DERIVED from the files on this run; neither is held in this file"
fi
if [ "${P_PAT:-0}" -le 0 ]; then
  FAIL "P2: VACUITY — no grant pattern was extracted, so spelling closure is unmeasured"
elif [ "${P_MIXED:-0}" -ne 0 ]; then
  FAIL "P2: SPELLING CLOSURE — ${P_MIXED} file(s) carry more than one grant-prefix spelling"; show "$P_OUT" "$P2A"
else
  PASS "P2: SPELLING CLOSURE — each of the ${P_FILES} verb file(s) carries exactly ONE grant-prefix spelling across its permitting and denying lines. This is the arm that catches a partial rewrite: a rooted permit beside a bare prohibition passes P1's permitting half and fails here"
fi
if [ "${P_UNIV:-0}" -le 0 ] || [ "${P_OBLIG:-0}" -le 0 ]; then
  FAIL "P3: VACUITY — the derived subcommand universe holds ${P_UNIV:-0} member(s) and yielded ${P_OBLIG:-0} per-verb deny obligation(s). A parity assertion quantified over nothing is satisfied by anything"
elif [ "${P_GAP:-0}" -ne 0 ]; then
  FAIL "P3: PRIVILEGE PARITY — ${P_GAP} of ${P_OBLIG} deny obligation(s) are unmet"; show "$P_OUT" "$P3A"
else
  PASS "P3: PRIVILEGE PARITY — ${P_OBLIG} deny obligation(s) over a ${P_UNIV}-member subcommand universe, all met at the same prefix as the permit beside them. The universe is the union of what the verbs themselves name, so a subcommand entering it through one verb obliges every other verb on the next run"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group Q — the grant tables: every row paired with a frontmatter grant, every grant with a row.
#
# THREE VERDICTS, EACH ONE ASSERTION FUNCTION, and each calls grant_table_check itself rather
# than reading a precomputed stream. That is what lets the end of group MD register all three
# with md_flips: removing the function removes the evidence, and each verdict must then report
# exactly one FAIL. Every PASS here is gated on counts the subject produced, never on the
# absence of a finding, and an unreadable verb file withholds all three rather than letting two
# of them pass over the readable remainder. An allowed-tools value continued onto a line this
# reader does not join fails Q0 and withholds Q2 in the same way.
#
# The ids are registered with group Y here and armed in group GQ below; group Y's two-direction
# mapping covers them on the same commit that introduces them.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group Q — the grant tables: every row paired with a frontmatter grant, every grant with a row."
# Registration only: the verdicts are count-gated, so the returned alternation is not consumed.
surface Q0 Q1 Q2 >/dev/null
gq_assert_anchor "$CDIR"
gq_assert_rows   "$CDIR"
gq_assert_grants "$CDIR"

echo
echo "── Group R — the DECLARED read-only key set and its membership-delta sentinel."
RO_CINV="$(getcount "$R_OUT" ROCINV)"
# ONE LIMB, and a zero on it is a FAILURE rather than a vacuous pass. This group previously
# carried a second, pre-execution limb whose population is permanently empty — the carrier it
# tested was retired corpus-wide — so it was retired rather than kept as a green establishing
# nothing; its successor is group I, directly below. The surviving limb is re-grounded on
# ANY engine script, not the publish script alone, which is what gives it a real population. If
# that population ever falls back to zero the limb is vacuous again, and the disposition is to
# retire it too — so a zero fails loud here instead of reading as coverage.
if has_finding "$ALL" "$(surface R1)"; then FAIL "R1: a read-only region carries a fenced script invocation"; show "$ALL" 'R1'
elif [ -z "$RO_CINV" ]; then FAIL "R1: NO SUBJECT — readonly_check emitted no candidate count, so the limb was never evaluated"
elif [ "$RO_CINV" -eq 0 ]; then FAIL "R1: VACUOUS — the $(getcount "$R_OUT" ROKEYS) declared read-only keys were quantified over 0 fenced script invocations of ${READONLY_OF_COMMAND}, so the limb had nothing it could match and a pass here would establish nothing. This limb was kept only because its candidate population was non-zero; with that gone, retire it rather than let it read as coverage"
else PASS "R1: each of the $(getcount "$R_OUT" ROKEYS) declared read-only regions carries no fenced invocation of any engine script, quantified NON-VACUOUSLY over ${RO_CINV} fenced script invocation(s) attributed to ${READONLY_OF_COMMAND}'s other regions — invocations exist on this command's surface, so the limb has something it could catch and caught none of it in a read-only region"; fi
if has_finding "$ALL" "$(surface R2)"; then FAIL "R2: the MEMBERSHIP-DELTA SENTINEL fired — the read-only set needs re-adjudication"; show "$ALL" 'R2'
else PASS "R2: sentinel — ${READONLY_OF_COMMAND}'s $(getcount "$R_OUT" ROLIVE) live declared verbs match the adjudicated set as a SET, in both directions. A count would hold while membership churned"; fi

echo
echo "── Group I — the retired pre-execution carrier stays retired, in every verb file and the carrier."
# Three limbs, in the order group C states for itself: a finding fails; then a MISSING or EMPTY
# scan fails, because an absent preexec_check, or one whose inputs vanished, emits no finding
# either; only then does the pass fire, and it names the lines it read.
I_LINES="$(getcount "$I_OUT" PXLINES)"; I_FILES="$(getcount "$I_OUT" PXFILES)"
I_MISS="$(getcount "$I_OUT" PXMISSING)"
if has_finding "$ALL" "$(surface I1)"; then FAIL "I1: a line opens with a bang and a backtick at fence depth 0 — the retired pre-execution carrier is back"; show "$ALL" 'I1'
elif [ -z "$I_LINES" ] || [ "${I_FILES:-0}" -eq 0 ] || [ "${I_MISS:-1}" -ne 0 ]; then FAIL "I1: NO SUBJECT — preexec_check read ${I_FILES:-no} file(s) and could not read ${I_MISS:-an unknown number of} named input(s), so a pre-execution line in them was not ruled out"
else PASS "I1: no line opens with a bang and a backtick at fence depth 0 across ${I_FILES} file(s) — every verb file and the guided-entry carrier at the engine root — over ${I_LINES} fence-depth-0 line(s) scanned. Every region of every file is in the quantifier, not the read-only ones alone. SCOPE: the line-opening rendering the retired carrier used; the same two characters mid-line or inside a fence are not graded here"; fi

echo
echo "── Group C — the inference line: the marker in the routing map joined to its source."
# ── THE SHAPE OF EVERY VERDICT IN THIS GROUP AND IN GROUP L, and why it has three limbs.
# A finding FAILS. Then a MISSING COUNT FAILS — the count is what the subject emits only by
# running, so an absent or unhooked inference_check reaches that limb and never the PASS. Only
# then does the PASS fire. A two-limb `finding -> FAIL, else PASS` would pass on a subject that
# never ran, because an absent subject emits no finding either; that is the shape group MD
# exists to refuse, and this group's residual contribution to it is zero.
C_BLOCKS="$(getcount "$C_OUT" CBLOCKS)"; C_ADMIT="$(getcount "$C_OUT" CADMIT)"
C_RETAIN="$(getcount "$C_OUT" CRETAIN)"; C_SENS="$(getcount "$C_OUT" CSENS)"
C_SPEC="$(getcount "$C_OUT" CSPEC)"; C_UNITS="$(getcount "$C_OUT" CUNITS)"
C_LCONF="$(getcount "$C_OUT" CLIMBCONF)"; C_LTYPED="$(getcount "$C_OUT" CLIMBTYPED)"
C_NOSRC="$(getcount "$C_OUT" CNOSRC)"; C_LNONE="$(getcount "$C_OUT" CLIMBNONE)"
C_J1="$(getcount "$C_OUT" CJ1)"; C_J2="$(getcount "$C_OUT" CJ2)"
if has_finding "$ALL" "$(surface C0)"; then FAIL "C0: the population is empty, or a control arm did not fire — the admitted set below is unusable"; show "$ALL" 'C0'
elif [ -z "$C_BLOCKS" ] || [ -z "$C_SENS" ]; then FAIL "C0: NO SUBJECT — inference_check emitted no population count, so it did not run and nothing below it was measured"
else PASS "C0: population ${C_BLOCKS} per-arm read-declaration blocks over ${C_UNITS} coverage units, ONE per arm and the FIRST in its region — the token also opens a prose sentence on this surface, and counting occurrences rather than arms would add a phantom arm declaring nothing. Components, each derived at grade time: writes-nothing $(getcount "$C_OUT" CNEGW) · dispatches-no-agent $(getcount "$C_OUT" CNEGD) · no-effect-outside $(getcount "$C_OUT" CNEGO). Strict fail-closed intersection ADMITS ${C_ADMIT} and RETAINS ${C_RETAIN}. All three arms fired in this process: sensitivity ${C_SENS} of 7 on a block declaring all three; specificity ${C_SPEC} of 7 on a block declaring the positive of each beside a word carrying a negative only as its suffix; and $(getcount "$C_OUT" CNOEFF) of 7 — the first two limbs, not the third — on a block declaring writes-nothing and dispatches-no-agent beside runs-no-script with NO effect clause, so a runs-no-script sentence is not read as the effect predicate"; fi
if has_finding "$ALL" "$(surface C4)"; then FAIL "C4: a coverage unit resolves to neither side or to both — the side function is not total"; show "$ALL" 'C4'
elif [ -z "$C_NOSRC" ]; then FAIL "C4: NO SUBJECT — the totality count was not emitted, so the side function was never evaluated"
else PASS "C4: TOTALITY — each of the ${C_UNITS} coverage units carries exactly one read-declaration block (${C_NOSRC} carry none), so the side function is total over the surface and every later assertion branches on a defined value"; fi
if has_finding "$ALL" "$(surface C2)"; then FAIL "C2: an arm retaining declared intent stands behind neither the confirm gate nor the typed-only posture"; show "$ALL" 'C2'
elif [ -z "$C_LNONE" ]; then FAIL "C2: NO SUBJECT — the per-limb counts were not emitted, so no arm was graded"
else PASS "C2: each of the ${C_RETAIN} arms retaining declared intent declares a confirm gate in its own read-declaration block, or its file carries the typed-only posture (${C_LNONE} carry neither) — the per-arm obligation, graded per arm rather than per file, and from a declaration rather than from any sentence in the region that mentions a confirmation. The posture is role-scoped by the charter's own ROLE record: a CREATE-role file takes an argument rather than a verb, so the flag alone is its posture"; fi
if [ -z "$C_LCONF" ] || [ -z "$C_LTYPED" ]; then FAIL "C3: NO SUBJECT — the per-limb report has no counts to report, so C2's green above is unreadable"
else PASS "C3: PER-LIMB REPORT — of ${C_RETAIN} retained arms, the confirm limb carries ${C_LCONF} and the typed-only limb carries ${C_LTYPED}. The confirm limb credits ${#CONFIRM_SHAPES[@]} declared confirmation shape(s) — counted from the list the recogniser is built from, never spelled here — all of them named by the standing confirm rule C5 grades, and its count is a LOWER BOUND on gated arms rather than a census of them: it leaves out an arm that gates without declaring one of those shapes in its own read block, and an arm whose declared gate covers only some of its paths rather than the whole arm, which the class does not credit. The banner above CONFIRM_SHAPES names the gated arms each case leaves out, and the one condition the bound rests on.$( [ "${C_LCONF}" -eq 0 ] && printf ' %s' 'The CONFIRM LIMB IS VACUOUS: it carried zero arms on this run, so C2 above establishes nothing about it and its green rests entirely on the typed-only limb.' )$( [ "${C_LTYPED}" -eq 0 ] && printf ' %s' 'The TYPED-ONLY LIMB IS VACUOUS: it carried zero arms on this run.' ) Its verdict never depends on either count; it is the measurement that keeps C2 from reading as coverage it does not have"; fi
if has_finding "$ALL" "$(surface C1)"; then FAIL "C1: THE JOIN — a rendered marker disagrees with the source it is supposed to state"; show "$ALL" 'C1'
elif [ -z "$C_J1" ] || [ -z "$C_J2" ]; then FAIL "C1: NO SUBJECT — the join emitted no difference counts, so no marker was joined to anything"
else PASS "C1: THE JOIN — for every graded coverage unit the side derived from its own read-declaration block equals the entry-class marker the routing map renders, as a set difference EMPTY IN BOTH DIRECTIONS (${C_J1} admitted-at-source-but-not-marked, ${C_J2} marked-but-not-admitted-at-source). Neither side holds a list: the source is read from the blocks and the marker from field 3 of the row B7 graded"; fi
# ── C6 — set composition, fail-closed. Its own vacuity note, keyed on its OWN population and never
# on AMBCELLS: a set population is non-zero whether or not a single DISPOSITION-bearing set exists,
# so a note keyed on it would print "quantified over LIVE data" on a line whose subject was empty.
# The same discipline DISP_NOTE already applies one level up, and for the same reason.
C_DSETS="$(getcount "$C_OUT" CDISPSETS)"; C_COMPOSE="$(getcount "$C_OUT" CCOMPOSE)"
if [ "${C_DSETS:-0}" -eq 0 ]; then
  C6_NOTE="LIVE DISPOSITION-BEARING SET POPULATION 0 — this line quantified over nothing on this commit and establishes nothing about live data. Its evidence on this run is arm GC6, which plants the refused composition and FAILS if it is not flagged, and arm GC6b beside it, the near-miss that must stay green"
else
  C6_NOTE="Quantified over ${C_DSETS} LIVE disposition-bearing set(s) on this commit, not over fixtures alone"
fi
if has_finding "$ALL" "$(surface C6)"; then FAIL "C6: SET COMPOSITION — a declared set carries a disposition member beside unit members that are ALL inference-admitted, so the set's own membership reads admitted while the fail-closed rule retains it"; show "$ALL" 'C6'
elif [ -z "$C_DSETS" ] || [ -z "$C_COMPOSE" ]; then FAIL "C6: NO SUBJECT — the set-composition counts were not emitted, so no set's membership was composed and nothing here was measured"
else PASS "C6: SET COMPOSITION, FAIL-CLOSED — each of the ${C_DSETS} declared set(s) carrying a disposition member names at least one unit member that RETAINS declared intent (${C_COMPOSE} do not). A member that declares nothing is an arm whose block declares nothing, so it retains declared intent and the set with it; the requirement is ADR-007 § 3's set-obligations bullet and this guard holds no copy of it — each member's side is derived live from that verb's own read-declaration block, by the same side function C1 and C2 use. SCOPE: it grades a set's COMPOSITION and says nothing about rendering — a set is proposed and never resolved either way. ${C6_NOTE}"; fi
C_RFILES="$(getcount "$C_OUT" CRULEFILES)"; C_RCARRY="$(getcount "$C_OUT" CRULECARRY)"
C_RFORMS="$(getcount "$C_OUT" CRULEFORMS)"; C_RFLAG="$(getcount "$C_OUT" CRULEFLAG)"
if has_finding "$ALL" "$(surface C5)"; then FAIL "C5: a verb file carries no statement of the standing confirm rule, or the verb files state it in more than one rendering"; show "$ALL" 'C5'
elif [ -z "$C_RCARRY" ] || [ -z "$C_RFORMS" ] || [ "${C_RFILES:-0}" -eq 0 ]; then FAIL "C5: NO SUBJECT — the rule census emitted no counts, or read no verb file, so no file was examined for the rule"
else PASS "C5: PRESENCE, NOT BEHAVIOUR — the standing confirm rule is stated in ${C_RCARRY} of ${C_RFILES} verb file(s), in ${C_RFORMS} rendering, read from the files' own text: this guard holds the rule's subject clause as a locator and never a copy of what the rule requires. The rule is DORMANT and this line does not say otherwise — it governs an act on a verb the operator did not type, and ${C_RFLAG} of ${C_RFILES} verb file(s) carry the frontmatter flag that withholds them from the model on this run. Whether it is FOLLOWED is conduct no static assertion reads, and C2 and C3 above do not read this rule at all"; fi

echo
echo "── Group L — the landing surface: the guided-entry carrier at the engine root."
# A single-letter group, and the letter is load-bearing: group Y derives the emittable ids with a
# ONE-letter, ONE-digit pattern, so a two-letter id would be surfaced here and invisible there —
# graded by this group and armed by nothing Y could see. L is free, and is neither a prefix nor a
# suffix of any multi-letter group banner in this file.
L_VERBS="$(getcount "$C_OUT" LVERBS)"; L_NEG="$(getcount "$C_OUT" LNEG)"
if has_finding "$ALL" "$(surface L1)"; then FAIL "L1: the carrier names a verb token, or is absent"; show "$ALL" 'L1'
elif [ -z "$L_VERBS" ]; then FAIL "L1: NO SUBJECT — the carrier's verb-token count was not emitted"
else PASS "L1: the carrier holds NO verb token of any command (${L_VERBS} found), quantified over the ${C_UNITS}-unit live declared verb set read from the record stream — no list on either side. A verb added to the charter is reachable from the carrier with no edit to it"; fi
if has_finding "$ALL" "$(surface L2)"; then FAIL "L2: the carrier carries a disable-model-invocation key — guided entry is silently disabled"; show "$ALL" 'L2'
elif [ -z "$L_NEG" ]; then FAIL "L2: NO SUBJECT — the carrier was never read, so the absence of the key was not established"
else PASS "L2: the carrier carries NO disable-model-invocation key. Its absence is the mechanism: every verb file withholds itself from the model and this one deliberately does not"; fi
if has_finding "$ALL" "$(surface L3)"; then FAIL "L3: the carrier does not declare all three negatives"; show "$ALL" 'L3'
elif [ -z "$L_NEG" ]; then FAIL "L3: NO SUBJECT — the carrier's declarations were never read"
else PASS "L3: the carrier declares all three negatives in its own body (${L_NEG} of 7 by the same recogniser C0 applies to the verb blocks) — writes nothing, dispatches no agent, and performs no act whose effect lands outside the trip's own files. It is the one surface here the model can see, so what it may do is written down"; fi

echo
echo "── Group H — the picker surface: what a reader is shown before they open a file."
if has_finding "$ALL" "$(surface H1)"; then FAIL "H1: a RESOLVE-role command file declares no argument-hint"; show "$ALL" 'H1'
else PASS "H1: all $(getcount "$H_OUT" HRESOLVE) RESOLVE-role command files declare an argument-hint — the one surface that renders at the moment a verb is chosen names something on every one of them. The role comes from the charter's ROLE record, never from a filename"; fi
if has_finding "$ALL" "$(surface H2)"; then FAIL "H2: an argument-hint names a token its own file declares no verb for"; show "$ALL" 'H2'
else PASS "H2: OUTWARD DRIFT EMPTY — every token of every hint's verb list is a declared verb of its own file, quantified over $(getcount "$H_OUT" HVERBS) declared verbs. A bare placeholder is caught here as the degenerate case of this assertion rather than by a rule of its own"; fi
if has_finding "$ALL" "$(surface H3)"; then FAIL "H3: a hint omits a declared verb and its description points at no reference"; show "$ALL" 'H3'
else PASS "H3: OVERFLOW IS DECLARED — every hint either carries its file's whole declared verb set or its description points at ${DOC_REL}. SCOPE: this grades VERB-SET AGREEMENT and never LENGTH. No length constant is held anywhere in this file: the rendering budget belongs to a CLI this repository does not own, does not version and cannot pin, so front-loading is an authoring rule and the ORDER of a hint is a named residual this group does not close"; fi
H_ROWS="$(getcount "$H_OUT" HROWS)"
if has_finding "$ALL" "$(surface H4)"; then FAIL "H4: the command reference is absent, unreadable, or its derived-region markers are not unique"; show "$ALL" 'H4'
else PASS "H4: ${DOC_REL} is readable and carries exactly one opening and one closing derived-region marker, in that order — the region has unambiguous bounds"; fi
if has_finding "$ALL" "$(surface H5)"; then
  FAIL "H5: the committed derived region disagrees with the live requirement tables"; show "$ALL" 'H5'
  printf '       the block the guard expected — replace the region with this:\n'
  printf '%s\n' "$H_OUT" | sed -n 's/^H5EXPECT /       /p'
elif [ -z "${H_ROWS:-}" ]; then
  FAIL "H5: the derivation never ran — the derived region could not be located, so a green here would report a comparison that did not happen. Resolve H4 first"
else
  PASS "H5: TOTALITY — the committed region equals the ${H_ROWS}-row derivation from the live requirement tables, recomputed on this commit. The eighth in-repo enumeration of the verb set is DERIVED and asserted, not remembered; on a divergence the guard prints the block it expected, so the remediation is a paste rather than a hunt"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group UW — a Zone A universal over the verb set, checked against the verb set.
#
# WHAT THIS GROUP IS FOR, AND THE DEFECT THAT PAID FOR IT. `.claude/skills/trip-record/SKILL.md`
# gave the ground for refusing a bare invocation as "every verb of this command writes" — a
# universal quantified over its own verb set, stated in Zone A, where nothing derives it. A
# later slice added a verb that declares it writes nothing, and the sentence became false.
# It had been written at TWO sites; one was converted when the verb landed and the other was
# missed, so the corpus shipped a false universal at the surviving site with the five suites
# then in place and every required check green. That is the whole argument for this group: the failure mode is
# not that the rule is unknown, it is that a prose universal has no reader, and a repair that
# leaves the next author the same silence is not a repair.
#
# ── THE ORACLE IS SOUND AND DELIBERATELY INCOMPLETE ────────────────────────────
# A verb counts as read-only IFF its own read-declaration block declares that it writes
# nothing — read as the WRITES-NOTHING BIT of the same NEG record C0 counts, so this group and
# C0 share one derivation and UW1 prints the two figures side by side. The block is the whole
# of it, from its opening line to the next blank line, normalised and token-bounded, which is
# the scope the three negatives are read over. It used to be the `**Reads:**` line alone, read
# case-sensitively, and that reading missed every verb whose declaration wraps: `/trip status`
# and `/trip schema` state it on a later physical line of the block, so a false universal planted
# beside them in `/trip` passed this group. Arm UW0b is that shape, built, and it must fire.
#
# It is still a LOWER bound on the read-only set: a verb that writes nothing and does not
# declare it is not counted. Incompleteness is safe HERE and would not be safe in a group
# asserting the converse — this group fails only when a read-only verb is FOUND beside a
# universal, so under-counting can only miss a finding and can never manufacture one.
# `/trip check` is the worked case: this file's held set declares it read-only, and its block
# does not state the negative, so the oracle does not count it.
#
# ── THE MATCHER IS FLATTENED, AND THAT IS THE POINT ────────────────────────────
# Zone A is normalised — lowercased, markdown emphasis and code ticks removed, whitespace
# collapsed to one line — before the pattern is applied, because the site that shipped false
# was HARD-WRAPPED between "this" and "command" and a line-anchored scan reports it absent.
# The pattern is likewise a SOUND, INCOMPLETE enumeration of shapes: it reads the two forms
# the corpus actually writes and no others, so a paraphrase is a false negative. Both bounds
# are stated here rather than left for a reader to infer from a green.
#
# ── WHY THE POPULATION GATE IS SHAPED THE WAY IT IS ────────────────────────────
# The subject arm is a ZERO, so UW0 asserts every input non-empty first — and it asserts
# COMPLETE region coverage rather than mere non-emptiness, because a Zone A/Zone B split that
# derived a fraction of the verb set would issue a confident vacuous pass. Group V3 already
# asserts one region per declared verb; UW0 asserts the count this group actually walked
# equals the count that file declares, so the two cannot disagree silently. The matcher
# carries a SENSITIVITY arm (a planted universal, which must be found) and TWO SPECIFICITY
# arms (a scoped non-universal and a whole-file quantifier, neither of which is a claim about
# what every verb does) — both of those were live false positives in an earlier attempt at
# this detector, and they are kept as arms rather than as a comment.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group UW — a Zone A universal over the verb set, checked against the verb set."

# The two shapes the corpus writes. Held as one string so every arm below — subject,
# sensitivity and both specificity arms — is demonstrably the SAME matcher.
UW_RE='((every|each|all) verbs? of this command [^.]*writes?)|((every|each|all) of this commands verbs? [^.]*writes?)'

# uw_norm <text> — lowercase, strip markdown emphasis / code ticks / apostrophes, collapse
# every run of whitespace to one space. A hard wrap must not hide a sentence from a scan.
uw_norm() { printf '%s' "$(lower "$(printf '%s' "$1" | tr -d '*`'"'")")" | tr -s '[:space:]' ' '; }

# uw_hits <normalised text> — how many universal-over-the-verb-set claims it carries.
uw_hits() { printf '%s\n' "$1" | awk -v re="$UW_RE" '{ n += gsub(re, "") } END { print n + 0 }'; }

# uw_file <verb-file> <records> — the per-file walk behind UW0 and UW1, and the ONE function arm
# UW0b runs too, so the arm grades the implementation the live tree gets rather than a second
# statement of it. Prints one line:
#   UWF <cmd> <walked> <declared> <zone-a-lines> <universals> <read-only> [<read-only verb> ...]
# On a coverage mismatch it prints the two counts and zeros, and the caller treats that as UW0's
# failure rather than as a clean file.
uw_file() {
  local f="$1" recs="$2" base cmd regions n decl first za zal univ ro=0 rolist='' s e v w
  local t1 t2 t3 t4
  local -a WN=()
  base="$(verb_id "$f")"; cmd="/$base"
  # Zone B's regions, from the SAME parser the rest of this guard runs on. Zone A is
  # everything above the first of them, which IS the file's own stated zone rule.
  # REGION records read "REGION <cmd> <verb> <start> <end>"; re-emitted here as
  # start / end / verb so the loop below reads positions first and never re-parses.
  regions="$(printf '%s\n' "$recs" | awk -v c="$cmd" '$1 == "REGION" && $2 == c { print $4 "\t" $5 "\t" $3 }')"
  n="$(printf '%s\n' "$regions" | grep -c '[^[:space:]]' || true)"
  decl="$(getcount "$recs" "DECL_$base")"
  if [ "$n" -eq 0 ] || [ "${decl:-0}" -eq 0 ] || [ "$n" -ne "${decl:-0}" ]; then
    printf 'UWF %s %d %d 0 0 0\n' "$cmd" "$n" "${decl:-0}"
    return 0
  fi
  # The oracle's population: this file's arms whose NEG record carries the writes-nothing bit.
  # One NEG record per arm, from its first read-declaration block — the record C0 counts.
  while IFS= read -r w || [ -n "$w" ]; do
    case "$w" in
      "NEG $cmd "*) IFS=' ' read -r t1 t2 t3 t4 <<< "$w"; [ $(( t4 & 4 )) -ne 0 ] && WN+=( "$t3" ) ;;
    esac
  done <<< "$recs"
  first="$(printf '%s\n' "$regions" | awk -F'\t' 'NR == 1 { m = $1 } $1 < m { m = $1 } END { print m + 0 }')"
  za="$(awk -v k="$first" 'NR <= k { print }' "$f")"
  zal="$(printf '%s\n' "$za" | grep -c '[^[:space:]]' || true)"
  univ="$(uw_hits "$(uw_norm "$za")")"
  while IFS="$(printf '\t')" read -r s e v; do
    [ -n "${s:-}" ] || continue
    if in_list "$v" "${WN[@]+"${WN[@]}"}"; then ro=$((ro+1)); rolist="$rolist$v "; fi
  done <<< "$regions"
  printf 'UWF %s %d %d %d %d %d %s\n' "$cmd" "$n" "$decl" "$zal" "$univ" "$ro" "$rolist"
}

UW_FILES=0; UW_UNIV=0; UW_RO=0; UW_BOTH=""; UW_ZA_LINES=0; UW_COVER_BAD=""; UW_UFILES=0
for uwf in "$CDIR"/*/SKILL.md; do
  [ -e "$uwf" ] || continue
  UW_FILES=$((UW_FILES+1))
  IFS=' ' read -r uwtag uwcmd uwn uwdecl uwzal uwu uwro uwrolist <<< "$(uw_file "$uwf" "$ALL")"
  if [ "${uwn:-0}" -eq 0 ] || [ "${uwdecl:-0}" -eq 0 ] || [ "${uwn:-0}" -ne "${uwdecl:-0}" ]; then
    UW_COVER_BAD="$UW_COVER_BAD${uwcmd:-$uwf}(walked=${uwn:-0} declared=${uwdecl:-0}) "
    continue
  fi
  UW_ZA_LINES=$((UW_ZA_LINES + uwzal))
  UW_UNIV=$((UW_UNIV + uwu)); UW_RO=$((UW_RO + uwro))
  [ "$uwu" -gt 0 ] && UW_UFILES=$((UW_UFILES+1))
  if [ "$uwu" -gt 0 ] && [ "$uwro" -gt 0 ]; then
    UW_BOTH="$UW_BOTH$uwcmd: $uwu universal(s) beside read-only verb(s) [ ${uwrolist}]; "
  fi
done

# ── Arm UW0b's world: the PLANTED SHAPE, built rather than patched. A Zone A universal in a file
# whose writes-nothing verb declares it past the first physical line of its read block — the shape
# the line-scoped oracle this replaced read as a verb stating no negative, so the universal passed.
UWP="$WORK/uwp"; gen_tree "$UWP" ok uwplant
UWP_F="$UWP/skills/trip/SKILL.md"
UWP_INT=1
grep -qF 'Every verb of this command writes' "$UWP_F" || UWP_INT=0
grep -q '^It writes nothing, dispatches no agent' "$UWP_F" || UWP_INT=0
grep -q '^\*\*Reads:\*\*.*writes nothing' "$UWP_F" && UWP_INT=0
IFS=' ' read -r uwptag uwpcmd uwpn uwpdecl uwpzal uwpu uwpro uwprolist <<< "$(uw_file "$UWP_F" "$(collect_records "$UWP")")"

UW_SENS="$(uw_hits "$(uw_norm 'and stop. **Every verb of this
command writes, and a write command never picks a write for you.**')")"
UW_SPEC1="$(uw_hits "$(uw_norm 'no verb reaching a reference store may write outside it.')")"
UW_SPEC2="$(uw_hits "$(uw_norm 'the guard reads every verb section on purpose, and writes nothing.')")"

# UW0 GATES UW1, AND THAT IS NOT DEFENSIVENESS — IT WAS MEASURED. Every number UW1
# reports is computed from the SAME region extents UW0 validates, so a failed gate does not
# merely weaken UW1's verdict, it makes UW1's verdict a statement about the wrong bytes.
# Under a deliberate regression that corrupted those extents, UW0 failed correctly AND UW1
# printed a PASS naming five read-only verbs where the oracle of that day counted two — a
# confidently wrong denominator on a green line, which is the exact shape of defect this whole
# group exists to catch, reproduced inside the group itself. The gate is therefore fail-closed: on a bad
# population UW1 reports a WITHHELD verdict rather than a computed one, because a group that
# went quiet would be an undeclared skip under this suite's strict-skip contract.
UW_OK=1
if [ "$UW_FILES" -eq 0 ] || [ "$UW_ZA_LINES" -eq 0 ]; then
  UW_OK=0
  FAIL "UW0: the walk read ${UW_FILES} command file(s) and ${UW_ZA_LINES} non-blank Zone A line(s) — one of those populations is empty, so the zero below would cover nothing"
elif [ -n "$UW_COVER_BAD" ]; then
  UW_OK=0
  FAIL "UW0: COVERAGE IS INCOMPLETE, and this is a failure rather than a partial pass — $UW_COVER_BAD. Zone A is defined as everything above the FIRST verb region, so a file whose regions were partly derived yields a Zone A of the wrong extent and a confident verdict over the wrong bytes. The walked count is asserted equal to the count each file declares, which group V3 independently grades one-region-per-verb"
elif [ "$UW_SENS" -eq 0 ]; then
  UW_OK=0
  FAIL "UW0: MUST FIRE — the SENSITIVITY arm returned zero. The identical matcher was run over a planted, HARD-WRAPPED universal of the exact shape that shipped false, and did not find it. The subject zero below is therefore an empty scan rather than a clean corpus, and this group reports the probe UNUSABLE"
elif [ "$UW_SPEC1" -ne 0 ] || [ "$UW_SPEC2" -ne 0 ]; then
  UW_OK=0
  FAIL "UW0: the SPECIFICITY arms fired — a scoped non-universal returned $UW_SPEC1 and a whole-file quantifier returned $UW_SPEC2, expected zero from both. Neither is a claim about what every verb does, and a matcher that reads them as one turns green corpora red; both were live false positives in an earlier attempt at this detector"
else
  PASS "UW0: the walk covered ${UW_FILES} command file(s) and ${UW_ZA_LINES} non-blank Zone A line(s), with every file's walked region count EQUAL to the verb count it declares — coverage is total rather than merely non-empty, which is what stops a partial Zone A/Zone B split from issuing a confident vacuous pass. The matcher is a measurement: the SENSITIVITY arm found ${UW_SENS} planted hard-wrapped universal, and both SPECIFICITY arms returned zero on sentences shaped like one"
fi

# UW0b — MUST FIRE, and UW1 is withheld unless it does. Its world carries exactly one verb that
# declares writes-nothing (past the first physical line) beside one that does not, so the arm is a
# sensitivity arm and a specificity arm at once: the oracle has to count the first and not the
# second, and the file has to yield the universal beside it.
if [ "$UWP_INT" -eq 0 ]; then
  UW_OK=0
  FAIL "UW0b: fixture integrity — the planted world must carry a Zone A universal AND a verb stating writes-nothing only past the first physical line of its read block; one of those is absent, so a verdict here would prove nothing"
elif [ -z "${uwpro:-}" ] || [ -z "${uwpu:-}" ]; then
  UW_OK=0
  FAIL "UW0b: NO SUBJECT — uw_file emitted nothing over the planted world, so the oracle was never run on it"
elif [ "$uwpu" -gt 0 ] && [ "$uwpro" -eq 1 ] && [ "$(trim "${uwprolist:-}")" = 'status' ]; then
  PASS "UW0b: MUST FIRE — over a built world carrying a Zone A universal in ${uwpcmd}, the oracle counts ${uwpro} read-only verb (${uwprolist% }), whose read block states writes-nothing only on its SECOND physical line, and does not count the verb beside it that states no negative — so this group would name ${uwpcmd} beside ${uwpu} universal(s). The oracle is the writes-nothing bit C0 reads, over the whole block; the line-scoped reading it replaced counts zero here and passes the planted universal"
else
  UW_OK=0
  FAIL "UW0b: the oracle over the planted world returned universals=${uwpu} read-only=${uwpro} [${uwprolist:-}], where at least one universal and exactly [status] were required — it does not count a verb whose declaration wraps, or counts one that declares nothing, so the zero below is not a measurement"
fi

UW_CNEGW="$(getcount "$C_OUT" CNEGW)"
UW_RO_NOTE="the oracle found no verb declaring writes-nothing in any file"
[ "$UW_RO" -gt 0 ] && UW_RO_NOTE="the oracle found ${UW_RO} verb(s) declaring writes-nothing, every one of them in a file carrying no universal"
if [ "$UW_OK" -eq 0 ]; then
  FAIL "UW1: VERDICT WITHHELD — UW0 or UW0b did not pass, and every figure this arm would report is computed from the same region extents and the same oracle those two grade. A verdict here would be a confident statement over the wrong bytes rather than a weaker statement over the right ones. Resolve them first; this arm has nothing trustworthy to say until then"
elif [ -z "$UW_CNEGW" ] || [ "$UW_RO" -ne "$UW_CNEGW" ]; then
  FAIL "UW1: the oracle counted ${UW_RO} verb(s) declaring writes-nothing and C0 counted ${UW_CNEGW:-none} over the same read-declaration records — one derivation read two ways has come apart, so neither figure can be trusted"
elif [ -n "$UW_BOTH" ]; then
  FAIL "UW1: a Zone A universal quantified over the verb set stands beside a verb that declares it writes nothing — ${UW_BOTH}. The universal is false as written. Convert it to the rule that derives the set rather than repairing the enumeration, per that file's own repair extension point, and check EVERY site: this defect shipped once already because the sentence stood at two sites and only one was converted"
elif [ "$UW_UNIV" -eq 0 ] && [ "$UW_RO" -gt 0 ]; then
  PASS "UW1: ZERO Zone A universals of this shape survive across ${UW_FILES} command file(s), and the oracle found ${UW_RO} verb(s) whose own read-declaration block declares that they write nothing — the writes-nothing component C0 reports over the same records, ${UW_CNEGW} there. Both halves matter: the subject is the zero, and the ${UW_RO} is what makes it a measurement — a run where the oracle found none would pass this assertion while establishing nothing about it"
elif [ "$UW_UNIV" -eq 0 ]; then
  PASS "UW1: VACUOUS ON THE ORACLE — READ THIS AS VACUOUS, NOT AS PASSING. Zero Zone A universals were found, but the read-only oracle also found zero verbs declaring no write, so this run establishes nothing about the conjunction it exists to forbid. The oracle is deliberately a lower bound: it counts only a verb whose own read declaration states the negative in the corpus's declaration form"
else
  PASS "UW1: ${UW_UNIV} Zone A universal(s) over the verb set stand in ${UW_UFILES} of ${UW_FILES} file(s), and none of those files declares a verb that writes nothing — ${UW_RO_NOTE}. So each universal is unfalsified on the evidence this guard can reach. The oracle is a lower bound by construction, so this is not a proof that every such sentence is true; it is a statement that none is contradicted by a declaration in its own file"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group TD — a verb that declares the roster block as a read disposes of the count in it.
#
# WHAT THIS GROUP IS FOR, AND THE DEFECT THAT PAID FOR IT. `## group [<name>]` declares its
# read of `## Group` for four stated purposes, one of which is that the disposition for
# `- **Total travelers:**` is chosen from that field's current value. `## group-expand`
# CITED that read — "which is `## group`'s read and is cited rather than re-derived" — and
# named two of the four, while its write clause named only the roster row. The citation
# therefore imported a purpose the citing verb never discharged, and two faithful readers
# got different bytes in `trip-context.md` on the verb's own headline path: a freshly
# scaffolded trip, where the template ships the field bracketed and every member surveys
# `NEW`, ends with a populated roster beside a placeholder total. No AC graded it and five
# suites were green. That is the whole argument for this group — a cited read has no reader,
# and the half of a block that carries a reconciliation table is the half that goes stale
# in silence.
#
# ── THE ORACLE IS THE READ DECLARATION, NOT THE BODY ───────────────────────────
# A verb is IN the population iff its own column-0 `**Reads:**` line names the block. That
# is the corpus's own declaration form, and it is what makes this a rule rather than an
# enumeration: a verb added later that declares the same read lands in the population with
# no edit here. Body mentions are deliberately NOT the oracle — `## fact`, `## erase`,
# `## extract` and `## profile` each name the block in prose without declaring it as a read,
# and sweeping them in would grade verbs that never took the read whose purposes are at issue.
#
# ── THE SUBJECT EXCLUDES THE READ LINE, AND THAT IS THE POINT ──────────────────
# The field must be disposed of in the verb's OWN PROSE, not merely named in the read
# declaration that raised the question. Naming a purpose is what `group-expand` failed to
# do; saying what the verb does about it is what settles the ambiguity, and only the second
# is graded here. TD0's second specificity arm is that distinction, executed: the identical
# field matcher is run over a `**Reads:**` line CARRYING the field and must return zero.
#
# ── WHY THE POPULATION GATE IS SHAPED THE WAY IT IS ────────────────────────────
# The subject arm is a ZERO, so TD0 asserts the population non-empty first, and asserts
# COMPLETE region coverage rather than mere non-emptiness for the reason group UW states at
# length: a split that derived a fraction of the verb set issues a confident vacuous pass.
# Both matchers carry a SENSITIVITY arm and a SPECIFICITY arm, and all four run the
# identical functions the subject runs. Every matcher is `index()` over a literal rather
# than a pattern, so none can be silently rejected into a plausible zero.
#
# ── WHAT THIS GROUP DELIBERATELY DOES NOT GRADE ────────────────────────────────
# It grades that the field is DISPOSED OF, never HOW. A verb stating in terms that it does
# not touch the field passes here, and correctly: the defect was the silence, not the
# disposition. Which disposition `group-expand` takes is decided in
# `reference/adr/ADR-016-reusable-groups.md` § 4 and stated in that verb's own section; this
# group holds the question answered, not the answer.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group TD — a verb that declares the roster block as a read disposes of the count in it."

# The block and the field, held as strings so every arm below — subject, both sensitivity
# arms and both specificity arms — is demonstrably the SAME matcher. Literal substrings,
# never patterns: a rejected pattern yields a plausible zero, which is the failure this
# group exists to make impossible.
TD_BLOCK='`## Group`'
TD_FIELD='- **Total travelers:**'

# td_declares <text> — 1 if a column-0 `**Reads:**` line in the text names the block.
td_declares() {
  printf '%s\n' "$1" | awk -v b="$TD_BLOCK" '
    index($0, "**Reads:**") == 1 && index($0, b) > 0 { f = 1 }
    END { print f + 0 }'
}

# td_disposes <text> — how many NON-read-declaration lines name the field. The read line is
# dropped here rather than by the caller, because a caller that forgot would count a cited
# purpose as a discharged one, which is the exact defect.
td_disposes() {
  printf '%s\n' "$1" | awk -v f="$TD_FIELD" '
    index($0, "**Reads:**") == 1 { next }
    index($0, f) > 0             { n++ }
    END { print n + 0 }'
}

TD_FILES=0; TD_POP=0; TD_POPLIST=""; TD_BAD=""; TD_COVER_BAD=""
for tdf in "$CDIR"/*/SKILL.md; do
  [ -e "$tdf" ] || continue
  TD_FILES=$((TD_FILES+1))
  tdbase="$(verb_id "$tdf")"; tdcmd="/$tdbase"
  tdregions="$(printf '%s\n' "$ALL" | awk -v c="$tdcmd" '$1 == "REGION" && $2 == c { print $4 "\t" $5 "\t" $3 }')"
  tdn="$(printf '%s\n' "$tdregions" | grep -c '[^[:space:]]' || true)"
  tddecl="$(getcount "$ALL" "DECL_$tdbase")"
  if [ "$tdn" -eq 0 ] || [ "${tddecl:-0}" -eq 0 ] || [ "$tdn" -ne "${tddecl:-0}" ]; then
    TD_COVER_BAD="$TD_COVER_BAD$tdcmd(walked=$tdn declared=${tddecl:-0}) "
    continue
  fi
  while IFS="$(printf '\t')" read -r tds tde tdverb; do
    [ -n "${tds:-}" ] || continue
    # The region's own bounds, in the SAME attribution the parser uses to assign a read
    # declaration to a verb: strictly inside the heading and up to the next one.
    tdtext="$(awk -v s="$tds" -v e="$tde" 'NR > s && NR <= e { print }' "$tdf")"
    [ "$(td_declares "$tdtext")" -eq 1 ] || continue
    TD_POP=$((TD_POP+1)); TD_POPLIST="$TD_POPLIST$tdcmd ${tdverb:-?}; "
    if [ "$(td_disposes "$tdtext")" -eq 0 ]; then
      TD_BAD="$TD_BAD$tdcmd ${tdverb:-?}; "
    fi
  done <<TDEOF
$tdregions
TDEOF
done

TD_SENS="$(td_declares '**Reads:** `trips/<slug>/trip-context.md` — the whole of `## Group`, read before it is written.')"
TD_SPEC="$(td_declares '**Reads:** `trips/<slug>/trip-context.md` — the whole of `## Mode`, read before it is written.')"
TD_FSENS="$(td_disposes 'the disposition for `- **Total travelers:**` is chosen from that value.')"
TD_FSPEC="$(td_disposes '**Reads:** `## Group`, because the disposition for `- **Total travelers:**` is chosen from it.')"

TD_OK=1
if [ "$TD_FILES" -eq 0 ]; then
  TD_OK=0
  FAIL "TD0: the walk read ${TD_FILES} command file(s) — the population below would cover nothing"
elif [ -n "$TD_COVER_BAD" ]; then
  TD_OK=0
  FAIL "TD0: COVERAGE IS INCOMPLETE, and this is a failure rather than a partial pass — $TD_COVER_BAD. Every verdict below is computed from the region extents this gate grades, so a file whose regions were partly derived yields a population of the wrong shape and a confident verdict over the wrong bytes. The walked count is asserted equal to the count each file declares, which group V3 independently grades one-region-per-verb"
elif [ "$TD_POP" -eq 0 ]; then
  TD_OK=0
  FAIL "TD0: NO verb across ${TD_FILES} command file(s) declares \`## Group\` in its own \`**Reads:**\` line, so the subject arm would be a statement over the empty set. Two verbs declare it in the tree this group was written against; a zero here means the read declaration changed shape or the oracle stopped matching it, and either is a coverage regression rather than a clean corpus"
elif [ "$TD_SENS" -ne 1 ] || [ "$TD_FSENS" -ne 1 ]; then
  TD_OK=0
  FAIL "TD0: MUST FIRE — a SENSITIVITY arm returned the wrong value. The read oracle returned $TD_SENS over a planted declaration naming the block (expected 1), and the field matcher returned $TD_FSENS over a planted body line naming the field (expected 1). A matcher that cannot find what it is looking for reports nothing about the real regions, so this group reports the probe UNUSABLE rather than the corpus clean"
elif [ "$TD_SPEC" -ne 0 ] || [ "$TD_FSPEC" -ne 0 ]; then
  TD_OK=0
  FAIL "TD0: a SPECIFICITY arm fired — the read oracle returned $TD_SPEC over a declaration naming a DIFFERENT block (expected 0), and the field matcher returned $TD_FSPEC over a \`**Reads:**\` line CARRYING the field (expected 0). The second is the distinction this whole group turns on: naming a field among a cited read's purposes is not discharging it, and a matcher that counted the read line would have passed the defect that paid for this group"
else
  PASS "TD0: the walk covered ${TD_FILES} command file(s) with every file's walked region count EQUAL to the verb count it declares, and found ${TD_POP} verb(s) declaring \`## Group\` in their own read line — ${TD_POPLIST}a population rather than an enumeration held here, so a verb added later that takes the same read is graded with no edit. Both matchers are measurements: the SENSITIVITY arms returned $TD_SENS and $TD_FSENS on planted text, and both SPECIFICITY arms returned zero — including the identical field matcher run over a \`**Reads:**\` line that CARRIES the field"
fi

if [ "$TD_OK" -eq 0 ]; then
  FAIL "TD1: VERDICT WITHHELD — TD0 did not pass, and every figure this arm would report is computed from the same population TD0 grades. A verdict here would be a confident statement over the wrong bytes rather than a weaker statement over the right ones. Resolve TD0 first; this arm has nothing trustworthy to say until then"
elif [ -n "$TD_BAD" ]; then
  FAIL "TD1: a verb declares \`## Group\` in its own read line and never says what it does with \`- **Total travelers:**\` — ${TD_BAD}. That block's scope is the roster table, this field, \`- **Travel mode:**\` and \`- **Subgroup notes:**\`; a verb reading the whole block and writing part of it leaves the rest undisposed, and this is the field carrying a reconciliation table, so it is the one that goes stale in silence. Say what the verb does with it — reconcile it by \`## group\`'s table, or state that it does not touch it and why. Naming it among a cited read's purposes is not enough, and this arm excludes the read line for that reason"
else
  PASS "TD1: all ${TD_POP} verb(s) declaring \`## Group\` as a read dispose of \`- **Total travelers:**\` in their OWN prose, outside the read declaration that raises the question. The zero is a measurement: on the same run the field matcher found the field on planted text ($TD_FSENS) and returned zero over a read line carrying it ($TD_FSPEC). This grades that the question is ANSWERED, never which answer is taken — a verb declining the field in terms passes here, and correctly"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group J — every file an agent writes is named in its agent-roster row. The reader,
# roster_write_check, and its three one-verdict assertions are defined beside the other
# checkers; this is where they report. Its controls are group GJ, beside the other
# control blocks, and its assertions are registered with md_flips at the end of group MD.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group J — every file an agent writes is named in its roster row, as § 1.1's writer column and the agent's own prompt declare it."
surface J0 J1 J2 >/dev/null
rj_assert_population "$ROOT"
rj_assert_named "$ROOT"
rj_assert_join "$ROOT"

# ═════════════════════════════════════════════════════════════════════════════════
# Group G — controls. Fixture-driven: every fixture path below is rooted at $WORK, so no
# arm writes a surface this guard grades, and group Z grades that claim over the watched
# set. Every arm re-proves on each push instead of decaying into a one-time demonstration.
# Every arm asserts FIXTURE INTEGRITY FIRST: a control built on a fixture that was never
# constructed is a green proving nothing, one level down.
# The must-NOT-fire arms come FIRST, because without them the negative arms prove nothing
# — a checker hard-wired to return 1 passes every one of them.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group G — controls: the guard shown FAILING on deliberate defects, PASSING on a correct tree, and DERIVING rather than remembering."

G0="$WORK/g0"; gen_tree "$G0" ok ok
if [ -f "$G0/CLAUDE.md" ] && [ -f "$G0/skills/trip/SKILL.md" ] && [ -f "$G0/skills/trip-new/SKILL.md" ] && [ -f "$G0/skills/trip-record/SKILL.md" ] && [ -f "$G0/skills/trip-publish/SKILL.md" ]; then
  PASS "G0a: fixture integrity — the conforming tree was constructed"
  G0OUT="$(run_tree "$G0")"
  if grep -q '^FINDING ' <<<"$G0OUT"; then
    FAIL "G0b: MUST-NOT-FIRE — the conforming tree was flagged: $(printf '%s' "$G0OUT" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
  else
    PASS "G0b: MUST-NOT-FIRE — a correct tree returns no finding of any id; the guard is not hard-wired red"
    # G0c-h each name a SPECIFIC SHAPE the conforming tree is supposed to carry. G0b
    # establishes only that the tree produced no finding; on its own that is equally
    # consistent with the shape never having been generated. Each claim below therefore
    # probes its own shape first, and a missing shape is a fixture-integrity FAILURE, not
    # a quiet green — the same discipline every ctl/ectl arm already applies, which these
    # six inherited the label of without the probe.
    g0claim() {  # g0claim <ok> <id> <claim>
      if [ "$1" -eq 1 ]; then PASS "$2: MUST-NOT-FIRE — $3"
      else FAIL "$2: fixture integrity — the shape this arm names is absent from the conforming tree, so its green would prove nothing: $3"; fi
    }
    G0S=1
    grep -qF '## profile <name>' "$G0/skills/trip-record/SKILL.md" || G0S=0
    grep -qF '| .publish-slug | ACTIVE' "$G0/skills/trip-record/SKILL.md" || G0S=0
    grep -qF '| new (create) | ACTIVE' "$G0/skills/trip-new/SKILL.md" || G0S=0
    grep -qF '| new (resume) | ACTIVE' "$G0/skills/trip-new/SKILL.md" || G0S=0
    g0claim "$G0S" G0c "an argument-signature heading, a leading-dot verb and a parenthetical disposition pair all resolve"
    G0S=1
    grep -qF '    **Reads:** nothing beyond the blocks above.' "$G0/skills/trip/SKILL.md" || G0S=0
    grep -qF '**Reads:** an example read line.' "$G0/skills/trip/SKILL.md" || G0S=0
    g0claim "$G0S" G0d "four-space-indented read-declaration EXEMPLARS in a non-verb section produce no undeclared-verb finding (the column-0 rule), and a read-declaration line inside a fenced example produces none either (fence depth)"
    G0S=1
    grep -qF '## ghostverb' "$G0/skills/trip/SKILL.md" || G0S=0
    g0claim "$G0S" G0e "a verb-shaped heading inside a fenced example produces no section, so the file with no real verb sections is not given an invented one"
    G0S=1
    grep -qF 'never passes' "$G0/skills/trip/SKILL.md" || G0S=0
    grep -qF "| ${BT}Bash(${SCRIPT_REL} update:*)${BT} | the single invocation |" "$G0/skills/trip/SKILL.md" || G0S=0
    grep -qF "act, and see ${BT}/trip status${BT} for the current state" "$G0/CLAUDE.md" || G0S=0
    g0claim "$G0S" G0f "a negating sentence naming a forbidden flag INSIDE a verb region, a grant token rendered as a code span in a body table, and a decoy command span in the Action column all PASS: the test is USE and FIELD-INDEXED, not MENTION and row-wide"
    G0S=1
    grep -qF 'population-role: CREATE' "$G0/skills/trip-new/SKILL.md" || G0S=0
    grep -qF '## Create' "$G0/skills/trip-new/SKILL.md" || G0S=0
    grep -qF '**Reads:** the template it copies from.' "$G0/skills/trip-new/SKILL.md" || G0S=0
    g0claim "$G0S" G0g "a CREATE-role file implementing no verb section resolves through the charter-declared carve-out, and a read declaration in its body is claimed"
    G0S=1
    grep -qF "${SCRIPT_REL} publish trips/x" "$G0/CLAUDE.md" || G0S=0
    grep -qF "${SCRIPT_REL} rotate trips/x" "$G0/CLAUDE.md" || G0S=0
    g0claim "$G0S" G0h "the fixture charter carries literal EXCLUDED invocations in a fenced block and the invocation limb reports zero: its input set is the skills directory and nothing else"
    G0S=1
    grep -qF "${AMB_MARK}${BT}/trip status${BT}${AMB_SEP}${BT}/trip-publish list${BT}" "$G0/CLAUDE.md" || G0S=0
    g0claim "$G0S" G0i "a DECLARED, CROSS-COMMAND ambiguity set whose members each keep their own ADDRESSED row produces no finding of any id — the declared choice is TOLERATED while the accidental double cover beside it (arm GK3b) is still K3. This is the MUST-NOT-FIRE half of the tolerance; without it the set arms would only show the guard refusing things"
    G0S=1
    grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${BT}/trip-record profile${BT}${AMB_SEP}${BT}/trip-publish update${BT}" "$G0/CLAUDE.md" || G0S=0
    grep -qF "| /trip-record profile | sig | ${GRADE_RETAIN}${GRADE_SEP}act | ex | ${BT}/trip-record profile${BT} |" "$G0/CLAUDE.md" || G0S=0
    grep -qF "| /trip-publish update | sig | ${GRADE_RETAIN}${GRADE_SEP}act | ex | ${BT}/trip-publish update${BT} |" "$G0/CLAUDE.md" || G0S=0
    g0claim "$G0S" G0j "a set carrying ONE DISPOSITION member beside unit members that each keep their own ADDRESSED row produces no finding of any id — the G0i analogue for the second member kind. The probe asserts all three shapes, so the green cannot rest on a set that was never generated or on unit members that never had their own rows"
  fi
else
  FAIL "G0a: fixture integrity — the conforming tree was not constructed; G0b-i would prove nothing"
fi

# ── the two live differential arms. Drawn from the UNFILTERED live population.
D1_FENCE=0
for gf in "$CDIR"/*/SKILL.md; do
  [ -e "$gf" ] || continue
  D1_FENCE=$(( D1_FENCE + $(fence_scoped_declared "$gf") ))
done
D1_ANCH="$(printf '%s\n' "$RECS" | grep -c '^DECL ')"
if [ "${D1_ANCH:-0}" -gt "$D1_FENCE" ]; then
  PASS "G-D1: LIVE DIFFERENTIAL — the header-row anchor recovers ${D1_ANCH} declared verbs where the fence-scoped locator this guard replaced recovers ${D1_FENCE}. On committed state the fence-based reading returns a SILENT PLAUSIBLE ZERO, and every direction of K over it would be vacuously true"
elif [ "${D1_ANCH:-0}" -eq "$D1_FENCE" ] && [ "${D1_ANCH:-0}" -gt 0 ]; then
  PASS "G-D1: NO LONGER DIFFERENTIAL — both locators recover ${D1_ANCH}. The route here is NOT the requirement table moving back inside the contract-header fence: that state unhooks the depth-0 anchor entirely, yields ZERO against a positive fence-scoped count, and lands in the FAIL arm below with V0 firing per file alongside. This branch is reached when every file KEEPS its depth-0 header row AND the contract-header fences come to carry pipe rows totalling the same number. Read that as a coincidence of counts, not agreement of readings: the two comparators count DIFFERENT UNITS — DISTINCT verb identities on the anchor side, RAW fenced rows on the other — so a file declaring one identity across two parenthetical rows already separates them. This arm no longer establishes the anchor choice and is reported as such rather than as passing"
else
  FAIL "G-D1: the header-row anchor recovers ${D1_ANCH} declared verbs against the fence-scoped locator's ${D1_FENCE} — it cannot be poorer, so one of the two is broken"
fi

D2_COL0=0; D2_TRIM=0
for gf in "$CDIR"/*/SKILL.md; do
  [ -e "$gf" ] || continue
  gb="$(verb_id "$gf")"
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

# ── the re-key differential. K3 is keyed on the PAIR; the retired keying was on the
# COMMAND. Running both comparators over the live ADDRESSED set is what demonstrates the
# re-key on real rows instead of asserting it.
D3_CMD="$(getcount "$COV_OUT" CMDKEYED)"; D3_PAIR="$(getcount "$COV_OUT" DBLCOVER)"
if [ "${D3_CMD:-0}" -gt "${D3_PAIR:-0}" ]; then
  PASS "G-D3: LIVE DIFFERENTIAL — over the live ADDRESSED set the COMMAND-keyed comparator emits ${D3_CMD} collisions where the PAIR-keyed one emits ${D3_PAIR:-0}. The re-key is demonstrated on real rows, not claimed"
elif [ "${D3_CMD:-0}" -eq "${D3_PAIR:-0}" ]; then
  PASS "G-D3: NO LONGER DIFFERENTIAL — both comparators emit ${D3_CMD:-0}. Every command now carries at most one ADDRESSED cell, so this arm no longer establishes the re-key and is reported as such rather than as passing. The differential is a property of the DATA, not of the key rule, which is untouched"
else
  FAIL "G-D3: the command-keyed comparator emits ${D3_CMD:-0} against the pair-keyed ${D3_PAIR:-0} — it cannot emit FEWER, so one of the two is broken"
fi

# ── the heading-split differential. The section is matched on the heading's FIRST token;
# the whole-heading matcher runs in the same pass and its result must be a SUBSET. A
# heading it resolves that the split misses is a hard failure (V6); the differential
# below is what shows the split is doing work rather than agreeing by accident.
D4_FT=0; D4_WH=0
for gf in "$CDIR"/*/SKILL.md; do
  [ -e "$gf" ] || continue
  gb="$(verb_id "$gf")"
  gft="$(getcount "$RECS" "FT_$gb")"; gwh="$(getcount "$RECS" "WH_$gb")"
  D4_FT=$(( D4_FT + ${gft:-0} )); D4_WH=$(( D4_WH + ${gwh:-0} ))
done
if [ "$D4_FT" -gt "$D4_WH" ]; then
  PASS "G-D4: LIVE DIFFERENTIAL — first-token matching resolves ${D4_FT} verb sections where whole-heading matching resolves ${D4_WH}. The $(( D4_FT - D4_WH )) it would lose are argument-signature headings; a whole-heading join under-counts the verb population and every direction of K over it reads a smaller surface"
elif [ "$D4_FT" -eq "$D4_WH" ] && [ "$D4_FT" -gt 0 ]; then
  PASS "G-D4: NO LONGER DIFFERENTIAL — both matchers resolve ${D4_FT}. No heading carries an argument signature, so this arm no longer establishes the split and is reported as such rather than as passing. The subset assertion still runs and still fails on a lost member"
else
  FAIL "G-D4: first-token matching resolves ${D4_FT} sections against whole-heading's ${D4_WH} — the split cannot resolve FEWER, so one of the two is broken"
fi

# ── the negative arms. One per emittable id; group Y asserts the mapping is total.
ctl() {  # ctl <id> <want> <label> <charter-defect> <cmd-defect> <integrity-probe>
  local id="$1" want="$2" label="$3" cdd="$4" mdd="$5" probe="$6"
  local d="$WORK/$id"; gen_tree "$d" "$cdd" "$mdd"
  arm "$want"
  if ! eval "$probe"; then FAIL "${id}a: fixture integrity — the deliberate defect is absent; ${id}b would prove nothing"; return; fi
  PASS "${id}a: fixture integrity — the deliberate defect is present"
  local out; out="$(run_tree "$d")"
  if ! grep -q '^FINDING ' <<<"$out"; then FAIL "${id}b: the deliberate defect was NOT flagged ($label)"
  elif grep -q "^FINDING $want " <<<"$out"; then PASS "${id}b: flagged, naming $want — $label"
  else FAIL "${id}b: flagged but not as $want ($label): $(printf '%s' "$out" | grep '^FINDING ' | head -1)"; fi
}

ctl GA0  A0 "an empty skills directory — a FAIL, not a vacuous pass"          ok        nocmds  '[ -d "$WORK/GA0/skills" ] && [ -z "$(ls -A "$WORK/GA0/skills")" ]'
ctl GA0b A0 "an absent Step-1 slice — a FAIL, not a vacuous pass"              nostep1   ok      '! grep -q "^### Step 1:" "$WORK/GA0b/CLAUDE.md"'
ctl GV0  V0 "a command file whose requirement table is absent"                 ok        notable    '! grep -q "^| verb | lifecycle" "$WORK/GV0/skills/trip/SKILL.md"'
ctl GV0b V0 "a command file carrying TWO requirement-table header rows"        ok        twotables  '[ "$(grep -c "^| verb | lifecycle" "$WORK/GV0b/skills/trip/SKILL.md")" = "2" ]'
ctl GV1  V1 "a requirement-table row that does not parse at five columns"      ok        badrow     'grep -qF "| broken | ACTIVE | any |" "$WORK/GV1/skills/trip/SKILL.md"'
ctl GV2  V2 "one verb identity declared twice with no parenthetical"           ok        dupident   '[ "$(grep -c "^| status | ACTIVE" "$WORK/GV2/skills/trip/SKILL.md")" = "2" ]'
ctl GV3  V3 "a declared verb with no implementing region"                      ok        nosection  '! grep -q "^## status$" "$WORK/GV3/skills/trip/SKILL.md"'
ctl GV3b V3 "a declared verb with TWO implementing regions"                    ok        twosections 'grep -qF "## status <other>" "$WORK/GV3b/skills/trip/SKILL.md"'
ctl GV4  V4 "a column-0 read declaration in a NON-verb section"                ok        strayreads 'grep -qF "**Reads:** something undeclared." "$WORK/GV4/skills/trip/SKILL.md"'
ctl GV5  V5 "a command file with no contract-header block"                     ok        noheader   '! grep -q "trip-contract-header" "$WORK/GV5/skills/trip/SKILL.md"'
ctl GV5b V5 "a command file carrying TWO contract-header blocks"               ok        twoheader  '[ "$(grep -c "trip-contract-header" "$WORK/GV5b/skills/trip/SKILL.md")" = "2" ]'
ctl GV6  V6 "a Step-1 cell whose code-span strip changes the VALUE while the row count holds" badspan ok 'grep -qF "st${BT}atus" "$WORK/GV6/CLAUDE.md"'
ctl GB1  B1 "a Step-1 row matching none of the three cell classes"             badcell   ok  'grep -qF "| ex | neither |" "$WORK/GB1/CLAUDE.md"'
ctl GB4  B4 "the same row seen as an exhaustiveness gap — it is counted as neither" badcell ok 'grep -qF "| ex | neither |" "$WORK/GB4/CLAUDE.md"'
ctl GB2  B2 "an EXCLUDED reason outside the closed five-value enum"            offenum   ok  'grep -qF "because I said so" "$WORK/GB2/CLAUDE.md"'
ctl GB2b B2 "an EXCLUDED cell carrying the same reason twice"                  dupreason ok  'grep -qF "repo-creation + repo-creation" "$WORK/GB2b/CLAUDE.md"'
ctl GB3  B3 "a cell the MINIMAL widening would admit and the alternation rejects" badgrammar ok 'grep -qF -- "/trip --.x" "$WORK/GB3/CLAUDE.md"'
ctl GB5  B5 "an ADDRESSED cell whose COMMAND component fails N1"               badn1     ok  'grep -qF "/Trip status" "$WORK/GB5/CLAUDE.md"'
# ── The ambiguity-set arms. Each plants ONE defect beside the conforming set every fixture
# world already carries, so the arms grade the new predicates rather than the fixture. Every
# one is MUST-FIRE: a run where the planted defect goes unflagged FAILS, which is what makes
# the set leg gate on every push while the LIVE ambiguity population is still zero. Read
# them with G0i, which is the must-NOT-fire half of the same claim.
ctl GB6  B6 "an ambiguity set declaring ONE member — a choice needs two"       ambone       ok 'grep -qF "| ex | ${AMB_MARK}${BT}/trip status${BT} |" "$WORK/GB6/CLAUDE.md"'
ctl GB6b B6 "an ambiguity-set member that fails the UNCHANGED cell grammar"    ambbadmember ok 'grep -qF "${AMB_MARK}${BT}/trip status${BT}${AMB_SEP}${BT}/trip --.x${BT}" "$WORK/GB6b/CLAUDE.md"'
ctl GB6c B6 "two code spans joined by the separator with NO marker — the UNDECLARED set, which must stay a hard failure so a set is declared and never inferred from a parse failure" ambnomarker ok 'grep -qF "| ex | ${BT}/trip status${BT}${AMB_SEP}${BT}/trip check${BT} |" "$WORK/GB6c/CLAUDE.md"'
# ── The ENTRY-CLASS arms. GB7 is MUST-FIRE and GB7b is the MUST-NOT-FIRE half beside it; read
# them as a pair, because each closes a direction the other cannot. GB7 closes the FIELD INDEX:
# its world carries a correctly-spelled marker in the Example cell of an ungraded row, so a
# row-wide scan of the row reads green and only a read of field 3 goes red. GB7b closes the
# QUANTIFIER: B7 grades ADDRESSED rows and nothing else, in both directions.
#
# The spec's third defect row — a MISSPELLED marker — is deliberately NOT generated. A
# misspelling and an absence reach the same `case` limb by the same route, so an arm over it
# would add an assertion that cannot fail while GB7 passes, and a fixture world no arm drives is
# the dead green this group exists to refuse. The field-index property was bought instead.
ctl GB7  B7 "an ADDRESSED row whose ACTION cell carries no entry-class marker while a correctly-spelled one sits in its EXAMPLE cell — a row-wide read of the row passes this arm and only a FIELD-INDEXED read of field 3 fails it" b7none ok 'grep -qF "| X | sig | act | ${GRADE_RETAIN}${GRADE_SEP}ex | ${BT}/trip check${BT} |" "$WORK/GB7/CLAUDE.md"'
ctl GK1  K1 "an ADDRESSED cell naming a verb no requirement table declares"    ghostkey  ok  'grep -qF "nosuchverb" "$WORK/GK1/CLAUDE.md"'
ctl GK2  K2 "a declared verb covered by no ADDRESSED cell"                     uncovered ok  '! grep -qF "| /trip check |" "$WORK/GK2/CLAUDE.md"'
# GK2b is the arm that proves TOTALITY DID NOT WEAKEN: the verb is named as an OPTION in a
# well-formed declared set and nowhere else, and it is still a K2. Without it, "set
# membership never satisfies totality" would be a sentence in a banner rather than a check.
ctl GK2b K2 "a verb reachable ONLY as an option inside a well-formed declared set — set membership never satisfies totality" ambuncovered ok 'grep -qF "${AMB_MARK}${BT}/trip check${BT}${AMB_SEP}${BT}/trip status${BT}" "$WORK/GK2b/CLAUDE.md"'
ctl GK3  K3 "a command carrying both a verbless and a verbed ADDRESSED cell"   dblcover  ok  'grep -qF "| ex | ${BT}/trip${BT} |" "$WORK/GK3/CLAUDE.md"'
# GK3b drives K3's FIRST limb alone — the accidental double cover — on a tree that also
# carries a declared set. GK3 above reaches limbs 1 and 2 together, so neither arm on its
# own shows that the accident is still caught while the declared choice beside it is not.
ctl GK3b K3 "a second ADDRESSED cell for a unit already covered — the ACCIDENTAL double cover, still a finding on a tree that also carries a declared set" dblcover2 ok 'grep -qF "| X | sig | ${GRADE_RETAIN}${GRADE_SEP}act | ex | ${BT}/trip status${BT} |" "$WORK/GK3b/CLAUDE.md"'
ctl GK4  K4 "an ambiguity-set member resolving to no coverage unit"            ambghost     ok 'grep -qF "${AMB_MARK}${BT}/trip status${BT}${AMB_SEP}${BT}/trip nosuchverb${BT}" "$WORK/GK4/CLAUDE.md"'
ctl GK4b K4 "an ambiguity-set member naming a WHOLE COMMAND, which covers more than one unit — a command is itself a choice" ambwholecmd ok 'grep -qF "${AMB_MARK}${BT}/trip${BT}${AMB_SEP}${BT}/trip-publish list${BT}" "$WORK/GK4b/CLAUDE.md"'
ctl GK5  K5 "one declared set naming the same coverage unit twice"             ambdup       ok 'grep -qF "${AMB_MARK}${BT}/trip status${BT}${AMB_SEP}${BT}/trip status${BT}" "$WORK/GK5/CLAUDE.md"'
# Members REORDERED against the conforming set, so a passing arm proves the comparison is
# over SETS rather than over strings — order is not graded, membership is.
ctl GK5b K5 "two declared sets denoting the same units, members reordered"     ambsame      ok 'grep -qF "${AMB_MARK}${BT}/trip-publish list${BT}${AMB_SEP}${BT}/trip status${BT}" "$WORK/GK5b/CLAUDE.md"'
# ── The DISPOSITION-MEMBER arms. B8's charter is crisp: every predicate below is one that
# could not fire before this change. A new id rather than more sites under B6, because group
# Y arms by ID and not by SITE — a sub-predicate added under an existing id can ship unarmed
# beneath a green Y2, which is the hole GZV was written to close. A new id forces Y1 and Y2
# to demand a registration and an arm on the same commit.
#
# GB6d is deliberately a B6 and not a B8: a member missing the marker's colon is not a
# disposition member whose reason is wrong, it is a member of NEITHER kind — the id follows
# which question the member failed, not which feature introduced it.
#
# Read every one of these with G0j and GK5e, the must-NOT-fire pair: without them these arms
# would only show the guard refusing things, which is the half a hard-wired red also passes.
ctl GB8  B8 "a disposition member whose reason is outside the closed five-value enum"        dispoffenum   ok 'grep -qF "${AMB_MARK}${DISP_MARK}because I said so" "$WORK/GB8/CLAUDE.md"'
ctl GB8b B8 "a disposition member CONJOINING two enum reasons — independent grounds on a row, but not one distinguishable option in a choice" dispconj ok 'grep -qF "${AMB_MARK}${DISP_MARK}repo-creation + argv-secret" "$WORK/GB8b/CLAUDE.md"'
ctl GB8c B8 "a set whose members are ALL dispositions — a row that routes to no command is an exclusion with prose, not a choice" dispnounit ok 'grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${DISP_MARK}repo-creation" "$WORK/GB8c/CLAUDE.md"'
ctl GB6d B6 "a member spelling the exclusion marker WITHOUT its colon — neither a cell under the grammar nor a declared disposition, so it stays B6 and never reaches the reason grading" dispbadmarker ok 'grep -qF "${AMB_MARK}EXCLUDED lightest-weight-action" "$WORK/GB6d/CLAUDE.md"'
ctl GK5c K5 "one declared set naming the SAME disposition twice — limb 1 over the disposition kind, the analogue of GK5 over the unit kind" dispdup ok 'grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${DISP_MARK}lightest-weight-action" "$WORK/GK5c/CLAUDE.md"'
ctl GK5d K5 "two declared sets denoting the same options INCLUDING the same disposition, members reordered — limb 2 still fires when the disposition matches too" dispsame ok 'grep -qF "${AMB_MARK}${BT}/trip-publish update${BT}${AMB_SEP}${DISP_MARK}lightest-weight-action${AMB_SEP}${BT}/trip-record profile${BT}" "$WORK/GK5d/CLAUDE.md"'
# GK2c is GK2b with a disposition member standing beside the unit members. It is the arm that
# proves the widening did not open a totality hole: the one shape by which a disposition could
# have satisfied K2 is a disposition standing in for the missing ADDRESSED cell, and this world
# builds exactly that and requires it to stay a K2.
ctl GK2c K2 "a verb reachable ONLY as a unit member of a set that ALSO carries a disposition member — admitting the disposition did not make set membership satisfy totality" dispambuncovered ok 'grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${BT}/trip check${BT}${AMB_SEP}${BT}/trip status${BT}" "$WORK/GK2c/CLAUDE.md"'

# ── GK5e — the arm that fails against the NAIVE implementation, and the only must-NOT-fire
# arm on the K5 widening. Its world carries a set whose UNIT members are identical to the
# conforming disposition set's and whose DISPOSITION member differs. Drop disposition members
# from K5's set identity — the obvious implementation, and the one a reader who took K4 as the
# model would write — and the two compare equal, limb 2 emits a spurious K5, and this arm goes
# red while every must-fire arm above still passes. That is the whole of its job.
#
# It is NOT a ctl arm: ctl's contract is MUST-FIRE. It is written in GPV's shape rather than
# GB7b's — fixture integrity folded into the same verdict rather than asserted beside it — so
# it contributes exactly one PASS/FAIL site, and a world that was never built reports as a
# fixture failure rather than as a quiet green.
GK5E="$WORK/GK5e"; gen_tree "$GK5E" dispdiff ok
arm K5
GK5E_OUT=""; GK5E_HITS=""
if ! grep -qF "${AMB_MARK}${DISP_MARK}repo-creation${AMB_SEP}${BT}/trip-record profile${BT}${AMB_SEP}${BT}/trip-publish update${BT}" "$GK5E/CLAUDE.md" \
   || ! grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${BT}/trip-record profile${BT}${AMB_SEP}${BT}/trip-publish update${BT}" "$GK5E/CLAUDE.md"; then
  FAIL "GK5e: fixture integrity — the world must carry BOTH sets, same two unit members and DIFFERENT dispositions; one of them is absent, so a zero here would prove nothing"
else
  GK5E_OUT="$(run_tree "$GK5E")"
  GK5E_HITS="$(printf '%s\n' "$GK5E_OUT" | grep '^FINDING K5 ' | head -3 | tr '\n' ' ')"
  if [ -z "$GK5E_HITS" ]; then
    PASS "GK5e: MUST-NOT-FIRE — two sets sharing both unit members and differing ONLY in their disposition member are TWO sets, and no K5 is emitted over $(getcount "$GK5E_OUT" DISPMEMBERS) live disposition member(s) in that world. The zero is a measurement: GK5d is the sensitivity arm on the same limb, over the same fixture shape with the disposition MATCHING, and fires on the same run. This arm is what makes the K5 quantifier widening evidence rather than an argument — an implementation that omits disposition members from the set identity emits a spurious K5 here while passing every must-fire arm above"
  else
    FAIL "GK5e: a SPURIOUS K5 — two sets differing only in their disposition member compared EQUAL, so disposition members are missing from K5's set identity: ${GK5E_HITS}"
  fi
fi
# GB7b is not a ctl arm: ctl's contract is MUST-FIRE, and what this asserts is an ABSENCE
# together with the shapes that absence has to survive. It is written in the remediated polarity
# — the PASS on the `then` limb — so it does not join group MD's declared residual, and it states
# its denominator because a zero over an unbuilt world proves nothing.
GB7B="$WORK/GB7b"; gen_tree "$GB7B" b7excl ok
arm B7
GB7B_S=1
grep -qF "| X | sig | ${GRADE_ADMIT}${GRADE_SEP}act | ex | EXCLUDED: lightest-weight-action |" "$GB7B/CLAUDE.md" || GB7B_S=0
grep -qF "| X | sig | act | ex | EXCLUDED: lightest-weight-action |" "$GB7B/CLAUDE.md" || GB7B_S=0
grep -qF "| X | sig | ${GRADE_RETAIN}${GRADE_SEP}act | ex | ${AMB_MARK}${BT}/trip check${BT}${AMB_SEP}${BT}/trip-record log${BT} |" "$GB7B/CLAUDE.md" || GB7B_S=0
if [ "$GB7B_S" -eq 1 ]; then
  PASS "GB7ba: fixture integrity — the world carries a MARKED excluded row, an UNMARKED excluded row and a MARKED ambiguity set, so GB7bb grades all three shapes rather than one"
  GB7B_OUT="$(run_tree "$GB7B")"
  GB7B_ADDR="$(getcount "$GB7B_OUT" S1_ADDR)"; GB7B_GRD="$(getcount "$GB7B_OUT" S1_GRADED)"
  GB7B_HITS="$(printf '%s\n' "$GB7B_OUT" | grep '^FINDING B7 ' | head -3 | tr '\n' ' ')"
  if [ -z "$GB7B_HITS" ]; then
    PASS "GB7bb: MUST-NOT-FIRE — B7's quantifier is the ADDRESSED class and nothing else: over a world carrying ${GB7B_ADDR} ADDRESSED row(s), all ${GB7B_GRD} graded, plus an EXCLUDED row and an ambiguity set that CARRY a marker and an EXCLUDED row that does not, no B7 is emitted. The zero is a measurement and not an empty scan — GB7 is the sensitivity arm on the same predicate and fires on the same run"
  else
    FAIL "GB7bb: a NON-ADDRESSED row was graded for its entry class — B7 is quantifying over rows it must not reach, or objecting to a marker where no class is owed: ${GB7B_HITS}"
  fi
else
  FAIL "GB7ba: fixture integrity — the specificity world was not constructed, so GB7bb's zero would prove nothing"
fi
ctl GS1  S1 "a key present in Step 1 and absent from Step 2"                   step2drift ok '[ "$(grep -c "trip-record log" "$WORK/GS1/CLAUDE.md")" = "1" ]'
ctl GS1b S1 "the same divergence in the OTHER direction — present in Step 2, absent from Step 1" step1drift ok '[ "$(grep -c "trip-record log" "$WORK/GS1b/CLAUDE.md")" = "1" ]'
ctl GS2  S2 "only ONE enumeration derivable — SINGLE-SOURCE, not agreement"    nostep2   ok  '! grep -q "^### Step 2:" "$WORK/GS2/CLAUDE.md"'
ctl GF1  F1 "a verb region invoking the EXCLUDED form rotate"                  ok        rotate      'grep -qF "publish-trip-site.sh rotate" "$WORK/GF1/skills/trip-publish/SKILL.md"'
ctl GF2  F2 "an unpublish invocation lacking the pages-only flag"              ok        nounpubflag 'grep -qF "unpublish trips/x" "$WORK/GF2/skills/trip-publish/SKILL.md"'
ctl GF3  F3 "a forbidden flag passed on a publish-script invocation"           ok        badflag     'grep -qF -- "--passphrase secret" "$WORK/GF3/skills/trip-publish/SKILL.md"'
ctl GF4  F4 "a command file that SETS the plaintext override, not merely names it" ok    allowplain  'grep -qF "ALLOW_PLAINTEXT=1" "$WORK/GF4/skills/trip/SKILL.md"'
ctl GF5  F5 "a script mention reached through a variable — unresolved, not silently clean" ok varmention 'grep -q "^SCRIPT=scripts" "$WORK/GF5/skills/trip/SKILL.md"'
ctl GF6  F6 "a fenced invocation in no verb region — a finding that could name only a FILE" ok orphaninv 'grep -q "^## Not a verb$" "$WORK/GF6/skills/trip/SKILL.md"'
# ── The two arms that bound the engine-root admission, in both directions. Without the first,
# the admission could have been implemented as "skip a rooted line" and every privilege finding
# on a rooted invocation would have gone silent under a green suite. Without the second, it
# could have been implemented as "accept any variable" and F5 would have stopped meaning
# anything. Each is a MUST-FIRE arm on an id this guard already emits, so neither adds a finding
# id and group Y's mapping is unchanged.
ctl GF1r F1 "a SANCTIONED-root invocation of the EXCLUDED form rotate — rooting a path does not retire the privilege grading over it" ok rootrotate 'grep -qF "CLAUDE_SKILL_DIR}/../../scripts/publish-trip-site.sh rotate trips/x" "$WORK/GF1r/skills/trip-publish/SKILL.md"'
# ── The P-group arms. Each defects the FRONTMATTER, which is the surface group P reads and
# which parse_command_file reads nothing of — the same blind spot the H-group arms below were
# written for. All three are MUST-FIRE, and group Y asserts the mapping in both directions, so
# a P id added without an arm here reddens the inventory rather than shipping ungraded.
ctl GP1  P1 "a grant pattern left on a bare path — it follows the invoking working directory" ok baregrant 'grep -q "^allowed-tools: Bash(ls:\*), Bash(scripts/" "$WORK/GP1/skills/trip/SKILL.md"'
ctl GP2  P2 "a ROOTED permit beside a BARE prohibition — the escalation shape: the permit resolves and the prohibition matches nothing" ok mixgrant 'grep -q "^disallowed-tools: \[Bash(scripts/" "$WORK/GP2/skills/trip/SKILL.md"'
ctl GP3  P3 "one verb permits a subcommand the others neither permit nor deny — the universe grew and the obligation did not" ok extrasub 'grep -qF "publish-trip-site.sh rotate:*)" "$WORK/GP3/skills/trip-publish/SKILL.md"'

# ── GPV — the VACUITY arm on group P's OWN population, and it is not a ctl arm because what it
# asserts is the absence of a finding TOGETHER WITH a zero population, which ctl's must-fire
# contract cannot express.
#
# Measured: over an empty verb root parity_check emits ZERO findings. So a group P written as
# `if has_finding …; then FAIL; else PASS` would read GREEN over zero verb files — which is the
# defect class this release has now met four times, a correct control whose population no longer
# contains the thing at risk. The verdicts in group P are gated on PFILES and PPAT for that
# reason, and this arm is what makes that gating a measurement rather than a convention: it
# proves the empty state is reachable, observable, and silent.
GPV_DIR="$WORK/GPV/skills"; mkdir -p "$GPV_DIR"
GPV_OUT="$(parity_check "$GPV_DIR")"
GPV_F="$(getcount "$GPV_OUT" PFILES)"; GPV_P="$(getcount "$GPV_OUT" PPAT)"
GPV_N="$(printf '%s\n' "$GPV_OUT" | grep -c '^FINDING ')"
if [ ! -d "$GPV_DIR" ] || [ -n "$(ls -A "$GPV_DIR" 2>/dev/null)" ]; then
  FAIL "GPVa: fixture integrity — the empty verb root was not constructed, so GPVb would prove nothing"
elif [ "${GPV_F:-1}" -eq 0 ] && [ "${GPV_P:-1}" -eq 0 ] && [ "${GPV_N:-1}" -eq 0 ]; then
  PASS "GPVb: VACUITY REACHABLE — over an empty verb root parity_check emits ${GPV_N} finding(s) and reports PFILES ${GPV_F} / PPAT ${GPV_P}. A finding-absence reading of group P would be GREEN on exactly this state; the count-gated verdicts are what make it RED"
else
  FAIL "GPVb: over an empty verb root parity_check reported PFILES ${GPV_F:-?} / PPAT ${GPV_P:-?} and ${GPV_N:-?} finding(s) — group P's vacuity gating rests on all three being zero, and one of them is not"
fi
ctl GF5r F5 "a fenced invocation rooted through a DIFFERENT variable — the admission is ONE literal, not the class of rooted-looking paths" ok wrongroot 'grep -qF "ZZ_OTHER_ROOT}/scripts/publish-trip-site.sh update trips/x" "$WORK/GF5r/skills/trip-publish/SKILL.md"'
# ── H-group arms. The first three defect the FRONTMATTER, which parse_command_file reads
# nothing of — which is exactly why this class went undetected until group H existed. The
# last two defect the DOCUMENT while leaving the command files correct, so the divergence
# is in the direction H5 is aimed at.
ctl GH1  H1 "a RESOLVE-role command file declaring no argument-hint"           ok        nohint     '! grep -q "^argument-hint:" "$WORK/GH1/skills/trip/SKILL.md"'
ctl GH2  H2 "a hint naming a token the file declares no verb for"              ok        hintghost  'grep -q "^argument-hint:.*ghostverb" "$WORK/GH2/skills/trip/SKILL.md"'
ctl GH3  H3 "a hint omitting a declared verb with no reference in the description" ok    hintshort  '[ "$(sed -n "s/^argument-hint: //p" "$WORK/GH3/skills/trip/SKILL.md")" = "status" ]'
ctl GH4  H4 "an absent command reference — a FAIL, not a vacuous pass"         ok        nodoc      '[ ! -f "$WORK/GH4/reference/command-reference.md" ]'
ctl GH5  H5 "a derived region that disagrees with the live requirement tables" ok        docdrift   'grep -q "^| .*| ARCHIVED |" "$WORK/GH5/reference/command-reference.md"'

# ── X-group: the key channel, driven with a synthetic record stream. Feeding the
# consumer directly is what makes these ids reachable without a debug backdoor and
# without a fixture that could not occur on a real surface.
arm X1
XS1="FILE /a
DECL /a plan
KEY /a:plann
ADDRPARTS /a plan"
if grep -q '^KEY /a:plann$' <<<"$XS1"; then
  PASS "GX1a: fixture integrity — the synthetic record stream carries a key that disagrees with its declaration"
  if grep -q '^FINDING X1 ' <<<"$(coverage_check "$XS1")"; then
    PASS "GX1b: flagged, naming X1 — an emitted key that did not round-trip byte-identical is caught even though the COUNT of keys is unchanged"
  else FAIL "GX1b: a key whose VALUE changed in transport was NOT flagged"; fi
else FAIL "GX1a: fixture integrity — the synthetic stream was not built; GX1b would prove nothing"; fi

arm X2
XS2="FILE /a
DECL /a plan
KEY /a:two words
ADDRPARTS /a plan"
if grep -q '^KEY /a:two words$' <<<"$XS2"; then
  PASS "GX2a: fixture integrity — the synthetic record stream carries a whitespace-bearing key"
  if grep -q '^FINDING X2 ' <<<"$(coverage_check "$XS2")"; then
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
  if grep -q "^FINDING $want " <<<"$out"; then PASS "${id}b: flagged, naming $want — $label"
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
  if grep -q '^FINDING E5 ' <<<"$(adr4_check "$GE5/ADR.md" "$GE5/pub.sh" "$GEREC")"; then
    PASS "GE5b: flagged, naming E5 — an unreadable publish script makes the sentinel unable to run, which is a failure and not a skip"
  else FAIL "GE5b: an unreadable publish script did NOT fail the sentinel"; fi
else FAIL "GE5a: fixture integrity — a script exists where none should; GE5b would prove nothing"; fi

# ── R-group arms.
arm R1
if grep -q '^INV /trip-publish update ' <<<"$GEREC"; then
  PASS "GR1a: fixture integrity — a fixture verb region carries a fenced invocation line"
  if grep -q '^FINDING R1 ' <<<"$(readonly_check "$GEREC" '/trip-publish:update' -- status check)"; then
    PASS "GR1b: flagged, naming R1 — a declared read-only key whose region carries an executable instruction. Non-vacuous: regions that DO carry one exist, so the assertion has something to catch"
  else FAIL "GR1b: an executable instruction in a declared read-only region was NOT flagged"; fi
else FAIL "GR1a: fixture integrity — no fixture region carries an invocation; GR1b would prove nothing"; fi

arm R2
if grep -q '^FINDING R2 ' <<<"$(readonly_check "$RECS" "${READONLY_KEYS[@]}" -- status check nosuchverb)"; then
  PASS "GR2: flagged, naming R2 — the MEMBERSHIP-DELTA SENTINEL fires on a set difference in either direction, and the message names the required action. Diffed as a SET: a verb removed and another added holds the count while membership churns"
else FAIL "GR2: the membership-delta sentinel did not fire on a deliberate set difference"; fi

# ═════════════════════════════════════════════════════════════════════════════════
# C-group and L-group arms — the inference-line join, the confirm obligation, the carrier.
#
# These drive inference_check DIRECTLY rather than through run_tree, and that is deliberate
# rather than incidental: run_tree is the input to some fifty existing arms, and adding a new
# checker to it would put this group's findings into every one of their outputs. The arms below
# build the same fixture trees and call the one function they grade.
#
# EVERY MUST-FIRE ARM IS PAIRED WITH A MUST-NOT-FIRE ONE over a world differing in exactly the
# graded property. A group of must-fire arms alone is satisfied by a checker hard-wired to
# report a finding, which is the failure mode this card exists to retire.
# ═════════════════════════════════════════════════════════════════════════════════
cfix() {  # cfix <id> <charter-defect> <cmd-defect> <carrier-defect> -> prints the finding stream
  local d="$WORK/$1"; gen_tree "$d" "$2" "$3"; gen_carrier "$d/SKILL.md" "$4"
  inference_check "$(collect_records "$d")" "$d/SKILL.md"
}
cctl() {  # cctl <id> <want> <label> <charter-defect> <cmd-defect> <carrier-defect>
  local id="$1" want="$2" label="$3"; shift 3
  arm "$want"
  local out; out="$(cfix "$id" "$1" "$2" "$3")"
  if grep -q "^FINDING $want " <<<"$out"; then PASS "${id}: flagged, naming $want — $label"
  else FAIL "${id}: the deliberate defect was NOT flagged as $want ($label). First finding, if any: $(printf '%s' "$out" | grep '^FINDING ' | head -1)"; fi
}

echo
echo "── Group GC/GL — control arms for the inference line, the confirm obligation and the carrier."

# The CONFORMING world, built once and read by every must-NOT-fire arm below. Marker and source
# agree on every unit, every retained arm carries the confirm limb, every unit has a read
# declaration, and the carrier names no verb. A finding of ANY C or L id here is a false positive.
GCOK="$(cfix GCok ok ok ok)"
if grep -q '^FINDING ' <<<"$GCOK"; then
  FAIL "GC0b: the CONFORMING world produced a finding — every must-not-fire arm below is reading a world that is already defective, so none of them establishes specificity: $(printf '%s' "$GCOK" | grep '^FINDING ' | head -2)"
elif [ -z "$(getcount "$GCOK" CBLOCKS)" ]; then
  FAIL "GC0b: NO SUBJECT — the conforming world produced no population count, so inference_check did not run over it"
else
  PASS "GC0b: MUST-NOT-FIRE — the conforming world yields no C or L finding at all, over $(getcount "$GCOK" CBLOCKS) arms and $(getcount "$GCOK" CUNITS) coverage units, with $(getcount "$GCOK" CADMIT) admitted at BOTH marker and source. Read every must-fire arm below against this one"
fi

# ── C0 — the population and its arms.
cctl GC0 C0 "a world whose every region carries no read declaration — the population the side function quantifies over is EMPTY, which is a failure and not a vacuous pass" ok c0empty ok
arm C0
if [ -z "$(getcount "$GCOK" CSENS)" ] || [ -z "$(getcount "$GCOK" CNOEFF)" ]; then FAIL "GC0c: NO SUBJECT — the conforming world reported no sensitivity or no-effect result"
elif [ "$(getcount "$GCOK" CSENS)" -ne 7 ] || [ "$(getcount "$GCOK" CSPEC)" -ne 0 ] || [ "$(getcount "$GCOK" CNOEFF)" -ne 6 ]; then
  FAIL "GC0c: the recogniser's own arms did not all fire — sensitivity $(getcount "$GCOK" CSENS) of 7 (must be 7), specificity $(getcount "$GCOK" CSPEC) of 7 (must be 0), and no-effect $(getcount "$GCOK" CNOEFF) of 7 (must be 6)"
else PASS "GC0c: the three-negative recogniser is a MEASUREMENT — it derived 7 of 7 on a block declaring all three; 0 of 7 on a block declaring the positive of each beside a word carrying a negative only as its suffix; and 6 of 7 on a block declaring writes-nothing and dispatches-no-agent beside runs-no-script with no effect clause, in this process. A recogniser that matched neither, or both, would report the same admitted set and mean nothing; one reading runs-no-script as the effect predicate would ADMIT the third block, and one without a token boundary would read the second's suffix as a negative"; fi

# ── C4 — totality.
cctl GC4 C4 "a coverage unit whose region carries no read declaration while every other does — the side function is UNDEFINED on it, so it resolves to neither side" ok c4nosrc ok

# ── C1 — THE JOIN, armed in BOTH directions. One direction alone would leave the other's
# half of the comparison deletable beneath a green suite.
cctl GC1 C1 "a unit the routing map marks INFERENCE-ADMITTED whose own block declares NONE of the three negatives — the marker asserts a property nobody declared" ok c1undeclared ok
cctl GC1c C1 "the OPPOSITE direction — a unit whose block declares all three while the routing map still marks it DECLARED-INTENT. The set difference must be empty both ways, and this is the way the first arm cannot reach" ok c1source ok
arm C1
if grep -q '^FINDING C1 ' <<<"$GCOK"; then FAIL "GC1b: MUST-NOT-FIRE — the join fired on a world where marker and source agree on every unit"
elif [ -z "$(getcount "$GCOK" CJ1)" ]; then FAIL "GC1b: NO SUBJECT — the conforming world emitted no join difference counts"
else PASS "GC1b: MUST-NOT-FIRE — the join is silent on the conforming world ($(getcount "$GCOK" CJ1) and $(getcount "$GCOK" CJ2) in the two directions), so GC1 and GC1c above grade a disagreement rather than a checker that always fires"; fi

# ── C6 — SET COMPOSITION, armed as a PAIR over two worlds differing in exactly one member.
# The must-fire arm alone would be satisfied by a rule refusing any inference-admitted member
# inside a disposition-bearing set, which is a different and much wider rule than the one
# ADR-007 § 3 states; GC6b below is what separates the two.
cctl GC6 C6 "a declared set carrying a disposition member whose unit members are ALL inference-admitted — the composition whose own membership reads admitted while the fail-closed rule retains it, and the shape that was authorable with this entire suite green" dispalladmit ok ok
GC6B="$WORK/GC6b"; gen_tree "$GC6B" dispmixed ok; gen_carrier "$GC6B/SKILL.md" ok
arm C6
GC6B_OUT=""; GC6B_HITS=""
if ! grep -qF "${AMB_MARK}${DISP_MARK}lightest-weight-action${AMB_SEP}${BT}${FIXTURE_ADMIT_KEY}${BT}${AMB_SEP}${BT}/trip-record log${BT}" "$GC6B/CLAUDE.md"; then
  FAIL "GC6b: fixture integrity — the near-miss world must carry the disposition member, the ADMITTED unit member and a RETAINED unit member beside it; that set is absent, so a zero here would prove nothing"
else
  GC6B_OUT="$(inference_check "$(collect_records "$GC6B")" "$GC6B/SKILL.md")"
  GC6B_HITS="$(printf '%s\n' "$GC6B_OUT" | grep '^FINDING C6 ' | head -3 | tr '\n' ' ')"
  if [ -z "$GC6B_HITS" ]; then
    PASS "GC6b: MUST-NOT-FIRE — a disposition-bearing set naming ${FIXTURE_ADMIT_KEY} (admitted) BESIDE a unit member that retains declared intent yields no C6, over $(getcount "$GC6B_OUT" CDISPSETS) disposition-bearing set(s) in that world. The zero is a measurement, not an absence: GC6 is the sensitivity arm on the same predicate over the same world MINUS the retained member, and it fires on this run. This arm is what makes C6 a composition rule rather than a ban on an inference-admitted member appearing in such a set at all"
  else
    FAIL "GC6b: a SPURIOUS C6 — a set that already names a unit member retaining declared intent was refused, so the predicate is reading the PRESENCE of an admitted member rather than the ABSENCE of a retained one: ${GC6B_HITS}"
  fi
fi

# ── C2 / C3 — the confirm obligation and the per-limb report.
cctl GC2 C2 "a retained arm whose region carries no confirm gate and whose file carries neither half of the typed-only posture — it stands behind nothing" ok noconfirm ok
arm C2
if grep -q '^FINDING C2 ' <<<"$GCOK"; then FAIL "GC2b: MUST-NOT-FIRE — the confirm obligation fired on a world where every retained arm carries the gate"
elif [ -z "$(getcount "$GCOK" CLIMBNONE)" ]; then FAIL "GC2b: NO SUBJECT — the conforming world emitted no limb counts"
else PASS "GC2b: MUST-NOT-FIRE — the same world as GC2 with the confirm gate PRESENT yields no C2, so the arm above grades the gate's absence rather than the fixture"; fi

GCNC="$(cfix GCnc ok noconfirm ok)"
if [ -z "$(getcount "$GCOK" CLIMBCONF)" ] || [ -z "$(getcount "$GCNC" CLIMBCONF)" ]; then
  FAIL "GC3: NO SUBJECT — one of the two worlds emitted no confirm-limb count"
elif [ "$(getcount "$GCOK" CLIMBCONF)" -le 0 ]; then
  FAIL "GC3: the confirm limb read ZERO on a world where every retained arm carries the gate — the limb is not reading what it claims to read, and C3's report is a constant rather than a measurement"
elif [ "$(getcount "$GCNC" CLIMBCONF)" -ne 0 ]; then
  FAIL "GC3: the confirm limb read $(getcount "$GCNC" CLIMBCONF) on a world carrying NO confirm gate — it is counting something other than the gate"
else
  PASS "GC3: the per-limb report is a MEASUREMENT — the confirm limb reads $(getcount "$GCOK" CLIMBCONF) on a world where every retained arm carries the gate and 0 on the same world with it stripped. A limb hardcoded to either value fails one of those two"
fi

# ── The OFF-PATH shape, which is how two live arms were counted as gated when neither is. Every
# retained arm in this world only MENTIONS the confirmation: inside its read block, by a sentence
# placing the confirmation before its path; and outside the block, by a sentence shaped exactly
# like a declaration. A limb reading the region counts both, a limb matching the bare phrase inside
# the block counts the first, and a limb matching the declaration form across the region counts the
# second — only a limb reading the DECLARATION inside the BLOCK counts neither. GC2c is the
# obligation's side of it and GC3b the report's.
cctl GC2c C2 "a retained arm whose only confirm text is OFF its path — a sentence in its read block placing the confirmation before the path, and a gate-shaped sentence outside the block — stands behind nothing" ok confirmoffpath ok
GCOP="$(cfix GCop ok confirmoffpath ok)"
GCOP_S=1
grep -qF 'It returns before the typed confirmation, so nothing on this path is gated by it.' "$WORK/GCop/skills/trip/SKILL.md" || GCOP_S=0
grep -qF 'Destructive work in this region stands behind a typed confirmation.' "$WORK/GCop/skills/trip/SKILL.md" || GCOP_S=0
if [ "$GCOP_S" -eq 0 ]; then
  FAIL "GC3b: fixture integrity — the off-path world must carry BOTH the in-block mention and the out-of-block gate-shaped sentence; one is absent, so a zero here would prove nothing"
elif [ -z "$(getcount "$GCOP" CLIMBCONF)" ]; then
  FAIL "GC3b: NO SUBJECT — the off-path world emitted no confirm-limb count"
elif [ "$(getcount "$GCOP" CLIMBCONF)" -eq 0 ]; then
  PASS "GC3b: MUST-NOT-COUNT — over a world where every retained arm only MENTIONS the typed confirmation, in its block and beside it, the confirm limb reads 0 of $(getcount "$GCOP" CRETAIN). GC3 is the sensitivity arm on the same limb and reads $(getcount "$GCOK" CLIMBCONF) on the declaring world, so this zero is the limb telling a declaration from a mention"
else
  FAIL "GC3b: the confirm limb counted $(getcount "$GCOP" CLIMBCONF) arm(s) as gated in a world where the confirmation is only mentioned — it is reading a mention as a gate, which is the over-count this limb was narrowed to end"
fi

# ── The WIDENED CLASS, armed per shape rather than per list. GC3 and GC3b above exercise the
# limb end-to-end through a built world, and they do it on ONE shape — the typed confirmation the
# fixture generator emits. A list of four that is only ever exercised on its first member is a
# list whose other three are unmeasured: a typo in the fourth alternative, or an alternative whose
# token boundary does not hold, reads green on every run and silently drops that arm to the
# typed-only limb. So the two arms below walk CONFIRM_SHAPES itself and grade the recogniser
# directly, once per member, in the same normalisation the limb applies.
#
# They are two halves of one discrimination and neither stands alone. GC3c is SENSITIVITY: every
# shape, behind the stem, is admitted — it fails if any member is unreachable. GC3d is
# SPECIFICITY: every shape WITHOUT the stem, in the live off-path sentence shape, is refused, and
# so is the stem carrying a shape the list does not hold. That second arm is what keeps the
# widening from becoming the mention-counting defect D-40 removed, re-armed once per shape: a
# limb loosened to match a bare shape name passes GC3c unchanged and fails GC3d on all four.
GC3C_N=0; GC3C_MISS=''; GC3D_N=0; GC3D_FIRED=''
for gcs in "${CONFIRM_SHAPES[@]}"; do
  gcp="$(neg_norm "Its destructive work stands behind ${gcs}, stated in full below.")"
  if [[ "$gcp" =~ $CONFIRM_DECL_RE ]]; then GC3C_N=$((GC3C_N+1)); else GC3C_MISS="$GC3C_MISS${gcs}; "; fi
  gcp="$(neg_norm "It returns before ${gcs}, so nothing on this path is gated by it.")"
  if [[ "$gcp" =~ $CONFIRM_DECL_RE ]]; then GC3D_N=$((GC3D_N+1)); GC3D_FIRED="$GC3D_FIRED${gcs}; "; fi
done
GC3D_UNLISTED="$(neg_norm 'Its destructive work stands behind a verbal nod from the operator, stated in full below.')"
[[ "$GC3D_UNLISTED" =~ $CONFIRM_DECL_RE ]] && GC3D_FIRED="${GC3D_FIRED}a shape the list does not hold; "
if [ "${#CONFIRM_SHAPES[@]}" -eq 0 ]; then
  FAIL "GC3c: NO SUBJECT — the credited-shape list is empty, so the confirm limb can never fire and both arms here prove nothing"
elif [ "$GC3C_N" -ne "${#CONFIRM_SHAPES[@]}" ]; then
  FAIL "GC3c: MUST-FIRE — ${GC3C_N} of ${#CONFIRM_SHAPES[@]} credited shape(s) are admitted behind the declaration stem; unreachable: ${GC3C_MISS%; }. An alternative the recogniser cannot match drops its arm to the typed-only limb silently"
else
  PASS "GC3c: MUST-FIRE, PER SHAPE — all ${GC3C_N} of ${#CONFIRM_SHAPES[@]} credited shape(s) are admitted behind the declaration stem, each walked from the same list the pattern is built from. A shape added to that list and not reachable by the pattern fails here rather than reading green"
fi
if [ -n "$GC3D_FIRED" ]; then
  FAIL "GC3d: MUST-NOT-FIRE — the recogniser admitted ${GC3D_N} shape(s) stated as a MENTION rather than a declaration, and/or a stem carrying an unlisted shape: ${GC3D_FIRED%; }. The class is open, which is the mention-counting the limb was narrowed to end"
else
  PASS "GC3d: MUST-NOT-FIRE, PER SHAPE — none of the ${#CONFIRM_SHAPES[@]} credited shape(s) is admitted when the sentence places it BEFORE the path instead of behind it, and the declaration stem carrying a shape the list does not hold is refused too. GC3c is the sensitivity arm over the identical list and admits all ${GC3C_N}, so this zero is the widened class staying closed and staying a declaration"
fi

# ── C5 — the standing confirm rule's presence, both failure shapes. GC0b above is the
# must-NOT-fire half: every conforming fixture file states the fixture's own rule, alike.
cctl GC5  C5 "a verb file carrying no statement of the standing confirm rule while the others state it — presence is graded file by file" ok norule ok
cctl GC5b C5 "a verb file stating the rule in a DIFFERENT rendering from the rest — the comparand is read from the files themselves, so the divergent file is found with no copy of the rule held here" ok rulediff ok

# ── L — the carrier.
cctl GL1 L1 "a carrier naming a live verb token — the second enumeration of the verb set that the inverted dependency exists to remove" ok ok verbtoken
cctl GL2 L2 "a carrier carrying disable-model-invocation — the one key whose presence disables guided entry while every other assertion stays green" ok ok flag
cctl GL3 L3 "a carrier declaring none of the three negatives — the one surface here the model can see, silent on what it may do" ok ok noneg
arm L1
arm L2
arm L3
if grep -qE '^FINDING L[123] ' <<<"$GCOK"; then FAIL "GL1b: MUST-NOT-FIRE — a carrier assertion fired on a conforming carrier"
elif [ -z "$(getcount "$GCOK" LNEG)" ]; then FAIL "GL1b: NO SUBJECT — the conforming carrier was never read"
else PASS "GL1b: MUST-NOT-FIRE — a conforming carrier yields no L finding: it names $(getcount "$GCOK" LVERBS) verb tokens, carries no flag, and declares $(getcount "$GCOK" LNEG) of 7 negatives. The three arms above grade the defects rather than the surface"; fi

# ── I — the retired pre-execution carrier. Armed on BOTH surfaces the live check reads — a verb
# REGION and the CARRIER at the engine root — and paired with a must-NOT-fire world carrying the
# near-miss on both, the same two characters in the other order. Each arm is one verdict with its
# fixture-integrity probe folded in, so a world that was never built reports as a failure.
ifix() {  # ifix <id> <cmd-defect> <carrier-defect> -> the preexec_check stream over a built world
  local d="$WORK/$1"; gen_tree "$d" ok "$2"; gen_carrier "$d/SKILL.md" "$3"
  preexec_check "$d/skills"/*/SKILL.md "$d/SKILL.md"
}
arm I1
GI1_OUT="$(ifix GI1 preexec ok)"
if ! grep -q "^!${BT}ls -1 trips${BT}\$" "$WORK/GI1/skills/trip/SKILL.md"; then
  FAIL "GI1: fixture integrity — the planted line is absent from the fixture verb region, so a verdict here would prove nothing"
elif grep -q '^FINDING I1 .*GI1/skills/trip/SKILL\.md:' <<<"$GI1_OUT"; then
  PASS "GI1: flagged, naming I1 — a line opening with a bang and a backtick inside a fixture VERB REGION, the rendering the retired carrier used"
else
  FAIL "GI1: a pre-execution line planted in a fixture verb region was NOT flagged as I1"
fi
GI1B_OUT="$(ifix GI1b ok preexec)"
if ! grep -q "^!${BT}ls -1 trips${BT}\$" "$WORK/GI1b/SKILL.md"; then
  FAIL "GI1b: fixture integrity — the planted line is absent from the fixture carrier, so a verdict here would prove nothing"
elif grep -q '^FINDING I1 .*GI1b/SKILL\.md:' <<<"$GI1B_OUT"; then
  PASS "GI1b: flagged, naming I1 — the same line in the CARRIER at the engine root, which sits outside the verb directory every per-file glob here reads and is the one surface the model reaches unprompted"
else
  FAIL "GI1b: a pre-execution line planted in the fixture carrier was NOT flagged as I1"
fi
GI1C_OUT="$(ifix GI1c preexecnear preexecnear)"
GI1C_S=1
grep -qF "${BT}!ls -1 trips${BT}" "$WORK/GI1c/skills/trip/SKILL.md" || GI1C_S=0
grep -qF "${BT}!ls -1 trips${BT}" "$WORK/GI1c/SKILL.md" || GI1C_S=0
GI1C_N="$(getcount "$GI1C_OUT" PXLINES)"
if [ "$GI1C_S" -eq 0 ]; then
  FAIL "GI1c: fixture integrity — the near-miss is absent from the verb region or the carrier, so a zero here would prove nothing"
elif [ -z "$GI1C_N" ] || [ "$GI1C_N" -eq 0 ]; then
  FAIL "GI1c: NO SUBJECT — preexec_check scanned no line of the near-miss world"
elif [ "$(getcount "$GI1C_OUT" PXHITS)" = '0' ]; then
  PASS "GI1c: MUST-NOT-FIRE — a backtick then a bang, in a verb region and in the carrier, is not the pre-execution rendering and yields no I1 over ${GI1C_N} fence-depth-0 line(s) scanned. GI1 and GI1b are the sensitivity arms and fire on the same run, so I1 grades the ORDER of the two characters rather than either character's presence"
else
  FAIL "GI1c: the near-miss was flagged as I1 — the assertion is matching the characters rather than the line-opening rendering: $(printf '%s' "$GI1C_OUT" | grep '^FINDING I1 ' | head -2 | tr '\n' ' ')"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group GQ — control arms for the grant tables.
#
# Every world is rooted at $WORK, so no arm writes a tracked file and group Z grades that claim.
# The MUST-FIRE arms run on BUILT verb files, the house rule for fixtures: gq_gen_verb writes a
# frontmatter and a grant table that pair exactly, and each defect is a switch in the generator,
# never a patch over a generated file. The MUST-NOT-FIRE arm and the derivation arm run on a COPY
# of the live verb files, because what they assert is about the live tables themselves. Each arm
# renders ONE verdict with its fixture-integrity probe folded in, so a world that was never
# built reports as a failure rather than as a quiet green.
#
# The planted script name, zz-fixture.sh, exists nowhere in the repository, so the
# normalization is exercised on a script it has never met; its grant carries the sanctioned
# engine root, exactly as the live frontmatter does.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group GQ — control arms for the grant tables."

# A grant token nothing on any surface holds. GQ1 plants it in a GRANT cell and must fire; GQ0
# plants the same token in every USE cell, in prose and in a fenced example and must not. The
# pair differs in the one property the arm keys on — which column the token sits in.
GQ_UNHELD='Bash(zzq-unheld:*)'

# The add-only world carries GQ_FILL further grants, each with its own row, BEFORE the appended
# one, so a reader that samples the first N entries misses it for every N below GQ_FILL + 4.
# That is 36 — four and a half times the longest allowed-tools line any verb carries today (8).
# Its row-side twin appends a ROW with no grant after the same GQ_FILL paired rows, so a reader
# that samples the first N rows of a table misses that row for the same N (GQ9).
GQ_FILL=32

# gq_gen_verb <verb-root> <name> <defect> — one BUILT verb file. `ok` pairs three rows with three
# grants: a plain Bash grant, a bare tool, and a path-bearing script grant named by script and arm.
# Two denials sit beside them and have no row, so every world also shows that denials are not
# paired. The defects, one departure each:
#   extrarows   two rows no grant holds: the held script grant respelled under the bare path the
#               frontmatter does not carry, and the token nothing holds       -> Q1 only
#   droprow     the script grant's row removed                                  -> Q2 only
#   addgrant    GQ_FILL paired grants, then a bare tool appended at the END of allowed-tools with
#               no row, and nothing removed                                     -> Q2 only
#   celledit    one Grant cell edited in place, so rows and grants still count 3 and 3 -> Q1 and Q2
#   renamedhead the Use column renamed, so the header is not the key            -> Q0
#   swappedhead the two columns swapped, so `Grant` is not the first cell       -> Q0
#   pluralhead  the Grant column pluralized                                     -> Q0
#   nodelim     the key with no delimiter row beneath it                        -> Q0
#   toolhead    the Grant column renamed `Tool`: only the Use cell marks the row  -> Q0
#   usefirst    `Tool` and the Use cell, swapped: the Use cell alone, in column 1 -> Q0
#   colonhead   `Grant:` over a renamed Use column: the stem alone, punctuated    -> Q0
#   parenhead   `Grant(s)` over a renamed Use column: the stem alone, bracketed   -> Q0
#   stemlast    a renamed Use column, then `Grant`: the stem alone, in column 2   -> Q0
#   respaced    the key re-spaced, re-cased and trailed by whitespace, which is still the key -> nothing
#   crossverb   the Read grant and the Bash(ls:*) row both dropped, so beside an `ok` verb each is
#               held, or named, only by the OTHER verb                           -> Q1 and Q2
#   rootedrow   the script grant's row spelled as the full rooted token rather than by script
#               and arm                                                          -> nothing
#   wrapgrant   the allowed-tools value wrapped: a bare tool no row names on the indented line
#               after it                                                         -> Q0, Q2 withheld
#   addrow      GQ_FILL paired grants, then a row no grant holds appended AFTER their GQ_FILL rows,
#               as the last row of the table, and nothing removed                -> Q1 only
#   secondtable a second table headed by the key, after the first one's prose, holding one row no
#               grant holds                                                      -> Q1 only
#   unticked    a row no grant holds whose Grant cell is not a code span, right after the three
#               rows                                                             -> Q1 only
#   notable     no grant table: the three rows sit under a header naming neither form, so the verb
#               is read and graded by nothing                                    -> nothing
gq_gen_verb() {
  local d="$1/$2" name="$2" defect="${3:-ok}" k
  mkdir -p "$d"
  {
    printf -- '---\nname: %s\ndescription: grant-pairing fixture\n' "$name"
    if [ "$defect" = 'crossverb' ]; then
      printf -- 'allowed-tools: Bash(ls:*), Bash(%sscripts/zz-fixture.sh arm:*)' "$ENGINE_ROOT_TOK"
    else
      printf -- 'allowed-tools: Bash(ls:*), Read, Bash(%sscripts/zz-fixture.sh arm:*)' "$ENGINE_ROOT_TOK"
    fi
    case "$defect" in
      addgrant|addrow) for (( k=1; k<=GQ_FILL; k++ )); do printf -- ', Bash(zzq-fill-%d:*)' "$k"; done ;;
    esac
    if [ "$defect" = 'addgrant' ]; then printf -- ', Glob'; fi
    if [ "$defect" = 'wrapgrant' ]; then printf -- ',\n  Glob\n'; else printf -- '\n'; fi
    printf -- 'disallowed-tools: [Bash(%sscripts/zz-fixture.sh other:*), Write]\n' "$ENGINE_ROOT_TOK"
    printf -- '---\n\n# /%s\n\n' "$name"
    case "$defect" in
      renamedhead) printf -- '| Grant | What each grant is used for |\n|---|---|\n' ;;
      swappedhead) printf -- '| The use that holds it | Grant |\n|---|---|\n' ;;
      pluralhead)  printf -- '| Grants | The use that holds it |\n|---|---|\n' ;;
      toolhead)    printf -- '| Tool | The use that holds it |\n|---|---|\n' ;;
      usefirst)    printf -- '| The use that holds it | Tool |\n|---|---|\n' ;;
      colonhead)   printf -- '| Grant: | What it is for |\n|---|---|\n' ;;
      parenhead)   printf -- '| Grant(s) | What it is for |\n|---|---|\n' ;;
      stemlast)    printf -- '| Purpose | Grant |\n|---|---|\n' ;;
      nodelim)     printf -- '| Grant | The use that holds it |\n' ;;
      respaced)    printf -- '|grant|  The Use  That Holds It  |  \n| --- | :-- |\n' ;;
      notable)     printf -- '| Step | What it does |\n|---|---|\n' ;;
      *)           printf -- '| Grant | The use that holds it |\n|---|---|\n' ;;
    esac
    if [ "$defect" = 'celledit' ]; then printf -- '| %sBash(ls)%s | the listing |\n' "$BT" "$BT"
    elif [ "$defect" != 'crossverb' ]; then printf -- '| %sBash(ls:*)%s | the listing |\n' "$BT" "$BT"; fi
    printf -- '| %sRead%s | a read |\n' "$BT" "$BT"
    if [ "$defect" = 'rootedrow' ]; then
      printf -- '| %sBash(%sscripts/zz-fixture.sh arm:*)%s | the single invocation of that arm, spelled in full |\n' "$BT" "$ENGINE_ROOT_TOK" "$BT"
    elif [ "$defect" != 'droprow' ]; then
      printf -- '| %szz-fixture.sh arm%s | the single invocation of that arm |\n' "$BT" "$BT"
    fi
    if [ "$defect" = 'unticked' ]; then printf -- '| Glob | a row whose Grant cell is not a code span, and nothing holds it |\n'; fi
    case "$defect" in
      addgrant|addrow) for (( k=1; k<=GQ_FILL; k++ )); do printf -- '| %sBash(zzq-fill-%d:*)%s | a filler grant, held and named |\n' "$BT" "$k" "$BT"; done ;;
    esac
    if [ "$defect" = 'addrow' ]; then printf -- '| %sGlob%s | a row appended after the filler rows, and nothing holds it |\n' "$BT" "$BT"; fi
    if [ "$defect" = 'extrarows' ]; then
      printf -- '| %sBash(scripts/zz-fixture.sh arm:*)%s | a copy of a held grant under a path the frontmatter does not carry |\n' "$BT" "$BT"
      printf -- '| %s%s%s | a grant nothing holds |\n' "$BT" "$GQ_UNHELD" "$BT"
    fi
    printf -- '\nProse beneath the table.\n'
    if [ "$defect" = 'secondtable' ]; then
      printf -- '\n| Grant | The use that holds it |\n|---|---|\n| %sGlob%s | a row of a second grant table in this verb, and nothing holds it |\n' "$BT" "$BT"
      printf -- '\nProse beneath the second table.\n'
    fi
  } > "$d/SKILL.md"
}

# gq_world <id> <defect> [<extra-name> <extra-defect>]… — a verb root holding one conforming verb
# that carries no grant table beside the graded one, so the scanned population is never the
# graded population by accident.
gq_world() {
  local r="$WORK/$1/skills" defect="$2"; shift 2
  mkdir -p "$r/zz-untabled"
  printf -- '---\nname: zz-untabled\nallowed-tools: Read, Write\n---\n\n# /zz-untabled\n\nNo grant table here.\n' > "$r/zz-untabled/SKILL.md"
  gq_gen_verb "$r" zz-graded "$defect"
  while [ "$#" -ge 2 ]; do gq_gen_verb "$r" "$1" "$2"; shift 2; done
  printf '%s' "$r"
}

# ── GQ1..GQ5 — MUST-FIRE. Each names the verb and the unpaired entry, and each is ISOLATED: the
# direction its defect does not touch must stay silent, so an arm that fires both ids on a
# one-sided defect, or fires the wrong one, fails here rather than passing on "a finding appeared".
# `--only` before the entries asks for more: the run finds exactly one finding per entry named, and
# nothing else, so a reader that leaves any other entry or row of the world unpaired fails the arm.
gqctl() {  # gqctl <id> <defect> <want-ids> <silent-ids> [--only] <must-name…> -- <label>
  local id="$1" defect="$2" want="$3" silent="$4"; shift 4
  local -a NAMES=(); local label='' w s nm r out ok=1 why='' only=0 nfound
  if [ "${1:-}" = '--only' ]; then only=1; shift; fi
  while [ "$#" -gt 0 ]; do
    if [ "$1" = '--' ]; then shift; label="$*"; break; fi
    NAMES+=( "$1" ); shift
  done
  for w in $want; do arm "$w"; done
  r="$(gq_world "$id" "$defect")"
  if ! grep -q '^| Grant |' "$r/zz-graded/SKILL.md"; then
    FAIL "${id}: fixture integrity — the built verb carries no grant-table header, so a verdict here would prove nothing"; return 0
  fi
  out="$(grant_table_check "$r")"
  for w in $want; do
    grep -q "^FINDING $w /zz-graded" <<<"$out" || { ok=0; why="$why no $w naming /zz-graded;"; }
  done
  for s in $silent; do
    grep -q "^FINDING $s " <<<"$out" && { ok=0; why="$why $s fired on a defect it does not own;"; }
  done
  for nm in "${NAMES[@]+"${NAMES[@]}"}"; do
    grep -qF "\"$nm\"" <<<"$out" || { ok=0; why="$why the entry \"$nm\" is not named;"; }
  done
  grep -q '^FINDING [A-Z][0-9] /zz-untabled' <<<"$out" && { ok=0; why="$why the untabled verb was graded;"; }
  if [ "$only" -eq 1 ]; then
    nfound="$(grep -c '^FINDING ' <<<"$out")"
    [ "$nfound" = "${#NAMES[@]}" ] || { ok=0; why="$why ${nfound} finding(s) where exactly ${#NAMES[@]} may name the entr(ies) above and nothing else;"; }
  fi
  if [ "$ok" -eq 1 ]; then
    PASS "${id}: flagged, naming ${want} and the verb and the entry, with ${silent:-nothing} silent — ${label}"
  else
    FAIL "${id}: the deliberate defect was not flagged as specified (${label}):${why} First finding, if any: $(grep '^FINDING ' <<<"$out" | head -1)"
  fi
}

gqctl GQ1 extrarows Q1 Q2 "Bash(scripts/zz-fixture.sh arm:*)" "$GQ_UNHELD" -- "a ROW WITH NO MATCHING GRANT: the held script grant respelled under the bare path the frontmatter does not carry, which a normalization applied to both sides would pair in silence, and a grant nothing holds"
gqctl GQ2 droprow   Q2 Q1 "Bash(${ENGINE_ROOT_TOK}scripts/zz-fixture.sh arm:*)" "zz-fixture.sh arm" -- "a GRANT WITH NO ROW: the path-bearing grant's row removed, the finding naming the entry and the script-and-arm row that would pair it"
gqctl GQ3 addgrant  Q2 Q1 --only "Glob" -- "the ADD-ONLY mutation: a bare tool appended at the END of a $((GQ_FILL + 4))-entry allowed-tools line and nothing removed, which a reader of Bash tokens, of script grants, or of any fewer than $((GQ_FILL + 4)) leading entries does not see. Q2 names that entry and nothing else, because every other entry pairs with its row, so a reader that samples the first rows of the $((GQ_FILL + 3))-row table fails here as well"
gqctl GQ4 celledit  "Q1 Q2" "" "Bash(ls)" "Bash(ls:*)" -- "a Grant-column edit that leaves rows and grants at 3 and 3 — the accidental edit the guard lands ahead of, which a count comparison passes"
arm Q0
# The shapes, one BUILT verb each, and the exact header line each must carry. The last five
# isolate the recognizer's two limbs: `Tool` and `usefirst` carry the Use cell and no stem, in
# either column; `Grant:`, `Grant(s)` and `stemlast` carry the stem and no Use cell, in either
# column. So each limb, and each limb's ANY-COLUMN claim, is the only thing that can name its
# verb, and removing either limb, or pinning it to one column, leaves a verb unnamed here.
GQ5_V=( zz-graded zz-nodelim zz-swapped zz-plural zz-tool zz-usefirst zz-colon zz-paren zz-stemlast )
GQ5_H=( '| Grant | What each grant is used for |' '| Grant | The use that holds it |'
        '| The use that holds it | Grant |' '| Grants | The use that holds it |'
        '| Tool | The use that holds it |' '| The use that holds it | Tool |'
        '| Grant: | What it is for |' '| Grant(s) | What it is for |' '| Purpose | Grant |' )
GQ5R="$(gq_world GQ5 renamedhead zz-nodelim nodelim zz-swapped swappedhead zz-plural pluralhead zz-tool toolhead zz-usefirst usefirst zz-colon colonhead zz-paren parenhead zz-stemlast stemlast)"
GQ5O="$(grant_table_check "$GQ5R")"
GQ5_S=1; GQ5_N=0; GQ5_MISS=''
for (( gq5k=0; gq5k<${#GQ5_V[@]}; gq5k++ )); do
  grep -qxF "${GQ5_H[$gq5k]}" "$GQ5R/${GQ5_V[$gq5k]}/SKILL.md" || GQ5_S=0
  if grep -q "^FINDING Q0 /${GQ5_V[$gq5k]}:" <<<"$GQ5O"; then GQ5_N=$((GQ5_N+1)); else GQ5_MISS="$GQ5_MISS /${GQ5_V[$gq5k]}"; fi
done
grep -qF '|---|---|' "$GQ5R/zz-nodelim/SKILL.md" && GQ5_S=0
if [ "$GQ5_S" -eq 0 ]; then
  FAIL "GQ5: fixture integrity — a built header shape, or the missing delimiter row, is not as the arm requires, so a verdict here would prove nothing"
elif [ "$GQ5_N" -gt 0 ] && [ "$GQ5_N" -eq "${#GQ5_V[@]}" ] && [ "$(getcount "$GQ5O" GQVERBS)" = '0' ]; then
  PASS "GQ5: flagged, naming Q0 ${GQ5_N} times — the design's four shapes (the Use column renamed, the columns swapped, the Grant column pluralized, the key with no delimiter row) and five that isolate the recognizer's limbs: the Use cell alone under a Grant column renamed Tool, in column 2 and in column 1, and the stem alone over a renamed Use column, as Grant: and Grant(s) and in column 2. Each is named with its verb and line, and none is counted as graded (GQVERBS 0). Without Q0 each edit would drop its table out of the graded set while every direction stayed green"
else
  FAIL "GQ5: a table the key does not read was not flagged, or was graded anyway — ${GQ5_N} of ${#GQ5_V[@]} shape(s) named, unnamed:${GQ5_MISS:- none}; GQVERBS=$(getcount "$GQ5O" GQVERBS)"
fi

# ── GQ6 — PAIRING IS PER VERB, in both directions. Two BUILT graded verbs share Bash(ls:*) and
# Read. The first in glob order holds each and names each; the second holds Bash(ls:*) with no
# row for it, and names Read in a row while holding no Read grant. Each unpaired entry is paired
# only by the OTHER verb, so a reader that pooled rows or grants across verbs would pair both and
# report nothing, while the per-verb reader names the second verb twice and the first not at all.
GQ6R="$(gq_world GQ6 ok zz-lacks crossverb)"
GQ6O="$(grant_table_check "$GQ6R")"
GQ6_S=1
grep -qF "| ${BT}Bash(ls:*)${BT} |" "$GQ6R/zz-graded/SKILL.md" || GQ6_S=0
grep -q '^allowed-tools: Bash(ls:\*), Read, ' "$GQ6R/zz-graded/SKILL.md" || GQ6_S=0
grep -qF "| ${BT}Bash(ls:*)${BT} |" "$GQ6R/zz-lacks/SKILL.md" && GQ6_S=0
grep -qF "| ${BT}Read${BT} |" "$GQ6R/zz-lacks/SKILL.md" || GQ6_S=0
grep -q '^allowed-tools: Bash(ls:\*), Bash(' "$GQ6R/zz-lacks/SKILL.md" || GQ6_S=0
if [ "$GQ6_S" -eq 0 ]; then
  FAIL "GQ6: fixture integrity — the two built verbs do not share their entries as the arm requires, so a verdict here would prove nothing"
elif grep -qF 'FINDING Q2 /zz-lacks the allowed-tools entry "Bash(ls:*)" has no grant-table row' <<<"$GQ6O" \
     && grep -q '^FINDING Q1 /zz-lacks:[0-9][0-9]* the grant-table row "Read" ' <<<"$GQ6O" \
     && [ "$(grep -c '^FINDING ' <<<"$GQ6O")" = '2' ] && [ "$(getcount "$GQ6O" GQVERBS)" = '2' ]; then
  PASS "GQ6: flagged, naming Q2 and Q1 against the SECOND verb only — /zz-lacks holds Bash(ls:*) with no row and names Read with no grant, while /zz-graded, which holds and names both, is named by nothing. Each unpaired entry is paired only by the other verb, so this is the arm that tells a per-verb reader from one that pools rows or grants across verbs"
else
  FAIL "GQ6: pairing leaked across verbs, or the second verb was not named in both directions: $(grep '^FINDING ' <<<"$GQ6O" | head -4 | tr '\n' ' ') GQVERBS=$(getcount "$GQ6O" GQVERBS)"
fi

# ── GQ7 — MUST-NOT-FIRE: a row that spells the path-bearing grant IN FULL pairs by exact equality.
# The normalization ACCEPTS key(G) beside G and never REQUIRES it, so a verb rendering the rooted
# token in its Grant cell — the rendering the TOOL-GRANT class keeps its table half for — is
# paired rather than reported. A key-only rule would read that row as unpaired (Q1) and the grant
# as unnamed (Q2). GQ1 respells the same grant under the BARE path and fires on this run, so this
# silence is the exact-equality limb telling the two spellings apart.
GQ7R="$(gq_world GQ7 rootedrow)"
GQ7O="$(grant_table_check "$GQ7R")"
GQ7_S=1
grep -qF "| ${BT}Bash(${ENGINE_ROOT_TOK}scripts/zz-fixture.sh arm:*)${BT} |" "$GQ7R/zz-graded/SKILL.md" || GQ7_S=0
grep -qF "| ${BT}zz-fixture.sh arm${BT} |" "$GQ7R/zz-graded/SKILL.md" && GQ7_S=0
if [ "$GQ7_S" -eq 0 ]; then
  FAIL "GQ7: fixture integrity — the built verb does not name its script grant by the full rooted token alone, so a silence here would prove nothing"
elif [ "$(getcount "$GQ7O" GQVERBS)" = '1' ] && [ "$(getcount "$GQ7O" GQROWS)" = '3' ] && [ "$(getcount "$GQ7O" GQGRANTS)" = '3' ] \
     && [ "$(getcount "$GQ7O" GQUNROW)" = '0' ] && [ "$(getcount "$GQ7O" GQUNGRANT)" = '0' ] \
     && [ "$(getcount "$GQ7O" GQNEAR)" = '0' ] && [ "$(getcount "$GQ7O" GQCONT)" = '0' ]; then
  PASS "GQ7: MUST-NOT-FIRE — a verb whose script row spells the full rooted token is graded (1 verb, 3 rows, 3 grants) and every row and grant pairs: the row equals its grant exactly, so the normalization accepts the files' script-and-arm rendering beside the full token and prefers neither. GQ1 plants the same grant under the bare path and fires on this run"
else
  FAIL "GQ7: a row spelling the full rooted token did not pair — verbs $(getcount "$GQ7O" GQVERBS), rows $(getcount "$GQ7O" GQROWS), grants $(getcount "$GQ7O" GQGRANTS), unpaired rows $(getcount "$GQ7O" GQUNROW), unnamed grants $(getcount "$GQ7O" GQUNGRANT): $(grep '^FINDING ' <<<"$GQ7O" | head -2 | tr '\n' ' ')"
fi

# ── GQ8 — a CONTINUATION LINE is loud. The allowed-tools value is wrapped, and the indented line
# after it carries a bare tool no row names. This reader does not join such a line, so the arm
# must name it as Q0 and withhold Q2 — exactly one FAIL and no PASS from each — rather than grade
# the three entries it did read and pass. GQ3 appends the same tool on the allowed-tools line
# itself, where it IS read, and names it as Q2.
GQ8R="$(gq_world GQ8 wrapgrant)"
GQ8O="$(grant_table_check "$GQ8R")"
GQ8_P0="$(md_probe zz_gq_no_such_fn gq_assert_anchor "$GQ8R")"
GQ8_P2="$(md_probe zz_gq_no_such_fn gq_assert_grants "$GQ8R")"
GQ8_S=1
grep -qx '  Glob' "$GQ8R/zz-graded/SKILL.md" || GQ8_S=0
grep -q '^allowed-tools: .*,$' "$GQ8R/zz-graded/SKILL.md" || GQ8_S=0
if [ "$GQ8_S" -eq 0 ]; then
  FAIL "GQ8: fixture integrity — the allowed-tools value is not wrapped onto an indented line, so a verdict here would prove nothing"
elif grep -q '^FINDING Q0 /zz-graded:[0-9][0-9]* continues its allowed-tools value' <<<"$GQ8O" && [ "$(getcount "$GQ8O" GQCONT)" = '1' ] \
     && [ "$GQ8_P0" = '0 1' ] && [ "$GQ8_P2" = '0 1' ] \
     && [ "$(getcount "$GQ8O" GQVERBS)" = '1' ] && [ "$(getcount "$GQ8O" GQUNROW)" = '0' ]; then
  PASS "GQ8: flagged, naming Q0 — an allowed-tools value wrapped onto an indented line that carries a grant no row names is reported with its verb and line, Q0 and Q2 each render exactly one FAIL and no PASS, and Q1 stays silent. Without this limb the reader graded the three entries it did read and Q2 passed, with the fourth grant absent from every count"
else
  FAIL "GQ8: a continuation of the allowed-tools value was not reported as Q0, or Q2 was not withheld: GQCONT=$(getcount "$GQ8O" GQCONT), Q0 probe '${GQ8_P0}', Q2 probe '${GQ8_P2}': $(grep '^FINDING ' <<<"$GQ8O" | head -2 | tr '\n' ' ')"
fi

# ── GQ9 — THE ROW SIDE IS READ IN FULL. Three BUILT worlds, each holding one row that no grant holds,
# placed where a reader narrower than the banner's ROW would not look:
#   addrow       after the GQ_FILL filler rows, as the last row of its table, so a reader that samples
#                the first N rows of a table misses it for every N below GQ_FILL + 4
#   secondtable  in a SECOND table headed by the key in the same verb, so a reader that stops at the
#                first graded table misses it
#   unticked     in a Grant cell that is not a code span, so a reader that reads only code-span
#                cells misses it
# Each world is isolated the way GQ1's is, and more tightly: Q1 must name /zz-graded, the row's line
# and its entry, and nothing else may be found, so Q2 and Q0 are silent and the untabled verb is not
# graded. The live tables carry none of the three shapes today — one grant table per verb, at most
# six rows, every Grant cell a code span — so nothing but this arm holds the reader to them.
arm Q1
GQ9_W=( addrow secondtable unticked )
GQ9_S=1; GQ9_N=0; GQ9_MISS=''
for gq9w in "${GQ9_W[@]}"; do
  gq9r="$(gq_world "GQ9-$gq9w" "$gq9w")"; gq9f="$gq9r/zz-graded/SKILL.md"
  # Fixture integrity, read off the built file and never off the reader: exactly one row names the
  # token, no allowed-tools entry holds it, and the row sits on the line its world says it does.
  [ "$(grep -c -e "^| ${BT}Glob${BT} |" -e '^| Glob |' "$gq9f")" = '1' ] || GQ9_S=0
  grep -q '^allowed-tools: .*Glob' "$gq9f" && GQ9_S=0
  gq9l="$(grep -n -e "^| ${BT}Glob${BT} |" -e '^| Glob |' "$gq9f")"; gq9l="${gq9l%%:*}"
  case "$gq9w" in
    addrow)      gq9a="$(grep -n "^| ${BT}Bash(zzq-fill-${GQ_FILL}:\*)${BT} |" "$gq9f")"; gq9d=1
                 [ "$(grep -c "^| ${BT}Bash(zzq-fill-[0-9]*:\*)${BT} |" "$gq9f")" = "$GQ_FILL" ] || GQ9_S=0
                 grep -q "^allowed-tools: .*, Bash(zzq-fill-${GQ_FILL}:\*)\$" "$gq9f" || GQ9_S=0 ;;
    secondtable) gq9a="$(grep -n -x -F '| Grant | The use that holds it |' "$gq9f" | tail -1)"; gq9d=2
                 [ "$(grep -c -x -F '| Grant | The use that holds it |' "$gq9f")" = '2' ] || GQ9_S=0 ;;
    unticked)    gq9a="$(grep -n "^| ${BT}zz-fixture.sh arm${BT} |" "$gq9f")"; gq9d=1
                 grep -q "^| ${BT}Glob${BT} |" "$gq9f" && GQ9_S=0 ;;
  esac
  gq9a="${gq9a%%:*}"
  [ -n "$gq9a" ] && [ "$gq9l" = "$(( gq9a + gq9d ))" ] || GQ9_S=0
  gq9o="$(grant_table_check "$gq9r")"
  if grep -q "^FINDING Q1 /zz-graded:${gq9l} the grant-table row \"Glob\" " <<<"$gq9o" \
     && [ "$(grep -c '^FINDING ' <<<"$gq9o")" = '1' ] && [ "$(getcount "$gq9o" GQVERBS)" = '1' ]; then
    GQ9_N=$((GQ9_N+1))
  else
    GQ9_MISS="$GQ9_MISS ${gq9w} ($(grep -c '^FINDING ' <<<"$gq9o") finding(s), GQVERBS $(getcount "$gq9o" GQVERBS));"
  fi
done
if [ "$GQ9_S" -eq 0 ]; then
  FAIL "GQ9: fixture integrity — a built world does not carry exactly one row naming Glob where its world places it (after the ${GQ_FILL} filler rows, beneath a second key header, or in a Grant cell that is not a code span), or holds Glob as a grant, so a verdict here would prove nothing"
elif [ "$GQ9_N" -gt 0 ] && [ "$GQ9_N" -eq "${#GQ9_W[@]}" ]; then
  PASS "GQ9: flagged, naming Q1 ${GQ9_N} times — a row no grant holds, planted where a narrower reader would not look: as row $((GQ_FILL + 4)) of its table after ${GQ_FILL} paired filler rows, in a second grant table of the same verb, and in a Grant cell that is not a code span. Each is named with its verb, line and entry as the only finding of its world, so Q2 and Q0 stay silent and the untabled verb is not graded. A reader that samples fewer than $((GQ_FILL + 4)) rows of a table, stops at the first graded table, or skips a Grant cell that is not a code span leaves a world unnamed here"
else
  FAIL "GQ9: a row no grant holds was not named as the only finding of its world — ${GQ9_N} of ${#GQ9_W[@]} world(s) as specified; not:${GQ9_MISS}"
fi

# ── GQ0 — MUST-NOT-FIRE on a COPY of the live tables. Three near-misses, each differing from a true
# positive in the one property the arm keys on:
#   · every data row of every table has everything after its first cell replaced by text naming
#     GQ_UNHELD — a Use-cell-only rewrite of the kind a body edit makes, carrying in the Use
#     column the exact token GQ1 plants in the Grant column
#   · a prose line after a blank line beneath every table, naming the same token
#   · a FENCED example grant table appended to every verb file
# The rewrite is structural — it keys on the pipe and the first cell, never on a header string or
# on any live wording — so it survives any rewrite of the live Use cells and needs no maintenance.
# The verdict is INVARIANCE: the counts and the finding set equal the live run's, so the arm stays
# answerable on a tree that is already red.
gq_copy_live() {  # gq_copy_live <dest-verb-root> — a byte copy of every live verb file
  local f v
  for f in "$CDIR"/*/SKILL.md; do
    [ -e "$f" ] || continue
    v="$(verb_id "$f")"; mkdir -p "$1/$v"; cat "$f" > "$1/$v/SKILL.md"
  done
}
gq_rewrite_tables() {  # gq_rewrite_tables <file> — the three near-misses, in place on a COPY
  # A DATA row is a pipe row below a delimiter row, up to the first line that does not open with
  # a pipe. Keyed on the delimiter row and never on a header string, so the header of every table
  # is left exactly as written and no live wording is needed to find a table.
  local f="$1" line prev='' c body=0
  {
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$prev" == '|'* ]] && [[ "$line" != '|'* ]]; then
        printf '\nProse beneath a table naming %s%s%s, which holds nothing.\n' "$BT" "$GQ_UNHELD" "$BT"
      fi
      if [[ "$line" != '|'* ]]; then body=0; printf '%s\n' "$line"
      elif is_sep "$line"; then body=1; printf '%s\n' "$line"
      elif [ "$body" -eq 1 ]; then
        c="${line#|}"; c="${c%%|*}"
        printf '|%s| rewritten, naming %s%s%s in the Use column |\n' "$c" "$BT" "$GQ_UNHELD" "$BT"
      else
        printf '%s\n' "$line"
      fi
      prev="$line"
    done < "$f"
    printf '\n```\n| Grant | The use that holds it |\n|---|---|\n| %s%s%s | an example inside a fence, which declares nothing |\n```\n' "$BT" "$GQ_UNHELD" "$BT"
  } > "$f.new" && mv "$f.new" "$f"
}
GQ0D="$WORK/GQ0/skills"; mkdir -p "$GQ0D"; gq_copy_live "$GQ0D"
for gqf in "$GQ0D"/*/SKILL.md; do [ -e "$gqf" ] && gq_rewrite_tables "$gqf"; done
GQ0L="$(grant_table_check "$CDIR")"; GQ0C="$(grant_table_check "$GQ0D")"
GQ0_USE=0; GQ0_FEN=0; GQ0_NV=0
for gqf in "$GQ0D"/*/SKILL.md; do
  [ -e "$gqf" ] || continue
  GQ0_NV=$((GQ0_NV+1))
  GQ0_USE=$(( GQ0_USE + $(grep -c 'in the Use column' "$gqf") ))
  GQ0_FEN=$(( GQ0_FEN + $(grep -c 'an example inside a fence' "$gqf") ))
done
# Line numbers are dropped before the finding sets are compared: the prose plant shifts every
# line beneath a table, and invariance is a property of WHAT is named, not of where it now sits.
gq_fset() { grep '^FINDING ' <<<"$1" | sed -E 's/^(FINDING [A-Z][0-9] [^ :]+):[0-9]+ /\1 /' | sort; }
GQ0_LF="$(gq_fset "$GQ0L")"; GQ0_CF="$(gq_fset "$GQ0C")"
arm Q1
if [ "${GQ0_USE:-0}" -lt "$(getcount "$GQ0L" GQROWS)" ] || [ "${GQ0_FEN:-0}" -ne "${GQ0_NV:-0}" ] || [ "${GQ0_NV:-0}" -le 0 ]; then
  FAIL "GQ0: fixture integrity — the copy carries ${GQ0_USE:-0} rewritten row(s) and ${GQ0_FEN:-0} fenced example(s) across ${GQ0_NV:-0} verb file(s); the near-misses were not all planted, so a zero here would prove nothing"
elif [ "$(getcount "$GQ0L" GQROWS)" -le 0 ]; then
  FAIL "GQ0: NO SUBJECT — the live tables yield no row, so there is nothing whose invariance could be shown"
elif [ "$(getcount "$GQ0C" GQVERBS)" = "$(getcount "$GQ0L" GQVERBS)" ] && [ "$(getcount "$GQ0C" GQROWS)" = "$(getcount "$GQ0L" GQROWS)" ] \
     && [ "$(getcount "$GQ0C" GQGRANTS)" = "$(getcount "$GQ0L" GQGRANTS)" ] && [ "$(getcount "$GQ0C" GQNEAR)" = "$(getcount "$GQ0L" GQNEAR)" ] \
     && [ "$GQ0_CF" = "$GQ0_LF" ]; then
  PASS "GQ0: MUST-NOT-FIRE — on a copy of the live verb files with every table row's Use cell rewritten (${GQ0_USE} rows) to name a grant nothing holds, the same token in prose beneath every table, and a fenced example grant table in each of ${GQ0_NV} files, the arm reads the SAME $(getcount "$GQ0C" GQVERBS) verb(s), $(getcount "$GQ0C" GQROWS) row(s) and $(getcount "$GQ0C" GQGRANTS) grant(s) and the SAME finding set as on the live tree. GQ1 plants that same token in a Grant cell and fires on the same run, so this zero is the arm telling the columns apart"
else
  FAIL "GQ0: a Use-cell rewrite, a prose line or a fenced example moved the verdict — live verbs/rows/grants $(getcount "$GQ0L" GQVERBS)/$(getcount "$GQ0L" GQROWS)/$(getcount "$GQ0L" GQGRANTS), copy $(getcount "$GQ0C" GQVERBS)/$(getcount "$GQ0C" GQROWS)/$(getcount "$GQ0C" GQGRANTS); first new finding: $(grep '^FINDING ' <<<"$GQ0C" | head -1)"
fi

# ── GQD — DERIVED, NOT LISTED. The live copy plus one BUILT conforming verb: the graded set must
# grow by exactly that verb and its three rows and grants, with nothing named against it. A held
# list of verbs would read the same count as the live run.
GQDD="$WORK/GQD/skills"; mkdir -p "$GQDD"; gq_copy_live "$GQDD"; gq_gen_verb "$GQDD" zz-joins respaced
GQDO="$(grant_table_check "$GQDD")"
if ! grep -q '^|grant|  The Use  That Holds It  |  $' "$GQDD/zz-joins/SKILL.md"; then
  FAIL "GQD: fixture integrity — the joining verb carries no grant table, so a count here would prove nothing"
elif [ "$(getcount "$GQDO" GQVERBS)" = "$(( $(getcount "$GQ0L" GQVERBS) + 1 ))" ] && [ "$(getcount "$GQDO" GQROWS)" = "$(( $(getcount "$GQ0L" GQROWS) + 3 ))" ] \
     && [ "$(getcount "$GQDO" GQGRANTS)" = "$(( $(getcount "$GQ0L" GQGRANTS) + 3 ))" ] && ! grep -q '^FINDING [A-Z][0-9] /zz-joins' <<<"$GQDO"; then
  PASS "GQD: DERIVED — a verb that adds a table headed | Grant | The use that holds it |, here re-spaced, re-cased and trailed by whitespace, is graded on the same run with no edit to this file: $(getcount "$GQ0L" GQVERBS) -> $(getcount "$GQDO" GQVERBS) verb(s), $(getcount "$GQ0L" GQROWS) -> $(getcount "$GQDO" GQROWS) row(s), and its path-bearing grant pairs by script and arm under a script name the repository does not carry"
else
  FAIL "GQD: a verb that joined with a paired grant table did not raise the graded set by exactly one verb and three rows and grants, or was named in a finding: verbs $(getcount "$GQDO" GQVERBS), rows $(getcount "$GQDO" GQROWS), grants $(getcount "$GQDO" GQGRANTS)"
fi

# ── GQV — the two degenerate populations reach FAIL, never PASS. An empty verb root, and a root
# whose only verb file is a link to nothing: each of the three verdicts must count exactly one
# FAIL and no PASS. md_probe is reused with a victim that does not exist, so it removes nothing
# and only counts.
GQV1="$WORK/GQV1/skills"; mkdir -p "$GQV1"
GQV2="$WORK/GQV2/skills"; mkdir -p "$GQV2/zz-gone"; ln -s "$WORK/GQV2/nowhere" "$GQV2/zz-gone/SKILL.md"
gq_gen_verb "$GQV2" zz-graded ok
GQV_N=0; GQV_OK=0; GQV_BAD=''
for gqa in gq_assert_anchor gq_assert_rows gq_assert_grants; do
  for gqd in "$GQV1" "$GQV2"; do
    GQV_N=$((GQV_N+1))
    gqr="$(md_probe zz_gq_no_such_fn "$gqa" "$gqd")"
    if [ "$gqr" = '0 1' ]; then GQV_OK=$((GQV_OK+1)); else GQV_BAD="$GQV_BAD$gqa over ${gqd#"$WORK"/} gave '$gqr'; "; fi
  done
done
if [ -n "$(ls -A "$GQV1")" ] || [ ! -L "$GQV2/zz-gone/SKILL.md" ] || [ -e "$GQV2/zz-gone/SKILL.md" ]; then
  FAIL "GQV: fixture integrity — the empty root is not empty or the link is not dangling, so neither degenerate population was built"
elif [ "$GQV_N" -gt 0 ] && [ "$GQV_OK" -eq "$GQV_N" ]; then
  PASS "GQV: VACUITY AND DEGRADATION REACH FAIL — ${GQV_OK} of ${GQV_N} probe(s): over an empty verb root, and over a root holding one conforming graded verb beside a verb file that is a link to nothing, each of Q0, Q1 and Q2 renders exactly one FAIL and no PASS. The unreadable file is counted and withholds the verdict, never skipped; a finding-absence reading would be green on both"
else
  FAIL "GQV: ${GQV_OK} of ${GQV_N} probe(s) reached exactly one FAIL on a degenerate population: ${GQV_BAD}"
fi

# ── GQK — A KEY NO TABLE CARRIES IS VACUITY, NEVER A PASS. The banner holds GQ_KEY_COLS both ways: a
# key no live table carries any more is Q0's VACUITY rather than a pass. GQV reaches Q0's other two
# degenerate limbs, an empty verb root and an unreadable verb file, and not this one. The world is
# BUILT by gq_world with its graded slot built `notable`: two readable verb files and no grant table,
# one verb carrying no table at all and the other a table whose header names neither form, over rows
# that carry neither word. The reader must read both, grade neither and find nothing, which leaves
# Q0 one limb: that VACUITY, rendering exactly one FAIL and no PASS. The reader's own counts pin the
# limb, because a reader that read no file at all reaches Q0's other VACUITY limb with the same FAIL.
GQKR="$(gq_world GQK notable)"
GQKO="$(grant_table_check "$GQKR")"
GQK_P0="$(md_probe zz_gq_no_such_fn gq_assert_anchor "$GQKR")"
GQK_S=1; GQK_NF=0
for gqkf in "$GQKR"/*/SKILL.md; do
  [ -f "$gqkf" ] || continue
  GQK_NF=$((GQK_NF+1))
  [ "$(grep -c -i -E '^[|].*(grant|holds)' "$gqkf")" = '0' ] || GQK_S=0
done
grep -qx '| Step | What it does |' "$GQKR/zz-graded/SKILL.md" || GQK_S=0
grep -qx '|---|---|' "$GQKR/zz-graded/SKILL.md" || GQK_S=0
[ "$GQK_NF" = '2' ] || GQK_S=0
if [ "$GQK_S" -eq 0 ]; then
  FAIL "GQK: fixture integrity — the built root does not hold two readable verb files free of every grant table and near miss, one of them carrying a table, so a verdict here would prove nothing"
elif [ "$(getcount "$GQKO" GQFILES)" = "$GQK_NF" ] && [ "$(getcount "$GQKO" GQUNREAD)" = '0' ] && [ "$(getcount "$GQKO" GQVERBS)" = '0' ] \
     && [ "$(getcount "$GQKO" GQNEAR)" = '0' ] && [ "$(getcount "$GQKO" GQCONT)" = '0' ] && [ "$GQK_P0" = '0 1' ]; then
  PASS "GQK: VACUITY REACHES FAIL — over ${GQK_NF} readable verb file(s) that carry no grant table and no near miss, one of them a table under a header naming neither form, the reader reads all ${GQK_NF}, grades none and finds nothing, and Q0 renders exactly one FAIL and no PASS: the VACUITY a key no table carries any more reaches. GQV reaches Q0's other two degenerate limbs; a Q0 that passed here would read the retirement of every grant table as a clean derivation"
else
  FAIL "GQK: over verb files that carry no grant table, Q0 did not render exactly one FAIL and no PASS from its VACUITY limb — files $(getcount "$GQKO" GQFILES) of ${GQK_NF}, unreadable $(getcount "$GQKO" GQUNREAD), graded $(getcount "$GQKO" GQVERBS), near misses $(getcount "$GQKO" GQNEAR), continued $(getcount "$GQKO" GQCONT); Q0 probe '${GQK_P0}' where '0 1' is required"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group GJ — controls for group J. Every fixture is rooted at $WORK, so group Z's claim
# covers them. The MUST-FIRE worlds are BUILT by gj_world from a defect switch — never
# patched — and each arm checks that its defect is present before it reads a verdict. Two
# arms use a byte copy of the live inputs, because what they assert is about those inputs:
# GJL removes one span from the Enrichment row, and GJD adds one agent, one prompt and one
# class. Each asserts that its edit landed before it reads anything.
# ═════════════════════════════════════════════════════════════════════════════════

# gj_world <dir> <defect> — two agents, their prompts, and a § 1.1 table carrying every writer
# cell shape the join reads: a bare id; a prose cell naming two writers and an operator verb;
# the block-owned sentinel; "the spoke that re-ran"; `zz-alpha-legacy`, a hyphen-extended
# near miss that must expect nothing of `zz-alpha`; and a class whose writer does not emit it
# yet, named in its row as declared and not yet written. The roster header is re-spaced and
# re-cased, a fenced copy of it precedes the real one, one prompt block is indented, one
# carries no writer, one is another pair's writer list and one quotes another agent's block in
# list form. The prompts carry the Output headings the reader must read — a bare Pre-Work file
# name, and a path followed by a parenthetical — beside the ones it must not: a heading with
# no colon, a fenced heading and an indented one. Each is a shape a naive reader gets wrong.
# Five more switches build on the conforming world. Four each append one file that a single
# branch of the reader alone declares: a File heading, a bare Pre-Work heading, and a writer
# list naming the prompt's own id first, with and without a space after its comma. The fifth
# adds a third agent, its class (the heading's count moving to 8 with it) and its prompt, and
# that agent's row names no outputs/ path. Their arms follow GJ9.
gj_world() {
  local d="$1" dft="$2" hdr rowa rowb cnt=7 bid='zz-beta' qlist='[zz-alpha, zz-gamma]' pend
  mkdir -p "$d/agents" "$d/reference"
  pend=', declares `outputs/zz-pending.md`, not written before the landing that ships its writer'
  hdr='|  agent|PROMPT  FILE | `Output File` |  When to  dispatch   |'
  [ "$dft" = 'anchor0' ] && hdr='| Agent | Prompt File | Output Files | When to dispatch |'
  rowa='| Zz Alpha | `agents/zz-alpha.md` | `outputs/zz-a.md`, its preserved `outputs/zz-a-v<N>.md`, `outputs/zz-shared.md` (primary writer), `outputs/zz-a-status.md`'"$pend"' | always |'
  rowb='| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md`, `outputs/zz-b-sections.md` (its sections), `outputs/zz-shared.md` (setup seed only) | always |'
  case "$dft" in
    rowmiss)    rowb='| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md`, `outputs/zz-b-sections.md` (its sections) | always |' ;;
    onespan)    rowb='| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md` | always |' ;;
    prose)      rowa='| Zz Alpha | `agents/zz-alpha.md` | outputs/zz-a.md, its preserved `outputs/zz-a-v<N>.md`, `outputs/zz-shared.md` (primary writer), `outputs/zz-a-status.md`'"$pend"' | always |' ;;
    badrow)     rowb='| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md` | always | extra |' ;;
    badprompt)  rowb='| Zz Beta | agents/zz-beta.md | `outputs/zz-b.md`, `outputs/zz-b-sections.md`, `outputs/zz-shared.md` | always |' ;;
    dangling)   rowb='| Zz Beta | `agents/zz-missing.md` | `outputs/zz-b.md`, `outputs/zz-b-sections.md`, `outputs/zz-shared.md` | always |' ;;
    countdrift) cnt=8 ;;
    noclasses)  cnt=0 ;;
    joinmiss)   bid='zz-gamma'; qlist='[zz-alpha, zz-delta]' ;;
    zerospan)   cnt=8 ;;
  esac
  {
    printf '# Fixture charter\n\nA fenced example of the roster, never a second anchor:\n\n'
    printf '```markdown\n| Agent | Prompt File | Output File | When to dispatch |\n|---|---|---|---|\n'
    printf '| Zz Example | `agents/zz-example.md` | `outputs/zz-example.md` | never |\n```\n\n'
    printf '**Agent roster:**\n\n%s\n|-------|------------|-------------|-----------------|\n' "$hdr"
    [ "$dft" = 'norows' ] || printf '%s\n%s\n' "$rowa" "$rowb"
    [ "$dft" = 'zerospan' ] && printf '| Zz Zero | `agents/zz-zero.md` | `trip-context.md` (the block it seeds) | always |\n'
    printf '\nAfter the table.\n'
    [ "$dft" = 'anchor2' ] && printf '\n| Agent | Prompt File | Output File | When to dispatch |\n|---|---|---|---|\n| Zz Gamma | `agents/zz-alpha.md` | `outputs/zz-a.md` | never |\n'
  } > "$d/CLAUDE.md"
  {
    printf '# Fixture architecture\n\n'
    if [ "$dft" = 'nosection' ]; then printf '### 1.9 Something else (%d)\n\n' "$cnt"
    else printf '### 1.1 In-model — artifact classes (%d)\n\n' "$cnt"; fi
    printf '| C | Class | W (exactly one) | L | Prov | P | Primary entities |\n|---|---|---|---|---|---|---|\n'
    if [ "$dft" != 'noclasses' ]; then
      printf '| 1 | `trip-context.md` | **block-owned** (`CLAUDE.md` § *Write ownership*) | `persist-mutable` | `human` | `bound` | Trip |\n'
      printf '| 2 | `outputs/zz-a.md` | zz-alpha | `accumulate-append` | `researched` | `internal` | Venue |\n'
      if [ "$dft" = 'badclassrow' ]; then
        printf '| 3 | `outputs/zz-b.md` | zz-beta | `accumulate-append` | `researched` | `internal` | Venue | extra |\n'
      else
        printf '| 3 | `outputs/zz-b.md` | zz-beta | `accumulate-append` | `researched` | `internal` | Venue |\n'
      fi
      printf '| 4 | `outputs/zz-shared.md` | zz-alpha (primary); zz-beta seeds; `/trip-record event` | `persist-mutable` | `recorded` | **`bound`** | Event |\n'
      printf '| 5 | `outputs/<slug>.md` — targeted-research output | the spoke that re-ran | `accumulate-append` | `researched` | `internal` | Venue |\n'
      printf '| 6 | `outputs/zz-legacy.md` | zz-alpha-legacy | `output` | `derived` | `output` | Venue |\n'
      printf '| 7 | `outputs/zz-pending.md` | zz-alpha | `rebuilt-each-synthesis` | `derived` | `internal` | Venue |\n'
      [ "$dft" = 'zerospan' ] && printf '| 8 | `outputs/zz-z.md` | zz-zero | `rebuilt-each-synthesis` | `derived` | `internal` | Venue |\n'
    fi
    printf '\n### 1.2 The next section\n\n| 8 | `outputs/zz-outside.md` | zz-alpha | x | x | x | x |\n'
  } > "$d/reference/data-architecture.md"
  {
    printf '## Output Format\n\n```yaml\n---\nartifact: outputs/zz-a.md\nschema-version: 1\nwriter: zz-alpha\n---\n```\n\n'
    printf 'When you preserve a version, change exactly these two lines:\n\n```yaml\nartifact: outputs/zz-a-v<N>.md\npublish: internal\n```\n\n'
    printf 'The status block, as an indented code block:\n\n    ---\n    artifact: outputs/zz-a-status.md\n    writer: zz-alpha\n    ---\n'
    printf '\nThe contract of a file this role reads, quoted in list form:\n\n```yaml\n---\nartifact: outputs/zz-b.md\nwriter: [zz-beta]\n---\n```\n'
    printf '\n### Output Quality Standards\n\n### Pre-Work Output 1: zz-a.md\n\nA heading shown as an example, fenced:\n\n```markdown\n### Output: outputs/zz-fenced.md\n```\n\nAnd one shown indented:\n\n    ### File: outputs/zz-indented.md\n'
    [ "$dft" = 'promptmiss' ] && printf '\n```yaml\n---\nartifact: outputs/zz-a2.md\nwriter: zz-alpha\n---\n```\n'
    [ "$dft" = 'quotebare' ] && printf '\nThe same contract quoted with a bare writer:\n\n```yaml\n---\nartifact: outputs/zz-b.md\nwriter: zz-beta\n---\n```\n'
    [ "$dft" = 'quotenowriter' ] && printf '\nThe same contract quoted with no writer:\n\n```yaml\n---\nartifact: outputs/zz-b.md\n---\n```\n'
    [ "$dft" = 'headmiss' ] && printf '\n### Output: outputs/zz-a3.md (its sections)\n\nA file this role declares by its heading alone.\n'
    [ "$dft" = 'headfile' ] && printf '\n### File: outputs/zz-f.md\n\nA file this role declares by its File heading alone.\n'
    [ "$dft" = 'headpre' ] && printf '\n### Pre-Work Output 2: zz-p.md\n\nA file this role declares by its Pre-Work heading alone, named bare.\n'
    [ "$dft" = 'listfirst' ] && printf '\nA block this role shares, its writer list naming this role first:\n\n```yaml\n---\nartifact: outputs/zz-l.md\nwriter: [zz-alpha, zz-beta]\n---\n```\n'
    [ "$dft" = 'listnospace' ] && printf '\nThe same block, its writer list written with no space after the comma:\n\n```yaml\n---\nartifact: outputs/zz-l.md\nwriter: [zz-alpha,zz-beta]\n---\n```\n'
  } > "$d/agents/zz-alpha.md"
  {
    printf '## Output Format\n\n```yaml\n---\nartifact: outputs/zz-b.md\nwriter: %s\n---\n```\n\n' "$bid"
    printf 'A section-owned block this role shares:\n\n```yaml\n---\nartifact: outputs/zz-b-sections.md\nwriter: [zz-alpha, %s]\n---\n```\n\n' "$bid"
    printf 'Another pair'"'"'s block, quoted for reference, read and never written:\n\n```yaml\n---\nartifact: outputs/zz-quoted.md\nwriter: %s\n---\n```\n' "$qlist"
    printf '\n### Output: outputs/zz-shared.md (its sections)\n\nThe setup seed this role writes once.\n'
    [ "$dft" = 'idambig' ] && printf '\n```yaml\n---\nartifact: outputs/zz-b.md\nwriter: zz-alpha\n---\n```\n'
  } > "$d/agents/zz-beta.md"
  [ "$dft" = 'zerospan' ] && printf '## Output Format\n\n```yaml\n---\nartifact: outputs/zz-z.md\nwriter: zz-zero\n---\n```\n' > "$d/agents/zz-zero.md"
  return 0
}

# gj_counts <out> — the per-id finding counts a control arm reads.
gj_counts() {
  GJ_N0="$(grep -c '^FINDING J0 ' <<<"$1")"; GJ_N1="$(grep -c '^FINDING J1 ' <<<"$1")"
  GJ_N2="$(grep -c '^FINDING J2 ' <<<"$1")"
}

# gj_tally <assert-fn> <root> -> "<pass> <fail>" — an assertion's verdicts, counted in a
# subshell, so a vacuity arm shows each assertion renders exactly one FAIL and no PASS.
gj_tally() {
  ( pass=0; fail=0
    PASS() { pass=$((pass+1)); }; FAIL() { fail=$((fail+1)); }; show() { :; }
    "$1" "$2" >/dev/null 2>&1
    printf '%d %d' "$pass" "$fail" )
}

echo
echo "── Group GJ — control arms for group J: shown failing on each defect, passing on a correct world, and deriving its population."
GJ="$WORK/gj"; mkdir -p "$GJ"
for gjd in ok rowmiss promptmiss prose joinmiss anchor0 anchor2 badrow badprompt idambig countdrift nosection badclassrow norows noclasses dangling quotebare quotenowriter headmiss onespan headfile headpre listfirst listnospace zerospan; do
  gj_world "$GJ/$gjd" "$gjd"
done

# GJ0 — MUST NOT FIRE. Integrity first: every near-miss plant is present in the world read.
GJ_INT=$(( $(grep -c '^    artifact: outputs/zz-a-status.md' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c '^publish: internal' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -F 'writer: [zz-alpha, zz-gamma]' "$GJ/ok/agents/zz-beta.md") \
         + $(grep -c -F 'zz-alpha-legacy' "$GJ/ok/reference/data-architecture.md") \
         + $(grep -c -F '|  agent|PROMPT  FILE |' "$GJ/ok/CLAUDE.md") \
         + $(grep -c -F '| Zz Example |' "$GJ/ok/CLAUDE.md") \
         + $(grep -c -x -F 'writer: [zz-beta]' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -x -F '### Output Quality Standards' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -x -F '### Output: outputs/zz-fenced.md' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -x -F '    ### File: outputs/zz-indented.md' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -x -F '### Pre-Work Output 1: zz-a.md' "$GJ/ok/agents/zz-alpha.md") \
         + $(grep -c -x -F '### Output: outputs/zz-shared.md (its sections)' "$GJ/ok/agents/zz-beta.md") \
         + $(grep -c -F 'declares `outputs/zz-pending.md`, not written before' "$GJ/ok/CLAUDE.md") ))
GJ_OUT="$(roster_write_check "$GJ/ok")"; gj_counts "$GJ_OUT"
GJ_TAB=$'\t'   # the RJEXP separator, spelled rather than typed, so no copy of this line can lose it
GJ_EXP="$(sed -n "s/^RJEXP \([^${GJ_TAB}]*\)${GJ_TAB}\([^${GJ_TAB}]*\)${GJ_TAB}.*/\1>\2/p" <<<"$GJ_OUT" | tr '\n' ' ')"
GJ_UNJ="$(sed -n 's/^RJUNJOINED //p' <<<"$GJ_OUT")"
if [ "$GJ_INT" -ne 13 ]; then
  FAIL "GJ0: fixture integrity — the conforming world carries ${GJ_INT} of its 13 near-miss plants, so a silence here would prove nothing"
elif [ "$GJ_N0" -ne 0 ] || [ "$GJ_N1" -ne 0 ] || [ "$GJ_N2" -ne 0 ]; then
  FAIL "GJ0: MUST NOT FIRE — the conforming world raised J0=${GJ_N0} J1=${GJ_N1} J2=${GJ_N2}; a near-miss plant was read as a defect"; show "$GJ_OUT" 'J0|J1|J2'
elif [ "$GJ_EXP" != 'Zz Alpha>outputs/zz-a.md Zz Alpha>outputs/zz-shared.md Zz Alpha>outputs/zz-pending.md Zz Alpha>outputs/zz-a-v<N>.md Zz Alpha>outputs/zz-a-status.md Zz Beta>outputs/zz-b.md Zz Beta>outputs/zz-shared.md Zz Beta>outputs/zz-b-sections.md ' ]; then
  FAIL "GJ0: the expected set on the conforming world is '${GJ_EXP}' — a plant widened or narrowed it"
elif [ "$GJ_UNJ" != 'C1 C5 C6' ]; then
  FAIL "GJ0: the unjoined census is '${GJ_UNJ}', expected 'C1 C5 C6' — the hyphen-extended id zz-alpha-legacy (C6) must join nothing"
else
  PASS "GJ0: MUST NOT FIRE — all 13 near-miss plants present (a fenced copy of the roster header, a re-spaced and re-cased real header, an indented frontmatter block, a block with no writer, another pair's quoted writer list, a block quoting another agent's in the one-id list form, a hyphen-extended id, a class named only as declared and not yet written, a bare Pre-Work heading file name, a heading path followed by a parenthetical, and three headings that declare nothing: one with no colon, one fenced, one indented); no finding; the expected set is exactly the 8 pairs the world declares, 3 of them reachable only through the indented, writer-less and shared-list blocks and 1 named only inside its declared-not-written clause; C6 joins nothing"
fi

# gj_fire <id> <world> <want-finding-regex> <arm-id> <prose> — a MUST-FIRE arm over a BUILT
# world: exactly one finding of <id>, matching <want>, and the other two ids silent.
gj_fire() {
  local id="$1" w="$2" want="$3" aid="$4" prose="$5" out nid nwant nother vt
  out="$(roster_write_check "$GJ/$w")"; gj_counts "$out"
  case "$id" in J0) nid="$GJ_N0"; nother=$((GJ_N1+GJ_N2)) ;; J1) nid="$GJ_N1"; nother=$((GJ_N0+GJ_N2)) ;; *) nid="$GJ_N2"; nother=$((GJ_N0+GJ_N1)) ;; esac
  nwant="$(grep -c -E "^FINDING $id .*$want" <<<"$out")"
  case "$id" in J0) vt="$(gj_tally rj_assert_population "$GJ/$w")" ;; J1) vt="$(gj_tally rj_assert_named "$GJ/$w")" ;; *) vt="$(gj_tally rj_assert_join "$GJ/$w")" ;; esac
  arm "$id"
  if [ "$vt" != '0 1' ]; then
    FAIL "$aid: MUST FIRE — $prose: the $id assertion rendered pass/fail '$vt' over the defect, expected '0 1' — its finding limb does not turn the verdict"
  elif [ "$nwant" -ne 1 ] || [ "$nid" -ne 1 ]; then
    FAIL "$aid: MUST FIRE — $prose: expected exactly one $id finding matching the defect, got $nid $id finding(s) of which $nwant match"; show "$out" "$id"
  elif [ "$nother" -ne 0 ]; then
    FAIL "$aid: the defect leaked into another id ($nother finding(s)) — $prose is not isolated"; show "$out" 'J0|J1|J2'
  else
    PASS "$aid: MUST FIRE — $prose: exactly one $id finding, naming the defect; no other id raised; and the $id assertion renders one FAIL and no PASS over it"
  fi
}
gj_fire J1 rowmiss    '"Zz Beta" does not name "outputs/zz-shared.md".*§ 1.1 C4'                 GJ1 'a row omits a class its writer cell assigns (a prose W cell naming two writers)'
gj_fire J1 promptmiss '"Zz Alpha" does not name "outputs/zz-a2.md".*frontmatter agents/zz-alpha.md' GJ2 'a row omits a file its own prompt emits frontmatter for, which § 1.1 does not list'
gj_fire J1 prose      '"Zz Alpha" does not name "outputs/zz-a.md"'                                 GJ3 'a row mentions the path in prose only — a mention outside a code span is not a name'
gj_fire J2 joinmiss   '"Zz Beta" joins as writer id "zz-gamma"'                                    GJ4 'a prompt declares a writer id no § 1.1 W cell names'

# GJ5 — MUST FIRE, one structural cause per BUILT world; J0 names the cause, and J1 and J2
# withhold their verdicts rather than grading a partial population.
GJ5_BAD=''; GJ5_N=0
for gjc in 'anchor0|0 roster header row' 'anchor2|2 roster header row' 'badrow|splits into 5 cell' \
           'badprompt|names 0 prompt path' 'idambig|declares 2 bare writer id' 'countdrift|declares 8 class' \
           'nosection|carries 0 heading line' 'badclassrow|a class row splits into 8 cell'; do
  gjw="${gjc%%|*}"; gjm="${gjc#*|}"; GJ5_N=$((GJ5_N+1))
  gjo="$(roster_write_check "$GJ/$gjw")"
  gjh="$(grep -c -F "$gjm" <<<"$gjo")"
  gjt0="$(gj_tally rj_assert_population "$GJ/$gjw")"; gjt1="$(gj_tally rj_assert_named "$GJ/$gjw")"; gjt2="$(gj_tally rj_assert_join "$GJ/$gjw")"
  if [ "$gjh" -lt 1 ] || [ "$gjt0" != '0 1' ] || [ "$gjt1" != '0 1' ] || [ "$gjt2" != '0 1' ]; then GJ5_BAD="$GJ5_BAD$gjw(hit=$gjh J0=$gjt0 J1=$gjt1 J2=$gjt2) "; fi
done
arm J0
if [ -n "$GJ5_BAD" ]; then
  FAIL "GJ5: MUST FIRE — a structural defect was not named by J0, or J1/J2 graded over it rather than withholding: $GJ5_BAD"
else
  PASS "GJ5: MUST FIRE — each of ${GJ5_N} structural defects (header renamed, header duplicated, a 5-cell row, a row with no prompt span, a prompt with 2 writer ids, a heading count off by one, the § 1.1 heading absent, an 8-cell class row) is named by J0 with its own cause, and each of the three assertions renders one FAIL and no PASS over it"
fi

# GJ6 and GJ7 — the two quoted-block shapes the list form exists to avoid, each named by its
# finding. A bare foreign writer gives the quoting prompt a second id (J0); a block with no writer
# is read as the quoting agent's own write (J1). The one-id list form itself is a GJ0 plant.
gj_fire J0 quotebare     '"zz-alpha zz-beta".*writer: \[<id>\]'                                                GJ6 'a prompt quotes the frontmatter of another agent with a bare writer, so it declares two ids — the finding names the list form'
gj_fire J1 quotenowriter '"Zz Alpha" does not name "outputs/zz-b.md".*in a block with no writer.*writer: \[<id>\]' GJ7 'a prompt quotes the frontmatter of another agent with no writer, so the quoted file reads as one the quoting agent writes — the finding names the list form'

# GJ8 — the heading limb. A file declared by an Output heading alone, with no frontmatter block
# and no § 1.1 class, is expected in its agent's row; the finding names the heading as its source.
gj_fire J1 headmiss '"Zz Alpha" does not name "outputs/zz-a3.md".*the Output heading agents/zz-alpha.md:[0-9]+' GJ8 'a row omits a file its prompt declares only in an Output heading'

# GJ9 — J1 NAMES THE /trip research KEY COUPLING, AND ONLY WHERE IT HOLDS. A row naming exactly one
# outputs/ path is what that verb's agent key admits a spoke by, so J1's remedy would take the spoke
# out of the key: each finding on such a row says so. On a row naming two such paths it must not.
GJR1="$(roster_write_check "$GJ/onespan")"; gj_counts "$GJR1"
GJR1_J1="$GJ_N1"; GJR1_OTHER=$(( GJ_N0 + GJ_N2 ))
GJR1_NOTE="$(grep -c -E '^FINDING J1 .*"Zz Beta" .*exactly one path under outputs/.*/trip research' <<<"$GJR1")"
GJR2="$(roster_write_check "$GJ/rowmiss")"; gj_counts "$GJR2"
GJR2_J1="$GJ_N1"
GJR2_NOTE="$(grep -c -E '^FINDING J1 .*/trip research' <<<"$GJR2")"
GJR_VT="$(gj_tally rj_assert_named "$GJ/onespan")"
GJR_INT=$(( $(grep -c -F '| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md` | always |' "$GJ/onespan/CLAUDE.md") \
          + $(grep -c -F '| Zz Beta | `agents/zz-beta.md` | `outputs/zz-b.md`, `outputs/zz-b-sections.md` (its sections) | always |' "$GJ/rowmiss/CLAUDE.md") ))
arm J1
if [ "$GJR_INT" -ne 2 ]; then
  FAIL "GJ9: fixture integrity — the one-path row and the two-path row were not both built, so neither direction below is a measurement"
elif [ "$GJR_VT" != '0 1' ] || [ "$GJR1_J1" -ne 2 ] || [ "$GJR1_OTHER" -ne 0 ]; then
  FAIL "GJ9: MUST FIRE — over the one-path row J1 raised ${GJR1_J1} finding(s) where 2 are required and other ids ${GJR1_OTHER}, and the J1 assertion rendered '${GJR_VT}' where '0 1' is required"; show "$GJR1" 'J0|J1|J2'
elif [ "$GJR1_NOTE" -ne 2 ]; then
  FAIL "GJ9: MUST FIRE — ${GJR1_NOTE} of the 2 J1 findings on a row naming exactly one outputs/ path name the /trip research key coupling; each must, because naming the file takes that spoke out of the key"; show "$GJR1" 'J1'
elif [ "$GJR2_J1" -ne 1 ] || [ "$GJR2_NOTE" -ne 0 ]; then
  FAIL "GJ9: MUST NOT FIRE — over a row naming two outputs/ paths J1 raised ${GJR2_J1} finding(s), ${GJR2_NOTE} of them naming the /trip research key coupling; that row is outside the key, so the note would mislead"; show "$GJR2" 'J1'
else
  PASS "GJ9: J1 NAMES THE RESEARCH-KEY COUPLING WHERE IT HOLDS — over a row naming exactly one outputs/ path, both J1 findings name the one-path rule /trip research's agent key admits a spoke by, and the J1 assertion renders one FAIL and no PASS; over a row naming two such paths, its one J1 finding does not"
fi

# ── ONE MUST-FIRE WORLD PER READER BRANCH. GJ0 to GJ9 were built one per ratified fix, so two of
# the heading limb's three forms and the writer list's split had no world in which removing the
# branch leaves a written file unexpected. The Pre-Work heading stands only in GJ0's conforming
# world, on a file other sources already expect; the File heading stands there only indented,
# as one the reader must not read; and every list there that names the reading prompt's own id
# names it last, after a comma and a space. Each world below declares one file by one branch
# and nowhere else. Its arm first reads that fact back from the built files, then requires
# exactly one J1 finding naming the row, the file and that one source — the source in its
# parentheses, so no second source can ride along. GJN, last, holds the research-key note's
# zero end.

# gj_mentions <world> <literal> -> how many lines of the world's charter, architecture document
# and prompts name <literal>, so an integrity limb can require that a file is declared on one
# line alone.
gj_mentions() {
  local n=0 c f
  for f in "$GJ/$1/CLAUDE.md" "$GJ/$1/$RJ_ARCH_REL" "$GJ/$1"/agents/*.md; do
    c="$(grep -c -F -- "$2" "$f" 2>/dev/null)"; n=$((n+${c:-0}))
  done
  printf '%d' "$n"
}

# gj_fire_int <read> <built> <what> <id> <world> <want> <arm-id> <prose> — gj_fire behind a
# fixture-integrity limb. <read> is the world's integrity figures as read from the built files,
# <built> the same figures as the generator builds them, each in the order <what> names. A world
# that does not carry them renders one FAIL, and no finding is read over it.
gj_fire_int() {
  local got="$1" need="$2" what="$3"; shift 3
  if [ "$got" != "$need" ]; then
    arm "$1"
    FAIL "$4: fixture integrity — the $2 world reads '${got}' where '${need}' is built (${what}), so a verdict over it would not measure the branch it names"
  else
    gj_fire "$@"
  fi
}

# GJF and GJP — the heading limb's other two forms, each alone. The Pre-Work form names its
# file bare, and the finding names it under outputs/.
GJF_INT="$(grep -c -x -F '### File: outputs/zz-f.md' "$GJ/headfile/agents/zz-alpha.md") $(gj_mentions headfile 'zz-f.md')"
gj_fire_int "$GJF_INT" '1 1' 'the File heading line; the lines naming zz-f.md in the world' \
  J1 headfile '"Zz Alpha" does not name "outputs/zz-f.md", which that agent writes \(the Output heading agents/zz-alpha.md:[0123456789]+\)' \
  GJF 'a row omits a file its prompt declares only in a File heading, "### File: <path>"'
GJP_INT="$(grep -c -x -F '### Pre-Work Output 2: zz-p.md' "$GJ/headpre/agents/zz-alpha.md") $(gj_mentions headpre 'zz-p.md')"
gj_fire_int "$GJP_INT" '1 1' 'the Pre-Work heading line; the lines naming zz-p.md in the world' \
  J1 headpre '"Zz Alpha" does not name "outputs/zz-p.md", which that agent writes \(the Output heading agents/zz-alpha.md:[0123456789]+\)' \
  GJP 'a row omits a file its prompt declares only in a Pre-Work heading, "### Pre-Work Output <N>: <file>", which names the file bare'

# GJW and GJC — a block whose writer list names the prompt's own id first. The list is split on
# its commas, so the id is a member wherever it stands in the list; GJC writes the list with no
# space after the comma. zz-beta.md's section-owned block carries GJW's list, its own id last.
GJW_INT="$(grep -c -x -F 'writer: [zz-alpha, zz-beta]' "$GJ/listfirst/agents/zz-alpha.md") $(grep -c -x -F 'artifact: outputs/zz-l.md' "$GJ/listfirst/agents/zz-alpha.md") $(gj_mentions listfirst 'zz-l.md')"
gj_fire_int "$GJW_INT" '1 1 1' 'the writer list line; the artifact line; the lines naming zz-l.md in the world' \
  J1 listfirst '"Zz Alpha" does not name "outputs/zz-l.md", which that agent writes \(the frontmatter agents/zz-alpha.md emits\)' \
  GJW 'a row omits a file its prompt declares only in a block whose writer list names that prompt first, writer: [zz-alpha, zz-beta]'
GJC_INT="$(grep -c -x -F 'writer: [zz-alpha,zz-beta]' "$GJ/listnospace/agents/zz-alpha.md") $(grep -c -x -F 'artifact: outputs/zz-l.md' "$GJ/listnospace/agents/zz-alpha.md") $(gj_mentions listnospace 'zz-l.md')"
gj_fire_int "$GJC_INT" '1 1 1' 'the writer list line; the artifact line; the lines naming zz-l.md in the world' \
  J1 listnospace '"Zz Alpha" does not name "outputs/zz-l.md", which that agent writes \(the frontmatter agents/zz-alpha.md emits\)' \
  GJC 'the same, its writer list written with no space after the comma, writer: [zz-alpha,zz-beta]'

# GJN — the research-key note's zero end. A third agent's row names no outputs/ path and omits
# the one file its class and its prompt assign it. J1 names the file, and the finding carries no
# note: the one-path rule the note states does not hold of a row naming none. The pattern ends
# with '$', at the last words of J1's own text, so a note appended to the finding moves the end
# of the line and the match fails; GJ9 holds the note's one-path and two-path cases.
GJN_INT="$(grep -c -x -F '| Zz Zero | `agents/zz-zero.md` | `trip-context.md` (the block it seeds) | always |' "$GJ/zerospan/CLAUDE.md") $(gj_mentions zerospan 'zz-z.md') $(grep -c -F 'zz-z.md' "$GJ/zerospan/CLAUDE.md")"
gj_fire_int "$GJN_INT" '1 2 0' 'the row naming no outputs/ path; the lines naming zz-z.md in the world, its class and its prompt; those in the charter' \
  J1 zerospan '"Zz Zero" does not name "outputs/zz-z.md", which that agent writes \(.* C8; the frontmatter agents/zz-zero.md emits\).* the whole content of a code span$' \
  GJN 'a row naming no outputs/ path omits the one file its agent writes, and the finding carries no /trip research key note, which holds only of a row naming exactly one'

# GJV — VACUITY and DEGRADATION: an empty roster, an empty class table, an unreadable prompt,
# and a root carrying neither input. Each assertion renders exactly one FAIL and no PASS.
mkdir -p "$GJ/empty"
GJV_BAD=''; GJV_N=0
for gjw in norows noclasses dangling empty; do
  for gjf in rj_assert_population rj_assert_named rj_assert_join; do
    GJV_N=$((GJV_N+1)); gjt="$(gj_tally "$gjf" "$GJ/$gjw")"
    [ "$gjt" = '0 1' ] || GJV_BAD="$GJV_BAD$gjw/$gjf=$gjt "
  done
  gjdg="$(getcount "$(roster_write_check "$GJ/$gjw")" J_DEGRADED)"
  case "$gjw" in dangling|empty) [ "${gjdg:-0}" -ge 1 ] || GJV_BAD="$GJV_BAD$gjw/degraded=${gjdg:-0} " ;; *) [ "${gjdg:-0}" -eq 0 ] || GJV_BAD="$GJV_BAD$gjw/degraded=$gjdg " ;; esac
done
arm J0
if [ -n "$GJV_BAD" ]; then
  FAIL "GJV: a degenerate world reached a PASS, or rendered more than one verdict: $GJV_BAD"
else
  PASS "GJV: VACUITY and DEGRADATION — over an empty roster, an empty class table, an unreadable prompt and a root with neither input, each of the three assertions renders exactly one FAIL and no PASS (${GJV_N} of ${GJV_N} probes), and an unread input is counted DEGRADED — never read as empty — while an empty-but-read input is not"
fi

# gj_live <dir> — a byte copy of the three live inputs this group reads.
gj_live() {
  mkdir -p "$1/agents" "$1/reference"
  cp "$ROOT/CLAUDE.md" "$1/CLAUDE.md"; cp "$ROOT/$RJ_ARCH_REL" "$1/$RJ_ARCH_REL"
  cp "$ROOT"/agents/*.md "$1/agents/"
}

# GJL — MUST FIRE on the live roster: the traveller model is removed from a copy of the
# Enrichment row. The mutation is asserted to have landed before the verdict is read.
GJL="$WORK/gjl"; gj_live "$GJL"
GJL_BEFORE="$(grep -c -F '`outputs/traveler-model.md`' "$GJL/CLAUDE.md")"
sed 's/^\(| Enrichment |.*\)`outputs\/traveler-model\.md`/\1outputs\/traveler-model.md/' "$GJL/CLAUDE.md" > "$GJL/CLAUDE.md.new" && mv "$GJL/CLAUDE.md.new" "$GJL/CLAUDE.md"
GJL_AFTER="$(grep -c -F '`outputs/traveler-model.md`' "$GJL/CLAUDE.md")"
GJL_DIFF="$(diff "$ROOT/CLAUDE.md" "$GJL/CLAUDE.md" | grep -c '^>')"
GJL_OUT="$(roster_write_check "$GJL")"; gj_counts "$GJL_OUT"
GJL_HIT="$(grep -c -E '^FINDING J1 .*"Enrichment" does not name "outputs/traveler-model.md".*§ 1.1 C[0-9]+; the frontmatter agents/00-enrichment.md emits' <<<"$GJL_OUT")"
arm J1
if [ "$GJL_DIFF" -ne 1 ] || [ "$GJL_AFTER" -ne $((GJL_BEFORE-1)) ]; then
  FAIL "GJL: fixture integrity — the span was not removed from exactly one line of the Enrichment row (lines changed: ${GJL_DIFF}; spans ${GJL_BEFORE} -> ${GJL_AFTER}), so this arm has no defect to detect"
elif [ "$GJ_N1" -ne 1 ] || [ "$GJL_HIT" -ne 1 ] || [ "$GJ_N0" -ne 0 ] || [ "$GJ_N2" -ne 0 ]; then
  FAIL "GJL: MUST FIRE — with the traveller model removed from the live Enrichment row the check reported J1=${GJ_N1} (matching: ${GJL_HIT}), J0=${GJ_N0}, J2=${GJ_N2}"; show "$GJL_OUT" 'J0|J1|J2'
else
  PASS "GJL: MUST FIRE on the live inputs — the traveller model removed from a copy of the Enrichment row is named by exactly one J1 finding, from both sources (§ 1.1's writer column and the frontmatter agents/00-enrichment.md emits); the copy differs from the tree in that one line"
fi

# GJD — DERIVATION: one agent, its prompt and its class added to a live copy. The population
# grows by exactly what was added and no finding appears — so nothing here is a held list.
GJD="$WORK/gjd"; gj_live "$GJD"
GJD_BASE="$(roster_write_check "$ROOT")"
sed 's/^\(| Validator | .*\)$/\1\
| Zz Derived | `agents\/zz-derived.md` | `outputs\/zz-derived.md` | never |/' "$GJD/CLAUDE.md" > "$GJD/CLAUDE.md.new" && mv "$GJD/CLAUDE.md.new" "$GJD/CLAUDE.md"
printf '## Output\n\n```yaml\n---\nartifact: outputs/zz-derived.md\nwriter: zz-derived\n---\n```\n' > "$GJD/agents/zz-derived.md"
gjn="$(getcount "$GJD_BASE" J_DECLARED)"
sed -e "s/^\(### 1\.1 .*\)(${gjn})\$/\1($((gjn+1)))/" \
    -e "/^### 1\.1 /,/^### 1\.2 /s/^\(| ${gjn} | .*\)\$/\1\\
| $((gjn+1)) | \`outputs\/zz-derived.md\` | zz-derived | \`rebuilt-each-synthesis\` | \`derived\` | \`internal\` | Venue |/" \
    "$GJD/$RJ_ARCH_REL" > "$GJD/arch.new" && mv "$GJD/arch.new" "$GJD/$RJ_ARCH_REL"
GJD_OUT="$(roster_write_check "$GJD")"; gj_counts "$GJD_OUT"
GJD_DR=$(( $(getcount "$GJD_OUT" J_ROWS) - $(getcount "$GJD_BASE" J_ROWS) ))
GJD_DC=$(( $(getcount "$GJD_OUT" J_CLASSES) - $(getcount "$GJD_BASE" J_CLASSES) ))
GJD_DE=$(( $(getcount "$GJD_OUT" J_EXPECTED) - $(getcount "$GJD_BASE" J_EXPECTED) ))
GJD_BN=$(( $(grep -c '^FINDING J' <<<"$GJD_BASE") ))
if [ "$(grep -c 'zz-derived' "$GJD/CLAUDE.md")" -ne 1 ] || [ "$(grep -c 'zz-derived' "$GJD/$RJ_ARCH_REL")" -ne 1 ]; then
  FAIL "GJD: fixture integrity — the added agent did not land in both the roster and § 1.1 copies"
elif [ "$GJD_DR" -ne 1 ] || [ "$GJD_DC" -ne 1 ] || [ "$GJD_DE" -ne 1 ]; then
  FAIL "GJD: DERIVATION — adding one agent, prompt and class moved rows by ${GJD_DR}, classes by ${GJD_DC} and expected pairs by ${GJD_DE}; each must move by exactly 1"
elif [ "$(( GJ_N0 + GJ_N1 + GJ_N2 ))" -ne "$GJD_BN" ]; then
  FAIL "GJD: the added agent changed the finding count ($GJD_BN on the tree, $(( GJ_N0 + GJ_N1 + GJ_N2 )) with the addition) — a conforming addition must raise nothing"; show "$GJD_OUT" 'J0|J1|J2'
else
  PASS "GJD: DERIVATION — one agent, its prompt and its class added to a copy of the live inputs move the roster rows, the class rows and the expected pairs by exactly 1 each and raise nothing. The population is read from the tree; none of it is held here"
fi

arm N1
NEEDLES_SAVE=( "${NEEDLES[@]}" )
NEEDLES+=( 'trailing ' )
if grep -q '^FINDING N1 ' <<<"$(needle_check)"; then
  PASS "GN1: flagged, naming N1 — a needle that does not survive the haystack's normalisation, and is not registered UNTRIMMED, is a build error rather than a silent non-match"
else FAIL "GN1: a needle failing norm(needle) == needle was NOT flagged"; fi
NEEDLES=( "${NEEDLES_SAVE[@]}" )

# ── the grammar control: the minimal widening admits junk the alternation rejects.
# The two list sizes are COUNTED as the lists are walked, never spelled in the message: a
# literal there is a frozen denominator that drifts silently the moment a form is added.
GRAM_OK=1; GRAM_TRUE=0
for gc in "${BT}/trip status${BT}" "${BT}/trip-record .publish-slug${BT}" "${BT}/trip-decommission --archive${BT}" "${BT}/trip-new${BT}" "${BT}/trip-publish list${BT}" "${BT}/trip-record .a-b${BT}"; do
  GRAM_TRUE=$((GRAM_TRUE+1))
  [[ "$gc" =~ $CELL_RE ]] || GRAM_OK=0
done
GRAM_BAD=0; GRAM_MAL=0
# The last two are the SET-SHAPED cells, and they belong in the MALFORMED list rather than
# the true one. That is the whole proof that the grammar was extended by a new CLASS and not
# widened: CELL_RE is shared with adr4_check, whose §4 column contract is one form -> one
# key, so a grammar that admitted either of these would silently re-grade that table too.
for gc in "${BT}/trip <verb>${BT}" "${BT}/trip-new new (create)${BT}" "${BT}/Trip status${BT}" "${BT}trip status${BT}" "${BT}/trip status extra${BT}" "${BT}/trip_status${BT}" "${BT}/trip -status${BT}" "${BT}/trip-record .${BT}" "${AMB_MARK}${BT}/trip status${BT}${AMB_SEP}${BT}/trip check${BT}" "${BT}/trip status${BT}${AMB_SEP}${BT}/trip check${BT}"; do
  GRAM_MAL=$((GRAM_MAL+1))
  [[ "$gc" =~ $CELL_RE ]] && GRAM_BAD=$((GRAM_BAD+1))
done
MIN_ADMITS_JUNK=0
[[ "${BT}/trip --.x${BT}" =~ $CELL_RE_MINIMAL ]] && MIN_ADMITS_JUNK=1
ALT_REJECTS_JUNK=1
[[ "${BT}/trip --.x${BT}" =~ $CELL_RE ]] && ALT_REJECTS_JUNK=0
if [ "$GRAM_OK" -eq 1 ] && [ "$GRAM_BAD" -eq 0 ] && [ "$MIN_ADMITS_JUNK" -eq 1 ] && [ "$ALT_REJECTS_JUNK" -eq 1 ]; then
  PASS "G-GR: grammar control — ${GRAM_TRUE} true forms admitted, ${GRAM_MAL} malformed rejected, and the MINIMAL widening admits the junk cell the ALTERNATION rejects. A leading dot is part of an identity; a double dash is a spelling variant the key rule normalises away; the two can never co-occur, so the grammar must not express both at once. The malformed list includes BOTH set-shaped cells — marked and unmarked — so the single-target grammar is asserted UNCHANGED by the slice that admitted the set class: a set is parsed by its own classifier and its MEMBERS are what this regex grades"
else
  FAIL "G-GR: grammar control — true admitted=$GRAM_OK, malformed admitted=$GRAM_BAD, minimal admits junk=$MIN_ADMITS_JUNK, alternation rejects junk=$ALT_REJECTS_JUNK"
fi

# ── the DERIVATION mutation pair. This is the arm a green run on unchanged state cannot
# satisfy. Both arms, or neither: a guard that failed on ANY change would pass the red
# arm while proving nothing, so the green arm is load-bearing. Both trees are BUILT from
# tuples — the rename is a different tuple table, never a patch over a generated file.
GM1="$WORK/gm1"; gen_tree "$GM1" ok  ok "${WORLD_MUT[@]}"
GM2="$WORK/gm2"; gen_tree "$GM2" mut ok "${WORLD_MUT[@]}"
if grep -q "checkx" "$GM1/skills/trip/SKILL.md" && ! grep -q "checkx" "$GM1/CLAUDE.md" \
   && grep -q "checkx" "$GM2/skills/trip/SKILL.md" && grep -q "checkx" "$GM2/CLAUDE.md"; then
  PASS "GM-a: fixture integrity — one tree carries the rename in the command file ONLY; the other carries the same rename on BOTH surfaces"
  M1="$(run_tree "$GM1")"; M2="$(run_tree "$GM2")"
  if grep -q '^FINDING ' <<<"$M1" && grep -q 'checkx' <<<"$M1"; then
    PASS "GM-b: RED ARM — a verb renamed in a command file with the charter untouched turns the guard red and NAMES the affected key. The verb population is DERIVED, not remembered"
  else
    FAIL "GM-b: RED ARM — a one-sided rename did NOT turn the guard red, or did not name the affected key: $(printf '%s' "$M1" | grep '^FINDING ' | head -1)"
  fi
  if grep -q '^FINDING ' <<<"$M2"; then
    FAIL "GM-c: GREEN ARM — the same rename applied to BOTH surfaces was still flagged, so the red arm proves only that the guard dislikes change: $(printf '%s' "$M2" | grep '^FINDING ' | head -3 | tr '\n' ' ')"
  else
    PASS "GM-c: GREEN ARM — the same rename applied to BOTH surfaces stays green. Both arms, or neither: a green run on unchanged state does not satisfy this control; only the pair does"
  fi
else
  FAIL "GM-a: fixture integrity — the mutation pair was not constructed; GM-b and GM-c would prove nothing"
fi

# ── the ZERO-VERB world. The banner argues that at zero declared verbs every coverage
# unit is a command, every cell is verbless, and K1/K2/K3 collapse TERM FOR TERM into the
# retired forward / reverse / injectivity. That argument was the slice's central claim and
# was ASSERTED NOWHERE IN CODE: no arm built the world it describes. The same world is
# also the only one that reaches V0's ZERO-ROWS clause — both existing V0 arms (GV0,
# GV0b) drive the ANCHOR site instead, so the clause the collapse argument turns on was
# armed by nothing. This arm does both jobs on one constructed world: a charter whose
# Step-1 cells are all verbless, against command files that keep the requirement-table
# header row and declare no rows under it.
GZV="$WORK/gzv"; gen_tree "$GZV" verbless norows
arm V0
ZV_FILES=0; ZV_OK=1
for gf in "$GZV/skills"/*/SKILL.md; do
  [ -e "$gf" ] || continue
  ZV_FILES=$((ZV_FILES+1))
  grep -qF '| verb | lifecycle | mode | destination | depth |' "$gf" || ZV_OK=0
  # a data row is the one shape gen_cmd renders for a declared verb; its absence is the
  # defect, so it is probed as an absence rather than assumed from the generator argument
  grep -qF '| ACTIVE | any | any | G8 |' "$gf" && ZV_OK=0
done
if [ "$ZV_FILES" -gt 0 ] && [ "$ZV_OK" -eq 1 ]; then
  PASS "GZV-a: fixture integrity — the ZERO-VERB world was constructed: ${ZV_FILES} command files, each carrying a requirement-table header row at fence depth 0 and no data row beneath it"
  ZVOUT="$(run_tree "$GZV")"
  if grep -q '^FINDING V0 .*carries no data rows' <<<"$ZVOUT"; then
    PASS "GZV-b: flagged, naming V0 — the ZERO-ROWS clause fires. This is the emission site neither other V0 arm reaches: GV0 removes the table and GV0b duplicates its header row, so both land on the ANCHOR clause and this one was armed by nothing"
  else
    FAIL "GZV-b: a world of requirement tables with no data rows did NOT raise V0's zero-rows clause"
  fi
  ZV_UNITS="$(getcount "$ZVOUT" UNITS)"
  if ! grep -q '^DECL ' <<<"$ZVOUT" && [ "${ZV_UNITS:-0}" -eq "$ZV_FILES" ]; then
    PASS "GZV-c: COLLAPSE — the record stream carries no declaration at all, and the coverage-unit enumeration is ${ZV_UNITS} units across ${ZV_FILES} command files. Every unit therefore came from the verbless fallback and every unit is a COMMAND, so K1/K2/K3 quantify over commands and are the retired forward / reverse / injectivity term for term. DEMONSTRATED on a constructed world, not argued in a comment"
  else
    FAIL "GZV-c: COLLAPSE — the zero-verb world yielded ${ZV_UNITS:-?} coverage units across ${ZV_FILES} command files, or the stream still carried a declaration; the degeneracy argument does not hold on it"
  fi
  if grep -q '^FINDING ' <<<"$ZVOUT"; then
    PASS "GZV-d: REACHABILITY — that same world is RED. The verbless fallback contributes coverage units only on a run that is already failing, which is what the banner now states in place of the retired claim that the branch is reachable where a file 'legitimately declares a table with no rows'. There is no such legitimate state: the zero-rows clause forbids it"
  else
    FAIL "GZV-d: REACHABILITY — the zero-verb world returned no finding, so the fallback CAN execute on a green run and the banner's reachability statement is false"
  fi
else
  FAIL "GZV-a: fixture integrity — the ZERO-VERB world was not constructed (${ZV_FILES} file(s), shape ok=${ZV_OK}); GZV-b through GZV-d would prove nothing"
fi

# ── a fresh specificity token, minted per run and never written into the repository.
# A published token stops being impossible.
TOKEN="tx$$$(date +%s)$RANDOM"
TOKHITS=0
for gp in "$MD" "$ADR" "$PUB" "$SELF"; do
  [ -f "$gp" ] && grep -qF "$TOKEN" "$gp" && TOKHITS=$((TOKHITS+1))
done
for gp in "$CDIR"/*/SKILL.md; do
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
#
# WHAT PER-ID TOTALITY DOES AND DOES NOT ESTABLISH. The unit of this inventory is the
# finding ID, not the emission SITE. Several ids are emitted from more than one site with
# a different predicate behind each — V0 has an ANCHOR clause and a ZERO-ROWS clause, V1
# has a field-count clause and an empty-identity clause, V3 has a no-region clause and a
# many-regions clause — and an id counts as armed here the moment ONE of its sites is
# reached. So Y2 is a sound guarantee that NO ID IS UNREACHABLE. It is NOT a guarantee
# that every predicate is exercised, and it must not be read as one. That gap is not
# hypothetical: the site the collapse argument turns on — V0's ZERO-ROWS clause — sat
# unarmed under a green Y2 until arm GZV was added, because both V0 arms drive the anchor
# site. The unarmed-SITE population is strictly larger than the unarmed-ID population and
# this guard does not measure it. The granularity is a property of the CRITERION this
# inventory implements, not a defect in the implementation of it; stated here rather than
# left to be inferred from a green.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group Y — the assertion inventory, derived from this file and checked in both directions."
EMIT_MARK="printf ${Q}FIND""ING "
# The three populations are ARRAYS, and every membership test below passes its haystack
# as a quoted array expansion. They were space-joined strings tested through an UNQUOTED
# word-split haystack — the exact transport parse_command_file's header note describes as
# failing in both directions once a member can carry a space. The ids here happen not to,
# so nothing was misreported; the inventory group nonetheless ran on the one transport the
# rest of this guard exists to eliminate, which is not a difference worth keeping.
DECLARED=()
while IFS= read -r yline || [ -n "$yline" ]; do
  case "$yline" in
    *"$EMIT_MARK"*)
      yrest="${yline#*"$EMIT_MARK"}"
      yid="${yrest%% *}"
      [[ "$yid" =~ ^[A-Z][0-9]$ ]] || continue
      in_list "$yid" "${DECLARED[@]+"${DECLARED[@]}"}" || DECLARED+=( "$yid" )
      ;;
  esac
done < "$SELF"

SURFACED=(); ARMED=()
while IFS= read -r yid || [ -n "$yid" ]; do
  [ -n "$yid" ] && SURFACED+=( "$yid" )
done <<< "$(sort -u "$SURF_LOG")"
while IFS= read -r yid || [ -n "$yid" ]; do
  [ -n "$yid" ] && ARMED+=( "$yid" )
done <<< "$(sort -u "$ARM_LOG")"

y_ms=""; y_ma=""; y_es=""; y_ea=""
for yid in "${DECLARED[@]+"${DECLARED[@]}"}"; do
  in_list "$yid" "${SURFACED[@]+"${SURFACED[@]}"}" || y_ms="$y_ms$yid "
  in_list "$yid" "${ARMED[@]+"${ARMED[@]}"}"       || y_ma="$y_ma$yid "
done
for yid in "${SURFACED[@]+"${SURFACED[@]}"}"; do in_list "$yid" "${DECLARED[@]+"${DECLARED[@]}"}" || y_es="$y_es$yid "; done
for yid in "${ARMED[@]+"${ARMED[@]}"}";    do in_list "$yid" "${DECLARED[@]+"${DECLARED[@]}"}" || y_ea="$y_ea$yid "; done

NDECL=${#DECLARED[@]}
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
# Group PF — this file's own verdicts do not depend on process scheduling.
#
# A verdict site of the form `if <writer> pipes-into grep -q; then` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on
# first match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed
# although the match succeeded. Measured on an unchanged tree before it was fixed: 10 red
# runs in 30, across TWO arms (GR2 and GX1b) that share nothing but the shape.
#
# Why a standing arm rather than a comment: the two arms it was OBSERVED on are
# `if <test>; then PASS` sites, where the spurious status is a false RED and someone
# notices. has_finding()'s 31 call sites are inverted — `if has_finding …; then FAIL` —
# where the same status is a false GREEN on a state that carries the finding. The
# dangerous direction is the one nobody would see, so the shape is what is asserted
# absent, not the two places it happened to surface.
#
# The needle is assembled from two pieces for the same reason EMIT_MARK is: this scan
# reads THIS FILE, so a literal spelling of the shape in the detector would make the
# detector match itself and report a defect it just introduced.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group PF — no verdict in this file is decided by a pipeline's exit status."
PF_PIPE_SHAPE='| grep -'"q"
PF_PIPE_TIGHT='|grep -'"q"
PF_BAD=0; PF_GOOD=0
while IFS= read -r pfline || [ -n "$pfline" ]; do
  case "$pfline" in
    *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
  esac
  case "$pfline" in
    *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
  esac
done < "$SELF"
# Graded in the order that makes the zero mean something: a detector that finds no
# instance of the CORRECT form is broken, and its zero on the incorrect form would be a
# probe failure wearing a pass. Same rule as K3 and L4b — an empty input is broken, not
# clean.
if [ "$PF_GOOD" -eq 0 ]; then
  FAIL "PF1: the scan found 0 here-string grep -q sites in this file, so its zero on the pipeline shape proves nothing — the convention or the scan has moved, and neither verdict below is trustworthy"
elif [ "$PF_BAD" -eq 0 ]; then
  PASS "PF1: ${PF_GOOD} grep -q sites in this file, 0 of them pipelines — no verdict here can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
else
  FAIL "PF1: ${PF_BAD} verdict site(s) in this file pipe into grep -q under pipefail — grep -q exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead; it is a simple command, so pipefail has nothing to aggregate"
fi

# ═════════════════════════════════════════════════════════════════════════════════

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
# carries 33 of them — more than the suite where the defect was found. A guard installed only where the defect
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
#   31 of these are the SAME shape over the SAME subject — `if has_finding …; then
#   FAIL …` with the PASS on the else limb, where an absent has_finding exits 127 and
#   lands on the PASS. G0b and GM-c are here-string probes over a captured output: an
#   empty capture matches nothing and reads as a clean run.
MD_LEGACY='N1 A1 V1 V2 V3 V4 V5 B1 B2 B3 B4 K0 K1 K2 K3 S1 E1 E2 E3 E4 E5 F1 F2 F3 F4 F5 R2 H1 H2 H3 H4 G0b GM-c'

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

# ── REGISTERED WITH md_flips — group Q's three verdicts, the first assertions in this suite to be
# registered. They were written in the remediated form from the start, so they need no
# remediation first; and they sit here, after MD4 and MD5, so every MD[Q…] verdict stands on an
# oracle whose sensitivity and specificity were measured on this run. Each assertion calls
# grant_table_check itself, so removing that function removes the evidence the verdict reads.
#
# CLAUSE 6 OPT-OUT, DECLARED RATHER THAN LEFT SILENT: the verb files those assertions read are
# FILES, not functions, and cannot be `unset -f`. Their removal is a degenerate POPULATION, not a
# degenerate subject. COMPENSATING POSITIVE CONTROL: GQV builds two degenerate populations — an
# empty verb root, and a verb file that is a link to nothing — and requires exactly one FAIL and
# no PASS from each of the three; GQK builds a third, readable verb files that carry no grant
# table, and requires the same of Q0; GQ1 to GQ6, GQ8 and GQ9 plant each defect in a BUILT file
# and observe the flip by identifier.
#
# The declared residual in MD2 is still this suite's registration queue for every site written
# before the rule: registration requires such an assertion to be remediated first, because an
# oracle asked to certify a still-blind assertion turns the suite red for a defect it is
# reporting rather than causing, and every entry that leaves MD_LEGACY gains an MD[...] arm in
# the same edit.
md_flips grant_table_check 'Q0' gq_assert_anchor "$CDIR"
md_flips grant_table_check 'Q1' gq_assert_rows   "$CDIR"
md_flips grant_table_check 'Q2' gq_assert_grants "$CDIR"

# ── REGISTERED WITH md_flips — group J's three verdicts. Each assertion calls
# roster_write_check itself, so removing that function removes the evidence, and each verdict
# must then report exactly one FAIL and no PASS. Appended after group Q's registrations.
md_flips roster_write_check 'J0' rj_assert_population "$ROOT"
md_flips roster_write_check 'J1' rj_assert_named "$ROOT"
md_flips roster_write_check 'J2' rj_assert_join "$ROOT"

# Group Z — the guard mutates none of the surfaces it reads. The watch set is those
# surfaces plus the workflow that runs this guard — see tree_state for its derivation. It
# is NOT the whole tree, and the Z1 line states that scope rather than claiming a
# tree-wide property this comparison does not establish.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group Z — non-mutation over the watched surfaces."
STATE_AFTER="$(tree_state)"
if [ "$STATE_BEFORE" = "$STATE_AFTER" ]; then
  PASS "Z1: the ${WATCHED} watched surfaces are byte-identical before and after this run — the charter, ADR-007, the publish script, this guard, this slice's workflow, the command reference, the guided-entry carrier at the engine root, each verb file, the architecture document and each agent prompt — so every fixture was built under the temporary directory. SCOPE: the watch set is the surfaces this guard reads plus its own workflow, derived from the paths above; it is not the whole tree, and a write outside it is not observed here"
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
