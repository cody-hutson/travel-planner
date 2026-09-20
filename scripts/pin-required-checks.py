#!/usr/bin/env python3
"""Capture, write and assert the app-pinning of a branch's required status checks.

WHAT THIS IS FOR
    `main` requires nine status checks. Eight are bound ("pinned") to the GitHub
    Actions app through `app_id`; one -- `Personal-data gate` -- carries
    `app_id: null`, so a check run reporting that context NAME from any
    integration satisfies it. This tool pins the ninth, and proves that it pinned
    the right thing.

WHY A TOOL RATHER THAN A ONE-LINER
    Branch protection has no version history and no restore API. It is the only
    state in this repository that does not revert by commit SHA. The write is
    therefore wrapped in three properties a one-liner does not have.

    1. A CAPTURE PRECONDITION.
       The pre-change protection object is written to disk, read back off disk,
       and re-parsed BEFORE anything is written. If any part of that fails the
       tool refuses to write at all. Without the captured artifact the change is
       recoverable only from memory; with it, recovery is a single API call. That
       refusal is what earns the cheaper reversibility tier, so it is load-bearing
       rather than defensive decoration -- and `--self-test` asserts it (guard
       arms G0-G3 drive capture failures and require that ZERO writes were
       attempted) instead of leaving it to be read and believed.

    2. A DISCRIMINATING READ-BACK ASSERTION.
       "nine contexts, zero nulls" is satisfied by three separate WRONG end
       states: every context pinned to the WRONG app; `app_id` stored as the
       STRING "15368"; and one context silently RENAMED. All three read nine and
       zero. The assertion here is four conjuncts instead -- cardinality, exact
       set equality, zero-null, and a uniform integer pin -- and `--self-test`
       drives eleven degenerate inputs through it, each of which must fail, plus
       one correct input which must pass. It then removes each conjunct in turn
       and requires the arm that names it to flip to PASS, so no conjunct is
       carried as unfalsifiable decoration.

    3. A NARROW ENDPOINT.
       Writes address `.../protection/required_status_checks` only. The full
       `PUT .../protection` REPLACES the entire protection object, so a payload
       that simply omits `required_conversation_resolution` or
       `required_pull_request_reviews` silently resets it. Those fields are not
       parameters of the narrow endpoint, so that whole failure class is
       structurally out of reach rather than procedurally guarded. An internal
       invariant re-checks the method and the path at the point of every write.

MODES
    --self-test
        Offline. No network, no `gh`, no token, no repository. Runs the assertion
        matrix, the conjunct-removal matrix, and the orchestrator guard arms.
        This is the arm that makes the tool trustworthy before it is ever pointed
        at a live branch, and it is the arm to run in CI.

    --census [--root DIR]
        Offline. Set equality, in both directions, between the workflow jobs
        that declare `# gate-efficacy: posture=required` and the CONTEXT_ORDER
        declaration below. It answers the question a new suite's author is
        never asked -- does this job bind? -- at pull-request time, on the
        author's own pull request.

        WHAT A CLEAN CENSUS DOES NOT ESTABLISH: `GITHUB_TOKEN` cannot read the
        branch protection API, so no check running in this repository's CI can
        confirm that a context is REGISTERED. A clean census means the
        committed declaration agrees with the context this reader READ for
        each job -- one line of text, which is not always the context GitHub
        reports, as the limit block states. Registration remains an operator
        act outside any pull request -- it is what --apply below performs. The
        census makes an omission visible; it cannot make one impossible.

        WHICH FORMS IT CAN READ is a separate limit from the one above, and it
        is stated in full in the limit block the census prints on EVERY exit
        path -- which key presentations are refused rather than missed, which
        files the parsers measured accept are refused as well, and the classes
        measured so far that still escape both the reader and its own refusal,
        given as instances rather than as a counted list. It is not restated
        here.

        Exit 0 clean / 1 finding(s) / 2 REFUSED -- no job this reader could
        read in any workflow file, or a workflow file this reader cannot vouch
        it read in full: it yielded no record read off a job key at the
        shallowest indentation in its `jobs:` block, or it carries a line there
        that this reader does not recognise as a `key:` line, or its `jobs:`
        block does not begin on the first line it read a job off. The limbs
        refuse some files that both parsers measured accept -- a job
        property's value continued at that indentation, or shallower, is no
        key, but this reader cannot tell it from one it cannot read; and a tag
        or an anchor written on a line of its own, or a bracket of a flow
        mapping, that opens the block ahead of its first key is no key either
        -- and each false refusal is accepted because it fails closed.

    --assert --stdin | --assert --file PATH
        The four-conjunct assertion alone, over a protection object or over a
        `required_status_checks` sub-resource. Exit 0 PASS / 1 FAIL / 2 malformed.

    --plan --staging DIR
        Capture, drift-check, and compose both the write payload and the restore
        payload. Stops BEFORE the write. Read-only against the API.

    --apply --staging DIR --confirm-write
        The full sequence: self-test, capture, drift-check, compose, write,
        fresh read-back assert, and a scope-containment diff of the full
        protection object. `--confirm-write` is mandatory: without it `--apply`
        runs every step up to the write and then stops, so the dangerous mode
        cannot be reached by a typo or a stale shell-history line.

    --restore --staging DIR --confirm-write
        Rollback. Re-applies the captured pre-change sub-resource verbatim,
        `app_id: null` included.

EXIT CODES
    0  the mode's assertion held
    1  an assertion failed
    2  input was malformed or refused (a read that returned a shape with no
       checks array; for --census, a workflow population in which this reader
       found no job it could read, or a workflow file this reader cannot vouch
       it read in full -- it yielded no record read off a job key at the
       shallowest indentation in its `jobs:` block, or it carries a line there
       that this reader does not recognise as a `key:` line, a job property's
       value continued there included, or its `jobs:` block does not begin on
       the first line it read a job off, a block that opens on a tag or an
       anchor line, or on a bracket of a flow mapping, included. "I cannot
       vouch I read this file" is a refusal, never a finding, so it never
       shares exit 1)
    3  CAPTURE REFUSED -- no rollback artifact, so nothing was written
    4  the live required-context set has drifted from the expected set
    5  the self-test did not pass, so no live mode may run
    6  a write was required but `--confirm-write` was not given (nothing written)
    7  the write itself, or its read-back, failed at the transport layer

STAGING DIRECTORY
    Pass `--staging <dir>`; the tool writes `<dir>/prot-PRE.json`,
    `<dir>/rsc-PRE.json`, `<dir>/rsc-PATCH.json`, `<dir>/rsc-RESTORE.json` and,
    after a write, `<dir>/prot-POST.json`. No path is compiled in, so the
    artifacts land wherever the operator keeps them -- deliberately NOT in this
    repository, which is public and where a protection snapshot would both
    disclose configuration and rot as corpus.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

# --------------------------------------------------------------------------
# The expected end state.
#
# CONTEXT_ORDER is the required-context set this tool is written against. It is
# a constant ON PURPOSE: the write payload is composed from a LIVE read, but the
# assertion is graded against a set that was established deliberately. If the
# live set drifts -- a tenth check added, one retired -- the drift guard aborts
# rather than pinning whatever happens to be there, because a set that changed
# is a set someone has to look at. SECURITY.md's Branch Protection Posture
# record states the same nine; the two move together or neither moves.
# --------------------------------------------------------------------------
APP_ID = 15368

CONTEXT_ORDER = (
    "Workflow SAST (actionlint)",
    "Markdown link integrity (markdown-link-check)",
    "Secret scanning (gitleaks)",
    "Personal-data gate",
    "Publish guard suite (test-publish-guard.sh)",
    "Artifact schema suite (test-artifact-schema.sh)",
    "Command taxonomy suite (test-command-taxonomy.sh)",
    "Trip resolution contract suite (test-trip-resolution-contract.sh)",
    "Corpus hygiene suite (test-corpus-hygiene.sh)",
)
EXPECTED_CONTEXTS = frozenset(CONTEXT_ORDER)
EXPECTED_COUNT = len(CONTEXT_ORDER)

# Every conjunct the evaluator can emit. The self-test asserts a bijection
# between this set and the set of conjuncts the arms name, in both directions,
# so a conjunct added later arrives UNCOVERED and red rather than silently
# untested, and an arm cannot name a conjunct the evaluator never emits.
EMITTABLE = ("C0", "C1", "C2", "C2b", "C3", "C4")

SUBRESOURCE_SUFFIX = "/protection/required_status_checks"


# ==========================================================================
# The assertion
# ==========================================================================

def evaluate(raw, disabled=frozenset()):
    """Grade a read against the four conjuncts.

    `raw` is the TEXT of a read, not a parsed object, so parsing is inside the
    assertion: a `gh` invocation that errors prints nothing, and nothing must
    reach a failure rather than a plausible pass.

    `disabled` removes named conjuncts. It exists for the self-test's
    conjunct-removal matrix and has no caller in any live mode. C0 is NOT
    removable: it is the structural precondition that makes the others
    evaluable at all, and a "PASS" reached by suppressing it would be a pass
    over a read that never happened.

    Returns (rc, failed_ids, lines).
      rc 0 = PASS, 1 = a conjunct failed, 2 = malformed (C0).
    """
    lines = []

    def c0(msg):
        lines.append("FAIL C0 " + msg)
        return (2, ["C0"], lines)

    try:
        doc = json.loads(raw) if isinstance(raw, str) else raw
    except Exception as exc:                       # noqa: BLE001 - any parse error
        return c0("malformed-json: {}".format(exc))

    if not isinstance(doc, dict):
        return c0("read is not a JSON object")

    # Accept the full protection object OR the sub-resource, so the same
    # assertion grades both captures without a second code path.
    rsc = doc.get("required_status_checks", doc)
    if not isinstance(rsc, dict) or "checks" not in rsc:
        return c0("no-'checks'-key: the read returned a shape with no checks array")

    checks = rsc["checks"]
    if not isinstance(checks, list):
        return c0("checks-not-a-list: got {}".format(type(checks).__name__))

    entries = [c if isinstance(c, dict) else {} for c in checks]
    names = [c.get("context") for c in entries]
    apps = [c.get("app_id") for c in entries]
    got = set(names)
    failed = []

    # C1 cardinality. Kills the empty-haystack path: `{"checks": []}` is the
    # shape a failed or filtered read produces, and it must never reach PASS.
    if "C1" not in disabled and len(entries) != EXPECTED_COUNT:
        failed.append("C1")
        lines.append("FAIL C1 cardinality: want {} checks, got {}".format(
            EXPECTED_COUNT, len(entries)))

    # C2 exact set equality. Kills rename, drop-and-add, and typo.
    if "C2" not in disabled and got != EXPECTED_CONTEXTS:
        failed.append("C2")
        lines.append("FAIL C2 context-set: missing={} unexpected={}".format(
            sorted(EXPECTED_CONTEXTS - got), sorted(got - EXPECTED_CONTEXTS)))

    # C2b no duplicates. A duplicated context can hold cardinality at nine while
    # a real required check has gone missing.
    if "C2b" not in disabled and len(names) != len(got):
        failed.append("C2b")
        lines.append("FAIL C2b duplicate contexts: {} entries, {} distinct".format(
            len(names), len(got)))

    # C3 zero-null. The defect itself.
    if "C3" not in disabled:
        nulls = [n for n, a in zip(names, apps) if a is None]
        if nulls:
            failed.append("C3")
            lines.append("FAIL C3 unpinned: {} context(s) with app_id null -> {}".format(
                len(nulls), nulls))

    # C4 uniform integer pin. Kills wrong-app and string-typed. `isinstance(a, int)`
    # excludes bool explicitly, because bool is a subclass of int in Python and
    # `True == 1` would otherwise be admitted by an equality test alone.
    if "C4" not in disabled:
        bad = [(n, a) for n, a in zip(names, apps)
               if isinstance(a, bool) or not isinstance(a, int) or a != APP_ID]
        if bad:
            failed.append("C4")
            lines.append("FAIL C4 app_id is not int {}: {}".format(APP_ID, bad))

    if failed:
        return (1, failed, lines)

    lines.append(
        "PASS {n}/{n} contexts, set-equal to the expected {n}, no duplicates, "
        "0 null, every app_id == int {a}".format(n=EXPECTED_COUNT, a=APP_ID))
    return (0, [], lines)


# ==========================================================================
# The registration census
#
# A second, independent assertion over the same expected set -- and the only
# one that runs with no token at all.
#
# It answers the question a new suite's author never gets asked: "does this
# job bind?" A job declares its own answer in place, on the line above its
# key, and the census set-compares the jobs claiming `required` against
# CONTEXT_ORDER in both directions. The declaration is the census's only
# input; there is no inference from triggers, filenames or membership, because
# each of those is either false by construction or vacuous -- a set derived
# from CONTEXT_ORDER can never disagree with it.
#
# WHAT A GREEN CENSUS DOES NOT MEAN. `GITHUB_TOKEN` cannot read the branch
# protection API, so no check running in this repository's CI can confirm that
# a context is REGISTERED. A clean census means the committed declaration
# agrees with the context this reader READ for each job, which is one line of
# text and not always the context GitHub reports -- the limit block names how
# the two can differ. Registration remains an operator act outside any pull
# request, performed by --apply above. The census makes an omission visible at
# pull-request time; it cannot make one impossible.
# ==========================================================================

POSTURE_VALUES = ("required", "advisory")

# The census's own emittable set. The self-test asserts a bijection between it
# and the codes the arms name, in both directions, on the same principle as
# EMITTABLE above: a code added later arrives uncovered and red.
CENSUS_CODES = ("UNREGISTERED", "ABSENT", "UNDECLARED")

_RE_MARKER = re.compile(r"^(\s*)#\s*gate-efficacy:\s*posture\s*=\s*(\S+)")
_RE_JOBS = re.compile(r"^jobs:\s*(#.*)?$")
# An OPTIONALLY-QUOTED key, with a matched-quote backreference. It covers the
# forms this repository writes and it is NOT exhaustive over the legal domain --
# a claim that stood here until it was measured and fell. The charset argument
# behind it (a job ID is [A-Za-z0-9_-], so no legal ID carries a quoting escape)
# is true about the VALUE and says nothing about its PRESENTATION: a YAML
# double-quoted scalar may escape any character whether or not it needs to, and
# YAML permits whitespace between a key scalar and its `:` indicator. Six
# presentations of the one legal ID `new-suite` sit outside this pattern,
# measured, and are armed as X20-X31; no bounded pattern closes that class.
#
# What DOES close it is not this pattern, and the claim needs its condition
# stated or it becomes the same overstatement one rung down. In a `jobs:` block
# this reader walks, whose job keys share one indentation as YAML requires, a
# file in which this reader misses a job key is refused by `run_census`, by
# name, in every position and whether or not the file also holds a job the
# reader reads. The argument has two cases. If the block's first job key is not
# the first line this reader recorded a job off, the file yields no record, or it
# fails the third limb: the block begins on that key, or on a line above it that
# is no key, and a job was recorded off neither. If it is, the reader's key
# indentation is the real one, so a key missed at it is a line this pattern does
# not match: that line fails the second limb when it is the block's shallowest,
# and when something sits shallower still, every record fails the first. An
# earlier form of this sentence rested on the second limb alone and was false of
# the class the third now closes (X64, X65); a form before that was true only of
# a file yielding NO genuine record.
#
# Read that in the direction it is written, and not backwards. Every file in
# which this reader misses a key is refused; NOT every refused file is missing
# one. A job property's quoted scalar or flow collection may be continued at the
# job-key indentation, or shallower, and that line is no key at all -- but it is
# refused all the same, because nothing on the line tells it from a key this
# pattern cannot read. That over-reach is ACCEPTED: it fails closed, where the
# one attempt to spare such lines failed open. So is a second, made by the third
# limb: a block that opens on a tag or an anchor written on a line of its own,
# or on a bracket of a flow mapping, ahead of a first key this pattern reads, is
# refused with every key read (X72). What the refusal does NOT reach is a key on
# a line it never walks, nor a line it reads as a key that is none: a
# continuation SHAPED like a key, at exactly the job-key indentation, is
# recorded as a job, and can claim a context no real job claims. Nor does it
# reach a continuation that begins with `#`: that is a comment to this reader
# whatever the file makes of it, so no limb of the refusal sees the line at all
# (X74). Nor, off the key axis, does it reach a job read in full whose `name:`
# it reads otherwise than GitHub does. The limit block the census prints states
# the residuals MEASURED SO FAR as conditions and names the arms that pin them.
# It carries no count of them, deliberately: the shapes a line-oriented reader
# cannot see are not an enumerable set, so a count of them is falsifiable by
# construction.
#
# The groups are NAMED deliberately: adding a group shifts every positional
# index, and two call sites read them.
_RE_KEY = re.compile(
    r"""^(?P<ind>\s+)(?P<q>['"]?)(?P<key>[A-Za-z0-9_][A-Za-z0-9_.-]*)(?P=q):"""
    r"""\s*(#.*)?$""")
_RE_NAME = re.compile(r"^(\s+)name:\s*(.+?)\s*$")
_RE_COMMENT = re.compile(r"^\s*#")


def _is_dedent(line):
    """A line that closes the `jobs:` block. Blanks and comments do not."""
    return bool(line.strip()) and not _RE_COMMENT.match(line) and not line[:1].isspace()


def _indent_of(line):
    return len(line) - len(line.lstrip(" "))


def _block_indent(lines, start, end):
    """The indentation this reader takes the `jobs:` mapping's children to share.

    YAML requires every child of a mapping to sit at one indentation, so the
    FIRST key line in the block answers for all of them -- and reading it is
    what keeps a job a job whatever the file's style. Assuming a number instead
    makes any other valid style invisible, and an invisible job is one that
    ships unregistered under a CLEAN verdict.

    Quoting is the same assumption on a different axis, and getting it wrong
    here is worse than missing the job: a reader that does not recognise a
    quoted key does not stop at it, it keeps scanning -- and the next line it
    DOES recognise is one of that job's own properties. The block's indentation
    then reads as the property indentation, and the census records a phantom job
    named after a property, which it goes on to grade instead of the job.

    What this returns is the first line `_RE_KEY` matches, and that is not
    always a key line. A job property's value continued onto a key-shaped line
    SHALLOWER than the real keys, ahead of every one of them, is matched first,
    and the answer is then that continuation's indentation. The file's real
    keys are deeper, and none of them is recorded. `_displaced_key_line` is what
    refuses that file: its block does not begin on the line matched here.

    Returns None when no line in the block matches `_RE_KEY`.
    """
    for i in range(start, end):
        m = _RE_KEY.match(lines[i])
        if m:
            return len(m.group("ind"))
    return None


def _block_child_indent(lines, start, end):
    """The shallowest indentation any line in the block carries, key or not.

    YAML puts a mapping's children at ONE indentation, so the shallowest line
    in the `jobs:` block ordinarily sits at the job keys' own indentation --
    whether or not this reader can recognise what is written there. That is the
    whole of its job: it is the comparator for `_block_indent`, which answers
    with the first indentation it RECOGNISED. This reader takes the answer to
    be where the job keys sit.

    Ordinarily, and not always. A job property's quoted scalar or flow
    collection may be continued at the job keys' indentation, or shallower, and
    that line is no child of the mapping at all. Continued AT it, a line this
    reader does not read as a key is counted as unread (see
    `_unread_key_lines`) and the file is refused; a line shaped like a key is
    READ as one, and in a file the three limbs pass it is recorded and graded
    as a job -- the phantom claim the limit block names as open. Continued
    SHALLOWER, the line answers here. Where the first line this reader
    recognises as a key sits deeper, every record read off a real job key
    carries the mark of one read off a property, and the file is refused.
    Where the continuation is itself that first line -- shaped like a key,
    and ahead of every other -- the two agree, nothing is marked, and
    `_displaced_key_line` refuses the file instead. Each refusal fails
    closed; the recorded phantom does not.

    The two agree on a file this reader can read. They disagree when a job key
    went unrecognised and the scan carried on into that job's own properties,
    which is the moment a phantom record is made -- so the knowledge that a
    record is synthesised exists at the point it is synthesised, and does not
    have to be inferred afterwards from the record itself. They also disagree
    when a continuation sits shallower than the first line this reader
    recognises as a key, or a tag, an anchor or a bracket of a flow mapping
    opens the block there, which sets the mark on records that are not phantoms,
    and when a key is indented with a tab, which `_RE_KEY` and `_indent_of`
    measure at different widths. The file is refused in every case, and the
    diagnosis says what this reader cannot vouch for.

    Blanks and comments are skipped because neither is a child; comments in
    particular sit at the marker indentation and would answer for the block.
    Returns None when the block holds no such line.
    """
    found = None
    for i in range(start, end):
        line = lines[i]
        if not line.strip() or _RE_COMMENT.match(line):
            continue
        ind = _indent_of(line)
        if found is None or ind < found:
            found = ind
    return found


def _unread_key_lines(lines, start, end, child_indent):
    """Indices of lines WHERE THE JOB KEYS SIT that are not `key:` lines to this reader.

    The second limb of the file-level refusal, and the one that closes the key
    PRESENTATION class rather than describing it. `_block_child_indent` gives the
    indentation this reader takes the job keys to sit at, whatever is written
    there, and every job key this reader misses AT that indentation is a
    non-comment line there that `_RE_KEY` does not match. So refusing every
    such line refuses every key missed there, and it is why no pattern had to be
    widened: the pattern decides what the reader CAN read, and this decides
    whether anything at the key indentation was left unread. Six measured key
    presentations, an anchored key and a record read off scalar content all
    reached a CLEAN census while the refusal rested only on where a record came
    from -- because each file also held a job the reader read, which satisfied
    that limb honestly. None of them presents a job key that is not a line at
    this indentation.

    A key missed ELSEWHERE is not this limb's, and it is not unguarded. Where
    something sits shallower than the indentation the reader read its keys at,
    the first limb marks every record. Where a key-shaped continuation that sits
    shallower than the real keys BECOMES the indentation the reader reads --
    ahead of every real key, so nothing is marked and every line here is a
    `key:` line -- the real keys are not at this indentation at all, and this
    limb finds nothing; `_displaced_key_line` is what refuses that file.

    The converse is FALSE, and an earlier form of this docstring asserted it:
    that every non-comment line at that indentation is a job key or part of one.
    A job PROPERTY's multi-line quoted scalar, or a flow collection it left open,
    continues onto later lines, and an author may land one of them at exactly
    the job-key indentation; that line is neither. Nor is a tag or an anchor
    written on a line of its own, or a bracket of a flow mapping, where it
    opens the block at that indentation. This limb counts each of them all the
    same: what tells a continuation from a key is what an earlier line left
    OPEN, which a line-oriented reader does not know, and the other lines it
    does not read for what they are. It counts them all the same only among the
    lines it SEES, and one shape escapes before the counting: a line beginning
    with `#` is a comment to this reader whatever the file makes of it, so a
    continuation landing here that begins with `#` is skipped rather than
    counted -- and `_bind_marker` then reads it as the first line of the
    comment block above the next job key, which is how a job comes to be graded
    under a posture no line of the file declares (X74). (A continuation line SHAPED
    like a key is the exception, and not a safe one: `_RE_KEY` matches it, so
    this limb passes it and the reader records a job off it. The limit block
    names that as open, and X66-X67 pin it as emitted.) So a workflow that both
    parsers measured accept, and whose every job key this reader reads, is
    refused, and X37-X41 pin five such files. That false refusal is ACCEPTED
    because it fails closed. The one attempt to spare such lines, by lexing what
    was open, failed open and let a real job key leave the census. X43 and
    X48-X63 pin one family of shapes in that direction and X68-X69 two shapes
    outside it; none of them pins the direction itself.

    Returned as INDICES rather than a boolean so the refusal can name the lines.
    `census_scan` and `_unread_reason` both call this, deliberately: two copies
    of one predicate drift, and the copy that drifts is the diagnosis, which is
    how a refusal comes to state a cause that is not the one that fired.
    """
    if child_indent is None:
        return []
    return [i for i in range(start, end)
            if lines[i].strip()
            and not _RE_COMMENT.match(lines[i])
            and _indent_of(lines[i]) == child_indent
            and not _RE_KEY.match(lines[i])]


def _key_lines(lines, start, end, job_indent):
    """Indices of the lines this reader records a job off: `key:` lines at `job_indent`.

    One definition, called by `census_scan` for its records and by
    `_displaced_key_line` for its comparison, so the line a record came from
    and the line the third limb compares against cannot drift apart.
    """
    return [i for i in range(start, end)
            if _RE_KEY.match(lines[i])
            and _indent_of(lines[i]) == job_indent]


def _displaced_key_line(lines, start, end, job_indent):
    """(first, first_key) when the `jobs:` block does not begin on its first key line.

    The third limb of the file-level refusal. `first` is the block's first line,
    blank lines and comments aside; `first_key` is the first line this reader
    recorded a job off. A `jobs:` block begins on its first job key, or on a
    line above that key which is no key: a tag or an anchor written on a line
    of its own, or the opening bracket of a flow mapping, which is not the
    block mapping this reader reads. So when the two differ,
    the line the block begins on is one this reader did not record a job off,
    and the lines it did record jobs off may not be the file's own.

    The class this closes is measured, not foreseen. A job property's quoted
    scalar or flow collection may be continued onto a line shaped like a key
    that sits SHALLOWER than the job keys. When that line comes ahead of every
    line this reader recognises as a key, it is the first `key:` line, so
    `_block_indent` answers with its indentation; it is also the shallowest line
    in the block, so `_block_child_indent` agrees and no record is marked
    synthesised; and every line at that indentation is a `key:` line, so
    `_unread_key_lines` finds nothing. Both earlier limbs are satisfied honestly,
    by a phantom, and every real job key -- deeper, and so at an indentation this
    reader no longer reads keys at -- leaves the census with no record, no
    finding and no refusal. Five measured files reached a CLEAN census or a
    finding on the phantom alone that way, and X64 and X65 arm two of them. What
    they share is the line the block begins on: a job key this reader could not
    read, ahead of the phantom.

    What else it refuses, and the refusal is accepted. Where the line the block
    begins on is a tag or an anchor, or a flow mapping's bracket, placed deeper
    than the job keys, the first line this reader records a job off may be the
    real first key and every record genuine -- and still the two lines differ,
    so the file is refused. Both parsers measured accept such a file, and X72
    pins the tag. The refusal fails closed and its diagnosis names both lines:
    the same kind of false refusal as the continuation the first two limbs
    refuse, accepted for the same reason. Deleting a tag or an anchor line
    clears it, and a flow mapping is outside the forms this reader reads.

    Line-local, deliberately: it compares two line indices the scan already
    has, and keeps no state across lines. It does not know what an earlier line
    left open, and does not need to -- a job property's continuation cannot
    come AHEAD of the block's first line, because the property it continues
    has to come first.

    None when the file yields no key line at all; the first limb refuses that.
    """
    keys = _key_lines(lines, start, end, job_indent)
    if not keys:
        return None
    for i in range(start, end):
        if lines[i].strip() and not _RE_COMMENT.match(lines[i]):
            return None if i == keys[0] else (i, keys[0])
    return None


def _comment_block_top(lines, i):
    """Index of the FIRST line of the contiguous comment block ending at i-1.

    None when the line above `i` is not a comment. A blank line or any
    non-comment line terminates the block, which is what binds a marker to one
    job rather than to whichever job happens to follow it.
    """
    j = i - 1
    if j < 0 or not _RE_COMMENT.match(lines[j]):
        return None
    while j - 1 >= 0 and _RE_COMMENT.match(lines[j - 1]):
        j -= 1
    return j


def _bind_marker(lines, i, job_indent):
    """(raw, note) for the job key at `i`. `raw` is set only by a BOUND marker.

    A marker binds when it is the FIRST line of the contiguous comment block
    directly above the job key AND its `#` sits at the job key's own
    indentation. Proximity alone is not enough and the reason is measured: under
    a walk that merely climbs the block looking for a marker, a comment that
    DOCUMENTS the grammar answers for a job that never did, and `UNDECLARED`
    -- the whole mechanism by which a future author is stopped -- silently
    becomes `advisory`.

    More than one marker line inside that block is AMBIGUOUS, and ambiguity is
    tested before binding rather than after. Whichever end a rule binds it
    discards the other end in silence, so the tool declines to choose -- and
    the order an editing accident produces is what makes declining the safe
    answer rather than the cautious one. A contributor ADDING a marker writes
    it against the job key, which puts the new line at the BOTTOM of the block
    and leaves the stale one on top: a first-line rule then binds the line the
    author just superseded and reports it as a confident answer. Where the
    superseded line reads `advisory`, that answer is a CLEAN verdict over a job
    that claims to bind -- the exact failure this whole mode exists to end.

    `note` explains a marker that is present and did not bind, so that case
    reads differently from a job with no marker at all. Both are UNDECLARED;
    only one of them is a contributor who tried.
    """
    top = _comment_block_top(lines, i)
    if top is None:
        return (None, None)

    markers = [k for k in range(top, i) if _RE_MARKER.match(lines[k])]

    if len(markers) > 1:
        return (None, "the comment block above this job carries {} `# gate-efficacy: "
                      "posture=` lines ({}). Two answers is not an answer, so neither "
                      "binds -- leave exactly one, and delete the line it replaces "
                      "rather than writing a second beneath it".format(
                          len(markers),
                          ", ".join(
                              "{!r} {}".format(
                                  _RE_MARKER.match(lines[k]).group(2),
                                  "on the block's first line" if k == top
                                  else "{} line(s) below it".format(k - top))
                              for k in markers)))

    first = _RE_MARKER.match(lines[top])
    if first and len(first.group(1)) == job_indent:
        return (first.group(2), None)

    if markers:
        k = markers[0]
        found = _RE_MARKER.match(lines[k])
        if k != top:
            return (None, "a `# gate-efficacy: posture=` line sits inside the comment "
                          "block above this job but is not that block's first line. A "
                          "marker binds only as the FIRST line of the contiguous "
                          "comment block directly above the job key, so this one "
                          "answers for no job")
        return (None, "the marker above this job is indented {} space(s); it binds "
                      "only at the job key's own indentation of {}".format(
                          len(found.group(1)), job_indent))
    return (None, None)


def repo_root():
    """The repository this file lives in, derived from the file's own location.

    Not the caller's working directory: a census that graded whatever tree the
    shell happened to be sitting in could report clean against the wrong repo.
    """
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def workflow_files(root):
    """(repo-relative, absolute) for every workflow file, sorted."""
    rel_dir = os.path.join(".github", "workflows")
    abs_dir = os.path.join(root, rel_dir)
    if not os.path.isdir(abs_dir):
        return []
    out = []
    for nm in sorted(os.listdir(abs_dir)):
        if nm.endswith(".yml") or nm.endswith(".yaml"):
            out.append((os.path.join(rel_dir, nm), os.path.join(abs_dir, nm)))
    return out


def census_scan(root):
    """Every job in every workflow, with the posture it declares.

    Line-oriented and stdlib-only: this module imports no YAML parser, and a
    census that needed one would not run on a runner that has not installed it.

    The context name is read off the job's `name:` when it has one and is the
    job KEY when it does not, because GitHub reports a job's name, or its key
    where it has none, as the check's context. What is read here, though, is
    ONE LINE: the first `name:` line at the job's property indentation,
    stripped in the order this reader strips it -- every leading and trailing
    character it reads as WHITESPACE first, its own runtime's Unicode notion
    rather than the space and tab a plain scalar sheds; then every leading and
    trailing double quote; then every leading and trailing single quote -- so a
    value quoted the other way round keeps its double quotes, and whitespace
    that only a quote pass exposes is never taken. A YAML parser reads a name from
    every line its value runs to, and a job whose name carries an expression,
    or that runs over a `strategy: matrix`, reports a context GitHub computes
    at run time -- so the context compared here is not always the one GitHub
    reports. The mechanisms measured for that follow, as instances rather than
    as a counted or complete list. A `name:` continued onto a further line is
    read as its first line alone (X70). A `name:`-shaped line inside another
    property's value, at the property indentation and ahead of the job's own
    `name:`, is read as the job's name (X71). And the quote-strip above is
    `.strip('"').strip("'")` -- TWO PASSES, each unconditional and each
    removing EVERY leading and trailing character of its own kind rather than
    one layer: all double quotes off each end, then all single quotes. So a
    value wrapped in ANY NUMBER of quote layers is read as the text inside all
    of them, while all three parsers measured read those quotes as part of the
    name (X75). And the whitespace strip that runs ahead of both quote passes
    -- the `name:` pattern's own whitespace class on either side of the value,
    and then the bare `.strip()` at the head of the chain -- takes this
    runtime's Unicode notion of whitespace, which is wider than the space and
    tab a plain scalar sheds, so an unquoted `name:` beginning or ending in a
    character such as `U+00A0` is read as the bare text while the parsers
    measured keep the character (X76). Where a plain scalar sheds it too, as it
    does an ASCII space, the two agree, so what masks is the DIVERGENCE and not
    the trimming; and removing either of those sites without the other leaves
    the mechanism open -- measured. The order is part of the mechanism: the
    whitespace strip runs before either quote pass, and the double-quote pass
    runs to completion before the single-quote pass begins, so a double quote
    that only the single-quote pass exposes is never taken. Those are
    properties of this line's own strip rather than of any continuation, so the
    fold that reads a continued `name:` the way the parsers do does not reach
    them. A `name:` written twice in one job is read at its first copy, where
    both parsers measured keep the later one -- the repeated-key class in the
    limit block. The limit block states each of them, and the run-time case, as
    conditions.
    `posture` is None when no marker BINDS to the job key (see
    `_bind_marker` for what binding requires and why proximity is not it), and
    also when the bound marker's value is not one this tool recognises -- an
    answer it cannot read is not an answer, so the unreadable case fails closed
    into the same finding as the absent one.

    Both the job indentation and each job's property indentation are read from
    the file rather than assumed, so the census sees a job whatever style the
    file is written in. A reader that assumed one style would report CLEAN over
    a tree carrying an unregistered job in another -- the very defect this mode
    exists to surface, arriving through the mode's own parser.

    Three per-FILE marks travel on every record, and the per-file assertion in
    `run_census` needs all three. None implies another and they answer
    different questions, which is why fewer of them were not enough.

    `synthesised` records where a record CAME FROM. A key presentation this
    reader does not recognise does not stop the scan: it carries on to the next
    line it DOES recognise, which is one of that job's own properties, and
    records a job off it. Such a record is evidence of nothing -- its key is a
    property name, its `name:` is whatever sits under that property, and any
    marker it binds was written for the job whose key was missed. It is marked
    at the moment it is made so the assertion can refuse to accept it as
    evidence the file was read. The mark is decided per file and from
    indentation alone, so a value continued SHALLOWER than the first line this
    reader recognises as a key sets it on records read off real keys as well:
    the same kind of false refusal as the one below, and it fails closed for
    the same reason. A value continued shallower that IS that first line --
    shaped like a key, and ahead of every real one -- sets no mark at all,
    because the phantom is then the shallowest line; `displaced_key` below is
    what refuses that file.

    `unread_key` records whether a line WHERE THE JOB KEYS SIT is one this
    reader does not recognise as a key. It exists because provenance alone
    cannot reach the shape that matters most: put one readable job in the same
    file and the file yields a genuine, unmarked record, the provenance limb is
    satisfied honestly, and the unread job sails to a CLEAN verdict it was never
    graded for. Nine measured shapes did exactly that. The mark is also set by
    a line that is no key at all -- a job property's value continued at that
    indentation, which this reader cannot tell from a key, or a tag, an anchor
    or a bracket of a flow mapping written there on a line of its own -- and
    that false refusal is accepted. It is NOT set when that line begins with
    `#`: the mark is computed over the lines this reader does not read as
    comments, and `#` is the whole of what makes a line a comment to it, so a
    continuation beginning with `#` is skipped by this limb and read as a
    comment line by `_bind_marker` (X74). See `_unread_key_lines`.

    `displaced_key` records whether the `jobs:` block begins, comments aside,
    on a line other than the first one this reader recorded a job off. Both
    marks above are satisfied by a phantom read off a key-shaped continuation
    that sits shallower than the job keys and ahead of all of them, because
    that phantom IS the shallowest line and every line beside it is a `key:`
    line -- and then every real job key is read as no key at all. What the
    phantom cannot be is the line the block begins on. The mark is also set by
    a block that opens on a tag or an anchor line, or a bracket of a flow
    mapping, ahead of a first key this reader reads, with every record genuine
    -- a false refusal accepted as well. See `_displaced_key_line`.
    """
    jobs = []
    for rel, path in workflow_files(root):
        try:
            with open(path, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except (OSError, UnicodeDecodeError):
            # A file that is not UTF-8 is a file this reader cannot read, which
            # is the same thing as one it cannot open: it contributes no record,
            # the per-file assertion below refuses the tree by name, and
            # `_unread_reason` says which file and why. Letting the exception
            # escape instead killed the process before any exit path, so the one
            # input that produced NO output at all was the one a reader could do
            # least about.
            continue

        start = None
        for i, line in enumerate(lines):
            if _RE_JOBS.match(line):
                start = i + 1
                break
        if start is None:
            continue

        end = len(lines)
        for i in range(start, len(lines)):
            if _is_dedent(lines[i]):
                end = i
                break

        job_indent = _block_indent(lines, start, end)
        if job_indent is None:
            continue

        # Whether these records are read off job KEYS or off a job's own
        # PROPERTIES, decided here rather than guessed later. See
        # `_block_child_indent`: the two answers diverge when a key at the
        # block's own indentation went unrecognised, which is how the scan
        # comes to reach a job's properties and record them -- and also when a
        # value continued shallower than the first line this reader recognises
        # as a key, or a tab, moves the shallowest line, which sets the mark on
        # records that are not phantoms. A continuation that IS that first line
        # moves both answers together and sets no mark; the third limb below
        # refuses that file.
        # It is per FILE because `job_indent` is, so a file's records are all
        # synthesised or none of them are -- there is no mixed case to reason
        # about, and after `run_census`'s refusal no synthesised record survives
        # into grading at all.
        child_indent = _block_child_indent(lines, start, end)
        synthesised = child_indent is not None and job_indent > child_indent

        # The second limb, and the one that closes the key-PRESENTATION class
        # beside a readable job (X26-X34). `synthesised` asks where this file's
        # records CAME FROM; this asks whether any line where
        # its job keys sit is one it could not read as a key -- a question that
        # a property's value continued there answers yes to as well, which is
        # the accepted false refusal `_unread_key_lines` describes. They are
        # different questions and neither implies the other: a file can yield
        # nothing but phantoms, and a file can yield a perfectly genuine record
        # beside a key this reader never saw. The second shape is the one that
        # reached exit 0, because the genuine record satisfied the provenance
        # limb honestly -- so a mark on provenance could never have refused it,
        # however the mark was computed.
        # Per FILE for the same reason `synthesised` is, and recorded on the
        # record for the same reason: `run_census` refuses before grading and
        # never re-reads the file.
        unread_key = bool(_unread_key_lines(lines, start, end, child_indent))

        # The third limb: whether the block begins on the first line this
        # reader records a job off. The two limbs above are both satisfied by a
        # phantom read off a key-shaped continuation that sits shallower than
        # the job keys and ahead of every one of them, because that phantom IS
        # the shallowest line and every line beside it is a `key:` line. What
        # the phantom cannot be is the line the block begins on. A block that
        # opens on a tag or an anchor line, or a bracket of a flow mapping,
        # fails it too with every key read -- the false refusal
        # `_displaced_key_line` accepts. Per FILE, and recorded on the record,
        # for the reason the other two are.
        displaced_key = _displaced_key_line(lines, start, end, job_indent) is not None

        keys = _key_lines(lines, start, end, job_indent)

        for n, i in enumerate(keys):
            key = _RE_KEY.match(lines[i]).group("key")
            stop = keys[n + 1] if n + 1 < len(keys) else end

            # The job's own properties share one indentation too, and `name:` is
            # read at exactly that one. Matching any deeper `name:` would read a
            # STEP's name as the job's, which is not the context GitHub reports.
            prop_indent = None
            for j in range(i + 1, stop):
                if lines[j].strip() and not _RE_COMMENT.match(lines[j]):
                    prop_indent = _indent_of(lines[j])
                    break

            name = None
            if prop_indent is not None and prop_indent > job_indent:
                for j in range(i + 1, stop):
                    got = _RE_NAME.match(lines[j])
                    if got and len(got.group(1)) == prop_indent:
                        name = got.group(2).strip().strip('"').strip("'")
                        break

            raw, note = _bind_marker(lines, i, job_indent)
            posture = raw if raw in POSTURE_VALUES else None

            jobs.append({"file": rel, "key": key, "name": name or key,
                         "posture": posture, "raw": raw, "note": note,
                         "synthesised": synthesised, "unread_key": unread_key,
                         "displaced_key": displaced_key})
    return jobs


def census_findings(jobs):
    """(code, file, context, why) for every disagreement. Empty is clean."""
    findings = []
    claimed = {}
    for job in jobs:
        if job["posture"] == "required":
            claimed.setdefault(job["name"], []).append(job)

    for job in sorted(jobs, key=lambda j: (j["file"], j["key"])):
        if job["posture"] is not None:
            continue
        if job["raw"] is not None:
            why = "posture value {!r} is not one of {}".format(
                job["raw"], "|".join(POSTURE_VALUES))
        elif job.get("note"):
            why = job["note"]
        else:
            why = ("no `# gate-efficacy: posture=` marker as the first line of the "
                   "comment block directly above the job key")
        findings.append(("UNDECLARED", job["file"], job["name"], why))

    for ctx in sorted(set(claimed) - EXPECTED_CONTEXTS):
        findings.append(("UNREGISTERED", claimed[ctx][0]["file"], ctx,
                         "claims posture=required, but no such context is declared "
                         "in CONTEXT_ORDER"))

    for ctx in sorted(EXPECTED_CONTEXTS - set(claimed)):
        findings.append(("ABSENT", "-", ctx,
                         "declared in CONTEXT_ORDER, but no job claims "
                         "posture=required under that name"))

    return findings


# Two limits, and they are different in kind. The first is about what a clean
# census MEANS; the second is about which inputs it could read at all. A widened
# reader that implies it now handles everything is more dangerous than the narrow
# one it replaced, because the next author trusts it further -- so the second
# limit names what escapes both the reader and its own refusal, and names it here
# rather than in a commit message nobody will read again.
#
# It says a CLASS and no longer a count, and that is a correction rather than a
# hedge. An older text said ONE SHAPE and named an example; six presentations of
# one legal job ID were then measured outside the reader, three of them with no
# quoting trick at all. A limit block that understates its own residual is the
# defect this whole mode exists to remove, sitting inside the instrument that
# removes it -- so the residual is stated as the condition that produces it, and
# the arms that hold it honest are named for whoever comes next.
#
# This version stops counting the residuals, and the reason is a pattern rather
# than any one finding. Each earlier version named a fixed number of open
# classes; each was then handed a class it had not named, and its own count
# went false in the same act. That is not bad luck five times over. The shapes a
# line-oriented reader cannot see are not an enumerable set, so a count of them
# is falsifiable BY CONSTRUCTION, and a block that carries one is a block whose
# next reviewer refutes it. So the claim changes shape: the block states what
# this reader structurally cannot see -- it reads KEY LINES and MARKER LINES,
# not VALUES -- and gives the measured classes as INSTANCES of that sentence
# rather than as a complete set. A class measured later then EXTENDS the block
# instead of contradicting it.
#
# What each earlier version got wrong is still worth naming. The first
# OVERSTATED coverage: it promised that a file yielding no record read off a job
# key is refused, which was never true of a record read off the CONTENT of a
# quoted scalar (X34). The second UNDERSTATED what could be done: it said no
# bounded pattern closes the class, which is true, and read as though the class
# were therefore unclosable, which is not -- the class was closed without
# touching the pattern, by refusing the FILE. The third OVERSTATED again, in both
# directions at once: it said a key this reader cannot read is refused in every
# position, which was false of one displaced by a shallower phantom until the
# third test closed it (X64-X65), and it named one open class where a further
# one was already reachable -- a job recorded off a line that is no key is
# walked, read, and graded (X66-X67). The fourth UNDERSTATED once more: it named
# two open classes where a further one was already reachable -- a job
# graded under a context read off one line of its `name:`, or off a
# `name:`-shaped line inside another value, is walked, read,
# and graded, and can reach CLEAN (X70-X71); its account of where the refusal
# fires with no key missing named only continuations, where a block that opens
# on a tag line is refused as well (X72); and its opening said a clean result
# means the workflows and the declaration agree, which holds only of the
# contexts this reader reads. The fifth UNDERSTATED once more, twice over: it
# said three open classes where a job graded under a POSTURE no line of the
# file declares was already reachable -- a property's quoted scalar continued
# at the job-key indentation onto a line beginning with `#`, which every limb
# skips and the marker binding reads as a comment (X74) -- and its account of
# the name class said two mechanisms where the quote-strip was a further one, on
# one line, reachable with no continuation at all (X75). So this version says
# which class is closed and by what mechanism, and then stops counting what is
# left.
#
# It counted again anyway. A later edit wrote that the reader and a file "come
# apart two further ways" -- a count of the WAYS rather than of the classes, true
# of every class then named -- and the next class measured, a key written twice,
# was none of them. A rule that was stated and then broken is now enforced: E9
# in the self-test fails on a number written in front of a class, a way, a
# mechanism or a member, here, in any docstring in this module or in any arm
# label. A count of a closed set is written as a measured tally in numerals, as
# in 5 of 5.
#
# The second limit also says where the refusal reaches too far. A refusal that
# fires on files the parsers measured accept is a limit of the instrument as
# much as a class it misses, and accepting it does not make it stop being one:
# an author whose workflow is refused should find, in the output, that the
# refusal knows it can be wrong about that file, and what to change to clear it.
_CENSUS_LIMIT = (
    "WHAT THIS DOES NOT ESTABLISH: `GITHUB_TOKEN` cannot read the branch protection",
    "API, so this census cannot confirm that any context is REGISTERED.",
    "Registration remains an operator act outside any pull request.",
    "",
    "WHAT A CLEAN RESULT MEANS, and it is narrower than it looks. This reader is",
    "line-oriented. It reads KEY LINES and MARKER LINES; it does not read VALUES,",
    "and it does not know what an earlier line left open. So a clean result says",
    "that the lines this reader COULD READ agree with the committed declaration.",
    "It is NOT a statement about what the file's values contain. A value is",
    "exactly where the text of a line this reader reads can be written without",
    "being one -- a key, a marker, a `name:`, the `jobs:` line, or the",
    "column-zero line that ends the block -- and wherever a file does that, the",
    "two come apart. That is not the only way they come apart, and naming it",
    "alone left the universal below false of classes it already covers. They",
    "also come apart where this reader TRANSFORMS the line it did read, as the",
    "quote-strip below does; where what decides the answer sits on a line it",
    "reads NOTHING of -- a continuation, or the `on:` block; and where what",
    "decides it is a rule that sits on NO line -- a key written twice, of which",
    "both parsers measured keep only the later copy while this reader has no",
    "rule for a repeat, so a file can come apart from this reader with every",
    "line read as what it is. Those ways are instances, not a complete list: the",
    "list carries no count, and a way measured later extends it rather than",
    "contradicting it. Every open class named below is one measured instance of",
    "this paragraph, and the paragraph is the claim; the instances are not.",
    "The context compared for each job is the text of ONE line -- its first",
    "`name:` line at the job's property indentation -- stripped in the order",
    "this reader strips it: EVERY leading and trailing character it reads as",
    "WHITESPACE comes off FIRST, its own runtime's Unicode notion rather than",
    "the space and tab a plain scalar sheds; then EVERY leading and trailing",
    "double quote; then EVERY leading and trailing single quote -- not one",
    "layer of each -- or its key where it has none. It is not always the",
    "context GitHub reports. A job whose",
    "`name:` carries an expression, or that runs over a `strategy: matrix`,",
    "reports a context GitHub computes at run time, which this reader never sees:",
    "a bare name added to the declaration to silence a finding on such a job can",
    "read CLEAN over a context GitHub never reports.",
    "",
    "WHICH FORMS IT READS: a block `jobs:` mapping at column zero whose job keys are",
    "`key:` lines, optionally quoted. That set is not exhaustive over the ways YAML",
    "lets a legal job ID be written, and no bounded pattern would be -- but do not",
    "read that as the class being unclosable. It is closed, and NOT by the pattern.",
    "A file is REFUSED BY NAME unless it yields a record read off a line recognised",
    "as a job key, at the shallowest indentation in its `jobs:` block; carries no",
    "line there, comments aside, that this reader does not recognise as a `key:`",
    "line; AND has a block that begins on the first line it read a job off. So, in",
    "a block it walks whose job keys share one indentation, a key this reader",
    "cannot read is refused in EVERY position: beside a job it reads perfectly",
    "well, where six presentations of one legal job ID used to reach CLEAN, and",
    "ahead of a key-shaped continuation that sits shallower than the real keys and",
    "so became the indentation this reader read keys at, where four files reached",
    "CLEAN and a fifth graded only the phantom. Those six, an anchored key",
    "(`key: &a`), X34's phantom beside an unread key, and that displaced class",
    "are all refused now -- measured (X20-X34, X64-X65).",
    "",
    "THAT REFUSAL ALSO FIRES WHERE NO KEY IS MISSING, and that is accepted. A job",
    "PROPERTY's quoted scalar or flow collection may be continued at exactly the",
    "job-key indentation, or shallower short of column zero. A line there that is",
    "not shaped like a key is no key at all, but this reader cannot tell it from a",
    "key it cannot read, so it refuses a workflow whose every job key it reads",
    "(X37-X41) -- UNLESS that line begins with `#`. Then it is a comment to this",
    "reader whatever the file makes of it: no limb of the refusal sees it, and it",
    "is read as a comment line instead, which is the posture class below (X74).",
    "A line shaped like a key that sits SHALLOWER leaves the records",
    "read off the real keys unvouched for, so that file is refused too. Indenting",
    "the continuation deeper than the job keys clears either (X42). A block may",
    "also open, ahead of its first job key, on a line carrying only a tag or an",
    "anchor, or on the opening bracket of a flow mapping. That line is no key, and",
    "the block does not begin on a line a job was recorded off, so the file is",
    "refused with every job key read, wherever the line sits (X72 pins a tag",
    "deeper than the keys). Deleting a tag or an anchor line clears it; a flow",
    "mapping is not a form this reader reads. Each false refusal fails closed and",
    "names a line. Sparing a continuation means knowing what every earlier line",
    "left open, and a reader that guessed instead let a real job key leave the",
    "census unrecorded -- the failure this census exists to prevent. X43, X48-X63",
    "and X68-X69 catch the sparing readers measured; they do not close that",
    "direction for every reader.",
    "",
    "WHAT REMAINS OPEN. What follows are the classes MEASURED SO FAR. It is a list",
    "of instances, not a complete set, and it carries no count on purpose: a count",
    "of what a line-oriented reader cannot see is falsifiable by construction, and",
    "four consecutive reviews each handed this block a class it had not named and",
    "made its own count false in the same act. None of these is a remnant of the",
    "class closed above and none of them is closed. A class measured later EXTENDS",
    "this list rather than contradicting it, and finding one is not evidence that",
    "what is written here was wrong.",
    "A job this reader never WALKS. The `jobs:` block ends at the first non-comment",
    "line at column zero, so a quoted scalar or flow collection continued at column",
    "zero ends it early and every job below that point is neither read nor refused.",
    "Measured on files two parsers read as two jobs: CLEAN at exit 0 over the",
    "second, which claims required under a name this declaration does not carry.",
    "It is pinned SO FAR by a double-quoted scalar, a single-quoted one, and a",
    "flow sequence closed at column zero (X36, X45, X46), not by one arm alone,",
    "because an author who closes one of them turns a single arm green with the",
    "others still open. A whole block can go unwalked the same way: a top-level",
    "scalar continued at column zero can carry a `jobs:` line of its own, and this",
    "reader begins at the first `jobs:` line it finds, so it walks a block that",
    "opens inside the scalar, records whatever that block holds, and never reaches",
    "the real one (X73). Nor is a continued value the only thing that ends a block",
    "early: a `---` document separator is a non-comment line at column zero too, so",
    "in a MULTI-DOCUMENT file -- two documents each carrying its own `jobs:` block,",
    "which the parsers measured read as two documents and actionlint accepts at",
    "rc 0 -- everything below the separator is neither read nor refused. What",
    "GitHub itself does with such a file was not measured, so no verdict is claimed",
    "for it here, and NO ARM PINS IT: this clause is described and unarmed. It is",
    "recorded because the general sentence above covers it and the causes named",
    "did not.",
    "A job this reader RECORDS that is not one. A continuation shaped like a key at",
    "EXACTLY the job-key indentation is a `key:` line to this reader, so none of",
    "the three tests fires on it, and it records a job off it. With a marker line",
    "above and a `name:` line below, that phantom can claim required under a",
    "declared context -- and where the real job for that context is gone, the",
    "ABSENT it owes is masked: CLEAN at exit 0, measured on files both parsers read",
    "as one job. Telling that line from a key means knowing that a quote or a flow",
    "is open, which this reader does not track. The members pinned so far include",
    "a quoted scalar and a flow mapping (X66, X67).",
    "A job this reader grades under a context the job does not report. It reads",
    "the context off one line, and a YAML parser reads a `name:` from every line",
    "its value runs to. The mechanisms measured for this are distinct, and a",
    "MEMBER COUNT IS NOT A MECHANISM COUNT -- read the arms as instances, never as",
    "the class. A `name:` continued onto a further line is read as its first line",
    "alone (X70). A `name:`-shaped line inside another property's quoted value,",
    "landing at the property indentation ahead of any `name:` of the job's own, is",
    "read as the job's name (X71). And the quote-strip is TWO PASSES, each",
    "unconditional and each taking EVERY leading and trailing character of its",
    "own kind rather than one layer -- all double quotes off each end, then all",
    "single quotes -- so a value wrapped in ANY NUMBER of quote layers is read as",
    "the text inside all of them while all three parsers measured read those",
    "quotes as part of the name (X75) -- one line, no continuation, no phantom",
    "`name:` line. And the strip that runs BEFORE both quote passes takes every",
    "leading and trailing character this reader reads as whitespace, which is",
    "its own runtime's Unicode notion and not the space and tab a plain scalar",
    "sheds: an unquoted `name:` beginning or ending in such a character --",
    "`U+00A0` is the member pinned -- is read as the bare declared context,",
    "while the parsers measured keep the character. Where a plain scalar sheds",
    "the character too, as it does an ASCII space, the reader and the parsers",
    "agree and nothing is masked, so the mechanism is the DIVERGENCE between",
    "the two notions rather than the trimming (X76). The ORDER is part of the",
    "mechanism and not an ordering of convenience: the whitespace strip runs",
    "before either quote pass, and the double-quote pass runs to completion",
    "before the single-quote pass begins, so a double quote that only the",
    "single-quote pass exposes is never taken, a value quoted the other way",
    "round keeps it, and whitespace that only a quote pass exposes is never",
    "taken either -- that direction gives a finding and fails closed. Where the",
    "line read is a declared context, the",
    "UNREGISTERED the job owes is masked, and so, where that context's real job is",
    "gone, is the ABSENT: CLEAN at exit 0, measured on files both parsers read as",
    "one job. Each mechanism closes separately: folding a continued `name:` the",
    "way the parsers do turns X70 red and leaves X71 and X75 at rc 0, measured. So",
    "an author who lands that fold must not read this class as one close from",
    "shut, and must not re-label the arms it did not reach. Read the",
    "other way -- a declared name wrapped onto a further line, written as a block",
    "scalar (`name: >-`) and read as `>-`, or followed by a comment read as part",
    "of it -- the same one-line read gives a false finding, and that direction",
    "fails closed.",
    "A job this reader grades under a POSTURE no line of the file declares. The",
    "only line it reads a posture off is a COMMENT line, and a leading `#` is the",
    "whole of what makes a line a comment to it. A job property's quoted scalar",
    "continued at the job-key indentation -- the line the refusal above accepts a",
    "false refusal for -- may begin with `#`, and then every limb of that refusal",
    "skips it and the marker binding reads it as the first line of the comment",
    "block above the NEXT job key. That job is graded under a posture the file",
    "never declares: CLEAN at exit 0 over a tree owing ABSENT and UNDECLARED,",
    "measured on a file the parsers read as two ordinary jobs and actionlint",
    "accepts at rc 0 (X74). The identical continuation WITHOUT the leading `#` is",
    "refused at exit 2, so the `#` is the whole of the difference, and it turns a",
    "refusal that fails closed into a CLEAN that fails open. Closing it is not",
    "line-local, as the other classes' closes are: telling a `#`-leading",
    "continuation from a comment means tracking what an earlier line left open,",
    "which is the cross-line lexing this reader does not do and which the one",
    "measured attempt at it got wrong in the fail-open direction. The blunt",
    "line-local close -- stop skipping comments in the second limb -- was measured",
    "to turn about half of these arms red, so it is not a candidate either.",
    "A job this reader grades in a workflow that cannot run on a pull request at",
    "all. It reads no `on:` line anywhere, so whether the workflow a job sits in",
    "could produce a pull-request check is outside every class above: a job",
    "claiming required under a declared context, in a workflow triggered only by",
    "`workflow_dispatch`, only by `schedule`, or by a `push` restricted to tags,",
    "reaches CLEAN at exit 0 over a tree owing ABSENT for that context --",
    "measured, with the census's WHOLE STDOUT byte-identical to the same file",
    "triggered on `pull_request`, so the `on:` block contributes nothing to the",
    "verdict at all. What GitHub itself reports for a required check whose",
    "workflow cannot fire on a pull request was NOT measured, so no verdict is",
    "claimed for it here -- the same footing the multi-document clause above",
    "stands on -- and NO ARM PINS IT either, so the backstop sentence below",
    "reaches it only through a separate measurement: actionlint accepts all",
    "three trigger shapes at rc 0, under a control it rejects. Every context",
    "this declaration carries sits, in this repository's live tree, in a",
    "workflow that does trigger on `pull_request`, measured over the whole",
    "declaration, so nothing here is live today; a context added later could",
    "change that with no line of this block changing.",
    "A job this reader grades off a key both parsers measured discard. A file may",
    "write a mapping key twice: both parsers measured accept it and keep only the",
    "LATER copy, and this reader has no rule for a repeat. A job key written twice",
    "-- the first copy claiming required under a declared context, the second",
    "advisory under another name -- is read as two jobs where both parsers read",
    "one, the later: CLEAN at exit 0 over a tree owing ABSENT for that context --",
    "measured, with the census's WHOLE STDOUT byte-identical to the same file with",
    "the two keys made distinct, so the repeat contributes nothing to the verdict",
    "at all. Every line of that file is read as what it is: what decides the answer",
    "is the parsers' rule that a repeated key replaces the earlier copy, and that",
    "rule sits on no line. The same rule reaches a job's `name:` written twice,",
    "which this reader reads at its first line, and a `jobs:` key written twice,",
    "whose second block it never walks -- each measured at CLEAN over a tree owing",
    "a finding; with the declared context in the later `name:` instead, the same",
    "read gives a false finding, which fails closed. What GitHub itself does with a",
    "repeated key was not measured, so no verdict is claimed for it here, and",
    "NO ARM PINS IT. It has a backstop all the same: `Workflow SAST (actionlint)`,",
    "in this same job, rejects every such file at rc 1, naming the key it repeats",
    "-- it checks the `jobs:` block, each job and the workflow's own keys for a",
    "repeat -- measured on every member here, with the version this job installs",
    "read in source rather than run. No workflow in this repository's live tree",
    "repeats a key, measured over every mapping in every file, so nothing here is",
    "live today; a workflow added later could change that with no line of this",
    "block changing.",
    "No backstop stands behind any class's arms: `Workflow SAST (actionlint)`, in",
    "this same job, exits 0 on every file their arms plant -- measured. It rejects",
    "YAML it cannot parse, and these files parse under both parsers measured, each",
    "of which accepts a continuation at every depth these arms use. GitHub's own",
    "parser was not run on any of them. A parser that refused a value continued no",
    "deeper than its key would still read X70, which continues its `name:` deeper",
    "than that. A class no arm pins is outside that measurement, and the repeated",
    "key's clause above names the backstop it has.",
)


# E9's detector, the self-test's guard on the rule stated above the limit
# block. It finds a NUMBER written in front of a class, a way, a mechanism or a
# member, with at most two ordinary words between them, as in "two further
# ways". Three shapes pass, each for a reason: a measured tally written in
# numerals, "5 of 5 members", which is how a count of a closed set is written
# here; an ordinal, which indexes an instance and stays true when another is
# found; and a number joined to the noun by a function word ("one for the
# class"), which counts something else. The function words are refused INSIDE
# the pattern rather than filtered afterwards, because a filtered match has
# already consumed its text: "one of three mechanisms" would be matched from
# "one", discarded, and the count inside it never seen.
_OPEN_COUNT_NUMBER = (r"\d+|one|two|three|four|five|six|seven|eight|nine|ten|"
                      r"eleven|twelve|twenty|both|pair of|couple of|dozen")
_OPEN_COUNT_NOUN = r"class(?:es)?|ways?|mechanisms?|members?"
_OPEN_COUNT_GLUE = (
    "a", "an", "the", "of", "for", "to", "in", "on", "at", "by", "with", "from",
    "into", "is", "are", "was", "were", "be", "been", "that", "which", "and",
    "or", "but", "than", "as", "per", "each", "every", "its", "their", "this",
    "these", "those")
_RE_OPEN_COUNT = re.compile(
    r"\b(" + _OPEN_COUNT_NUMBER + r")\s+((?:(?!(?:" + "|".join(_OPEN_COUNT_GLUE)
    + r")\s)[A-Za-z-]+\s+){0,2}?)(" + _OPEN_COUNT_NOUN + r")\b", re.IGNORECASE)
_RE_CLOSED_TALLY = re.compile(r"\d+\s+(?:out\s+)?of\s+$")


def _open_counts(text):
    """The counts E9 refuses in `text`: a number in front of a class, a way, a
    mechanism or a member. Whitespace is normalised first, so a count the limit
    block splits across its printed lines is read as the phrase it is."""
    text = " ".join(text.split())
    return [m.group(0) for m in _RE_OPEN_COUNT.finditer(text)
            if not (m.group(1).isdigit()
                    and _RE_CLOSED_TALLY.search(text[:m.start()]))]


_RE_JOBS_ISH = re.compile(r"^(['\"]?)jobs\1:")


def _unread_reason(path):
    """Why this file was refused. A DIAGNOSIS, not the guarantee.

    THE GUARANTEE IS THE SET DIFFERENCE IN `run_census`, NOT THIS LIST. That
    refusal fires whenever a walked file failed any of the three limbs -- it
    contributed no record read off a job key at the block's shallowest
    indentation, it carries a line there that this reader does not recognise as
    a `key:` line, or its block does not begin on the first line it read a job
    off -- whatever the cause, so a shape this helper cannot name still fails
    closed, and a silent skip added to `census_scan` later degrades the
    diagnostic without weakening the check. That asymmetry is the whole reason
    the guard is a relation over files rather than an enumeration of known-bad
    shapes: three shapes produced the first signature, nine the second and five
    the third, so a shape list would have been written seventeen times over and
    still missed the eighteenth.

    Every sentence returned here must be true of EVERY file that reaches it,
    including the files this reader refuses that both parsers measured accept.
    A line at the key indentation that this reader cannot read is sometimes a
    job key, sometimes the continuation of a property's value -- and nothing on
    the line says which of those two it is -- and sometimes a line that opens
    the block without being a key at all: a tag or an anchor written on a line
    of its own, or a bracket of a flow mapping, which this reader does not read
    for what it is. So the text names what this reader could not do and what
    the line may be, and never asserts which it is.

    The branch after the third limb's is not a fallback that should never be
    reached. It names the shallowest lines when this reader looked for its job
    keys deeper than they sit and every one of them is a `key:` line to it. A
    job key written with a tab reaches it -- `_RE_KEY` matches the key and
    `_indent_of` measures it at a different width -- and so does a block whose
    first `key:` line sits deeper than a later, shallower one, and so does a
    file whose every job key this reader reads, when a value is continued onto
    a key-shaped line shallower than those keys. Its text claims nothing that
    is untrue of any of them. The last return is the honest answer for a cause
    this helper does not model: no file the three limbs refuse reaches it
    today, and its text is true of any that ever does.
    """
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except (OSError, UnicodeDecodeError):
        return "it could not be opened and read as UTF-8 text"

    start = None
    for i, line in enumerate(lines):
        if _RE_JOBS.match(line):
            start = i + 1
            break

    if start is None:
        # A byte-order mark is read as a character, so a `jobs:` line after one
        # is not at column zero to this reader however it looks -- and the
        # remedy's "a bare `jobs:` line at column zero" is a description the
        # file already appears to meet. Named first, so the author is told the
        # one thing the text below would not.
        if lines and lines[0].startswith("\ufeff") and (
                _RE_JOBS.match(lines[0][1:]) or _RE_JOBS_ISH.match(lines[0][1:])):
            return ("it begins with a byte-order mark, which this reader reads as "
                    "a character, so its `jobs:` line on line 1 does not begin at "
                    "column zero to it; save the file as UTF-8 without the mark")
        if any(_RE_JOBS_ISH.match(line) for line in lines):
            return ("its `jobs:` line is quoted, or carries something after the "
                    "colon other than a comment -- a flow mapping, a tag or an "
                    "anchor among them; this reader begins at a bare `jobs:` at "
                    "column zero")
        return "it carries no `jobs:` line at column zero"

    end = len(lines)
    for i in range(start, len(lines)):
        if _is_dedent(lines[i]):
            end = i
            break

    job_indent = _block_indent(lines, start, end)
    if job_indent is None:
        return ("its `jobs:` block holds no `key:` line this reader recognises -- a "
                "job key carrying a flow mapping on its own line is not one")

    child_indent = _block_child_indent(lines, start, end)
    unread = _unread_key_lines(lines, start, end, child_indent)
    if unread:
        where = ", ".join(str(i + 1) for i in unread[:3])
        if len(unread) > 3:
            where += " (and {} more)".format(len(unread) - 3)
        if job_indent > child_indent:
            # Deliberately says nothing about how many records came out, nor
            # about what the lines ARE. The branch is reached by a file that
            # yielded phantoms; by one that yielded nothing at all -- a
            # tab-indented key is the measured case, because `_RE_KEY` counts
            # its `ind` group in characters while `_indent_of` counts spaces;
            # and by a file both parsers measured accept, whose records were
            # read off real job keys, when a property's value is continued
            # shallower than those keys, or when a tag or an anchor line, or a
            # bracket of a flow mapping, opens the block shallower than them. A
            # sentence asserting that records exist is false for one of them,
            # and one asserting that no job key was read is false for another.
            return ("line(s) {} sit at indentation {}, the shallowest in this "
                    "file's `jobs:` block and so where this reader takes its job "
                    "keys to sit, and it does not recognise them as `key:` lines. "
                    "The first line it DID recognise as one sits deeper, at "
                    "indentation {}, so it cannot vouch that any record it took "
                    "from this file was read off a job key rather than off a "
                    "job's own property. A line at the shallowest indentation may "
                    "be a job key this reader cannot read, the continuation of a "
                    "value that a job's property began on a deeper line, a tag or "
                    "an anchor written on a line of its own, a bracket of a flow "
                    "mapping, or a line indented with a tab, which it measures at "
                    "a different width; it does not tell which, so it refuses the "
                    "file".format(
                        where, child_indent, job_indent))
        # Lines at this indentation WERE read as job keys here, so the question
        # left is what the unread lines are, and this reader cannot say. A file
        # that continues a property's value at this indentation reaches this
        # branch as surely as one hiding a job key, and so does one whose block
        # opens on a tag or an anchor line, or a bracket of a flow mapping, at
        # this indentation, so the text states every one. It
        # says where this READER read the keys, not where the file's keys sit:
        # a key-shaped continuation shallower than the real keys can be what it
        # read, and the file's own keys are then elsewhere.
        return ("line(s) {} sit at indentation {}, the shallowest in this file's "
                "`jobs:` block and where this reader read its job keys, "
                "and this reader does not recognise them as `key:` lines. Other "
                "lines at that indentation WERE read as job keys, so a verdict "
                "could be issued on those -- but such a line may be a job key this "
                "reader cannot read, which would then never be graded at all, or "
                "it may be no key: the continuation of a value that a job's "
                "property began on a deeper line, a tag or an anchor written on "
                "a line of its own, or a bracket of a flow mapping. This reader "
                "does not tell these apart, so it refuses the file rather than "
                "grade it on the keys it did read".format(where, child_indent))

    # The third limb, reached only when every line at the shallowest
    # indentation IS a `key:` line to this reader -- so there is no unread line
    # to name, and naming the two lines the limb compares is what tells the
    # author where to look. The text claims neither line is what it looks like:
    # the measured class puts a job key on the first and a value's continuation
    # on the second, and the reader cannot see either fact. A block that opens
    # on a tag or an anchor line, or a bracket of a flow mapping, reaches here
    # too, with the real first key on the second line, so the text names that
    # possibility beside the other.
    displaced = _displaced_key_line(lines, start, end, job_indent)
    if displaced:
        first, first_key = displaced
        return ("its `jobs:` block begins, comments aside, on line {0}, and the "
                "first line this reader recorded a job off is line {1}, at "
                "indentation {2}. It recorded no job off line {3}. That line may "
                "be a job key this reader cannot read, which would then never be "
                "graded -- and line {4} may then be no key at all but the "
                "continuation of a value that a job's property began on an "
                "earlier line, which would make every job recorded here a "
                "phantom. Or line {3} may be no key but a line that opens the "
                "block: a tag or an anchor written on a line of its own ahead of "
                "the first job key, or the opening bracket of a flow mapping. It "
                "does not tell which, so it refuses the "
                "file".format(first + 1, first_key + 1, job_indent,
                              first + 1, first_key + 1))

    # The first limb with every shallowest line a `key:` line, so nothing above
    # named a line. Reached by a file whose every job key this reader reads, when
    # a key-shaped continuation sits shallower than those keys, and by the two
    # invalid shapes the docstring names. It names the shallowest lines and the
    # depth the reader looked for keys at, and claims nothing about what either
    # is: in the first case the reader DID record a job off every real key, so a
    # sentence denying that would be false of it.
    if job_indent > child_indent:
        shallow = [i for i in range(start, end)
                   if lines[i].strip() and not _RE_COMMENT.match(lines[i])
                   and _indent_of(lines[i]) == child_indent]
        where = ", ".join(str(i + 1) for i in shallow[:3])
        if len(shallow) > 3:
            where += " (and {} more)".format(len(shallow) - 3)
        return ("line(s) {} sit at indentation {}, the shallowest in this file's "
                "`jobs:` block and so where this reader takes its job keys to "
                "sit, and each is a `key:` line to it -- but the first line it "
                "recognised as a `key:` line measures {} deep, so it looked for "
                "its job keys at that deeper indentation and took no job off the "
                "shallower lines. It cannot vouch for any job it recorded here, "
                "nor that a line at the shallowest indentation is not a job key "
                "it never graded. Such a line may be a job key, the continuation "
                "of a value that a job's property began on an earlier line, or a "
                "line indented with a tab, which it measures at a different "
                "width; it cannot tell which, so it refuses the file".format(
                    where, child_indent, job_indent))

    if not _key_lines(lines, start, end, job_indent):
        return ("the reader walked it and recorded no job read off a line it "
                "recognised as a job key")
    return ("it failed a test in the definition below for a cause this "
            "diagnosis names no line for, so this reader cannot vouch that it "
            "read the file in full")


def run_census(root, stream=sys.stdout):
    """Grade the workflows against CONTEXT_ORDER. 0 clean / 1 findings / 2 malformed."""
    def out(msg):
        stream.write(msg + "\n")

    def limit():
        # On EVERY exit, the refusal included. The sentence is a standing
        # property of the instrument rather than a gloss on a green result, and
        # a reader who only ever meets the tool on its refusal path should still
        # meet its boundary.
        out("")
        for line in _CENSUS_LIMIT:
            out(line)

    jobs = census_scan(root)
    files = workflow_files(root)

    out("=" * 78)
    out("REGISTRATION CENSUS -- offline. No network, no gh, no token.")
    out("=" * 78)

    def refused(rows):
        # The per-file diagnoses, then the definition and the remedy -- ONE
        # copy, printed by both refusal paths below. The empty-population path
        # used to print neither, so a valid flow-style workflow, alone in its
        # tree, was called MALFORMED with no file named and no remedy given.
        for rel, path in rows:
            out("    {} -- {}".format(rel, _unread_reason(path)))
        if not rows:
            return
        out("A file is read in full, to this reader, when it passes three tests. "
            "It yielded at least one record read off a line it recognised as a "
            "job key, at the shallowest indentation in the file's `jobs:` block, "
            "which is where this reader takes the job keys to sit. Every line at "
            "that indentation is, blank lines and comments aside, a `key:` line "
            "it recognises. A line there that is not may be a job key it cannot "
            "read; the continuation of a value that a job's property began on a "
            "deeper line, which is no key at all and which this reader cannot "
            "tell from one; or a tag, an anchor or a bracket of a flow mapping on "
            "a line of its own. This reader refuses every one of them that it "
            "SEES, so a file whose every job key it reads is refused too when it "
            "carries one of the others there. What it does not see is a line "
            "there beginning with `#`: that is a comment to this reader whatever "
            "the file makes of it, so it is skipped rather than refused, and the "
            "limit block below names the class that follows from it. And the "
            "block begins, comments aside, on the first "
            "line it recorded a job off. A block beginning on any other line "
            "begins on a line this reader recorded no job off. That line may be "
            "a job key it could not read, or a line ahead of the first key that "
            "is no key at all -- a tag or an anchor on a line of its own, or the "
            "opening bracket of a flow mapping; this reader does not tell these "
            "apart and refuses the file whatever the line is, so a file whose "
            "every job key it reads is refused too when such a line opens its "
            "block. A file failing any of the three tests is one this reader "
            "cannot vouch for, and grading the rest would issue a verdict over a "
            "tree it may have read only in part. No verdict is issued.")
        out("Remedy: save the file as UTF-8 text without a byte-order mark, and "
            "write its jobs under a bare `jobs:` line at column zero, as a block "
            "mapping that begins on its first job key, with nothing between the "
            "`jobs:` line and that key but comments and blank lines -- no tag or "
            "anchor on a line of its own. Every line at the job keys' "
            "indentation, comments aside, must be a job key written as a `key:` "
            "line: indented with spaces, optionally quoted but spelled without "
            "escapes, with nothing between the key and its colon and nothing "
            "after the colon but a comment. Where a job property's quoted scalar "
            "or flow collection runs onto later lines, indent every continuation "
            "line deeper than the job keys. Where the file is not a workflow, "
            "move it out of .github/workflows/.")

    # The empty-population refusal, on the same principle as C0 in evaluate():
    # a scan that found nothing to grade has proved nothing about this tree, and
    # must never reach a clean exit. REFUSED, not MALFORMED, for the reason the
    # per-file header below is: a file this reader found no job in may be a
    # valid workflow written in a form it does not read.
    if not jobs:
        out("REFUSED: {} workflow file(s) walked under {}, 0 job(s) found.".format(
            len(files), os.path.join(root, ".github", "workflows")))
        out("A census over an empty population asserts nothing. Nothing was graded.")
        refused(files)
        limit()
        return 2

    # Per-file accountability -- the same principle as the refusal above, applied
    # at the granularity the fail-opens actually arrived through. The refusal
    # above asks whether ANYTHING was graded; this asks it of every file, which
    # is where the answer differs: `census_scan` drops a file it cannot read and
    # says nothing, and the summary line below reports a file count and a job
    # count but never their correspondence, so a reader cannot tell from it that
    # the eighth file contributed none.
    #
    # It is a SET DIFFERENCE, not a list of known-bad shapes. Three separate
    # shapes reached a clean census through this one signature, so a shape list
    # would have been written three times and still missed the fourth; a set
    # relation costs no new code per shape and closes the ones nobody has written
    # yet. Placement is load-bearing: a census that grades seven of eight files
    # and reports CLEAN has reported on a tree it did not read, so the refusal
    # precedes grading rather than annotating it.
    #
    # It exits 2 rather than joining the findings at exit 1, because it is not a
    # finding. "The workflows and the declaration disagree" and "I cannot vouch
    # I read this file" are different claims and must not collapse into one.
    #
    # WHAT THE ASSERTION ASSERTS, in the words it is worth being exact about:
    # every workflow file walked yielded at least one record READ OFF A LINE THIS
    # READER RECOGNISED AS A JOB KEY, AT THE SHALLOWEST INDENTATION IN ITS
    # `jobs:` BLOCK; carries NO LINE AT THAT INDENTATION that this reader failed
    # to recognise as a `key:` line; and has a `jobs:` block that BEGINS ON THE
    # FIRST LINE IT RECORDED A JOB OFF. Three limbs, and each was
    # arrived at by a measurement rather than by design. The second is stronger
    # than "no job key was left unread", and knowingly so: a line there that is
    # no key at all -- a job property's value continued at that indentation --
    # fails it too, because this reader cannot tell it from a key it cannot
    # read, and so does a tag, an anchor or a bracket of a flow mapping on a
    # line of its own there. That false refusal is accepted, because it fails
    # closed (X37-X41).
    #
    # The first limb replaced "at least one record", which was satisfied by a
    # PHANTOM: a file whose only job key went unrecognised still yields a record,
    # read off that job's own `steps:` line, and six key presentations reached
    # CLEAN at exit 0 through exactly that gap (X20-X25).
    #
    # The second limb replaced NOTHING -- it is what the first limb could not
    # reach, and the reason is structural rather than incidental. Provenance is a
    # property of a RECORD, and the file only has to produce ONE good record to
    # discharge a claim made of records. Put a readable job beside the unread one
    # and the file does exactly that, honestly, while the unread job is graded by
    # nobody: nine shapes reached exit 0 that way (X26-X34), including one whose
    # good-looking record was read off the CONTENT of a quoted scalar. No
    # sharpening of the provenance mark closes that, because the mark is not
    # wrong there. So the second limb is a claim about the FILE instead: not
    # "did a good record come out" but "is every line at the key indentation one
    # this reader read as a key". X35 is what keeps it from being a reader that
    # refuses any file holding two jobs.
    #
    # The third limb asks whether the `jobs:` block BEGINS on the first line
    # this reader recorded a job off. Both limbs above are satisfied by a
    # phantom read off a key-shaped continuation that sits shallower than the
    # job keys and ahead of every one of them -- it is the shallowest line, and
    # every line beside it is a `key:` line -- and then every real job key is
    # read as no key at all. Five measured files reached CLEAN, or a finding on
    # the phantom alone, that way (X64, X65). A `jobs:` block begins on its
    # first job key, or on a line above it that is no key -- a tag or an anchor
    # on a line of its own, or a bracket of a flow mapping -- and that phantom
    # is none of them. The third limb is stronger than "no key was displaced",
    # as the second is stronger than its own name: a block that opens on such a
    # line fails it with every key read, and that false refusal is accepted as
    # well, because it fails closed (X72).
    read = set(j["file"] for j in jobs
               if not j["synthesised"] and not j["unread_key"]
               and not j["displaced_key"])
    silent = [(rel, path) for rel, path in files if rel not in read]
    if silent:
        # REFUSED rather than MALFORMED, because a file named here may be a
        # valid workflow: see the definition printed below it.
        out("REFUSED: {} of {} workflow file(s) this reader cannot vouch it read "
            "in full.".format(len(silent), len(files)))
        refused(silent)
        limit()
        return 2

    declared_required = [j for j in jobs if j["posture"] == "required"]
    declared_advisory = [j for j in jobs if j["posture"] == "advisory"]
    out("scanned {} workflow file(s), {} job(s): {} claiming required, {} advisory, "
        "{} undeclared".format(
            len(files), len(jobs), len(declared_required), len(declared_advisory),
            len(jobs) - len(declared_required) - len(declared_advisory)))
    out("graded against CONTEXT_ORDER: {} declared context(s)".format(EXPECTED_COUNT))

    findings = census_findings(jobs)
    out("")
    if findings:
        for code, where, ctx, why in findings:
            out("FINDING {:<12} {:<42} [{}]".format(code, ctx, where))
            out("        {}".format(why))
        out("")
        out("-" * 78)
        out("CENSUS FAILED -- {} finding(s).".format(len(findings)))
        out("  UNREGISTERED  a job claims to bind and the declaration does not carry it.")
        out("                Add the context to CONTEXT_ORDER in this file AND ask the")
        out("                operator to register it in branch protection -- or declare")
        out("                the job `posture=advisory` and say why in the line beneath.")
        out("  ABSENT        the declaration carries a context no job claims. The job was")
        out("                renamed or removed; protection now waits on a check that")
        out("                can never report.")
        out("  UNDECLARED    a job has not answered the question. Put exactly ONE")
        out("                `# gate-efficacy: posture=required` or `=advisory` as the")
        out("                FIRST line of the comment block directly above its job")
        out("                key, indented to match the key. A marker anywhere else in")
        out("                that block answers for no job -- otherwise a comment that")
        out("                merely documents this grammar would answer for one -- and")
        out("                a SECOND marker is two answers, so it is read as none.")
    else:
        out("CENSUS CLEAN -- every job declares a posture, and the set of jobs claiming")
        out("required is set-equal to CONTEXT_ORDER in both directions.")

    limit()
    return 1 if findings else 0


# ==========================================================================
# Transport
# ==========================================================================

def gh_fetch_json(path):
    """GET `path` through `gh api`. Returns (ok, text, err). Never raises."""
    try:
        proc = subprocess.run(["gh", "api", path],
                              capture_output=True, text=True)
    except Exception as exc:                       # noqa: BLE001 - gh may be absent
        return (False, "", "could not run gh: {}".format(exc))
    if proc.returncode != 0:
        return (False, proc.stdout, proc.stderr.strip() or
                "gh exited {}".format(proc.returncode))
    return (True, proc.stdout, "")


def gh_patch_json(path, payload_file):
    """PATCH `path` with `payload_file`. Returns (ok, text, err).

    The narrow-endpoint invariant is re-checked HERE, at the point of the write,
    rather than only where the path is built -- so a later edit that widens the
    target has to defeat the check at the write itself.
    """
    if not path.endswith(SUBRESOURCE_SUFFIX):
        return (False, "", "INVARIANT VIOLATED: refusing to write to {!r}; this "
                           "tool writes only to {}".format(path, SUBRESOURCE_SUFFIX))
    try:
        proc = subprocess.run(
            ["gh", "api", "-X", "PATCH", path, "--input", payload_file],
            capture_output=True, text=True)
    except Exception as exc:                       # noqa: BLE001
        return (False, "", "could not run gh: {}".format(exc))
    if proc.returncode != 0:
        return (False, proc.stdout, proc.stderr.strip() or
                "gh exited {}".format(proc.returncode))
    return (True, proc.stdout, "")


def resolve_repo(explicit):
    """`OWNER/NAME`, from --repo or from the checkout's origin remote.

    Nothing is compiled in: the tool is pointed at a repository, it does not
    carry one. That keeps an owner handle out of a public source file and keeps
    the tool usable from a fork or a renamed remote.
    """
    if explicit:
        return explicit
    try:
        proc = subprocess.run(["git", "remote", "get-url", "origin"],
                              capture_output=True, text=True)
    except Exception:                              # noqa: BLE001
        return None
    if proc.returncode != 0:
        return None
    url = proc.stdout.strip()
    if url.endswith(".git"):
        url = url[:-4]
    if ":" in url and "//" not in url:             # git@host:OWNER/NAME
        url = url.split(":", 1)[1]
    parts = [p for p in url.split("/") if p]
    if len(parts) < 2:
        return None
    return "/".join(parts[-2:])


# ==========================================================================
# Artifacts
# ==========================================================================

def canonical_digest(obj):
    blob = json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()


class CaptureRefused(Exception):
    """Raised when a pre-change artifact could not be captured and verified."""


def capture(fetch, path, dest, label, require_checks=True):
    """Fetch, persist, READ BACK OFF DISK, and re-parse. Any failure refuses.

    The read-back is not ceremony. A fetch that succeeded and a file that was
    written are two different claims, and a truncated or unwritable file is the
    same unrecoverable state as a failed fetch.
    """
    ok, text, err = fetch(path)
    if not ok:
        raise CaptureRefused("{}: fetch failed -- {}".format(label, err))
    try:
        with open(dest, "w", encoding="utf-8") as fh:
            fh.write(text)
    except OSError as exc:
        raise CaptureRefused("{}: could not write {} -- {}".format(label, dest, exc))
    try:
        with open(dest, "r", encoding="utf-8") as fh:
            back = fh.read()
    except OSError as exc:
        raise CaptureRefused("{}: could not read back {} -- {}".format(label, dest, exc))
    try:
        obj = json.loads(back)
    except Exception as exc:                       # noqa: BLE001
        raise CaptureRefused("{}: artifact at {} does not parse -- {}".format(
            label, dest, exc))
    if not isinstance(obj, dict):
        raise CaptureRefused("{}: artifact at {} is not a JSON object".format(label, dest))
    if require_checks:
        rsc = obj.get("required_status_checks", obj)
        checks = rsc.get("checks") if isinstance(rsc, dict) else None
        if not isinstance(checks, list) or not checks:
            raise CaptureRefused(
                "{}: artifact at {} carries no non-empty checks array -- an empty "
                "capture is not a rollback artifact".format(label, dest))
    return obj


def sub_checks(obj):
    rsc = obj.get("required_status_checks", obj)
    return rsc.get("checks", []), rsc.get("strict", False)


def compose_payload(pre_obj, app_id=APP_ID):
    """Build the write payload FROM THE LIVE READ, never from a literal list."""
    checks, strict = sub_checks(pre_obj)
    return {"strict": strict,
            "checks": [{"context": c.get("context"), "app_id": app_id} for c in checks]}


def compose_restore(pre_obj):
    """Rebuild the pre-change sub-resource verbatim, `app_id: null` included."""
    checks, strict = sub_checks(pre_obj)
    return {"strict": strict,
            "checks": [{"context": c.get("context"), "app_id": c.get("app_id")}
                       for c in checks]}


def _normalise(obj):
    """Order-insensitive view of a protection object.

    The API does not promise a stable order for `checks`, and a reordered array
    would otherwise read as dozens of differing leaves and drown the one real
    difference the scope diff exists to isolate.
    """
    out = json.loads(json.dumps(obj))
    rsc = out.get("required_status_checks")
    if isinstance(rsc, dict):
        if isinstance(rsc.get("checks"), list):
            rsc["checks"] = sorted(rsc["checks"],
                                   key=lambda c: str(c.get("context")))
        if isinstance(rsc.get("contexts"), list):
            rsc["contexts"] = sorted(rsc["contexts"], key=str)
    return out


def _leaves(obj, prefix=""):
    if isinstance(obj, dict):
        for k in sorted(obj):
            for item in _leaves(obj[k], prefix + "." + str(k)):
                yield item
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            for item in _leaves(v, prefix + "[" + str(i) + "]"):
                yield item
    else:
        yield (prefix, obj)


def scope_diff(pre_obj, post_obj):
    """Differing leaves between two full protection objects, normalised."""
    a = dict(_leaves(_normalise(pre_obj)))
    b = dict(_leaves(_normalise(post_obj)))
    # Sort on (path, repr(value)): leaf VALUES are heterogeneous -- the one leaf
    # this change moves goes from None to int, and those two do not order
    # against each other. Sorting on the raw tuple raises TypeError on exactly
    # the diff this tool exists to produce.
    return sorted(set(a.items()) ^ set(b.items()),
                  key=lambda kv: (kv[0], repr(kv[1])))


# ==========================================================================
# The self-test
# ==========================================================================

def _checks(pairs):
    return json.dumps({"strict": False,
                       "checks": [{"context": c, "app_id": a} for c, a in pairs]})


def _correct_pairs():
    return [(c, APP_ID) for c in CONTEXT_ORDER]


def _pre_pairs():
    return [(c, None if c == "Personal-data gate" else APP_ID) for c in CONTEXT_ORDER]


def assertion_arms():
    """Eleven degenerate inputs that must fail, and one correct input that must pass.

    The first seven (S0-S6) are the canonical matrix: S4, S5 and S6 are the three
    shapes that a weaker "nine contexts, zero nulls" check certifies as SUCCESS.
    S7-S10 are supplementary and exist so that no conjunct the evaluator can emit
    is left unfalsifiable -- an untested conjunct is indistinguishable from a
    conjunct that cannot fail.
    """
    correct = _correct_pairs()
    dropped = [p for p in correct if p[0] != "Corpus hygiene suite (test-corpus-hygiene.sh)"]
    wrong_app = [(c, 99999) for c, _ in correct]
    stringy = [(c, str(APP_ID)) for c, _ in correct]
    renamed = [(("Personal data gate" if c == "Personal-data gate" else c), a)
               for c, a in correct]
    duped = dropped + [("Personal-data gate", APP_ID)]
    extra = correct + [("Tenth check (never declared)", APP_ID)]

    return [
        # id,  what it models,                                   raw,                      rc, conjuncts
        ("S0", "the live pre-change state: one context unpinned", _checks(_pre_pairs()), 1, {"C3", "C4"}),
        ("S1", "an empty checks array -- the shape a failed read produces", '{"checks": []}', 1, {"C1", "C2"}),
        ("S2", "an empty object -- the other shape a failed read produces", "{}", 2, {"C0"}),
        ("S3", "the write dropped one context (8 contexts, 0 null)", _checks(dropped), 1, {"C1", "C2"}),
        ("S4", "every context pinned to the WRONG app (9, 0 null)", _checks(wrong_app), 1, {"C4"}),
        ("S5", "app_id stored as the STRING form (9, 0 null)", _checks(stringy), 1, {"C4"}),
        ("S6", "one context RENAMED by the write (9, 0 null, right app)", _checks(renamed), 1, {"C2"}),
        ("S7", "a context duplicated: 9 entries, 8 distinct", _checks(duped), 1, {"C2", "C2b"}),
        ("S8", "an unexpected tenth context, all pinned", _checks(extra), 1, {"C1", "C2"}),
        ("S9", "checks present but not an array", '{"checks": "nine"}', 2, {"C0"}),
        ("S10", "unparseable JSON", '{"checks": [', 2, {"C0"}),
    ], ("P0", "the correct post-write shape", _checks(correct), 0, set())


def _rec_writer(log):
    def _w(path, payload_file):
        log.append((path, payload_file))
        return (True, "{}", "")
    return _w


def _fetcher(script):
    """Build a fetcher from a list of (ok, text, err) responses, consumed in order."""
    state = {"i": 0}

    def _f(path):
        i = state["i"]
        state["i"] = i + 1
        if i >= len(script):
            return (False, "", "fetcher exhausted")
        return script[i]

    return _f


def guard_arms():
    """Drive the orchestrator offline and assert the capture refusal is real.

    Each arm names the exit code the orchestrator must reach AND the number of
    writes it must have attempted. The write count is the load-bearing half: an
    orchestrator that returned the right code after having already written is
    indistinguishable, by exit code alone, from one that refused.
    """
    pre = _checks(_pre_pairs())
    post = _checks(_correct_pairs())
    full_pre = json.dumps({"required_status_checks": json.loads(pre),
                           "enforce_admins": {"enabled": False},
                           "required_conversation_resolution": {"enabled": True}})
    full_post = json.dumps({"required_status_checks": json.loads(post),
                            "enforce_admins": {"enabled": False},
                            "required_conversation_resolution": {"enabled": True}})
    # Same POST, checks array reversed -- proves the scope diff is order-insensitive.
    reordered = json.loads(full_post)
    reordered["required_status_checks"]["checks"].reverse()
    full_post_reordered = json.dumps(reordered)

    drifted = _checks(_correct_pairs()[:-1] + [("Tenth check (never declared)", APP_ID)])
    full_drift = json.dumps({"required_status_checks": json.loads(drifted)})
    full_already = json.dumps({"required_status_checks": json.loads(post)})

    return [
        ("G0", "the first capture fails at the transport layer",
         [(False, "", "HTTP 403")], True, 3, 0),
        ("G1", "the capture returns unparseable text",
         [(True, "not json at all", "")], True, 3, 0),
        ("G2", "the capture returns an object with no checks array",
         [(True, "{}", "")], True, 3, 0),
        ("G3", "the SECOND capture (the sub-resource) fails",
         [(True, full_pre, ""), (False, "", "HTTP 500")], True, 3, 0),
        ("G4", "the live context set has drifted from the expected set",
         [(True, full_drift, ""), (True, drifted, "")], True, 4, 0),
        ("G5", "the branch is already correctly pinned -- no write is needed",
         [(True, full_already, ""), (True, post, "")], True, 0, 0),
        ("G6", "a write IS required but --confirm-write was not given",
         [(True, full_pre, ""), (True, pre, "")], False, 6, 0),
        ("G7", "the happy path, with the read-back array returned in a different order",
         [(True, full_pre, ""), (True, pre, ""), (True, post, ""),
          (True, full_post_reordered, "")], True, 0, 1),
    ]


def _synth_workflow(jobs, indent=2, lead=()):
    """Render a minimal workflow file. `jobs` is [(key, name|None, posture|None)].

    `indent` is the indentation of the `jobs:` block's children -- two by
    convention here, and four in the arm that asserts the census reads the
    file's own indentation instead of assuming one. `lead` is raw comment lines
    emitted verbatim directly above the first job key, so an arm can model a
    comment block whose marker is not the block's first line, one whose marker
    sits at an indentation that is not the job's, or -- where `lead` carries a
    marker and `posture` is set too -- one carrying two contradictory markers.

    `key` is interpolated VERBATIM, so an arm models a quoted job key by passing
    the quotes inside the key string. Nothing here needs to know about quoting.
    """
    pad, prop, item = " " * indent, " " * (indent * 2), " " * (indent * 3)
    out = ["name: Synthetic", "", "on:", "  pull_request:", "", "jobs:"]
    out.extend(lead)
    for key, name, posture in jobs:
        if posture is not None:
            out.append("{}# gate-efficacy: posture={}".format(pad, posture))
        out.append("{}{}:".format(pad, key))
        if name is not None:
            out.append("{}name: {}".format(prop, name))
        out.extend(["{}runs-on: ubuntu-latest".format(prop),
                    "{}steps:".format(prop),
                    "{}- run: 'true'".format(item), ""])
    return "\n".join(out) + "\n"


def _synth_unreadable_key(key_lines, beside=False):
    """A workflow whose job carries a key presentation this reader misses.

    `key_lines` is emitted VERBATIM in place of the job key line, so an arm
    models a presentation by passing the presentation and nothing here needs to
    know how any of them is spelled.

    The job's real answer -- `posture=required` -- sits above its key, where a
    contributor writes it. A SECOND marker sits directly above the job's own
    `steps:` line, at the property indentation, and that placement is the whole
    point of these arms: a record read off `steps:` binds a marker at `steps:`'s
    own indentation, so this is the shape in which a missed key reaches a
    POSTURE rather than reading UNDECLARED. The loud variant is not the
    dangerous one and is not what these arms model.

    `beside` puts a job the reader DOES read ahead of the unreadable one. That
    is not a decoration on the arm, it is the POSITION: with a readable job
    present the file yields a genuine record, so an assertion resting only on
    where a record came from is honestly satisfied and the missed job reaches a
    verdict it was never graded for. Every one of these presentations sat at
    exit 0 in this position until the file-level refusal grew its second limb.
    """
    lead = ("" if not beside else
            "  # gate-efficacy: posture=advisory\n"
            "  readable:\n"
            "    name: Readable job\n"
            "    runs-on: ubuntu-latest\n"
            "    steps:\n"
            "      - run: 'true'\n")
    return ("name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
            + lead +
            "  # gate-efficacy: posture=required\n"
            + key_lines +
            "    runs-on: ubuntu-latest\n"
            "    # gate-efficacy: posture=advisory\n"
            "    steps:\n"
            "      - run: 'true'\n")


def _census_baseline():
    """A synthetic tree that is clean by construction: one job per declared
    context, all markered required, plus one job that is legitimately advisory.

    Synthetic ON PURPOSE. Arms built from the live `.github/workflows/` tree
    would change verdict whenever a workflow is added, so the self-test would
    stop being a property of this file and start being a property of the
    repository around it. The live tree is what `--census` grades; these arms
    grade `--census`.
    """
    files = {}
    for i, ctx in enumerate(CONTEXT_ORDER):
        files[".github/workflows/synth-{:02d}.yml".format(i)] = _synth_workflow(
            [("job{:02d}".format(i), ctx, "required")])
    files[".github/workflows/synth-advisory.yml"] = _synth_workflow(
        [("advisory-job", "Synthetic advisory job", "advisory")])
    return files


def census_arms():
    """Inputs the census must grade a stated way, in the `assertion_arms` shape.

    Each arm is (id, what it models, {relative path: content}, want_rc, want_codes).
    X0 is the CONTROL: without an arm that reaches rc 0 over a non-empty
    population, every failing arm below is equally satisfied by a census that
    rejects everything.
    """
    base = _census_baseline()
    tenth = CONTEXT_ORDER[-1]

    unregistered = dict(base)
    unregistered[".github/workflows/synth-new.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "required")])

    renamed = dict(base)
    renamed[".github/workflows/synth-{:02d}.yml".format(len(CONTEXT_ORDER) - 1)] = \
        _synth_workflow([("job{:02d}".format(len(CONTEXT_ORDER) - 1),
                          tenth + " RENAMED", "required")])

    unmarked_new = dict(base)
    unmarked_new[".github/workflows/synth-new.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", None)])

    advisory_new = dict(base)
    advisory_new[".github/workflows/synth-new.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "advisory")])

    marker_stripped = dict(base)
    marker_stripped[".github/workflows/synth-{:02d}.yml".format(len(CONTEXT_ORDER) - 1)] = \
        _synth_workflow([("job{:02d}".format(len(CONTEXT_ORDER) - 1), tenth, None)])

    bad_value = dict(base)
    bad_value[".github/workflows/synth-new.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "REQUIRED")])

    keyed = dict(base)
    keyed[".github/workflows/synth-new.yml"] = _synth_workflow(
        [("new-suite", None, "required")])

    # X9-X11 grade the READER rather than the comparison. Each input below is
    # valid YAML and a real job, and each was invisible-or-misread by the census
    # that shipped -- so each of the three is a way a suite could ship
    # unregistered while the census reported CLEAN at exit 0, which is the exact
    # defect this mode exists to end, recurring through the mode's own parser.
    indent4 = dict(base)
    indent4[".github/workflows/synth-indent4.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "required")], indent=4)

    doc_leak = dict(base)
    doc_leak[".github/workflows/synth-doc-leak.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", None)],
        lead=["  # Declare each job's gate posture with a marker line. The grammar is:",
              "  # gate-efficacy: posture=advisory",
              "  # ...as the FIRST line of the comment block above the job key."])

    stray_col0 = dict(base)
    stray_col0[".github/workflows/synth-col0.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", None)],
        lead=["# gate-efficacy: posture=advisory"])

    # X12 grades the binding rule where the block gives TWO answers. The order
    # below is the one an editing accident actually produces: a contributor
    # ADDING a marker writes it against the job key, so the new line lands at
    # the BOTTOM and the stale one is left on top. Whichever end a rule binds,
    # it discards the other silently -- and this end is the dangerous one,
    # because binding the superseded `advisory` lets a job that claims to bind
    # ship under a CLEAN verdict at exit 0. The arm asserts the census declines
    # to choose instead.
    two_markers = dict(base)
    two_markers[".github/workflows/synth-two-markers.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "required")],
        lead=["  # gate-efficacy: posture=advisory"])

    # X13-X19 grade the reader's KEY-level and FILE-level contracts. Every input
    # below is valid YAML and a real job, and all seven were constructed and then
    # MEASURED against the reader that shipped: five reached CENSUS CLEAN at exit
    # 0, and the other two were graded under a name no line of the file carries.
    #
    # X13-X16 are one family: the two quoting characters a key may carry, each an
    # independent alternative of one pattern. They were once argued to exhaust the
    # legal domain, on the ground that no legal job ID carries a quoting escape.
    # That ground is true of the VALUE and irrelevant to its PRESENTATION, and
    # X20-X25 are the six presentations that falsified it. X17-X19 are the other
    # family: three different causes, one signature -- the file contributed zero
    # job records and nothing said so.
    quoted_key = dict(base)
    quoted_key[".github/workflows/synth-quoted.yml"] = _synth_workflow(
        [('"new-suite"', "New suite (test-new-suite.sh)", "required")])

    single_quoted = dict(base)
    single_quoted[".github/workflows/synth-squoted.yml"] = _synth_workflow(
        [("'new-suite'", "New suite (test-new-suite.sh)", "required")])

    phantom_marker = dict(base)
    phantom_marker[".github/workflows/synth-phantom.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        '  "new-suite":\n'
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    # gate-efficacy: posture=advisory\n"
        "    steps:\n"
        "      - run: 'true'\n")

    flow_steps = dict(base)
    flow_steps[".github/workflows/synth-flowsteps.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        '  "new-suite":\n'
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [{run: 'true'}]\n")

    flow_jobs = dict(base)
    flow_jobs[".github/workflows/synth-flowjobs.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\n"
        "jobs: {new-suite: {name: New suite (test-new-suite.sh), "
        "runs-on: ubuntu-latest, steps: [{run: 'true'}]}}\n")

    quoted_jobs = dict(base)
    quoted_jobs[".github/workflows/synth-quotedjobs.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "required")]).replace(
            "\njobs:\n", '\n"jobs":\n')

    no_key = dict(base)
    no_key[".github/workflows/synth-nokey.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite: {name: New suite (test-new-suite.sh), "
        "runs-on: ubuntu-latest, steps: [{run: 'true'}]}\n")

    # X20-X25 are six presentations of ONE legal job ID, each ALONE in its file.
    # Each is valid YAML, each is read by an independent parser and by actionlint
    # as the job `new-suite`, and none matches `_RE_KEY`. They are here because
    # the per-file assertion does not catch them on its own: when the key goes
    # unrecognised the reader keeps scanning, finds the job's own `steps:`, and
    # records a job off it -- so the file DOES yield a record, the assertion is
    # satisfied by that record, and the census reaches CLEAN at exit 0 over a job
    # declaring `posture=required` under a name CONTEXT_ORDER does not carry.
    #
    # The presentations divide on two axes and both are exercised, because a
    # remedy aimed at one axis leaves the other standing: quoting (the `\u` and
    # `\x` escapes, which no bounded key pattern can enumerate) and spacing (a
    # space before the `:`, in each of the three spellings a key may take). The
    # explicit-key form is the sixth and is neither. The list is NOT the class --
    # no pattern is exhaustive over YAML key presentation, which is why the
    # remedy these arms grade is a property of the RECORD rather than of the key.
    unread_keys = (
        ("X20", "the YAML explicit-key form",
         "  ? new-suite\n  : name: New suite (test-new-suite.sh)\n"),
        ("X21", "a key spelled with a `\\u` escape",
         '  "new\\u002Dsuite":\n    name: New suite (test-new-suite.sh)\n'),
        ("X22", "a key spelled with a `\\x` escape",
         '  "new\\x2Dsuite":\n    name: New suite (test-new-suite.sh)\n'),
        ("X23", "a bare key carrying a space before its `:`",
         "  new-suite :\n    name: New suite (test-new-suite.sh)\n"),
        ("X24", "a double-quoted key carrying a space before its `:`",
         '  "new-suite" :\n    name: New suite (test-new-suite.sh)\n'),
        ("X25", "a single-quoted key carrying a space before its `:`",
         "  'new-suite' :\n    name: New suite (test-new-suite.sh)\n"),
    )
    unread_arms = []
    for aid, what, key_lines in unread_keys:
        tree = dict(base)
        tree[".github/workflows/synth-unread.yml"] = _synth_unreadable_key(key_lines)
        unread_arms.append((
            aid,
            "PHANTOM: {} -- alone in its file. The reader misses the key, records "
            "a job off the `steps:` line instead, and that record satisfies the "
            "per-file assertion. A record read off a job's own properties is not "
            "evidence the file was read".format(what),
            tree, 2, set()))

    # X26 was the RESIDUAL arm: it pinned what the record-provenance refusal did
    # NOT close, wanting rc 0, and its comment said that an arm going red here is
    # an author who has narrowed the residual. An author did. Its tree is
    # unchanged -- byte for byte the shape that reached CLEAN -- and only its
    # expectation moved, so the flip is the measurement and not a new arm
    # agreeing with new code. X27-X31 are the other five presentations in the
    # same position, and X32-X34 are the three further members that reached
    # CLEAN there; X35 is the specificity arm that keeps the whole family honest.
    residual = dict(base)
    residual[".github/workflows/synth-residual.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite :\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X27-X31: the five presentations X26 does not model, each BESIDE a job the
    # reader reads. Six arms for six presentations rather than one for the class
    # and a note about the rest: the two axes are independent, and an assertion
    # over the spacing axis establishes nothing about the escape axis.
    by_presentation = {aid: (what, key_lines) for aid, what, key_lines in unread_keys}
    beside_arms = []
    for aid, src in (("X27", "X20"), ("X28", "X21"), ("X29", "X22"),
                     ("X30", "X24"), ("X31", "X25")):
        what, key_lines = by_presentation[src]
        tree = dict(base)
        tree[".github/workflows/synth-beside.yml"] = _synth_unreadable_key(
            key_lines, beside=True)
        beside_arms.append((
            aid,
            "CLOSED, was open: {} -- beside a job the reader reads. The file "
            "yields a genuine record, so record provenance alone cannot refuse "
            "it; the file-level refusal fires on the unread key LINE instead"
            .format(what),
            tree, 2, set()))

    # X32-X34 are three further members, each measured at exit 0 in this same
    # position and none of them a key-spelling trick. They are here because a
    # family named by its six known members invites the reader to treat the six
    # as the class, which is the error the limit block was corrected for twice.
    #
    # X32's anchor is REFERENCED by a third job, so the file is a workflow
    # `actionlint` accepts at rc 0 rather than one it rejects for an unused
    # anchor -- an arm modelling an invalid workflow would prove nothing about a
    # shippable one.
    anchored = dict(base)
    anchored[".github/workflows/synth-anchor.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite: &a\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  clone: *a\n")

    # X33 is the arm that keeps ORDERING from being read as the condition. The
    # unreadable key comes FIRST here, and the file still reached CLEAN, because
    # its `steps:` is a flow sequence -- so the block holds no `key:` line above
    # the readable one and the first key the reader recognises is the readable
    # job's, at the block's own indentation. Position is not what decides it.
    flow_before = dict(base)
    flow_before[".github/workflows/synth-flowbefore.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite :\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [{run: 'true'}]\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X34 is the adversarial one, and it is the arm that falsifies the sentence
    # the limit block used to print. A READABLE job's `name:` is a multi-line
    # double-quoted scalar whose continuation sits AT the job-key indentation and
    # is shaped like a marker comment plus a `steps:` key. The reader takes a
    # record off SCALAR CONTENT at the key indentation -- so that record is not
    # read off a job key, is not marked synthesised either, and the file reached
    # CLEAN. Both parsers read this file as two jobs and `actionlint` exits 0 on
    # it. The same scalar continued one column SHALLOWER already refused, which
    # is why this variant and not that one is the arm.
    scalar_phantom = dict(base)
    scalar_phantom[".github/workflows/synth-scalar.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        '    name: "Readable\n'
        "  # gate-efficacy: posture=advisory\n"
        "  steps:\n"
        '  job"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite :\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [{run: 'true'}]\n")

    # X36 pins the residual the limit block now names, so it is executable rather
    # than only described -- the role X26 held until an author closed what X26
    # pinned. The `jobs:` block ends at the first non-comment line at column zero,
    # and a double-quoted scalar continued at column zero is such a line, so the
    # block ends INSIDE the first job and the second job is never walked at all.
    # No limb of the file-level refusal can see it: the truncated block yields
    # a genuine record, leaves nothing unread within itself, and begins on its
    # first key.
    #
    # This is not a remnant of the class above and no widening of that refusal
    # reaches it -- the file is not mis-READ, it is under-walked. It behaves
    # identically at the SHA before this change, so it is pre-existing rather than
    # introduced. An arm that goes red here is an author who has closed it: read
    # the limit block before changing this, exactly as X26 asked and was answered.
    truncated = dict(base)
    truncated[".github/workflows/synth-truncated.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        '    name: "Readable\n'
        'job"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X35 is the SPECIFICITY arm for the whole X26-X34 family, and without it
    # every one of them is satisfied by a reader that refuses any file holding
    # two jobs. Two jobs, both read, the second unregistered: the refusal must
    # NOT fire, and the finding must still arrive at rc 1.
    two_readable = dict(base)
    two_readable[".github/workflows/synth-two.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X37-X41 are an ACCEPTED FALSE REFUSAL, pinned deliberately: they DOCUMENT a
    # known defect. They want the refusal this reader gives, so they go red when
    # a reader stops giving it, whatever the reason -- which is why the red below
    # needs reading with care. In every file below, each job key IS a
    # `key:` line this reader reads. What lands at the job-key indentation is the
    # CONTINUATION of a value that a job's own PROPERTY began on an earlier line
    # -- a multi-line quoted scalar, or a flow collection still open. Such a line
    # is neither a job key nor part of one, but this reader cannot tell it from a
    # key it cannot read, so it refuses the file at rc 2. The verdict each file
    # deserves is its second job's: rc 1 UNREGISTERED.
    #
    # The refusal is kept because it fails closed: nothing ships ungraded, and
    # the refusal names the line. A lexer that spared these lines did repair all
    # five, and it failed OPEN -- it spared real job keys too, the direction X43,
    # X48-X63 and X68-X69 catch for the readers measured -- so it was taken back
    # out and this false refusal was accepted in its place. A correct future
    # fix, one that knows what every earlier line left open, turns each of these
    # arms RED at rc 1 UNREGISTERED.
    #
    # That red is NECESSARY for a correct fix and NOT SUFFICIENT. Two readers
    # that spare lines without knowing what is open were measured producing
    # exactly this red, with every other census arm but X44 green, while
    # losing real job keys on valid shapes no arm then carried. So before these
    # arms are re-labelled as repaired, X43, X48-X63, X68 and X69 must all stay
    # green -- and those catch the sparing readers measured, not every reader,
    # so a new one still owes a measurement of its own. Only then re-label
    # these arms rather than put rc 2 back.
    #
    # Five members and one paired control, because the two constructions are
    # independent: a quoted scalar continues by not having closed, a flow
    # collection by not having been bracketed shut, and a fix aimed at one leaves
    # the other refused. X41 drops the second job entirely, so the class is not
    # read as a property of files holding two. X42 is the control on the DEEPER
    # side: with its continuation one column deeper, the file is graded. It
    # confines the refusal from that side only -- a continuation SHALLOWER than
    # the job keys is refused too, as the limit block says.
    cont_double = dict(base)
    cont_double[".github/workflows/synth-cont-double.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        '    name: "Readable\n'
        '  job"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    cont_single = dict(base)
    cont_single[".github/workflows/synth-cont-single.yml"] = \
        cont_double[".github/workflows/synth-cont-double.yml"].replace(
            'name: "Readable', "name: 'Readable").replace('  job"', "  job'")

    cont_seq = dict(base)
    cont_seq[".github/workflows/synth-cont-seq.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [\n"
        "  {run: 'true'}]\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    cont_map = dict(base)
    cont_map[".github/workflows/synth-cont-map.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    env: {\n"
        "  A: 1}\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    cont_alone = dict(base)
    cont_alone[".github/workflows/synth-cont-alone.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    env: {\n"
        "  A: 1}\n"
        "    steps:\n"
        "      - run: 'true'\n")

    cont_deeper = dict(base)
    cont_deeper[".github/workflows/synth-cont-deeper.yml"] = \
        cont_double[".github/workflows/synth-cont-double.yml"].replace(
            '  job"', '   job"')

    # X43 is the arm to read first if a later reader ever SPARES lines where the
    # job keys sit -- and not the last. It catches one construction: a reader
    # that treats the start of a block-context plain scalar's FIRST
    # continuation line as a place a quote may open. Two other sparing readers
    # were measured passing it while losing real keys elsewhere; X68 and X69
    # are the shapes that caught them. It was rebuilt so that the open such a
    # reader might wrongly report SPANS the unread key line -- the dangerous
    # case -- rather than closing above it, where a skip is short and
    # harmless. ONE file carries, in order: a property's double-quoted scalar
    # continued AT the job-key indentation; then a step `name:` written as a
    # PLAIN scalar whose continuation line begins with `'`; then a key this
    # reader cannot read.
    # Nothing is open in YAML at that line start -- a plain scalar's continuation
    # is not a node position, so the `'` is text -- and both parsers read two
    # jobs. A reader that opens a quote there spans the key line with it, and
    # the key leaves the census. No line below the `'` carries another one, so
    # nothing closes that quote early and shortens the span.
    cont_and_unread = dict(base)
    cont_and_unread[".github/workflows/synth-cont-unread.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        '    name: "Readable\n'
        '  job"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - name: a step that keeps going\n"
        "          'til the very end\n"
        '        run: "true"\n'
        "  # gate-efficacy: posture=required\n"
        "  new-suite :\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        '      - run: "true"\n')

    # X44 pins a PRE-EXISTING PHANTOM exactly as this reader emits it: it
    # DOCUMENTS a known defect and detects none. A flow collection's continuation
    # can be shaped exactly like a key -- `  A:` is a mapping entry INSIDE the
    # flow, not a job -- and this reader records a job off it and grades it, so
    # the census emits an UNDECLARED naming a line of the file that is not a job.
    # Every reader of this file before the lexer did the same. The exit code is
    # right: `new-suite` really is UNREGISTERED, so rc 1 is the verdict the file
    # earns. The finding set is not: the UNDECLARED is false. On THIS shape the
    # phantom fails closed, adding a red finding and hiding none -- and that is a
    # property of the shape, not of the construction. The same construction with
    # a marker line above the key-shaped line and a `name:` line below it claims
    # a declared context and fails OPEN, masking ABSENT: X67 pins that. The
    # lexer's `keys` filter removed both phantoms, but the filter read the
    # lexer's output, so it left with the lexer. A correct future fix that stops
    # reading keys inside an open flow turns this arm red at UNREGISTERED alone,
    # and must re-label it.
    cont_keyish = dict(base)
    cont_keyish[".github/workflows/synth-cont-keyish.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    env: {\n"
        "  A:\n"
        "    1}\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X45-X46 pin further members of X36's class. X36 alone pins ONE
    # point in it, so an author who closes that point turns X36 green with these
    # two still open -- the opposite of what a tripwire is for. Both are valid to
    # both parsers and both reach a CLEAN census, exactly as X36 does. X46's flow
    # sequence is its job's `steps:`, which takes a sequence: under `env:`, which
    # takes a mapping, actionlint rejects the file, and an arm modelling an
    # invalid workflow proves nothing about a shippable one.
    trunc_single = dict(base)
    trunc_single[".github/workflows/synth-trunc-single.yml"] = \
        truncated[".github/workflows/synth-truncated.yml"].replace(
            'name: "Readable', "name: 'Readable").replace('job"', "job'")

    trunc_seq = dict(base)
    trunc_seq[".github/workflows/synth-trunc-seq.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [\n"
        "{run: 'true'}]\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X47 is the one input that never reached any exit at all. `census_scan`
    # caught `OSError` and let `UnicodeDecodeError` through, so a workflow file
    # that is not UTF-8 killed the process before `run_census` reached any
    # `return`: no census, no verdict, no limit block, just a traceback. It failed
    # closed -- a non-zero status is red in CI -- but a reader that cannot say
    # WHICH file it choked on has told the author nothing. The bytes below are
    # Latin-1, so the file is not valid UTF-8 at all rather than merely unusual.
    not_utf8 = dict(base)
    not_utf8[".github/workflows/synth-latin1.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: Caf\u00e9 suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n").encode("latin-1")

    # X48-X63 pin one FAMILY in a direction no arm pinned before them: a skip
    # that SPANS a job-key line. They pin the family they were built from, not
    # the direction. Each is a plain scalar in BLOCK context, carried by a `key:`
    # value, tripping on its FIRST continuation line. Two readers that spare
    # lines were measured passing all sixteen, and every other census arm bar
    # X37-X41 and X44, while losing real job keys on valid shapes outside the
    # family: both of them on a plain scalar inside a flow collection, and one
    # of them also on a name wrapped over three lines and on a `- plain`
    # sequence entry. X68 and X69 carry the first two of those.
    #
    # Each file wraps a PLAIN scalar -- a job `name:` or a step
    # `name:` -- onto a continuation line that begins with one of the four
    # characters that open something in flow syntax, and then declares a second
    # job. A plain scalar's continuation is not a node position, so in YAML that
    # character is text and nothing is open; both parsers read two jobs. A reader
    # that treats every line start as a node position opens a quote or a flow
    # there that never closes, and every line below it -- the second job's key
    # included -- reads as the continuation of a value. A reader that did this
    # was measured: all sixteen of these reached rc 0 under it.
    #
    # Four characters, two carriers and two key forms, and all sixteen are armed,
    # because each axis is an independent alternative -- the reason X13 and X14
    # are two arms. The tails are chosen so that NOTHING below the trigger closes
    # what it would open: after a quote, no line carries that quote character;
    # after a bracket, none carries its closer. A tail that closed the open early
    # would end the span above the key line, and the arm would be measuring its
    # tail. The READABLE form must grade UNREGISTERED at rc 1 -- the job is there
    # and this reader reads it -- and the UNREADABLE form must refuse at rc 2.
    spans = (("'", "'til the very end", '"'),
             ('"', '"quoted phrase to come', "'"),
             ("[", "[see the note below", '"'),
             ("{", "{subject to change", '"'))
    span_arms = []
    for trigger, text, q in spans:
        run = "run: {0}true{0}".format(q)
        carriers = (
            ("a job `name:`",
             "    name: a build that keeps going\n"
             "      " + text + "\n"
             "    runs-on: ubuntu-latest\n"
             "    steps:\n"
             "      - " + run + "\n"),
            ("a step `name:`",
             "    name: Readable job\n"
             "    runs-on: ubuntu-latest\n"
             "    steps:\n"
             "      - name: a step that keeps going\n"
             "          " + text + "\n"
             "        " + run + "\n"))
        for carrier, props in carriers:
            for key_line, want_rc, want_codes, then in (
                    ("  new-suite:\n", 1, {"UNREGISTERED"},
                     "a job key this reader READS. The job is there and must "
                     "grade UNREGISTERED; a reader that spans it drops the job "
                     "with no record, no finding and no refusal"),
                    ("  new-suite :\n", 2, set(),
                     "a key this reader cannot read. The file must refuse; a "
                     "reader that spans it reaches CLEAN over a job claiming "
                     "required")):
                tree = dict(base)
                tree[".github/workflows/synth-span.yml"] = (
                    "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
                    "  # gate-efficacy: posture=advisory\n"
                    "  readable:\n" + props +
                    "  # gate-efficacy: posture=required\n" + key_line +
                    "    runs-on: ubuntu-latest\n"
                    "    steps:\n"
                    "      - " + run + "\n")
                span_arms.append((
                    "X{}".format(48 + len(span_arms)),
                    "FAIL-OPEN DIRECTION: {} wrapped as a PLAIN scalar whose "
                    "continuation line begins with `{}`, then {}".format(
                        carrier, trigger, then),
                    tree, want_rc, want_codes))

    # X64-X65 pin class V: a DISPLACED key indentation. A job property's quoted
    # scalar or flow collection is continued onto a line that is shaped like a
    # key and sits SHALLOWER than the job keys, and that line comes ahead of
    # every line this reader reads as a key. The first key line it recognises
    # is then that continuation, the shallowest line in the block agrees with
    # it, and this reader takes its indentation to be the jobs' own -- so every
    # real job key, deeper than that, is read as no key at all. The first two
    # limbs of the file-level refusal are honestly satisfied, because the record
    # they check is the phantom, so until the third limb these files left every
    # real job out of the census with no record, no finding and no refusal. The
    # first job key must be one this reader cannot read, or it would itself be
    # the first key line; each file here also carries a canonical, readable
    # `new-suite:` claiming required, which went unrecorded with the rest. Both
    # parsers measured accept both files, and both reached a CLEAN census before
    # the third limb; the line the block begins on is what refuses them now.
    #
    # Two constructions, because they continue for different reasons: a quoted
    # scalar by not having closed, a flow collection by not having been
    # bracketed shut. X64 spells its first key with a space before the colon;
    # X65 anchors it and aliases it from a third job.
    displaced = dict(base)
    displaced[".github/workflows/synth-displaced.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  lint :\n"
        '    name: "Lint\n'
        " # gate-efficacy: posture=advisory\n"
        " steps:\n"
        '    job"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    displaced_flow = dict(base)
    displaced_flow[".github/workflows/synth-displaced-flow.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  lint: &base\n"
        "    runs-on: ubuntu-latest\n"
        "    env: {\n"
        " # gate-efficacy: posture=advisory\n"
        " steps:\n"
        "      one}\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "  clone: *base\n")

    # X66-X67 pin class P, a PHANTOM CLAIM, exactly as this reader emits it:
    # they DOCUMENT a named residual rather than guard against it. The same kind of
    # continuation lands at EXACTLY the job-key indentation, as a marker-shaped
    # line, a key-shaped line and a `name:`-shaped line. Every line there is a
    # `key:` line to this reader, so none of the three limbs fires, and it
    # records a job off the key-shaped line that claims required under the
    # declaration's own last context. The tree has had that context's job removed, so the census owes
    # ABSENT at rc 1 -- and the phantom claim masks it: CLEAN at rc 0. Telling
    # that line from a key needs to know that a quote or a flow is open, and the
    # one reader measured to know it failed open elsewhere and was taken out.
    #
    # Documenting arms cannot be red first: they want what the reader emits, so
    # they are green before and after the change that lands them. A future
    # close turns them red -- at rc 1 ABSENT if it spares the continuation and
    # reads the rest of the file, or at rc 2 if it refuses the file -- and must
    # re-label them to want that verdict, not put rc 0 back. Two constructions
    # for the reason X36, X45 and X46 are three: a close aimed at one leaves the
    # other open. X67 carries no quote at all; its `name:` line is a flow
    # mapping's plain value, which is why no space follows the colon.
    last = ".github/workflows/synth-{:02d}.yml".format(len(CONTEXT_ORDER) - 1)
    phantom_claim = dict(base)
    del phantom_claim[last]
    phantom_claim[".github/workflows/synth-phantom-claim.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        '    name: "Readable\n'
        "  # gate-efficacy: posture=required\n"
        "  claimed:\n"
        '    name: ' + tenth + '"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    phantom_claim_flow = dict(base)
    del phantom_claim_flow[last]
    phantom_claim_flow[".github/workflows/synth-phantom-claim-flow.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: Readable job\n"
        "    runs-on: ubuntu-latest\n"
        "    env: {\n"
        "  # gate-efficacy: posture=required\n"
        "  claimed:\n"
        "    name:" + tenth + "\n"
        "    }\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X68-X69 are the arms X48-X63 do not include. Those sixteen pin one family:
    # a plain scalar in BLOCK context, carried by a `key:` value, whose FIRST
    # continuation line begins with a flow-opening character. Two readers that
    # spare lines -- one treating a line start as a node position only inside a
    # flow, one refusing to open anything on the line directly after a
    # `key: plain` line -- pass all sixteen and every other census arm bar
    # X37-X41 and X44, and still lose a real job key on shapes outside that
    # family. X68 is a plain scalar INSIDE a flow collection, continued onto a
    # line beginning with `'`: it catches both. X69 is a job `name:` wrapped
    # over THREE lines, so the trigger sits on a continuation whose previous
    # line is itself a continuation: it catches the second. Both are valid to
    # both parsers; neither is a claim that these two close the direction.
    span_flow = dict(base)
    span_flow[".github/workflows/synth-span-flow.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    runs-on: ubuntu-latest\n"
        "    steps: [{name: a step that keeps going\n"
        "        'til the very end, run: \"true\"}]\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        '      - run: "true"\n')

    span_wrap = dict(base)
    span_wrap[".github/workflows/synth-span-wrap.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  readable:\n"
        "    name: a build that keeps going\n"
        "      and going and going\n"
        "      'til the very end\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        '      - run: "true"\n'
        "  # gate-efficacy: posture=required\n"
        "  new-suite :\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        '      - run: "true"\n')

    # X70-X71 pin the NAME AXIS, a named residual, exactly as this reader emits
    # it: they DOCUMENT it rather than guard against it. The census grades each
    # job under the text of ONE line -- the first `name:` line at the job's
    # property indentation -- while a YAML parser reads the name from every line
    # its value runs to. Where the line this reader keeps is a declared context
    # and the name a YAML parser reads is not, the job is graded under a context
    # it does not report. Both trees have that context's job removed, so each
    # owes ABSENT for the context and UNREGISTERED for the job that really claims
    # required -- rc 1 -- and each reaches CLEAN at rc 0. Both parsers measured
    # accept each file, and the name a YAML parser reads is the longer one.
    #
    # X70 is N1: a plain `name:` continued onto a second line indented DEEPER
    # than the property, and this reader keeps the first line. Every other
    # residual arm here continues a value on a line no deeper than the key whose
    # value it continues; this one does not, so a parser that refused such a
    # continuation would still read it. X71 is N2: another property's quoted
    # value continued onto a `name:`-shaped line at the property indentation,
    # ahead of the job's own `name:`, which this reader takes for the job's name
    # -- X66's mechanism one level down, a phantom NAME rather than a phantom
    # job. Two arms for two mechanisms, because they close separately: folding a
    # continued `name:` the way the parsers do turns X70 red and leaves X71 green.
    #
    # Documenting arms cannot be red first. A close turns each red -- at rc 1
    # ABSENT and UNREGISTERED if it reads the name the parsers read, or at rc 2 if
    # it refuses the file -- and must re-label it to want that verdict, not put
    # rc 0 back.
    name_cont = dict(base)
    del name_cont[last]
    name_cont[".github/workflows/synth-name-cont.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  hygiene-v2:\n"
        "    name: " + tenth + "\n"
        "      v2\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    name_in_value = dict(base)
    del name_in_value[last]
    name_in_value[".github/workflows/synth-name-in-value.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  hygiene-v2:\n"
        "    runs-on: ubuntu-latest\n"
        "    env:\n"
        '      NOTE: "renamed from the\n'
        "    name: " + tenth + '"\n'
        "    name: Hygiene v2\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X72 is an ACCEPTED FALSE REFUSAL of the THIRD limb, pinned beside X37-X41's
    # deliberately: it DOCUMENTS the over-reach and detects nothing. A `jobs:`
    # block may open on a line carrying node properties alone -- here a `!!map`
    # tag, deeper than the job keys -- and the job key below it is a `key:` line
    # this reader reads, so every record is genuine. The block does not begin on
    # the first line a job was recorded off, though, so the third limb refuses a
    # file both parsers measured accept, whose own verdict is rc 1 UNREGISTERED.
    # The refusal fails closed and its diagnosis names the tag line, and deleting
    # that line clears it. A flow mapping's opening bracket in the same place is
    # refused the same way and is not pinned here: a flow mapping is not the
    # block mapping this reader reads. A close that skips a line carrying only
    # node properties when it finds where the block begins turns this arm red at
    # rc 1 UNREGISTERED, and must re-label it rather than put rc 2 back.
    tag_head = dict(base)
    tag_head[".github/workflows/synth-tag-head.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "    !!map\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X73 pins the never-walked class a second way, and it documents it rather
    # than guarding against it. A top-level scalar -- the workflow's own `name:`
    # -- is continued at column zero, and one of its continuation lines is
    # `jobs:`. This reader begins at the FIRST `jobs:` line at column zero, so it
    # walks a block that opens inside the string and ends at the string's
    # column-zero close, and it never reaches the real `jobs:` block below: the
    # job there, claiming required under a name the declaration does not carry,
    # is neither read nor refused, and the census reaches CLEAN at rc 0 where it
    # owes rc 1 UNREGISTERED. Whatever the phantom block holds is recorded, so a
    # file of this shape can also claim a declared context, as X66 does. Both
    # parsers measured read the file as one job. A close aimed at in-block
    # truncation (X36, X45, X46) need not reach it, which is why it has an arm of
    # its own. A close turns it red -- at rc 1 UNREGISTERED if it walks the real
    # block, or at rc 2 if it refuses the file -- and must re-label it.
    # X74 pins the POSTURE class as emitted: it DOCUMENTS the residual rather
    # than guarding against it, and cannot be red first. `_RE_COMMENT` is `^\s*#`
    # and nothing else, so a leading `#` is the whole of what makes a line a
    # comment to this reader. A job property's quoted scalar continued at the
    # job-key indentation is the line D-58's accepted false refusal fires on --
    # write that continuation so it begins with `#` and the refusal does not fire
    # at all: `_is_dedent`, `_block_child_indent`, `_unread_key_lines` and
    # `_displaced_key_line` each skip it, and `_comment_block_top` admits it as
    # the comment block above the NEXT job key, where `_bind_marker` reads it as
    # a marker. Here `alpha` declares advisory honestly and its `env.NOTE` scalar
    # runs on; the continuation spells `posture=required` and binds to
    # `hygiene-v2`, whose `name:` is the declaration's last context and whose
    # real job this tree lacks. The file declares no posture for `hygiene-v2`
    # anywhere, so the tree owes rc 1 ABSENT and UNDECLARED, and the census
    # reaches CLEAN at rc 0. All three per-file limbs read False. The trailing
    # space before the closing quote is load-bearing: it leaves `_RE_MARKER`'s
    # `(\S+)` group reading `required` rather than `required"`.
    #
    # Measured against its own controls. Replace the marker text with ordinary
    # scalar text and the same file gives rc 1 ABSENT and UNDECLARED, so the
    # census can see this tree. Write the same marker as a genuine comment and it
    # gives rc 0, which is correct. Write the identical continuation at the same
    # indentation WITHOUT the leading `#` and it is refused at rc 2 -- so the `#`
    # is the whole of the difference between a refusal that fails closed and a
    # CLEAN that fails open. PyYAML and actionlint (rc 0) read two ordinary jobs
    # with the names below and no comment anywhere near the continuation.
    #
    # A close is NOT line-local, unlike the closes the other residual arms name:
    # telling this line from a comment means knowing what an earlier line left
    # open, which is the cross-line tracking this reader does not do. The blunt
    # line-local close -- stop skipping comments in the second limb -- was
    # measured to turn about half the arms in this list red, so it is not a
    # candidate. Whatever closes it turns this arm red at rc 1 ABSENT and
    # UNDECLARED, or rc 2 if it refuses the file, and must re-label it rather
    # than put rc 0 back.
    hash_cont = dict(base)
    del hash_cont[last]
    hash_cont[".github/workflows/synth-hash-cont.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  alpha:\n"
        "    name: An advisory probe\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n"
        "    env:\n"
        '      NOTE: "an open scalar\n'
        '  # gate-efficacy: posture=required "\n'
        "  hygiene-v2:\n"
        "    name: " + tenth + "\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X75 is the NAME AXIS's third mechanism, pinned as emitted beside X70 and
    # X71 so the class's arms cannot be read as its membership. `census_scan`
    # strips the name it reads with `.strip('"').strip("'")`: TWO PASSES, each
    # unconditional and each removing EVERY leading and trailing character of
    # its own kind rather than one layer -- all double quotes off each end, then
    # all single quotes -- so a value wrapped in any number of quote layers is
    # read as the text inside all of them. The order is part of the mechanism:
    # the double-quote pass finishes before the single-quote pass begins, so a
    # double quote that only the second pass exposes is never taken.
    #
    # TWO members are planted, and the second one is why the arity is stated
    # rather than counted. In both, the job's name is the declaration's last
    # context wrapped in literal quote characters -- ONE layer of single quotes
    # inside double quotes, and TWO layers of single quotes inside double quotes
    # -- and PyYAML, actionlint and Psych all read a name carrying those quote
    # characters, which is not a declared context. The tree has that context's
    # real job removed, so it owes rc 1 ABSENT and UNREGISTERED -- UNREGISTERED
    # once per member, measured against a parser-faithful reading of this same
    # tree -- and both members mask, so the census reaches CLEAN at rc 0. Adding
    # the second member moved no verdict: this arm wanted rc 0 and no codes
    # before it and wants the same after. The doubled member is the one a one-layer reading
    # of the strip mis-predicts: one layer off each end would leave the context
    # wrapped in single quotes, which is not declared, so a text saying "one
    # layer of each" predicts a FINDING where the reader emits CLEAN.
    #
    # It is a separate arm because it is a separate MECHANISM, not a variation on
    # one: there is no continuation and no phantom `name:` line, only the strip
    # applied to a single line, so the fold that reads a continued `name:` the way
    # the parsers do turns X70 red and leaves this one at rc 0 -- measured. An
    # author who lands that fold and reads the class as one close from shut would
    # re-label two arms while this mechanism stands untouched. A close turns this
    # red at rc 1 ABSENT and UNREGISTERED, or rc 2 if it refuses the file, and
    # must re-label it. So does the NARROWER close of taking at most one layer of
    # each: it reaches the doubled member and not the single-layer one, so this
    # arm goes red while the mechanism stays open -- and that close was measured
    # to turn X66 and X71 red as well, which is why it is deferred rather than
    # taken here.
    name_quoted = dict(base)
    del name_quoted[last]
    name_quoted[".github/workflows/synth-name-quoted.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  hygiene-v2:\n"
        '    name: "\'' + tenth + '\'"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")
    name_quoted[".github/workflows/synth-name-quoted-2.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  hygiene-v3:\n"
        '    name: "\'\'' + tenth + '\'\'"\n'
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    # X76 is the NAME AXIS mechanism that runs BEFORE X75's, pinned as emitted
    # beside X70, X71 and X75. Ahead of the quote passes this reader takes the
    # leading and trailing whitespace off the value -- in `_RE_NAME` on either
    # side of the capture, and again in the bare `.strip()` that heads the
    # chain -- and its notion of whitespace is its runtime's Unicode one, which
    # is wider than the space and tab a plain scalar sheds. So an unquoted
    # `name:` whose value begins or ends in a character inside that gap is read
    # as the text without it.
    #
    # The member planted is the declaration's last context followed by
    # `U+00A0`. The tree has that context's real job removed, so it owes rc 1
    # ABSENT and UNREGISTERED -- PyYAML 6.0.3 and Psych 3.1.0 both read a name
    # carrying the character, which is not a declared context -- and the reader
    # masks both: CLEAN at rc 0.
    #
    # What makes it a measurement rather than an observation is the pair of
    # controls it was built against, neither of which is planted here. The same
    # tree with a VISIBLE trailing character emits rc 1 ABSENT and UNREGISTERED
    # -- that is the verdict this one owes, measured on this tree shape rather
    # than argued. The same tree with a trailing ASCII SPACE emits rc 0 and
    # OWES rc 0, because a plain scalar sheds that character too. So the
    # mechanism is not "this reader trims whitespace": it is the divergence
    # between the two notions, and a close that narrowed the trim to the plain
    # scalar's own set is what would reach it.
    #
    # A close must reach BOTH sites. Removing the `.strip()` alone leaves this
    # arm at rc 0, and narrowing the pattern's whitespace class alone leaves it
    # at rc 0; only both together turn it red at rc 1 ABSENT and UNREGISTERED
    # -- measured on one-occurrence mutants of this reader. Whatever lands must
    # re-label this arm rather than put rc 0 back.
    #
    # Unlike the repeated key, this mechanism has NO backstop: actionlint
    # accepts the member at rc 0, under a control it rejects at rc 1. And
    # unlike X75 it reaches a value carrying no quote at all, which is why it
    # is a separate arm and not a variation on that one: the whitespace a quote
    # pass exposes is never taken, so the character INSIDE the quotes gives a
    # finding, and that direction fails closed.
    name_ws = dict(base)
    del name_ws[last]
    name_ws[".github/workflows/synth-name-ws.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  hygiene-v4:\n"
        "    name: " + tenth + " \n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    second_jobs = dict(base)
    second_jobs[".github/workflows/synth-second-jobs.yml"] = (
        'name: "Synthetic\n'
        "jobs:\n"
        "  # gate-efficacy: posture=advisory\n"
        "  phantom:\n"
        "    runs-on: ubuntu-latest\n"
        '"\n'
        "\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: New suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n")

    return [
        # id,  what it models,                                    files,        rc, codes
        ("X0", "the clean tree: every job declares, and the required set is "
               "set-equal to the declaration", base, 0, set()),
        ("X1", "a new suite that claims to bind and was never declared -- the "
               "AC3 defect itself", unregistered, 1, {"UNREGISTERED"}),
        ("X2", "a declared job renamed: TWO findings, because the remedies differ",
         renamed, 1, {"UNREGISTERED", "ABSENT"}),
        ("X3", "a new job that has not answered the question", unmarked_new, 1,
         {"UNDECLARED"}),
        ("X4", "SPECIFICITY: a new suite that declares itself advisory is "
               "legitimately unregistered", advisory_new, 0, set()),
        ("X5", "a declared job whose marker was deleted -- unanswered AND missing "
               "from the claimed set", marker_stripped, 1, {"UNDECLARED", "ABSENT"}),
        ("X6", "a marker whose value this tool does not recognise -- fails closed "
               "rather than reading as advisory", bad_value, 1, {"UNDECLARED"}),
        ("X7", "a job with no `name:`, whose KEY is therefore its context",
         keyed, 1, {"UNREGISTERED"}),
        ("X8", "STRUCTURAL: no workflow files at all -- an empty population must "
               "never reach a clean exit", {}, 2, set()),
        ("X9", "READER: a job indented four spaces. Valid YAML, a real job, and a "
               "census that assumes two cannot see it -- so it ships unregistered "
               "under a CLEAN verdict", indent4, 1, {"UNREGISTERED"}),
        ("X10", "DISCRIMINATOR: a job that never answered, under a comment block "
                "that merely DOCUMENTS the marker grammar. Read against X4, which "
                "is a job that DECLARED advisory: X4 is clean and this is not, and "
                "a census that cannot tell them apart has lost UNDECLARED",
         doc_leak, 1, {"UNDECLARED"}),
        ("X11", "READER: a marker at column zero -- a file-level note, not this "
                "job's answer. A marker binds at the job key's own indentation "
                "or it does not bind", stray_col0, 1, {"UNDECLARED"}),
        ("X12", "READER: TWO markers in one block, stale on top and the newly "
                "added one against the job key -- the shape an edit produces. A "
                "rule that binds either end discards the other in silence, and "
                "binding the stale `advisory` returns CLEAN over a job that "
                "claims to bind. Two answers is not an answer",
         two_markers, 1, {"UNDECLARED"}),
        ("X13", "READER: a DOUBLE-QUOTED job key. A reader that requires a bare key "
                "does not merely miss it -- it keeps scanning for the block's key "
                "indentation, finds the job's own `steps:`, and records a PHANTOM job "
                "named `steps` which it then grades. The real job ships unregistered "
                "under a finding that names a line of the file that is not a job",
         quoted_key, 1, {"UNREGISTERED"}),
        ("X14", "READER: a SINGLE-QUOTED job key -- the other alternative of the "
                "matched-quote form. Without its own arm that alternative is "
                "unexercised, and a pattern admitting only the double quote would "
                "pass every other arm in this list",
         single_quoted, 1, {"UNREGISTERED"}),
        ("X15", "FAIL-OPEN: a quoted key whose phantom `steps:` carries a comment "
                "directly above it. The phantom BINDS that marker at its own "
                "indentation, reads `advisory`, and the census reaches CLEAN at exit "
                "0 over a job claiming to bind -- measured, not supposed",
         phantom_marker, 1, {"UNREGISTERED"}),
        ("X16", "FAIL-OPEN: a quoted key whose `steps:` is a flow sequence, so the "
                "block holds no bare `key:` line at all and the whole file is dropped "
                "in silence. One ordinary formatting choice reaches it",
         flow_steps, 1, {"UNREGISTERED"}),
        ("X17", "FILE-LEVEL: a flow-style `jobs: {...}` mapping. Nothing is quoted "
                "and no key is hidden -- the file simply carries no line this reader "
                "can start from, so it contributed zero records under a summary that "
                "reports a file count and a job count and never their correspondence",
         flow_jobs, 2, set()),
        ("X18", "FILE-LEVEL: a quoted `\"jobs\":` key. Same signature, different "
                "cause -- which is why the guard is a set difference over files "
                "rather than a list of the shapes anyone has thought of",
         quoted_jobs, 2, set()),
        ("X19", "FILE-LEVEL: a bare `jobs:` whose job key carries a flow mapping on "
                "its own line, so no `key:` line exists for the reader to find. The "
                "third of the three silent skips in `census_scan`, and the one the "
                "quoted-key widening does NOT reach",
         no_key, 2, set()),
    ] + unread_arms + [
        ("X26", "CLOSED, was open: a bare key carrying a space before its `:`, BESIDE "
                "a job the reader does read. This arm wanted rc 0 and its tree has "
                "not changed a byte: the file still yields a GENUINE record, so the "
                "record-provenance limb is still honestly satisfied and still cannot "
                "refuse it. The unread-key limb refuses it on the LINE instead",
         residual, 2, set()),
    ] + beside_arms + [
        ("X32", "CLOSED, was open: an ANCHOR on the job key line (`key: &a`), beside a "
                "job the reader reads. No escape and no stray space -- one ordinary "
                "YAML feature, outside the pattern, which no list of key SPELLINGS "
                "would have reached", anchored, 2, set()),
        ("X33", "CLOSED, was open, and the arm that says ORDERING is not the "
                "condition: the unreadable key comes FIRST, with its `steps:` in flow "
                "style so the block holds no `key:` line above the readable job. A "
                "positional reading of this class -- 'it escapes when it follows a "
                "readable job' -- is falsified here", flow_before, 2, set()),
        ("X34", "CLOSED, was open, and the one that falsified the printed limit: a "
                "READABLE job whose `name:` is a multi-line scalar continued AT the "
                "job-key indentation, shaped like a marker plus a `steps:` key. The "
                "record is read off SCALAR CONTENT -- not off a job key, and not "
                "marked synthesised either -- so 'a file yielding no record read off "
                "a job key is refused' was never true of it",
         scalar_phantom, 2, set()),
        ("X35", "SPECIFICITY for X26-X34: two jobs in one file, BOTH read, the second "
                "unregistered. Without this arm every refusal above is equally "
                "satisfied by a reader that refuses any file holding two jobs -- the "
                "finding must still arrive, at rc 1", two_readable, 1,
         {"UNREGISTERED"}),
        ("X36", "RESIDUAL, pinned deliberately and NOT closed: a quoted scalar "
                "continued at column zero ends the `jobs:` block early, so the job "
                "below it is never walked -- not mis-read, never seen. Every limb of "
                "the file-level refusal is honestly satisfied by the truncated "
                "block, and the census reaches CLEAN over a job claiming required "
                "under an undeclared name. The limit block states this; an arm going "
                "red here is an author who has closed it", truncated, 0, set()),
        ("X37", "ACCEPTED FALSE REFUSAL -- documents a known defect, detects none: a "
                "job `name:` whose double-quoted scalar CONTINUES onto a line landing "
                "at the job-key indentation. Every job key here is a `key:` line this "
                "reader reads; that line is the tail of a string, which this reader "
                "cannot tell from a key it cannot read, so it refuses the file. The "
                "verdict the file deserves is rc 1 UNREGISTERED: a correct future fix "
                "turns this arm red there and must re-label it, not put rc 2 back",
         cont_double, 2, set()),
        ("X38", "ACCEPTED FALSE REFUSAL: the same, SINGLE-quoted. The two quoting "
                "characters are independent alternatives -- the reason X13 and X14 "
                "are two arms -- so a fix that repairs one leaves the other refused. "
                "A correct fix turns this red at rc 1 and must re-label it",
         cont_single, 2, set()),
        ("X39", "ACCEPTED FALSE REFUSAL: a `steps:` FLOW SEQUENCE left open at the end "
                "of its line and closed at the job-key indentation -- a different "
                "construction from the two above, continuing because it was not "
                "bracketed shut rather than because a quote did not close. A correct "
                "fix turns this red at rc 1 and must re-label it", cont_seq, 2,
         set()),
        ("X40", "ACCEPTED FALSE REFUSAL: an `env:` FLOW MAPPING, the other bracket "
                "pair. A correct fix turns this red at rc 1 and must re-label it",
         cont_map, 2, set()),
        ("X41", "ACCEPTED FALSE REFUSAL: the same in a file holding ONE job, so the "
                "class is not read as a property of files holding two. A correct fix "
                "turns this red at rc 1 and must re-label it", cont_alone, 2, set()),
        ("X42", "SPECIFICITY for X37-X41: the X37 file with its continuation ONE "
                "column deeper, at an indentation where no job key sits. It is graded, "
                "never refused, and must stay so. The landing column is the only "
                "difference from X37, so this arm confines the accepted false "
                "refusal from the DEEPER side only. A continuation one column "
                "SHALLOWER than the job keys is refused as well, and no arm here "
                "confines that side",
         cont_deeper, 1, {"UNREGISTERED"}),
        ("X43", "KEEPS X26-X34 CLOSED against the line-sparing reader that shipped "
                "and was taken out -- NOT against every such reader: two others "
                "pass this arm and lose real keys on the shapes X68 and X69 carry. "
                "The file: a property continuation at the job-key indentation, then a "
                "step `name:` whose PLAIN continuation line begins with `'`, then a "
                "key this reader cannot read. Nothing is open in YAML at that line "
                "start and both parsers read two jobs, so the refusal is the verdict "
                "this file earns from ANY reader. Against a reader that spares "
                "nothing the continuation already refuses it; against one that "
                "spares the continuation only the unread key can -- and a reader "
                "that opens a quote at that line start spans the key and reaches "
                "rc 0", cont_and_unread, 2, set()),
        ("X44", "PRE-EXISTING PHANTOM, pinned as emitted -- documents a known defect, "
                "detects none: a flow mapping whose continuation is shaped exactly "
                "like a key (`  A:`). This reader records a job `A` off that line and "
                "reports it UNDECLARED. The exit code is right -- `new-suite` really "
                "is UNREGISTERED -- and the UNDECLARED is false. A correct fix turns "
                "this red at UNREGISTERED alone and must re-label it",
         cont_keyish, 1, {"UNDECLARED", "UNREGISTERED"}),
        ("X45", "RESIDUAL, pinned and NOT closed -- the second member of X36's class: "
                "a SINGLE-quoted scalar continued at column zero. X36 pins one point "
                "in this class; an author who closes that point turns X36 green with "
                "this still open", trunc_single, 0, set()),
        ("X46", "RESIDUAL, pinned and NOT closed -- the third member: a FLOW SEQUENCE "
                "closed at column zero. Not a quoting trick at all, which is why "
                "pinning the class rather than a spelling of it is what these three "
                "arms are for", trunc_seq, 0, set()),
        ("X47", "a workflow file that is not UTF-8 at all. Every other refusal in "
                "this list reaches an exit and prints why; this one killed the "
                "process on an uncaught decode error before `run_census` reached any "
                "`return` -- no census, no verdict, no limit block, and no word about "
                "which file. It must refuse like the rest, and `_unread_reason`'s "
                "first branch, written for exactly this and unreachable until now, is "
                "what names it", not_utf8, 2, set()),
    ] + span_arms + [
        ("X64", "CLASS V, closed: a job property's quoted scalar continued onto "
                "a KEY-SHAPED line one column SHALLOWER than the job keys, ahead "
                "of every line this reader reads as a key. It takes that line's "
                "indentation for the jobs' own, records a phantom off it, and "
                "every real job -- a canonical `new-suite:` claiming required "
                "among them -- goes unrecorded, so a verdict here would leave "
                "them out of the census. The file must refuse",
         displaced, 2, set()),
        ("X65", "CLASS V, closed: the same through a FLOW MAPPING left open, with "
                "an anchored first key aliased by a third job. A close aimed at "
                "quoting alone leaves this one open. The file must refuse",
         displaced_flow, 2, set()),
        ("X66", "CLASS P, a NAMED RESIDUAL pinned as emitted -- it documents the "
                "residual rather than guarding against it, and cannot be red first: "
                "a quoted scalar continued "
                "at EXACTLY the job-key indentation as a marker, a key and a "
                "`name:` line. This reader records a phantom claiming the "
                "declaration's last context, whose real job this tree lacks, and "
                "the ABSENT it owes is masked: CLEAN at rc 0. A close turns this "
                "red at rc 1 ABSENT, or rc 2 if it refuses the file, and must "
                "re-label it", phantom_claim, 0, set()),
        ("X67", "CLASS P, the second member: the same through a FLOW MAPPING, with "
                "no quote anywhere. Pinned as emitted, for the reason X45 and X46 "
                "are pinned beside X36: a close aimed at one construction leaves "
                "the other open. It documents the residual, as X66 does, and a "
                "close turns this red at rc 1 ABSENT, or rc 2 if it refuses the "
                "file, and must re-label it", phantom_claim_flow, 0, set()),
        ("X68", "SPANNING, outside X48-X63's family: a plain scalar INSIDE a flow "
                "collection, continued onto a line beginning with `'`. Nothing is "
                "open there in YAML and both parsers read two jobs, so the second "
                "job must grade UNREGISTERED. Measured: both line-sparing readers "
                "that pass X48-X63 lose that job here", span_flow, 1,
         {"UNREGISTERED"}),
        ("X69", "SPANNING, outside X48-X63's family: a job `name:` wrapped over "
                "THREE lines, the `'` on the third, then a key this reader cannot "
                "read. The file must refuse. Measured: a reader that spares only "
                "the line after a `key: plain` line reaches rc 0 here; the other "
                "sparing reader does not, which is X68's to catch",
         span_wrap, 2, set()),
        ("X70", "NAME AXIS, N1, a NAMED RESIDUAL pinned as emitted -- it documents "
                "the residual rather than guarding against it, and cannot be red "
                "first: a job `name:` continued onto a second line indented DEEPER "
                "than the property. This reader keeps the first line, the "
                "declaration's last context, whose real job this tree lacks, so the "
                "ABSENT and the UNREGISTERED the file owes are both masked: CLEAN "
                "at rc 0. A close turns this red at rc 1 ABSENT and UNREGISTERED, "
                "or rc 2 if it refuses the file, and must re-label it",
         name_cont, 0, set()),
        ("X71", "NAME AXIS, N2, the second member, pinned as emitted: another "
                "property's quoted value continued onto a `name:`-shaped line at "
                "the property indentation, ahead of the job's own `name:`. This "
                "reader takes that line for the job's name -- the declaration's "
                "last context, whose real job this tree lacks: CLEAN at rc 0. "
                "Folding a continued `name:` does not reach it. A close turns this "
                "red at rc 1 ABSENT and UNREGISTERED, or rc 2 if it refuses the "
                "file, and must re-label it", name_in_value, 0, set()),
        ("X72", "ACCEPTED FALSE REFUSAL of the THIRD limb -- documents a known "
                "over-reach, detects none: a `jobs:` block that opens on a `!!map` "
                "tag alone on its line, deeper than the job keys, above a job key "
                "this reader reads. Every record is genuine, but the block does not "
                "begin on the first line a job was recorded off, so the file is "
                "refused. The verdict it deserves is rc 1 UNREGISTERED: a close "
                "that skips a line carrying only node properties turns this red "
                "there and must re-label it, not put rc 2 back",
         tag_head, 2, set()),
        ("X73", "RESIDUAL, pinned and NOT closed -- the never-walked class reached "
                "a second way: the workflow's own `name:`, a double-quoted scalar "
                "continued at column zero, carries a `jobs:` line. This reader "
                "begins at the first `jobs:` line it finds, walks the block that "
                "opens inside the string, and never reaches the real one, so the "
                "job there claiming required is neither read nor refused and the "
                "census reaches CLEAN. A close turns this red at rc 1 UNREGISTERED "
                "if it walks the real block, or rc 2 if it refuses the file, and "
                "must re-label it", second_jobs, 0, set()),
        ("X74", "POSTURE AXIS, a NAMED RESIDUAL pinned as emitted -- it documents "
                "the residual rather than guarding against it, and cannot be red "
                "first: a job property's quoted scalar continued at the job-key "
                "indentation onto a line beginning with `#`. Every limb of the "
                "file-level refusal skips it as a comment and the marker binding "
                "reads it as one, so the job below is graded under a posture no "
                "line of the file declares -- the declaration's last context, "
                "whose real job this tree lacks: CLEAN at rc 0 over a tree owing "
                "ABSENT and UNDECLARED. The identical continuation WITHOUT the `#` "
                "is refused at rc 2, so the `#` is the whole of the difference. A "
                "close needs cross-line tracking, not a line-local test; whatever "
                "closes it turns this red at rc 1 ABSENT and UNDECLARED, or rc 2 "
                "if it refuses the file, and must re-label it",
         hash_cont, 0, set()),
        ("X75", "NAME AXIS, the THIRD mechanism, pinned as emitted: a `name:` whose "
                "YAML value itself begins and ends with quote characters. The "
                "quote-strip is two unconditional passes, ALL double quotes off "
                "each end and then ALL single quotes -- not one layer of each -- so "
                "it reads the declared context inside ANY NUMBER of layers with the "
                "double quotes outside the single, while all three parsers measured "
                "read a name carrying those quotes; the tree's ABSENT and "
                "UNREGISTERED are both masked: CLEAN at rc 0. Quoted the other way "
                "round, single quotes outside double, the double quotes survive the "
                "strip and the name reads as a finding. It plants a member at one "
                "layer and a member at two, and the doubled one is what a one-layer "
                "reading of the strip mis-predicts as a finding. One line, no "
                "continuation, no phantom `name:`, so folding a continued `name:` "
                "does not reach it and this class's arms are instances rather than "
                "its membership. A close turns this red at rc 1 ABSENT and "
                "UNREGISTERED, or rc 2 if it refuses the file, and must re-label it "
                "-- as does the narrower close to at most one layer of each, which "
                "reaches the doubled member only and leaves the mechanism open",
         name_quoted, 0, set()),
        ("X76", "NAME AXIS, the mechanism that runs BEFORE the quote-strip, pinned "
                "as emitted: an unquoted `name:` whose value ends in `U+00A0`. "
                "Ahead of both quote passes this reader takes off every leading and "
                "trailing character its runtime calls whitespace -- a Unicode "
                "notion wider than the space and tab a plain scalar sheds -- so it "
                "reads the declaration's last context bare, while both parsers "
                "measured read a name carrying the character; the tree's ABSENT and "
                "UNREGISTERED are both masked: CLEAN at rc 0. The same tree with a "
                "VISIBLE trailing character emits rc 1 ABSENT and UNREGISTERED, "
                "which is the verdict this tree owes; with a trailing ASCII SPACE it "
                "emits rc 0 and OWES rc 0, because a plain scalar sheds that too -- "
                "so what masks is the DIVERGENCE between the two notions and not the "
                "trimming. The character INSIDE the quotes gives a finding instead, "
                "which is that direction failing closed. actionlint accepts the "
                "member at rc 0 under a control it rejects, so unlike the repeated "
                "key this has no backstop. A close must reach BOTH sites -- the "
                "pattern's whitespace class and the bare `.strip()` -- since "
                "removing either without the other leaves this at rc 0, measured; "
                "whatever lands turns it red at rc 1 ABSENT and UNREGISTERED, or "
                "rc 2 if it refuses the file, and must re-label it",
         name_ws, 0, set()),
    ]


def _materialise(files, root):
    for rel, text in files.items():
        dest = os.path.join(root, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        # `bytes` so an arm can plant a file that is not UTF-8 at all. Written
        # through the same helper as every other arm deliberately: an arm that
        # needed its own materialiser would be testing that materialiser.
        mode, kw = (("wb", {}) if isinstance(text, bytes)
                    else ("w", {"encoding": "utf-8"}))
        with open(dest, mode, **kw) as fh:
            fh.write(text)


def self_test(stream=sys.stdout):
    def out(msg):
        stream.write(msg + "\n")

    failures = []
    out("=" * 78)
    out("SELF-TEST -- offline. No network, no gh, no token, no repository.")
    out("=" * 78)

    arms, positive = assertion_arms()

    # -- vacuity guard ----------------------------------------------------
    canonical = [a for a in arms if a[0] in
                 ("S0", "S1", "S2", "S3", "S4", "S5", "S6")]
    out("")
    out("V -- vacuity guards")
    if len(canonical) != 7:
        failures.append("V1: canonical matrix is {} arms, want 7".format(len(canonical)))
        out("  FAIL V1")
    else:
        out("  PASS V1: the canonical matrix is 7 degenerate arms (S0-S6), the "
            "shape this tool's design was validated against")
    if len(arms) != 11:
        failures.append("V2: {} degenerate arms, want 11".format(len(arms)))
        out("  FAIL V2")
    else:
        out("  PASS V2: 11 degenerate arms in total (7 canonical + 4 supplementary), "
            "1 positive arm")

    armed = set()
    for arm in arms:
        armed |= arm[4]
    emittable = set(EMITTABLE)
    if armed != emittable:
        failures.append("V3: conjunct coverage is not a bijection -- "
                        "unexercised={} unemittable={}".format(
                            sorted(emittable - armed), sorted(armed - emittable)))
        out("  FAIL V3")
    else:
        out("  PASS V3: every conjunct the evaluator can emit {} is named by at "
            "least one arm, and every conjunct an arm names is one the evaluator "
            "can emit -- a bijection, asserted both ways".format(sorted(emittable)))

    # -- A: the degenerate matrix -----------------------------------------
    out("")
    out("A -- degenerate inputs: each must FAIL, and must fail for the stated reason")
    for aid, what, raw, want_rc, want_c in arms:
        rc, failed, _ = evaluate(raw)
        got_c = set(failed) if rc != 2 else {"C0"}
        if rc == 0:
            failures.append("{}: PASSED, and it must not ({})".format(aid, what))
            out("  FAIL {}: reached PASS -- {}".format(aid, what))
        elif rc != want_rc:
            failures.append("{}: rc {} != {}".format(aid, rc, want_rc))
            out("  FAIL {}: rc {}, want {}".format(aid, rc, want_rc))
        elif got_c != want_c:
            failures.append("{}: conjuncts {} != {}".format(aid, sorted(got_c), sorted(want_c)))
            out("  FAIL {}: failed on {}, want exactly {}".format(
                aid, sorted(got_c), sorted(want_c)))
        else:
            out("  PASS {}: rc {} on exactly {} -- {}".format(
                aid, rc, ",".join(sorted(want_c)), what))

    # -- B: the positive arm ----------------------------------------------
    out("")
    out("B -- the positive arm: the control that the assertion is not always-fail")
    pid, pwhat, praw, pwant, _ = positive
    prc, pfailed, plines = evaluate(praw)
    if prc != pwant:
        failures.append("{}: rc {} != {} ({})".format(pid, prc, pwant, ";".join(pfailed)))
        out("  FAIL {}: rc {}, want {} -- {}".format(pid, prc, pwant, ";".join(plines)))
    else:
        out("  PASS {}: rc 0 -- {}. Without this arm every A result above is "
            "satisfied by an assertion that rejects everything".format(pid, pwhat))

    # -- C: conjunct removal ----------------------------------------------
    out("")
    out("C -- conjunct removal: remove the conjuncts an arm names and it must flip "
        "to PASS, which is what makes each conjunct load-bearing rather than decorative")
    skipped = []
    for aid, what, raw, _rc, want_c in arms:
        if "C0" in want_c:
            skipped.append(aid)
            continue
        rc_off, failed_off, _ = evaluate(raw, disabled=frozenset(want_c))
        if rc_off != 0:
            failures.append("{}: still fails on {} with {} removed -- the arm is "
                            "not bound to the conjuncts it names".format(
                                aid, sorted(failed_off), sorted(want_c)))
            out("  FAIL {}: with {} removed it still fails on {}".format(
                aid, sorted(want_c), sorted(failed_off)))
        else:
            out("  PASS {}: removing {} flips it to PASS, so nothing else was "
                "incidentally catching it".format(aid, ",".join(sorted(want_c))))
    out("  DECLARED EXCLUSION: {} are C0 structural arms -- C0 is a precondition, "
        "not a removable conjunct, so the removal matrix does not cover them. "
        "Stated rather than silently skipped.".format(",".join(skipped)))

    # -- D: orchestrator guard arms ---------------------------------------
    out("")
    out("D -- orchestrator guards: the capture refusal, asserted rather than coded")
    for gid, what, script, confirm, want_rc, want_writes in guard_arms():
        tmp = tempfile.mkdtemp(prefix="prc-selftest-")
        log = []
        with open(os.devnull, "w") as sink:
            rc = run_apply(repo="owner/name", branch="main", staging=tmp,
                           confirm=confirm, fetch=_fetcher(script),
                           write=_rec_writer(log), stream=sink,
                           run_self_test=False)
        if rc != want_rc or len(log) != want_writes:
            failures.append("{}: rc {} writes {} -- want rc {} writes {}".format(
                gid, rc, len(log), want_rc, want_writes))
            out("  FAIL {}: rc {} / {} write(s) -- want rc {} / {} write(s) -- {}".format(
                gid, rc, len(log), want_rc, want_writes, what))
        else:
            out("  PASS {}: rc {} and {} write(s) attempted -- {}".format(
                gid, rc, len(log), what))

    # -- E: the registration census ---------------------------------------
    out("")
    out("E -- the registration census: the second assertion over the same expected "
        "set, and the only one that runs with no token at all")
    c_arms = census_arms()

    armed_codes = set()
    for arm in c_arms:
        armed_codes |= arm[4]
    census_emittable = set(CENSUS_CODES)
    if armed_codes != census_emittable:
        failures.append("E0: census code coverage is not a bijection -- "
                        "unexercised={} unemittable={}".format(
                            sorted(census_emittable - armed_codes),
                            sorted(armed_codes - census_emittable)))
        out("  FAIL E0")
    else:
        out("  PASS E0: every code the census can emit {} is named by at least one "
            "arm, and every code an arm names is one the census can emit -- a "
            "bijection, asserted both ways".format(sorted(census_emittable)))

    controls = [a for a in c_arms if a[3] == 0]
    if not controls:
        failures.append("E1: no census arm reaches rc 0 -- every failing arm is "
                        "equally satisfied by a census that rejects everything")
        out("  FAIL E1")
    else:
        out("  PASS E1: {} arm(s) reach rc 0, so the failing arms below are "
            "measurements rather than the output of an always-fail census".format(
                len(controls)))

    baseline_jobs = None
    seen = {}
    for aid, what, files, want_rc, want_codes in c_arms:
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(files, root)
            jobs = census_scan(root)
            seen[aid] = len(jobs)
            if aid == "X0":
                baseline_jobs = len(jobs)
            with open(os.devnull, "w") as sink:
                rc = run_census(root, stream=sink)
            got = set(f[0] for f in census_findings(jobs)) if rc == 1 else set()
        if rc != want_rc or got != want_codes:
            failures.append("{}: rc {} codes {} -- want rc {} codes {}".format(
                aid, rc, sorted(got), want_rc, sorted(want_codes)))
            out("  FAIL {}: rc {} on {} -- want rc {} on {} -- {}".format(
                aid, rc, sorted(got), want_rc, sorted(want_codes), what))
        else:
            out("  PASS {}: rc {} on exactly {} -- {}".format(
                aid, rc, ",".join(sorted(want_codes)) or "no findings", what))

    want_jobs = EXPECTED_COUNT + 1
    if baseline_jobs != want_jobs:
        failures.append("E2: the control arm graded {} job(s), want {} -- a control "
                        "over a degenerate population proves nothing".format(
                            baseline_jobs, want_jobs))
        out("  FAIL E2")
    else:
        out("  PASS E2: the control arm grades {} job(s) -- {} declared contexts plus "
            "one deliberately advisory job. That tenth job is the whole reason the "
            "census reads a declaration instead of enumerating every job name".format(
                baseline_jobs, EXPECTED_COUNT))

    # E3 asserts the POPULATION of the indentation arm, not its verdict. X9's rc
    # already implies the job was read -- UNREGISTERED cannot be emitted for a
    # job the scan never saw -- but an exit code is an inference and a count is a
    # measurement, and "a job is a job whatever its indentation" is a claim about
    # what the reader SEES. This guard is what makes it one.
    want_seen = EXPECTED_COUNT + 2
    if seen.get("X9") != want_seen:
        failures.append("E3: the four-space arm was scanned as {} job(s), want {} -- "
                        "the census is not reading the file's own indentation".format(
                            seen.get("X9"), want_seen))
        out("  FAIL E3")
    else:
        out("  PASS E3: the four-space arm scans {} job(s) -- the baseline's {} plus "
            "the one indented four spaces. The reader takes the indentation from "
            "the file rather than assuming it".format(want_seen, baseline_jobs))

    by_id = {a[0]: a[2] for a in c_arms}

    # E4 asserts the KEY the reader recorded, not how many keys it recorded, and
    # that difference IS the guard. Under the reader that shipped, X13 also scans
    # EXPECTED_COUNT + 2 records -- the phantom `steps` counts as one -- so an
    # E3-style population guard PASSES on the defect. The name is what separates
    # them: `steps` is a line of the file that is not a job; `new-suite` is the
    # job. Both quoting characters are asserted, because they are two independent
    # alternatives of one pattern and an assertion over one establishes nothing
    # about the other.
    for aid, rel in (("X13", ".github/workflows/synth-quoted.yml"),
                     ("X14", ".github/workflows/synth-squoted.yml")):
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(by_id[aid], root)
            got_keys = sorted(j["key"] for j in census_scan(root) if j["file"] == rel)
        if got_keys != ["new-suite"]:
            failures.append("E4/{}: scanned key(s) {} -- want ['new-suite']. A quoted "
                            "key was not read as the job it is".format(aid, got_keys))
            out("  FAIL E4/{}: scanned key(s) {} -- want ['new-suite']".format(
                aid, got_keys))
        else:
            out("  PASS E4/{}: the quoted-key file scans as exactly ['new-suite'] -- "
                "the job the file declares, under the name the file gives it".format(
                    aid))

    # E5 discriminates the per-file refusal from X8's empty-population refusal.
    # Both exit 2, so without this an arm asserting rc 2 could be satisfied by
    # either. Each of these arms must refuse a population it DID partly read --
    # the baseline's own jobs, entire, with the added file contributing nothing.
    want_partial = EXPECTED_COUNT + 1
    for aid in ("X17", "X18", "X19"):
        if seen.get(aid) != want_partial:
            failures.append("E5/{}: scanned {} job(s), want {} -- the refusal is not "
                            "over a partly-read tree, so it re-measures X8's "
                            "empty-population refusal rather than this guard".format(
                                aid, seen.get(aid), want_partial))
            out("  FAIL E5/{}: scanned {} job(s), want {}".format(
                aid, seen.get(aid), want_partial))
        else:
            out("  PASS E5/{}: refuses over {} job(s) it had already read -- a "
                "partly-read tree, not X8's empty one".format(aid, want_partial))

    # E6 asserts WHY X20-X25 refuse, and it is the only thing that distinguishes
    # the remedy that was built from a cheaper one that would pass every arm
    # above: a reader that simply stopped recording anything from those files
    # would also reach rc 2, and would have thrown away the diagnosis with the
    # record. So the file must still CONTRIBUTE its record, and the record must
    # carry the mark. Both limbs are asserted, because either alone is vacuous --
    # a mark that is always set refuses every legitimate file (X0 would fall, but
    # only on its verdict, which is an inference), and a mark that is never set
    # refuses none. `.get` rather than `[...]`, deliberately: a refactor that
    # drops the field reads as UNMARKED and fails this guard, rather than raising
    # out of the self-test and taking every arm below it down as collateral.
    for aid, rel, want_marked, want_total in (
            ("X0", None, 0, EXPECTED_COUNT + 1),
            ("X23", ".github/workflows/synth-unread.yml", 1, EXPECTED_COUNT + 2)):
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(by_id[aid], root)
            scanned = census_scan(root)
        marked = [j for j in scanned if j.get("synthesised")]
        bad = len(scanned) != want_total or len(marked) != want_marked or (
            rel is not None and sorted(j["file"] for j in marked) != [rel])
        if bad:
            failures.append("E6/{}: scanned {} record(s) of which {} marked "
                            "synthesised {} -- want {} of {} from {}. The per-file "
                            "assertion is not resting on the record's provenance".format(
                                aid, len(scanned), len(marked),
                                sorted(j["file"] for j in marked),
                                want_marked, want_total, rel or "no file"))
            out("  FAIL E6/{}: {} of {} record(s) marked synthesised, want {}".format(
                aid, len(marked), len(scanned), want_marked))
        elif want_marked:
            out("  PASS E6/{}: the file CONTRIBUTED its record and that record is "
                "marked synthesised ({} of {}) -- so the refusal is the record's "
                "provenance, not its absence".format(aid, want_marked, want_total))
        else:
            out("  PASS E6/{}: {} of {} record(s) marked synthesised -- the control "
                "arm's records are all read off real job keys, so the mark is a "
                "measurement and not a reader that refuses everything".format(
                    aid, want_marked, want_total))

    # E7 asserts WHY X26-X34 refuse, and it is the limb E6 structurally cannot
    # reach. E6's arm refuses a file whose every record is a phantom; these files
    # yield a record read off a REAL job key, which is exactly the shape that
    # satisfied the record-provenance limb all the way to exit 0. So a refusal
    # here cannot rest on provenance, and asserting the rc alone would not say
    # which limb fired -- every limb reaches rc 2 and the arm could not tell
    # them apart. This asserts the discriminating pair on one file: NOT synthesised,
    # AND carrying the unread-key mark. X0 is the control, and it is the one that
    # matters: a mark that fired on a legitimate tree would refuse every file in
    # it, and every rc-2 arm above would pass for the wrong reason.
    for aid, rel, want_unread, want_synth, want_total in (
            ("X0", None, 0, 0, EXPECTED_COUNT + 1),
            ("X26", ".github/workflows/synth-residual.yml", 1, 0, EXPECTED_COUNT + 2)):
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(by_id[aid], root)
            scanned = census_scan(root)
        unread = [j for j in scanned if j.get("unread_key")]
        synth = [j for j in scanned if j.get("synthesised")]
        bad = len(scanned) != want_total or len(unread) != want_unread or (
            len(synth) != want_synth) or (
            rel is not None and sorted(j["file"] for j in unread) != [rel])
        if bad:
            failures.append("E7/{}: scanned {} record(s), {} marked unread_key {} "
                            "and {} marked synthesised -- want {} unread_key of {} "
                            "from {}, and {} synthesised. The file-level refusal is "
                            "not resting on the unread key line".format(
                                aid, len(scanned), len(unread),
                                sorted(j["file"] for j in unread), len(synth),
                                want_unread, want_total, rel or "no file", want_synth))
            out("  FAIL E7/{}: {} unread_key / {} synthesised of {} record(s) -- "
                "want {} / {}".format(aid, len(unread), len(synth), len(scanned),
                                      want_unread, want_synth))
        elif want_unread:
            out("  PASS E7/{}: the file's record is NOT synthesised -- it was read "
                "off a real job key -- and the file still carries the unread-key "
                "mark ({} of {}). The refusal is the unread LINE, which is the only "
                "limb that can reach this shape".format(aid, want_unread, want_total))
        else:
            out("  PASS E7/{}: {} of {} record(s) carry the unread-key mark -- the "
                "control arm's job keys are all lines this reader recognises, so the "
                "mark is a measurement and not a reader that refuses every "
                "file".format(aid, want_unread, want_total))

    # E8 asserts WHY X64 refuses, and it is the limb neither E6 nor E7 reaches.
    # In a class-V file the first line this reader recognises as a key IS the
    # shallowest line in the block, so the provenance mark is not set; and every
    # line there is a `key:` line to it, so the unread-key mark is not set
    # either. Both earlier limbs are honestly satisfied -- that is how the file
    # reached CLEAN. What is wrong is WHERE the reader took the job keys from: not the
    # line the block begins on. So this asserts the third mark on one file with
    # the other two unset, and X0 is the control that matters -- a mark firing
    # on a legitimate tree would refuse every file in it, and X64 would pass for
    # the wrong reason.
    for aid, rel, want_disp, want_total in (
            ("X0", None, 0, EXPECTED_COUNT + 1),
            ("X64", ".github/workflows/synth-displaced.yml", 1, EXPECTED_COUNT + 2)):
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(by_id[aid], root)
            scanned = census_scan(root)
        disp = [j for j in scanned if j.get("displaced_key")]
        also = [j for j in disp if j.get("synthesised") or j.get("unread_key")]
        bad = len(scanned) != want_total or len(disp) != want_disp or also or (
            rel is not None and sorted(j["file"] for j in disp) != [rel])
        if bad:
            failures.append("E8/{}: scanned {} record(s), {} marked displaced_key {} "
                            "({} also carrying another mark) -- want {} of {} from "
                            "{}, carrying no other mark. The file-level refusal is "
                            "not resting on the displaced key".format(
                                aid, len(scanned), len(disp),
                                sorted(j["file"] for j in disp), len(also),
                                want_disp, want_total, rel or "no file"))
            out("  FAIL E8/{}: {} displaced_key ({} with another mark) of {} "
                "record(s) -- want {}".format(aid, len(disp), len(also),
                                              len(scanned), want_disp))
        elif want_disp:
            out("  PASS E8/{}: the file's record carries the displaced-key mark and "
                "neither other mark ({} of {}). The refusal is WHERE the keys were "
                "read from, which is the only limb that can reach this "
                "shape".format(aid, want_disp, want_total))
        else:
            out("  PASS E8/{}: {} of {} record(s) carry the displaced-key mark -- "
                "every control file's block begins on its first job key, so the "
                "mark is a measurement and not a reader that refuses every "
                "file".format(aid, want_disp, want_total))

    # E9 guards the census's TEXT rather than its verdicts: the limit block,
    # every docstring in this module and every arm label must not write a
    # number in front of a class, a way, a mechanism or a member. The comment
    # above `_CENSUS_LIMIT` says why the rule is enforced rather than stated.
    # E9/controls runs first and is what makes a clean E9 a measurement: the
    # detector must fire on every planted count -- the count the limit block
    # itself once shipped among them -- and on none of the near-misses, so a
    # detector that matches nothing cannot pass. Its reach is stated rather
    # than implied: it does not see a count written after its noun, as an
    # ordinal, by anaphora ("that pair") or as "twice", a count in a comment,
    # or any noun outside those four. Nor does it read every text the census
    # PRINTS: the refusal's definition and remedy, and `_unread_reason`'s
    # per-file diagnoses, are function-local strings rather than a docstring or
    # an arm label, and they are exactly where the census states what it does
    # not see -- so a count planted in either leaves this arm green while the
    # census prints it, measured. The arm's PASS line is scoped to what it
    # reads for that reason, and widening `texts` to reach them is the other
    # route. It goes red wherever --self-test runs,
    # --plan and --apply included (they refuse at exit 5); CI runs --census
    # alone, so it is not a CI gate.
    planted = ("They come apart two further ways, and naming only the first",
               "Three mechanisms for that are measured",
               "and the three classes that still escape both the reader",
               "Two members are pinned so far", "the 2 further ways",
               "both mechanisms close separately", "a pair of ways",
               "CLASS P, the second of two members",
               "it is one of three mechanisms")
    near_misses = ("5 of 5 members refused", "9 out of 9 members read",
                   "NAME AXIS, the THIRD mechanism",
                   "both parsers read as one job. Each mechanism closes separately",
                   "Six arms for six presentations rather than one for the class",
                   "Every open class named below is one measured instance")
    blind = [p for p in planted if not _open_counts(p)]
    loose = [p for p in near_misses if _open_counts(p)]
    if blind or loose:
        failures.append("E9/controls: the detector missed {} and fired on {} -- a "
                        "clean E9 would measure nothing".format(blind, loose))
        out("  FAIL E9/controls: missed {} planted count(s), fired on {} "
            "near-miss(es)".format(len(blind), len(loose)))
    else:
        out("  PASS E9/controls: the detector fires on each of the {} planted "
            "counts, the count the limit block once shipped among them, and on "
            "none of the {} near-misses -- a closed count, an ordinal, and a "
            "number and a noun in different sentences or joined by a function "
            "word".format(len(planted), len(near_misses)))

    texts = [("the limit block", " ".join(_CENSUS_LIMIT)),
             ("the module docstring", globals().get("__doc__") or "")]
    texts += [("{}()'s docstring".format(nm), obj.__doc__ or "")
              for nm, obj in sorted(globals().items())
              if hasattr(obj, "__code__")
              and getattr(obj, "__module__", None) == __name__]
    texts += [("arm {}'s label".format(a[0]), a[1])
              for a in list(arms) + [positive] + list(guard_arms()) + list(c_arms)]
    present = set(w for w, t in texts if t.strip())
    hollow = sorted(set(("the limit block", "the module docstring",
                         "census_scan()'s docstring")) - present)
    hits = [(w, h) for w, t in texts for h in _open_counts(t)]
    if hollow:
        failures.append("E9: nothing to scan in {} -- docstrings stripped (python "
                        "-OO) or missing, so this arm cannot vouch for them".format(
                            ", ".join(hollow)))
        out("  FAIL E9: nothing to scan in {}".format(", ".join(hollow)))
    elif hits:
        for where, hit in hits:
            failures.append("E9: {} writes {!r}, a count of an open set -- state "
                            "the members as instances, or write a closed count "
                            "as a tally in numerals, 5 of 5".format(where, hit))
            out("  FAIL E9: {} writes {!r}".format(where, hit))
    else:
        out("  PASS E9: no text THIS ARM READS writes a number in front of a "
            "class, a way, a mechanism or a member -- the limit block, every "
            "docstring in this module and every arm label, {} texts scanned. "
            "The census prints text this arm does not read: the refusal's "
            "definition and its remedy, and `_unread_reason`'s per-file "
            "diagnoses. Those are outside this measurement".format(len(texts)))

    out("")
    out("-" * 78)
    if failures:
        out("SELF-TEST FAILED -- {} arm(s):".format(len(failures)))
        for f in failures:
            out("  " + f)
        return 1
    out("SELF-TEST PASSED -- 11 degenerate arms all failed on exactly their named "
        "conjuncts, the positive arm passed, every named conjunct is individually "
        "load-bearing, every capture failure refused the write, the registration "
        "census graded every arm the stated way with a control that reached rc 0, "
        "and no text E9 reads counts an open set.")
    return 0


# ==========================================================================
# Live modes
# ==========================================================================

def run_apply(repo, branch, staging, confirm, fetch=gh_fetch_json,
              write=gh_patch_json, stream=sys.stdout, run_self_test=True):
    """capture -> drift-check -> compose -> [write] -> read-back assert -> scope diff.

    `fetch` and `write` are injected so the self-test can drive every branch of
    this function with no network and count the writes it attempted.
    """
    def out(msg):
        stream.write(msg + "\n")

    if run_self_test:
        if self_test(stream) != 0:
            out("ABORT: the self-test did not pass, so this tool is not trusted "
                "to grade a live write.")
            return 5

    prot_path = "repos/{}/branches/{}/protection".format(repo, branch)
    rsc_path = "repos/{}/branches/{}{}".format(repo, branch, SUBRESOURCE_SUFFIX)
    pre_full_f = os.path.join(staging, "prot-PRE.json")
    pre_rsc_f = os.path.join(staging, "rsc-PRE.json")
    patch_f = os.path.join(staging, "rsc-PATCH.json")
    restore_f = os.path.join(staging, "rsc-RESTORE.json")
    post_full_f = os.path.join(staging, "prot-POST.json")

    # 1. CAPTURE. This is the precondition, not a courtesy.
    out("[1/6] capture -- the rollback artifact, before anything is written")
    try:
        pre_full = capture(fetch, prot_path, pre_full_f, "full protection object")
        pre_rsc = capture(fetch, rsc_path, pre_rsc_f, "required_status_checks")
    except CaptureRefused as exc:
        out("CAPTURE REFUSED: {}".format(exc))
        out("Nothing was written. Branch protection has no restore API, so without "
            "a verified pre-change artifact this change would be recoverable only "
            "from memory. Fix the capture and re-run.")
        return 3
    out("      prot-PRE.json  sha256(canonical) = {}".format(canonical_digest(pre_full)))
    out("      rsc-PRE.json   sha256(canonical) = {}".format(canonical_digest(pre_rsc)))

    # The restore payload is written NOW, from the captured artifact, so the
    # rollback exists on disk before the write rather than after it.
    with open(restore_f, "w", encoding="utf-8") as fh:
        json.dump(compose_restore(pre_rsc), fh, indent=2)
    out("      rsc-RESTORE.json written -- rollback payload, app_id nulls preserved")

    # 2. DRIFT GUARD.
    checks, _strict = sub_checks(pre_rsc)
    live_names = set(c.get("context") for c in checks)
    out("[2/6] drift guard -- the live context set against the expected set")
    if live_names != EXPECTED_CONTEXTS:
        out("ABORT: the required-context set has drifted.")
        out("       missing    = {}".format(sorted(EXPECTED_CONTEXTS - live_names)))
        out("       unexpected = {}".format(sorted(live_names - EXPECTED_CONTEXTS)))
        out("Nothing was written. A set that changed is a set a person has to look "
            "at: re-derive CONTEXT_ORDER, re-run --self-test, and reconcile "
            "SECURITY.md's Branch Protection Posture record in the same change.")
        return 4
    out("      {} contexts, set-equal to the expected set".format(len(checks)))

    # 3. IS THE WRITE EVEN NEEDED?
    out("[3/6] pre-state assertion")
    pre_rc, _pre_failed, pre_lines = evaluate(json.dumps(pre_rsc))
    for line in pre_lines:
        out("      " + line)
    if pre_rc == 0:
        out("ALREADY PINNED -- the end state already holds. Nothing was written.")
        return 0

    # 4. COMPOSE, from the live read.
    out("[4/6] compose the payload from the live read")
    payload = compose_payload(pre_rsc)
    if len(payload["checks"]) != EXPECTED_COUNT or \
            any(c["app_id"] != APP_ID for c in payload["checks"]):
        out("ABORT: composed payload failed its own shape check. Nothing was written.")
        return 1
    with open(patch_f, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
    out("      rsc-PATCH.json -- {} contexts, every app_id int {}".format(
        len(payload["checks"]), APP_ID))

    if not confirm:
        out("STOPPING BEFORE THE WRITE -- --confirm-write was not given.")
        out("Everything above ran; nothing was written. Re-run with --confirm-write "
            "to perform the one non-git-reversible action in this change.")
        return 6

    # 5. WRITE -- narrow endpoint only.
    out("[5/6] PATCH {} (narrow sub-resource; never PUT .../protection)".format(rsc_path))
    ok, _text, err = write(rsc_path, patch_f)
    if not ok:
        out("WRITE FAILED: {}".format(err))
        out("Restore from {} if the branch is in a partial state.".format(restore_f))
        return 7

    # 6. FRESH read-back, then the scope diff.
    out("[6/6] fresh read-back and scope-containment diff")
    ok, text, err = fetch(rsc_path)
    if not ok:
        out("READ-BACK FAILED: {} -- the write is UNVERIFIED.".format(err))
        return 7
    rc, _failed, lines = evaluate(text)
    for line in lines:
        out("      " + line)
    if rc != 0:
        out("The post-write state does not satisfy the assertion. Restore from {}."
            .format(restore_f))
        return rc

    try:
        post_full = capture(fetch, prot_path, post_full_f, "post-change protection")
    except CaptureRefused as exc:
        out("      post-capture unavailable ({}) -- the four conjuncts held, but "
            "the scope-containment diff could not be run.".format(exc))
        return 1
    diff = scope_diff(pre_full, post_full)
    out("      differing leaves: {}".format(len(diff)))
    for k, v in diff:
        out("        {} = {!r}".format(k, v))
    if len(diff) != 2 or not all("app_id" in k for k, _ in diff):
        out("SCOPE VIOLATION: the write changed something other than the one app_id. "
            "Restore from {}.".format(restore_f))
        return 1
    out("      exactly two differing leaves, both the one app_id -- no sibling "
        "protection setting moved")
    out("DONE -- the required-context set is pinned, and the write is scope-contained.")
    return 0


def run_restore(repo, branch, staging, confirm, fetch=gh_fetch_json,
                write=gh_patch_json, stream=sys.stdout):
    def out(msg):
        stream.write(msg + "\n")

    rsc_path = "repos/{}/branches/{}/protection{}".format(
        repo, branch, SUBRESOURCE_SUFFIX)
    restore_f = os.path.join(staging, "rsc-RESTORE.json")
    if not os.path.exists(restore_f):
        pre_rsc_f = os.path.join(staging, "rsc-PRE.json")
        if not os.path.exists(pre_rsc_f):
            out("No rollback artifact in {} -- nothing to restore from.".format(staging))
            return 3
        with open(pre_rsc_f, encoding="utf-8") as fh:
            with open(restore_f, "w", encoding="utf-8") as wfh:
                json.dump(compose_restore(json.load(fh)), wfh, indent=2)
    with open(restore_f, encoding="utf-8") as fh:
        payload = json.load(fh)
    out("restore payload: {} contexts, {} of them unpinned".format(
        len(payload.get("checks", [])),
        sum(1 for c in payload.get("checks", []) if c.get("app_id") is None)))
    if not confirm:
        out("STOPPING -- --confirm-write was not given. Nothing was written.")
        return 6
    ok, _text, err = write(rsc_path, restore_f)
    if not ok:
        out("RESTORE FAILED: {}".format(err))
        out("Fallback, if app_id: null is rejected on the write path: PATCH the "
            "pinned contexts, then POST each unpinned context NAME to "
            "{}/contexts -- that endpoint produces an unpinned context by "
            "construction, which is the pre-change shape.".format(rsc_path))
        return 7
    ok, text, _err = fetch(rsc_path)
    if ok:
        checks, _ = sub_checks(json.loads(text))
        out("read-back: {} contexts, {} unpinned".format(
            len(checks), sum(1 for c in checks if c.get("app_id") is None)))
    out("RESTORED.")
    return 0


# ==========================================================================

def main(argv):
    ap = argparse.ArgumentParser(
        description="Capture, write and assert the app-pinning of a branch's "
                    "required status checks.",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true",
                      help="offline validation of the assertion and the guards")
    mode.add_argument("--census", action="store_true",
                      help="offline: grade the workflows against CONTEXT_ORDER")
    mode.add_argument("--assert", dest="do_assert", action="store_true",
                      help="grade a read against the four conjuncts")
    mode.add_argument("--plan", action="store_true",
                      help="capture and compose; stop before the write")
    mode.add_argument("--apply", action="store_true",
                      help="the full sequence; needs --confirm-write to write")
    mode.add_argument("--restore", action="store_true",
                      help="re-apply the captured pre-change sub-resource")
    ap.add_argument("--stdin", action="store_true", help="--assert reads stdin")
    ap.add_argument("--file", help="--assert reads this file")
    ap.add_argument("--root", help="--census grades this tree; default: the "
                                   "repository this file lives in")
    ap.add_argument("--staging", help="directory for the capture artifacts")
    ap.add_argument("--repo", help="OWNER/NAME; default: the origin remote")
    ap.add_argument("--branch", default="main")
    ap.add_argument("--confirm-write", dest="confirm", action="store_true",
                    help="required before any write is attempted")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()

    if args.census:
        return run_census(args.root or repo_root())

    if args.do_assert:
        if args.stdin:
            raw = sys.stdin.read()
        elif args.file:
            with open(args.file, encoding="utf-8") as fh:
                raw = fh.read()
        else:
            ap.error("--assert needs --stdin or --file")
        rc, _failed, lines = evaluate(raw)
        for line in lines:
            print(line)
        return rc

    if not args.staging:
        ap.error("--staging is required for this mode")
    if not os.path.isdir(args.staging):
        print("staging directory does not exist: {}".format(args.staging))
        return 3
    repo = resolve_repo(args.repo)
    if not repo:
        print("could not resolve a repository; pass --repo OWNER/NAME")
        return 3
    print("repository: {}   branch: {}".format(repo, args.branch))

    if args.restore:
        return run_restore(repo, args.branch, args.staging, args.confirm)
    return run_apply(repo, args.branch, args.staging,
                     confirm=(args.confirm and args.apply))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
