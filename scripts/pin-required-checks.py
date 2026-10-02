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

# The census's emittable finding set. The self-test asserts a bijection between
# it and the codes the arms name, in both directions (E0).
CENSUS_CODES = ("UNREGISTERED", "ABSENT", "UNDECLARED", "DUPLICATE", "UNTRIGGERED")

# Every reason the census refuses. A refusal is exit 2 and never exit 1: "I cannot
# vouch I read this" is not "the workflows and the declaration disagree". The
# self-test asserts a bijection between this set and the refusals the arms name (E10).
REFUSAL_CODES = (
    "NO-PARSER", "NO-WORKFLOWS", "UNREADABLE", "YAML11-BREAK", "UNPARSEABLE",
    "NOT-ONE-DOCUMENT", "NO-JOBS", "NO-JOB", "KEY-TWICE", "MERGE-KEY",
    "KEY-NOT-TEXT", "JOB-NOT-MAPPING", "NAME-NOT-TEXT",
    "RUNTIME-NAME", "RUNTIME-MATRIX", "RUNTIME-REUSABLE")

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


def _load_yaml():
    """The YAML parser the census reads with: PyYAML, imported here and only here.

    A function rather than a module-level import, so --assert, --plan and
    --restore never need the parser, and so the self-test can hand the census a
    loader that fails (X95) and watch it refuse.
    """
    import yaml
    return yaml


def _no_yaml():
    """A loader that cannot import the parser -- X95's, and no one else's."""
    raise ImportError("No module named 'yaml' (a loader built to fail)")


def census_verdict(root, load=_load_yaml):
    """(rc, records, findings, refusals, version) -- the census's whole result, unprinted.

    AN INTERIM SHIM, standing for the census the next commit lands. It grades
    with the line reader above -- `census_scan`, `census_findings` and
    `run_census` -- so the parser-based arms run against the reader they are
    written to replace and record its verdicts as they are. `load` is accepted
    and never called, because the line reader needs no parser; so X95's failing
    loader changes nothing here. `refusals` is always empty and `version` None:
    the line reader's refusals carry no code, and the self-test at this commit
    compares the exit code and the finding codes only.
    """
    records = census_scan(root)
    with open(os.devnull, "w") as sink:
        rc = run_census(root, stream=sink)
    findings = census_findings(records) if rc == 1 else []
    return (rc, records, findings, [], None)


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

    Each arm is (id, what it models, {relative path: content}, want_rc,
    want_codes[, want_refusal[, load]]). An arm wanting rc 2 names the refusal
    code it wants; X95 also carries the loader it runs under. The harness reads
    the optional elements by the tuple's length.
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

    # X9-X11 model a job indented four spaces, a job under a comment block that
    # only documents the marker grammar, and a marker at column zero. The parser
    # reads each job where it sits, and the marker binding gives the second and
    # the third no posture.
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

    # X12 models a comment block carrying two markers, the stale `advisory` on
    # top and the new `required` against the job key -- the order an edit
    # produces. The marker binding declines to choose, so the job declares no
    # posture.
    two_markers = dict(base)
    two_markers[".github/workflows/synth-two-markers.yml"] = _synth_workflow(
        [("new-suite", "New suite (test-new-suite.sh)", "required")],
        lead=["  # gate-efficacy: posture=advisory"])

    # X13-X19 model a quoted job key in each quoting character, a quoted key with
    # a marker above its own `steps:`, a quoted key whose `steps:` is a flow
    # sequence, a flow-style `jobs:`, a quoted `"jobs":` key, and a job key whose
    # properties are a flow mapping on its own line. The parser reads each job
    # under the key and the name the file gives it.
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

    # X20-X25 model presentations of the one legal job ID `new-suite`, each alone
    # in its file and claiming required: the explicit-key form, escaped spellings,
    # and a space before the `:`. The parser reads each as the key `new-suite`,
    # whose name the declaration does not carry.
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
            "KEY PRESENTATION, read by the parser: {} -- alone in its file, the "
            "job claiming required. The line reader this replaced gave rc 2, "
            "having recorded a job off the `steps:` line instead; the parser "
            "reads the key as `new-suite`, a name the declaration does not "
            "carry, so the tree gets rc 1 UNREGISTERED".format(what),
            tree, 1, {"UNREGISTERED"}))

    # X26 models a key with a space before its `:`, claiming required, beside a
    # job the reader reads. The parser reads both jobs, the second as `new-suite`.
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

    # X27-X31 model the other presentations of X20-X25 in X26's position, each
    # beside a job the reader reads. The parser reads both jobs in each file, the
    # second as `new-suite`.
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
            "KEY PRESENTATION, read by the parser: {} -- beside a job the reader "
            "reads, the job claiming required. The line reader this replaced gave "
            "rc 2 on the unread key line; the parser reads both jobs, the second "
            "as `new-suite`, a name the declaration does not carry, so the tree "
            "gets rc 1 UNREGISTERED".format(what),
            tree, 1, {"UNREGISTERED"}))

    # X32 models an anchored job key (`key: &a`) beside a job the reader reads,
    # aliased by a third job so that actionlint accepts the file. The parser
    # reads all three jobs, and the alias reports the anchored job's context
    # with no marker of its own.
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

    # X33 models a key with a space before its `:` coming first, its `steps:` a
    # flow sequence, ahead of a readable job. The parser reads both jobs in order.
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

    # X34 models a readable job whose `name:` is a double-quoted scalar continued
    # at the job-key indentation, shaped like a marker and a `steps:` key, ahead
    # of a key with a space before its `:`. The parser reads the continuation as
    # part of the first job's name, and both jobs as jobs.
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

    # X36 models a double-quoted scalar continued at column zero inside the first
    # job, ahead of a second job claiming required under an undeclared name. The
    # parser reads the scalar to its close, and both jobs.
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

    # X35 models two plainly written jobs in one file, the second claiming
    # required under an undeclared name. The parser reads both, and the finding
    # arrives at rc 1.
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

    # X37-X42 model a job property's value -- a double- or single-quoted scalar,
    # a flow sequence or a flow mapping -- continued onto a line at the job-key
    # indentation (X42: one column deeper), ahead of a job claiming required
    # under an undeclared name, or alone in its file (X41). The parser reads each
    # continuation as the rest of its value, and every job as a job.
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

    # X43 models, in one file, a property's double-quoted scalar continued at the
    # job-key indentation, then a step `name:` whose plain continuation line
    # begins with `'`, then a key with a space before its `:` claiming required.
    # The parser reads the `'` as text, and both jobs.
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

    # X44 models an `env:` flow mapping whose continuation line is shaped like a
    # key (`  A:`), ahead of a job claiming required under an undeclared name.
    # The parser reads `A` as a key inside the mapping, not as a job.
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

    # X45-X46 model X36's tree with a single-quoted scalar, and with a `steps:`
    # flow sequence, closed at column zero. The parser reads each value to its
    # close, and both jobs.
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

    # X47 models a workflow file written in Latin-1, so it is not valid UTF-8 at
    # all. The census cannot decode it, and refuses it by name.
    not_utf8 = dict(base)
    not_utf8[".github/workflows/synth-latin1.yml"] = (
        "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
        "  # gate-efficacy: posture=required\n"
        "  new-suite:\n"
        "    name: Caf\u00e9 suite (test-new-suite.sh)\n"
        "    runs-on: ubuntu-latest\n"
        "    steps:\n"
        "      - run: 'true'\n").encode("latin-1")

    # X48-X63 model a job `name:` or a step `name:` wrapped as a plain scalar onto
    # a continuation line that begins with a quote or a flow bracket, then a
    # second job claiming required under an undeclared name, its key written
    # plainly or with a space before its `:`. The parser reads the character as
    # text, and both jobs.
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
                    ("  new-suite :\n", 1, {"UNREGISTERED"}, None)):
                tree = dict(base)
                tree[".github/workflows/synth-span.yml"] = (
                    "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"
                    "  # gate-efficacy: posture=advisory\n"
                    "  readable:\n" + props +
                    "  # gate-efficacy: posture=required\n" + key_line +
                    "    runs-on: ubuntu-latest\n"
                    "    steps:\n"
                    "      - " + run + "\n")
                if then is not None:
                    what = ("FAIL-OPEN DIRECTION: {} wrapped as a PLAIN scalar "
                            "whose continuation line begins with `{}`, then "
                            "{}".format(carrier, trigger, then))
                else:
                    what = ("SPAN, read by the parser: {} wrapped as a plain "
                            "scalar whose continuation line begins with `{}`, "
                            "then a key with a space before its `:`, claiming "
                            "required. The line reader this replaced gave rc 2; "
                            "the parser reads the `{}` as text and the key as "
                            "`new-suite`, a name the declaration does not carry, "
                            "so the tree gets rc 1 UNREGISTERED".format(
                                carrier, trigger, trigger))
                span_arms.append((
                    "X{}".format(48 + len(span_arms)),
                    what, tree, want_rc, want_codes))

    # X64-X65 model a job property's quoted scalar (X64) or open flow mapping
    # (X65) continued onto a key-shaped line one column shallower than the job
    # keys, ahead of a canonical `new-suite:` claiming required; X65 also anchors
    # its first job and aliases it from a third. The parser reads each
    # continuation as part of its value, and every job as a job.
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

    # X66-X67 model a quoted scalar (X66) or an open flow mapping (X67) continued
    # at exactly the job-key indentation as a marker-shaped line, a key-shaped
    # line and a `name:`-shaped line carrying the declaration's last context, in
    # a tree whose real job for that context is removed. The parser reads those
    # lines as part of the value, so no job claims that context.
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

    # X68-X69 model a plain scalar inside a flow sequence continued onto a line
    # beginning with `'` (X68), and a job `name:` wrapped over three lines with
    # the `'` on the third (X69), each ahead of a job claiming required under an
    # undeclared name. The parser reads the `'` as text, and both jobs.
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

    # X70-X71 model a job claiming required whose name begins with the
    # declaration's last context: a plain `name:` continued onto a deeper line
    # (X70), and another property's quoted value continued onto a `name:`-shaped
    # line ahead of the job's own `name:` (X71), in a tree whose real job for
    # that context is removed. The parser reads the whole name, which the
    # declaration does not carry.
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

    # X72 models a `jobs:` block that opens on a `!!map` tag alone on its line,
    # above a job claiming required under an undeclared name. The parser reads
    # the tag as the mapping's own, and the job beneath it.
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

    # X73 (its tree, `second_jobs`, follows X76's) models a workflow whose own
    # `name:` is a double-quoted scalar continued at column zero and carrying a
    # `jobs:` line, ahead of the real `jobs:` block, whose job claims required
    # under an undeclared name. The parser reads the string as the workflow's
    # name, and the real block.
    # X74 models a property's double-quoted scalar continued at the job-key
    # indentation onto a line that begins with `#` and is shaped like a
    # `posture=required` marker, above a job carrying the declaration's last
    # context in a tree whose real job for that context is removed. The parser
    # reads that line as part of the scalar, so the job declares no posture.
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

    # X75 models jobs claiming required whose `name:` is the declaration's last
    # context wrapped in literal single quotes inside double quotes, at one layer
    # and at two, in a tree whose real job for that context is removed. The
    # parser keeps the inner quotes as part of each name, which the declaration
    # does not carry.
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

    # X76 models a job claiming required whose unquoted `name:` is the
    # declaration's last context followed by `U+00A0`, in a tree whose real job
    # for that context is removed. The parser keeps the character as part of the
    # name, which the declaration does not carry.
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
               "never reach a clean exit", {}, 2, set(), "NO-WORKFLOWS"),
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
        ("X17", "FILE-LEVEL, read by the parser: a flow-style `jobs: {...}` "
                "mapping on one line, its job carrying no marker. The line reader "
                "this replaced gave rc 2, finding no line to start from; the parser "
                "reads the job `new-suite`, which declares no posture, so the tree "
                "gets rc 1 UNDECLARED",
         flow_jobs, 1, {"UNDECLARED"}),
        ("X18", "FILE-LEVEL, read by the parser: a quoted `\"jobs\":` key over a job "
                "claiming required. The line reader this replaced gave rc 2, since "
                "it began only at a bare `jobs:`; the parser reads the key's text, "
                "`jobs`, and the job `new-suite` beneath it, a name the declaration "
                "does not carry, so the tree gets rc 1 UNREGISTERED",
         quoted_jobs, 1, {"UNREGISTERED"}),
        ("X19", "FILE-LEVEL, read by the parser: a job key claiming required whose "
                "properties are a flow mapping on the key's own line. The line "
                "reader this replaced gave rc 2, finding no `key:` line; the parser "
                "reads the job `new-suite`, a name the declaration does not carry, "
                "so the tree gets rc 1 UNREGISTERED",
         no_key, 1, {"UNREGISTERED"}),
    ] + unread_arms + [
        ("X26", "KEY PRESENTATION, read by the parser: a bare key carrying a space "
                "before its `:` -- beside a job the reader reads, the job claiming "
                "required. The line reader this replaced gave rc 2 on the unread key "
                "line; the parser reads both jobs, the second as `new-suite`, a name "
                "the declaration does not carry, so the tree gets rc 1 UNREGISTERED",
         residual, 1, {"UNREGISTERED"}),
    ] + beside_arms + [
        ("X32", "ANCHORED KEY, read by the parser: a job key carrying an anchor "
                "(`key: &a`) and claiming required, beside a job the reader reads, "
                "and aliased by a third job. The line reader this replaced gave "
                "rc 2; the parser reads all three jobs, and the alias `clone` "
                "reports the anchored job's context with no marker of its own, so "
                "the tree gets rc 1 DUPLICATE, UNDECLARED and UNREGISTERED",
         anchored, 1, {"DUPLICATE", "UNDECLARED", "UNREGISTERED"}),
        ("X33", "ORDERING, read by the parser: a key with a space before its `:`, "
                "claiming required, comes first, its `steps:` a flow sequence, "
                "ahead of a readable job. The line reader this replaced gave rc 2; "
                "the parser reads both jobs in order, the first as `new-suite`, a "
                "name the declaration does not carry, so the tree gets rc 1 "
                "UNREGISTERED", flow_before, 1, {"UNREGISTERED"}),
        ("X34", "SCALAR CONTENT, read by the parser: a readable job whose `name:` "
                "is a double-quoted scalar continued at the job-key indentation, "
                "shaped like a marker and a `steps:` key, ahead of a key with a "
                "space before its `:` claiming required. The line reader this "
                "replaced gave rc 2; the parser reads the continuation as part of "
                "the first job's name and the key as `new-suite`, a name the "
                "declaration does not carry, so the tree gets rc 1 UNREGISTERED",
         scalar_phantom, 1, {"UNREGISTERED"}),
        ("X35", "SPECIFICITY for X26-X34: two jobs in one file, BOTH read, the second "
                "unregistered. Without this arm every refusal above is equally "
                "satisfied by a reader that refuses any file holding two jobs -- the "
                "finding must still arrive, at rc 1", two_readable, 1,
         {"UNREGISTERED"}),
        ("X36", "NEVER WALKED, read by the parser: a double-quoted scalar continued "
                "at column zero inside the first job, ahead of a second job claiming "
                "required under an undeclared name. The line reader this replaced "
                "ended the `jobs:` block at that line and gave CLEAN at rc 0; the "
                "parser reads the scalar to its close, and both jobs, so the tree "
                "gets rc 1 UNREGISTERED", truncated, 1, {"UNREGISTERED"}),
        ("X37", "CONTINUATION, read by the parser: a job `name:` whose double-quoted "
                "scalar continues onto a line at the job-key indentation, ahead of a "
                "job claiming required under an undeclared name. The line reader "
                "this replaced gave rc 2, unable to tell that line from a key it "
                "could not read; the parser reads it as the rest of the name, and "
                "both jobs, so the tree gets rc 1 UNREGISTERED",
         cont_double, 1, {"UNREGISTERED"}),
        ("X38", "CONTINUATION, read by the parser: the same, single-quoted. The line "
                "reader this replaced gave rc 2; the parser reads the continuation "
                "as the rest of the name, and both jobs, so the tree gets rc 1 "
                "UNREGISTERED", cont_single, 1, {"UNREGISTERED"}),
        ("X39", "CONTINUATION, read by the parser: a `steps:` flow sequence left open "
                "at the end of its line and closed at the job-key indentation, ahead "
                "of a job claiming required under an undeclared name. The line "
                "reader this replaced gave rc 2; the parser reads the closing line "
                "as the rest of the sequence, and both jobs, so the tree gets rc 1 "
                "UNREGISTERED", cont_seq, 1, {"UNREGISTERED"}),
        ("X40", "CONTINUATION, read by the parser: an `env:` flow mapping closed at "
                "the job-key indentation, ahead of a job claiming required under an "
                "undeclared name. The line reader this replaced gave rc 2; the parser "
                "reads the closing line as the rest of the mapping, and both jobs, so "
                "the tree gets rc 1 UNREGISTERED", cont_map, 1, {"UNREGISTERED"}),
        ("X41", "CONTINUATION, read by the parser: the `env:` flow mapping of X40 in "
                "a file holding one job, which claims required under an undeclared "
                "name. The line reader this replaced gave rc 2; the parser reads the "
                "closing line as the rest of the mapping, and the job, so the tree "
                "gets rc 1 UNREGISTERED", cont_alone, 1, {"UNREGISTERED"}),
        ("X42", "SPECIFICITY for X37-X41: the X37 file with its continuation ONE "
                "column deeper, at an indentation where no job key sits. It is graded, "
                "never refused, and must stay so. The landing column is the only "
                "difference from X37, so this arm confines the accepted false "
                "refusal from the DEEPER side only. A continuation one column "
                "SHALLOWER than the job keys is refused as well, and no arm here "
                "confines that side",
         cont_deeper, 1, {"UNREGISTERED"}),
        ("X43", "SPARING-READER GUARD, read by the parser: a property's double-quoted "
                "scalar continued at the job-key indentation, then a step `name:` "
                "whose plain continuation line begins with `'`, then a key with a "
                "space before its `:` claiming required. The line reader this "
                "replaced gave rc 2; the parser reads the `'` as text and the key as "
                "`new-suite`, a name the declaration does not carry, so the tree "
                "gets rc 1 UNREGISTERED", cont_and_unread, 1, {"UNREGISTERED"}),
        ("X44", "FLOW CONTINUATION, read by the parser: an `env:` flow mapping whose "
                "continuation line is shaped like a key (`  A:`), ahead of a job "
                "claiming required under an undeclared name. The line reader this "
                "replaced recorded a phantom job `A` and gave rc 1 UNDECLARED and "
                "UNREGISTERED; the parser reads `A` as a key inside the mapping, so "
                "the false UNDECLARED is gone and the tree gets rc 1 UNREGISTERED "
                "alone", cont_keyish, 1, {"UNREGISTERED"}),
        ("X45", "NEVER WALKED, read by the parser: X36's tree with a single-quoted "
                "scalar continued at column zero. The line reader this replaced gave "
                "CLEAN at rc 0; the parser reads the scalar to its close, and both "
                "jobs, so the tree gets rc 1 UNREGISTERED", trunc_single, 1,
         {"UNREGISTERED"}),
        ("X46", "NEVER WALKED, read by the parser: X36's tree with a `steps:` flow "
                "sequence closed at column zero. The line reader this replaced gave "
                "CLEAN at rc 0; the parser reads the sequence to its close, and both "
                "jobs, so the tree gets rc 1 UNREGISTERED", trunc_seq, 1,
         {"UNREGISTERED"}),
        ("X47", "a workflow file that is not UTF-8 at all. Every other refusal in "
                "this list reaches an exit and prints why; this one killed the "
                "process on an uncaught decode error before `run_census` reached any "
                "`return` -- no census, no verdict, no limit block, and no word about "
                "which file. It must refuse like the rest, and `_unread_reason`'s "
                "first branch, written for exactly this and unreachable until now, is "
                "what names it", not_utf8, 2, set(), "UNREADABLE"),
    ] + span_arms + [
        ("X64", "DISPLACED INDENTATION, read by the parser: a job property's "
                "double-quoted scalar continued onto a key-shaped line one column "
                "shallower than the job keys, ahead of a canonical `new-suite:` "
                "claiming required. The line reader this replaced gave rc 2; the "
                "parser reads the continuation as part of the first job's name, and "
                "both jobs, so the tree gets rc 1 UNREGISTERED",
         displaced, 1, {"UNREGISTERED"}),
        ("X65", "DISPLACED INDENTATION, read by the parser: the same through an "
                "`env:` flow mapping left open, with an anchored first job aliased "
                "by a third. The line reader this replaced gave rc 2; the parser "
                "reads all three jobs, and the alias `clone` carries no marker of "
                "its own, so the tree gets rc 1 UNDECLARED and UNREGISTERED",
         displaced_flow, 1, {"UNDECLARED", "UNREGISTERED"}),
        ("X66", "PHANTOM CLAIM, read by the parser: a double-quoted scalar continued "
                "at the job-key indentation as a marker, a key and a `name:` line "
                "carrying the declaration's last context, whose real job this tree "
                "lacks. The line reader this replaced recorded a phantom claiming "
                "that context and gave CLEAN at rc 0; the parser reads those lines "
                "as the rest of the first job's name, so the tree gets rc 1 ABSENT",
         phantom_claim, 1, {"ABSENT"}),
        ("X67", "PHANTOM CLAIM, read by the parser: the same through an `env:` flow "
                "mapping, with no quote anywhere. The line reader this replaced gave "
                "CLEAN at rc 0; the parser reads those lines as an entry of the "
                "mapping, so the tree gets rc 1 ABSENT", phantom_claim_flow, 1,
         {"ABSENT"}),
        ("X68", "SPANNING, outside X48-X63's family: a plain scalar INSIDE a flow "
                "collection, continued onto a line beginning with `'`. Nothing is "
                "open there in YAML and both parsers read two jobs, so the second "
                "job must grade UNREGISTERED. Measured: both line-sparing readers "
                "that pass X48-X63 lose that job here", span_flow, 1,
         {"UNREGISTERED"}),
        ("X69", "SPAN, read by the parser: a job `name:` wrapped over three lines, "
                "the `'` on the third, then a key with a space before its `:` "
                "claiming required. The line reader this replaced gave rc 2; the "
                "parser reads the wrapped name and the key as `new-suite`, a name "
                "the declaration does not carry, so the tree gets rc 1 UNREGISTERED",
         span_wrap, 1, {"UNREGISTERED"}),
        ("X70", "NAME AXIS, read by the parser: a job claiming required whose plain "
                "`name:` is the declaration's last context continued onto a deeper "
                "line, in a tree whose real job for that context is removed. The "
                "line reader this replaced kept the first line and gave CLEAN at "
                "rc 0; the parser reads the whole name, ending in `v2`, so the tree "
                "gets rc 1 ABSENT and UNREGISTERED", name_cont, 1,
         {"ABSENT", "UNREGISTERED"}),
        ("X71", "NAME AXIS, read by the parser: another property's quoted value "
                "continued onto a `name:`-shaped line carrying the declaration's "
                "last context, ahead of the job's own `name: Hygiene v2`, in a tree "
                "whose real job for that context is removed. The line reader this "
                "replaced took that line for the name and gave CLEAN at rc 0; the "
                "parser reads it as part of the value and the name as `Hygiene v2`, "
                "so the tree gets rc 1 ABSENT and UNREGISTERED", name_in_value, 1,
         {"ABSENT", "UNREGISTERED"}),
        ("X72", "TAG LINE, read by the parser: a `jobs:` block that opens on a "
                "`!!map` tag alone on its line, above a job claiming required under "
                "an undeclared name. The line reader this replaced gave rc 2; the "
                "parser reads the tag as the mapping's own, and the job beneath it, "
                "so the tree gets rc 1 UNREGISTERED", tag_head, 1,
         {"UNREGISTERED"}),
        ("X73", "NEVER WALKED, read by the parser: the workflow's own `name:`, a "
                "double-quoted scalar continued at column zero, carries a `jobs:` "
                "line, ahead of the real `jobs:` block. The line reader this "
                "replaced walked a block opening inside the string and gave CLEAN at "
                "rc 0; the parser reads the string as the workflow's name and the "
                "real block, whose job claims required under an undeclared name, so "
                "the tree gets rc 1 UNREGISTERED", second_jobs, 1,
         {"UNREGISTERED"}),
        ("X74", "POSTURE AXIS, read by the parser: a property's double-quoted scalar "
                "continued at the job-key indentation onto a line that begins with "
                "`#` and is shaped like a `posture=required` marker, above a job "
                "carrying the declaration's last context, whose real job this tree "
                "lacks. The line reader this replaced read that line as the job's "
                "marker and gave CLEAN at rc 0; the parser reads it as part of the "
                "scalar, so the job declares no posture and the tree gets rc 1 "
                "ABSENT and UNDECLARED", hash_cont, 1, {"ABSENT", "UNDECLARED"}),
        ("X75", "NAME AXIS, read by the parser: jobs claiming required whose "
                "`name:` is the declaration's last context wrapped in literal "
                "quote characters, at one layer and at two, in a tree whose real "
                "job for that context is removed. The line reader this replaced "
                "stripped every quote off each end and gave CLEAN at rc 0; the "
                "parser keeps the inner quotes as part of each name, so the tree "
                "gets rc 1 ABSENT and UNREGISTERED", name_quoted, 1,
         {"ABSENT", "UNREGISTERED"}),
        ("X76", "NAME AXIS, read by the parser: a job claiming required whose "
                "unquoted `name:` is the declaration's last context followed by "
                "`U+00A0`, in a tree whose real job for that context is removed. "
                "The line reader this replaced stripped that character as "
                "whitespace and gave CLEAN at rc 0; the parser keeps it as part of "
                "the name, so the tree gets rc 1 ABSENT and UNREGISTERED",
         name_ws, 1, {"ABSENT", "UNREGISTERED"}),
    ] + _census_arms_parsed(base)


def _census_arms_parsed(base):
    """The arms the parser-based census added, X77 onward, each one change to `base`.

    Each tree is the clean baseline with one file added, replaced or removed, so
    the verdict an arm wants is the verdict of that one change. An arm wanting
    rc 2 names the refusal it wants, so a file refused for the wrong reason fails
    its arm (E10). X95 carries the loader that cannot import the parser.
    """
    tenth = CONTEXT_ORDER[-1]
    prev = CONTEXT_ORDER[-2]
    last = ".github/workflows/synth-{:02d}.yml".format(len(CONTEXT_ORDER) - 1)
    head = "name: Synthetic\n\non:\n  pull_request:\n\njobs:\n"

    def job(key, name, posture, extra=""):
        text = "  # gate-efficacy: posture={}\n".format(posture) if posture else ""
        text += "  {}:\n".format(key)
        if name is not None:
            text += "    name: {}\n".format(name)
        return text + extra + "    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n"

    def tree(add=None, drop=False, replace=None):
        files = dict(base)
        if drop:
            del files[last]
        files.update(replace or {})
        files.update(add or {})
        return files

    def wf(name):
        return ".github/workflows/synth-{}.yml".format(name)

    def on_only(on):
        return "name: Synthetic\n\n" + on + "\njobs:\n" + job("hygiene-v2", tenth, "required")

    new_suite = "New suite (test-new-suite.sh)"
    return [
        ("X77", "NEVER WALKED, the multi-document member, closed by refusal: a workflow file holding two YAML documents, each with its own `jobs:`. The line reader this replaces graded the first and never reached the second (CLEAN at rc 0); the census refuses the file, NOT-ONE-DOCUMENT, because what GitHub reads from such a file was not measured",
         tree(add={wf("multi"): head + job("a", "A", "advisory") + "---\n" + head + job("new-suite", new_suite, "required")}),
         2, set(), "NOT-ONE-DOCUMENT"),
        ("X78", "REPEATED KEY, closed by refusal: a job key written twice in one `jobs:` mapping, the first copy claiming required under the declaration's last context. The parsers measured keep the later copy and the line reader read both (CLEAN at rc 0); the census refuses, KEY-TWICE",
         tree(drop=True, add={wf("dupkey"): head + job("hygiene-v2", tenth, "required") + job("hygiene-v2", "Hygiene v2", "advisory")}),
         2, set(), "KEY-TWICE"),
        ("X79", "REPEATED KEY, the `name:` member: a job's `name:` written twice. The line reader read the first copy (CLEAN at rc 0); the census refuses, KEY-TWICE",
         tree(drop=True, add={wf("dupname"): head + "  # gate-efficacy: posture=required\n  hygiene-v2:\n    name: " + tenth + "\n    name: Hygiene v2\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n"}),
         2, set(), "KEY-TWICE"),
        ("X80", "REPEATED KEY, the `jobs:` member: a workflow's `jobs:` key written twice. The line reader never walked the second block (CLEAN at rc 0); the census refuses, KEY-TWICE",
         tree(add={wf("dupjobs"): head + job("a", "A", "advisory") + "\njobs:\n" + job("new-suite", new_suite, "required")}),
         2, set(), "KEY-TWICE"),
        ("X81", "UNPARSEABLE: a workflow whose quoted scalar never closes. The line reader read it (CLEAN at rc 0); the census refuses it, UNPARSEABLE, having read every other file in the tree",
         tree(add={wf("bad"): head + job("a", '"unterminated', "advisory")}),
         2, set(), "UNPARSEABLE"),
        ("X82", "MERGE KEY, refused: a job built with `<<:` from another job's mapping. Which keys GitHub reads through it was not measured, so the census refuses, MERGE-KEY",
         tree(add={wf("merge"): head + "  # gate-efficacy: posture=advisory\n  a: &x\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n  # gate-efficacy: posture=advisory\n  b:\n    <<: *x\n    name: B\n"}),
         2, set(), "MERGE-KEY"),
        ("X83", "RUN-TIME CONTEXT, the expression member: a job claiming required whose `name:` carries an expression. GitHub computes that context when the job runs, so the census refuses, RUNTIME-NAME, rather than compare a text GitHub never reports",
         tree(drop=True, add={wf("expr"): head + job("hygiene-v2", "${{ '" + tenth + "' }}", "required")}),
         2, set(), "RUNTIME-NAME"),
        ("X84", "RUN-TIME CONTEXT, the matrix member: a job claiming required that carries a `strategy` with a matrix. GitHub reports it under a context extended with the matrix values, so the census refuses, RUNTIME-MATRIX. The line reader graded the bare name (CLEAN at rc 0)",
         tree(drop=True, add={wf("matrix"): head + job("hygiene-v2", tenth, "required", "    strategy:\n      matrix:\n        os: [ubuntu-latest]\n")}),
         2, set(), "RUNTIME-MATRIX"),
        ("X85", "RUN-TIME CONTEXT, the reusable member: a job claiming required that calls a reusable workflow with `uses:`. Its checks report under names composed with the called workflow's jobs, so the census refuses, RUNTIME-REUSABLE. The line reader graded the caller's name (CLEAN at rc 0)",
         tree(drop=True, add={wf("reuse"): head + "  # gate-efficacy: posture=required\n  hygiene-v2:\n    name: " + tenth + "\n    uses: ./.github/workflows/synth-00.yml\n"}),
         2, set(), "RUNTIME-REUSABLE"),
        ("X86", "YAML VERSION DIVERGENCE, closed by refusal: a double-quoted `name:` carrying NEL (U+0085). PyYAML, a YAML 1.1 parser, folds it to a space and reads the declaration's last context, where YAML 1.2 reads the character as content; the census refuses, YAML11-BREAK",
         tree(drop=True, add={wf("nel"): head + job("hygiene-v2", '"' + tenth.replace(" (", "\x85(") + '"', "required")}),
         2, set(), "YAML11-BREAK"),
        ("X87", "TRIGGER, the dispatch member: a job claiming required under the declaration's last context, in a workflow triggered only by `workflow_dispatch`. Its check can never report on a pull request; the line reader read CLEAN at rc 0, and the census finds UNTRIGGERED",
         tree(drop=True, add={wf("trigger"): on_only("on: workflow_dispatch\n")}),
         1, {"UNTRIGGERED"}),
        ("X88", "TRIGGER, the schedule member: the same job in a workflow triggered only by `schedule`: UNTRIGGERED",
         tree(drop=True, add={wf("trigger"): on_only("on:\n  schedule:\n    - cron: '0 6 * * 1'\n")}),
         1, {"UNTRIGGERED"}),
        ("X89", "TRIGGER, the tag-push member: the same job in a workflow triggered only by a `push` restricted to tags: UNTRIGGERED",
         tree(drop=True, add={wf("trigger"): on_only("on:\n  push:\n    tags: ['v*']\n")}),
         1, {"UNTRIGGERED"}),
        ("X90", "SPECIFICITY for X87-X89: the same job in a workflow triggered by `[push, pull_request]`. A pull request triggers it, so there is no UNTRIGGERED: CLEAN at rc 0",
         tree(drop=True, add={wf("trigger"): on_only("on: [push, pull_request]\n")}),
         0, set()),
        ("X91", "DUPLICATE, the masked shape: a second job claims required under the declaration's last context, beside the job that already does. The set of claimed contexts is unchanged, so set equality held and the line reader read CLEAN at rc 0; the census counts the claims and finds DUPLICATE, naming both jobs",
         tree(add={wf("dup"): head + job("hygiene-copy", tenth, "required")}),
         1, {"DUPLICATE"}),
        ("X92", "DUPLICATE, the card's fixture: two jobs claim one declared context and the declaration's last context is claimed by none. The census finds DUPLICATE, naming both jobs, and ABSENT for the unclaimed context, where the clean tree (X0) holds each declared context with one job",
         tree(replace={last: head + job("job{:02d}".format(len(CONTEXT_ORDER) - 1), prev, "required")}),
         1, {"ABSENT", "DUPLICATE"}),
        ("X93", "DUPLICATE, the shadow: an advisory job reports the declaration's last context beside the required job that claims it. A check run from either satisfies the context, so the census finds DUPLICATE and names the advisory job as the one that shadows",
         tree(add={wf("shadow"): head + job("lookalike", tenth, "advisory")}),
         1, {"DUPLICATE"}),
        ("X94", "SPECIFICITY for X91-X93: two advisory jobs share a name the declaration does not carry. Nothing binds on that name, so there is no DUPLICATE: CLEAN at rc 0",
         tree(add={wf("two-advisory"): head + job("probe-a", "Probe", "advisory") + job("probe-b", "Probe", "advisory")}),
         0, set()),
        ("X95", "NO PARSER, refused: the census run with a loader that cannot import PyYAML. It must refuse, NO-PARSER, and read nothing, never fall back to reading lines",
         dict(base), 2, set(), "NO-PARSER", _no_yaml),
        ("X96", "RUN-TIME LIMIT, pinned as emitted, the paths member: a job claiming required under the declaration's last context whose `pull_request` trigger carries a `paths:` filter. Whether a given pull request runs it is decided when that pull request runs, so the census reads CLEAN at rc 0; a close turns this red and must re-label it",
         tree(drop=True, add={wf("paths"): "name: Synthetic\n\non:\n  pull_request:\n    paths: ['docs/**']\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X97", "RUN-TIME LIMIT, pinned as emitted, the branches member: the same job whose `pull_request` trigger carries a `branches:` filter that leaves out the protected branch: CLEAN at rc 0",
         tree(drop=True, add={wf("branches"): "name: Synthetic\n\non:\n  pull_request:\n    branches: [develop]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X98", "RUN-TIME LIMIT, pinned as emitted, the job-condition member: the same job carrying an `if:` that is false on a pull request: CLEAN at rc 0",
         tree(drop=True, add={wf("job-if"): head + job("hygiene-v2", tenth, "required", "    if: github.event_name == 'push'\n")}),
         0, set()),
        ("X99", "BINDING inside a flow mapping: `jobs:` written as a multi-line flow mapping, with a marker on a comment line directly above a key that begins its line. The marker binds, and the job claims required under an undeclared name: UNREGISTERED",
         tree(add={wf("flow-marker"): "name: Synthetic\n\non:\n  pull_request:\n\njobs: {\n  # gate-efficacy: posture=required\n  new-suite: {name: " + new_suite + ", runs-on: ubuntu-latest, steps: [{run: 'true'}]}\n}\n"}),
         1, {"UNREGISTERED"}),
        ("X100", "NOT A WORKFLOW: a file under .github/workflows with no `jobs` mapping: refused, NO-JOBS",
         tree(add={wf("no-jobs"): "name: Synthetic\n\non:\n  pull_request:\n"}),
         2, set(), "NO-JOBS"),
        ("X101", "NOT A WORKFLOW: `jobs: {}`, a mapping that holds no job: refused, NO-JOB",
         tree(add={wf("empty-jobs"): "name: Synthetic\n\non:\n  pull_request:\n\njobs: {}\n"}),
         2, set(), "NO-JOB"),
        ("X102", "KEY NOT TEXT: a job key written as a flow sequence. A job ID is a scalar, so the census refuses, KEY-NOT-TEXT",
         tree(add={wf("seq-key"): head + "  ? [a, b]\n  : runs-on: ubuntu-latest\n"}),
         2, set(), "KEY-NOT-TEXT"),
        ("X103", "JOB NOT A MAPPING: a job whose value is a scalar: refused, JOB-NOT-MAPPING",
         tree(add={wf("job-scalar"): head + "  # gate-efficacy: posture=advisory\n  a: nothing\n"}),
         2, set(), "JOB-NOT-MAPPING"),
        ("X104", "NAME NOT TEXT, an accepted false refusal: a job whose `name:` is empty. actionlint accepts it and the line reader read the key as its context (CLEAN at rc 0), but what GitHub reports for it was not measured, so the census refuses, NAME-NOT-TEXT; deleting the empty key clears it",
         tree(add={wf("empty-name"): head + "  # gate-efficacy: posture=advisory\n  a:\n    name:\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n"}),
         2, set(), "NAME-NOT-TEXT"),
        ("X105", "RUN-TIME LIMIT, pinned as emitted, the advisory-expression member: an advisory job whose `name:` is an expression that evaluates to the declaration's last context, beside the job that claims it. The census compares the expression text, which matches nothing declared, so it reads CLEAN at rc 0; at run time the check satisfies the context. A close turns this red and must re-label it",
         tree(add={wf("advisory-expr"): head + job("lookalike", "${{ '" + tenth + "' }}", "advisory")}),
         0, set()),
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


def _census_group(out, failures):
    """Group E of the self-test: the registration census, graded arm by arm.

    Returns the census arms, so E9 can read their labels. Without PyYAML the arms
    cannot run, so the group reports itself NOT-EVALUATED and fails; it never
    reports a pass over arms it did not run.
    """
    out("")
    out("E -- the registration census: the second assertion over the same expected "
        "set, and the only one that runs with no token at all")
    c_arms = census_arms()

    armed = set()
    for arm in c_arms:
        armed |= arm[4]
    if armed != set(CENSUS_CODES):
        failures.append("E0: census code coverage is not a bijection -- unexercised={} "
                        "unemittable={}".format(sorted(set(CENSUS_CODES) - armed),
                                                sorted(armed - set(CENSUS_CODES))))
        out("  FAIL E0")
    else:
        out("  PASS E0: every code the census can emit {} is named by at least one arm, "
            "and every code an arm names is one the census can emit -- a bijection, "
            "asserted both ways".format(sorted(CENSUS_CODES)))

    named = set(arm[5] for arm in c_arms if len(arm) > 5 and arm[5])
    if named != set(REFUSAL_CODES):
        failures.append("E10: refusal coverage is not a bijection -- unexercised={} "
                        "unemittable={}".format(sorted(set(REFUSAL_CODES) - named),
                                                sorted(named - set(REFUSAL_CODES))))
        out("  FAIL E10")
    else:
        out("  PASS E10: every refusal the census can emit is named by at least one arm, "
            "and every refusal an arm names is one it can emit -- a bijection, asserted "
            "both ways")

    controls = [a for a in c_arms if a[3] == 0]
    if not controls:
        failures.append("E1: no census arm reaches rc 0 -- every failing arm is equally "
                        "satisfied by a census that rejects everything")
        out("  FAIL E1")
    else:
        out("  PASS E1: {} arm(s) reach rc 0, so the failing arms below are measurements "
            "rather than the output of an always-fail census".format(len(controls)))

    try:
        _load_yaml()
    except ImportError as exc:
        failures.append("E: NOT-EVALUATED -- the census arms need PyYAML, and `import "
                        "yaml` failed under {} ({}); this is not a clean "
                        "result".format(sys.executable, exc))
        out("  FAIL E: NOT-EVALUATED -- the census arms need PyYAML, and this "
            "interpreter has none. This is not a clean result.")
        return c_arms

    # AT THIS COMMIT the harness compares the exit code, the finding codes and
    # the exit code `run_census` prints, and not the refusal an arm names: the
    # line reader's refusals carry no code. The refusal check lands with the
    # parser-based reader in the next commit.
    seen = {}
    for arm in c_arms:
        aid, what, files, want_rc, want_codes = arm[:5]
        load = arm[6] if len(arm) > 6 else _load_yaml
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(files, root)
            rc, jobs, findings, refusals, _version = census_verdict(root, load)
            with open(os.devnull, "w") as sink:
                printed = run_census(root, stream=sink)
        seen[aid] = (jobs, refusals)
        got = set(f[0] for f in findings)
        if (rc, got, printed) != (want_rc, want_codes, want_rc):
            failures.append("{}: rc {} codes {} (printed rc {}) -- want rc {} "
                            "codes {}".format(aid, rc, sorted(got), printed, want_rc,
                                              sorted(want_codes)))
            out("  FAIL {}: rc {} on {} -- want rc {} on {} -- {}".format(
                aid, rc, sorted(got), want_rc, sorted(want_codes), what))
        else:
            out("  PASS {}: rc {} on exactly {} -- {}".format(
                aid, rc, ",".join(sorted(want_codes)) or "no findings", what))

    # E2: the control arm grades the whole baseline, one job per declared context
    # and the one deliberately advisory job.
    n = len(seen["X0"][0])
    if n != EXPECTED_COUNT + 1:
        failures.append("E2: the control arm graded {} job(s), want {} -- a control "
                        "over a degenerate population proves nothing".format(
                            n, EXPECTED_COUNT + 1))
        out("  FAIL E2")
    else:
        out("  PASS E2: the control arm grades {} job(s) -- {} declared contexts plus "
            "one deliberately advisory job".format(n, EXPECTED_COUNT))

    # E3: a job indented four spaces is read as a job.
    n = len(seen["X9"][0])
    if n != EXPECTED_COUNT + 2:
        failures.append("E3: the four-space arm read {} job(s), want {}".format(
            n, EXPECTED_COUNT + 2))
        out("  FAIL E3")
    else:
        out("  PASS E3: the four-space arm reads {} job(s), the four-space job "
            "among them".format(n))

    # E4: a quoted job key is read as the job it names, under both quoting characters.
    for aid, rel in (("X13", ".github/workflows/synth-quoted.yml"),
                     ("X14", ".github/workflows/synth-squoted.yml")):
        keys = sorted(j["key"] for j in seen[aid][0] if j["file"] == rel)
        if keys != ["new-suite"]:
            failures.append("E4/{}: read key(s) {} -- want ['new-suite']".format(aid, keys))
            out("  FAIL E4/{}".format(aid))
        else:
            out("  PASS E4/{}: the quoted-key file reads as exactly ['new-suite']".format(aid))

    # E11 and E12 grade the parser-based reader, which lands in the next commit.
    # At this one each reports NOT-EVALUATED and fails: a guard that did not run
    # is not a guard that passed.
    for gid, what in (("E11", "the guard on X81's partly-read tree"),
                      ("E12", "the guard on the scanner's comment layer in X74's file")):
        failures.append("{}: NOT-EVALUATED -- {} needs the parser-based reader, "
                        "which this commit does not carry".format(gid, what))
        out("  FAIL {}: NOT-EVALUATED -- {} needs the parser-based reader, which "
            "this commit does not carry".format(gid, what))
    return c_arms



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

    c_arms = _census_group(out, failures)

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
