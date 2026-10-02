#!/usr/bin/env python3
"""Capture, write and assert the app-pinning of a branch's required status checks.

WHAT THIS IS FOR
    `main` requires the status checks CONTEXT_ORDER below declares, each bound
    ("pinned") to the GitHub Actions app through `app_id`, so only a check run
    from that app satisfies it. The tool was written when one of them --
    `Personal-data gate` -- carried `app_id: null`, so that a check run reporting
    that context NAME from any integration satisfied it; it pinned that context
    and proved that it pinned the right thing.

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
       "the right number of contexts, zero nulls" is satisfied by three separate
       WRONG end states: every context pinned to the WRONG app; `app_id` stored
       as the STRING "15368"; and one context silently RENAMED. All three read the
       right number and zero. The assertion here is four conjuncts instead --
       cardinality, exact set equality, zero-null, and a uniform integer pin --
       and `--self-test` drives eleven degenerate inputs through it, each of which
       must fail, plus one correct input which must pass. It then removes each
       conjunct in turn and requires the arm that names it to flip to PASS, so no
       conjunct is carried as unfalsifiable decoration.

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
        Offline. No network, no `gh`, no token. It reads exactly one file of the
        repository this script lives in -- SECURITY.md -- to hold that file's list
        of required checks to CONTEXT_ORDER in both directions (group F). Every
        census arm builds and grades a synthetic tree in a temporary directory,
        never this repository's workflows. It runs the assertion matrix, the
        conjunct-removal matrix, the orchestrator guard arms, the census arms and
        the SECURITY.md arm. This is the arm that makes the tool trustworthy before
        it is ever pointed at a live branch, and it is the arm to run in CI: the
        census step in .github/workflows/security.yml runs it ahead of the census
        on every pull request. It needs PyYAML for the census arms; without it the
        census group reports itself NOT-EVALUATED and the self-test fails.

    --census [--root DIR]
        Offline. Reads every workflow under .github/workflows through a YAML
        parser and set-compares the contexts of the jobs that declare
        `# gate-efficacy: posture=required` with the CONTEXT_ORDER declaration
        below, in both directions. It also finds a declared or claimed context
        that more than one job reports, and a job claiming required in a
        workflow that a pull request into main, or a push to one, does not run:
        no pull_request trigger, or a filter on it that leaves out `main` or
        `synchronize`. It refuses a job claiming required that carries a
        job-level `if:`, or that needs a job not claiming required, because
        GitHub can skip such a job without its check blocking the merge. It
        answers the question a new suite's author is never asked -- does this
        job bind? -- at pull-request time, on the author's own pull request.

        It needs PyYAML and imports it only here and in the self-test. It uses
        the pure-Python SafeLoader and composes nodes without constructing
        objects, so its reading does not depend on the C bindings and no value
        is coerced to a boolean or a number. Where PyYAML cannot be imported it
        refuses at exit 2 and reads nothing.

        WHAT A CLEAN CENSUS DOES NOT ESTABLISH is printed on every exit path, in
        the limit block below, and is not restated here.

        Exit 0 clean / 1 finding(s) / 2 REFUSED -- no YAML parser, no workflow
        file, or a workflow file this census cannot vouch for; each
        refusal carries a code from REFUSAL_CODES and names the file.

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
        It pins a context set that already equals CONTEXT_ORDER and never adds
        one: a live set that differs -- a context declared and not yet
        registered, or one retired -- stops at the drift guard (exit 4) before
        anything is written.

    --restore --staging DIR --confirm-write
        Rollback. Re-applies the captured pre-change sub-resource verbatim,
        `app_id: null` included.

EXIT CODES
    0  the mode's assertion held
    1  an assertion failed
    2  input was malformed or refused (a read that returned a shape with no
       checks array; for --census, a run with no YAML parser or no workflow
       file, or a workflow file this census cannot vouch for --
       each refusal carries a code from REFUSAL_CODES and names the file.
       "I cannot vouch for this file" is a refusal, never a finding, so it
       never shares exit 1)
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
# live set drifts -- a context added, one retired -- the drift guard aborts
# rather than pinning whatever happens to be there, because a set that changed
# is a set someone has to look at. SECURITY.md's Branch Protection Posture
# record lists the same set, and the self-test's group F fails whenever the two
# disagree, in either direction.
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
    "Shell script lint (shellcheck)",
)
EXPECTED_CONTEXTS = frozenset(CONTEXT_ORDER)
EXPECTED_COUNT = len(CONTEXT_ORDER)

_RE_SECURITY_HEADING = re.compile(r"^## Branch Protection Posture\s*$")
_RE_SECURITY_ROW = re.compile(
    "^\\|\\s*Required status checks\\s*\\|\\s*([0-9]+)\\s*\N{EM DASH}\\s*([^|]*?)\\s*\\|")

# Group F's controls: (id, what it models, want_ok). Each is built in memory from
# the live SECURITY.md row and graded against that row's own list, so a control
# tests the reader and the grader whatever the live file says, and each first
# asserts that its change landed.
SECURITY_CONTROLS = (
    ("F1", "SECURITY.md gains a name the declared list lacks, its stated count raised to match: must fail, naming that name in the SECURITY.md-only direction", False),
    ("F2", "SECURITY.md gains a name and its stated count is left as it was: must fail on the count, the row parse's own integrity check", False),
    ("F3", "the declared list renames one entry and SECURITY.md does not: must fail, naming a name in each direction", False),
    ("F4", "SPECIFICITY: the row's names written in reverse order, the set unchanged: must pass", True),
    ("F5", "the section heading renamed: must fail, the row not found, never read as an empty list", False),
    ("F6", "the row written twice in the section: must fail, two answers", False),
)


def security_contexts(text):
    """(names, problem) for the required checks SECURITY.md's posture table lists.

    The list is the second cell of the one table row whose first cell is
    `Required status checks`, inside the one `## Branch Protection Posture`
    section, written as `N -- name, name, ...` with an em dash. N is checked against
    the names read, so a name that itself carries a comma is caught as a mis-read
    rather than graded as two names. `problem` is None when the row reads cleanly.
    """
    lines = text.split("\n")
    heads = [i for i, line in enumerate(lines) if _RE_SECURITY_HEADING.match(line)]
    if len(heads) != 1:
        return None, ("the `## Branch Protection Posture` heading appears {} time(s), "
                      "want 1".format(len(heads)))
    start = heads[0] + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith("## ")),
               len(lines))
    rows = [m for m in (_RE_SECURITY_ROW.match(lines[i]) for i in range(start, end)) if m]
    if len(rows) != 1:
        return None, ("the `Required status checks` row appears {} time(s) in that "
                      "section, want 1".format(len(rows)))
    stated = int(rows[0].group(1))
    names = rows[0].group(2).split(", ")
    if stated != len(names):
        return None, "the row states {} but lists {} name(s)".format(stated, len(names))
    if len(set(names)) != len(names):
        return None, "the row lists a name twice"
    return names, None


def security_grade(text, declared):
    """(ok, detail): SECURITY.md's list against `declared`, in both directions."""
    names, problem = security_contexts(text)
    if problem:
        return False, problem
    listed, wanted = set(names), set(declared)
    if listed == wanted:
        return True, "{} listed, set-equal to the declaration in both directions".format(
            len(listed))
    return False, "in SECURITY.md only: {}; in the declaration only: {}".format(
        sorted(listed - wanted), sorted(wanted - listed))


def _security_mutants(text):
    """(baseline, {id: (text, declared)}) for F1-F6, built from `text` in memory.

    The baseline is (text, the row's own list); every control is graded against a
    list derived from the row rather than against CONTEXT_ORDER, so a drift in the
    live file fails F0 alone. None when the row cannot be found.
    """
    lines = text.split("\n")
    at = [i for i, line in enumerate(lines) if _RE_SECURITY_ROW.match(line)]
    if not at:
        return None
    i = at[0]
    row = lines[i]
    m = _RE_SECURITY_ROW.match(row)
    names = tuple(m.group(2).split(", "))

    def with_row(new_row, extra_after=False):
        out = list(lines)
        if extra_after:
            out.insert(i + 1, new_row)
        else:
            out[i] = new_row
        return "\n".join(out)

    renamed = (names[0] + " RENAMED",) + names[1:]
    return (text, names), {
        "F1": (with_row(row[:m.start(1)] + str(len(names) + 1) + row[m.end(1):m.end(2)]
                        + ", F1 synthetic check" + row[m.end(2):]), names),
        "F2": (with_row(row[:m.end(2)] + ", F2 synthetic check" + row[m.end(2):]), names),
        "F3": (text, renamed),
        "F4": (with_row(row[:m.start(2)] + ", ".join(reversed(names)) + row[m.end(2):]),
               names),
        "F5": (text.replace("## Branch Protection Posture", "## Branch Protection", 1),
               names),
        "F6": (with_row(row, extra_after=True), names),
    }


def _security_group(out, failures):
    """Group F of the self-test: SECURITY.md's required-check list against CONTEXT_ORDER.

    F0 reads this repository's SECURITY.md -- the one repository file the self-test
    reads -- and grades it against CONTEXT_ORDER in both directions. F1-F6 grade
    copies of the row changed in memory, each against the row's own list, and each
    first asserts its change landed. It needs no YAML parser, so it runs and
    reports when group E cannot.
    """
    out("")
    out("F -- SECURITY.md's required-check list against CONTEXT_ORDER, in both directions")
    path = os.path.join(repo_root(), "SECURITY.md")
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except (OSError, UnicodeDecodeError) as exc:
        failures.append("F0: SECURITY.md could not be read beside scripts/ ({})".format(
            type(exc).__name__))
        out("  FAIL F0: SECURITY.md could not be read, so the list cannot be graded")
        return
    ok, detail = security_grade(text, CONTEXT_ORDER)
    if ok:
        out("  PASS F0: SECURITY.md's Branch Protection Posture row -- {}".format(detail))
    else:
        failures.append("F0: SECURITY.md and CONTEXT_ORDER disagree -- {}".format(detail))
        out("  FAIL F0: SECURITY.md and CONTEXT_ORDER disagree -- {}".format(detail))
    built = _security_mutants(text)
    for cid, what, want_ok in SECURITY_CONTROLS:
        if built is None:
            failures.append("{}: not built -- the row was not found".format(cid))
            out("  FAIL {}: not built -- {}".format(cid, what))
            continue
        baseline, mutants = built
        mtext, declared = mutants[cid]
        if (mtext, tuple(declared)) == baseline:
            failures.append("{}: the change did not land, so the control proves nothing".format(cid))
            out("  FAIL {}: the change did not land -- {}".format(cid, what))
            continue
        got_ok, got = security_grade(mtext, declared)
        if got_ok != want_ok:
            failures.append("{}: graded ok={} ({}) -- want ok={}".format(cid, got_ok, got, want_ok))
            out("  FAIL {}: graded ok={} -- {}".format(cid, got_ok, what))
        else:
            out("  PASS {}: {} -- {}".format(cid, "passes" if got_ok else "fails", what))


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

    # C2b no duplicates. A duplicated context can hold cardinality at the expected
    # count while a real required check has gone missing.
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
# CONTEXT_ORDER in both directions. That declaration is the only thing the
# census reads to decide whether a job binds; a posture is never inferred from
# triggers, filenames or membership, because each of those is either false by
# construction or vacuous -- a set derived from CONTEXT_ORDER can never disagree
# with it.
#
# Every workflow is read through a YAML parser, so the jobs and their contexts
# are the parser's. The marker is a comment, which no YAML document carries, so
# it is read from the lines the parser's own scanner passed over as comments,
# directly above a job key the parser located.
#
# WHAT A GREEN CENSUS DOES NOT MEAN. `GITHUB_TOKEN` cannot read the branch
# protection API, so no check running in this repository's CI can confirm that
# a context is REGISTERED. Registration remains an operator act outside any pull
# request: --apply pins the contexts already registered, and a new context is
# registered through the required_status_checks endpoint and read back with
# --assert. The census makes an omission visible at pull-request time; it cannot
# make one impossible.
# ==========================================================================

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


POSTURE_VALUES = ("required", "advisory")

# The census's emittable finding set. The self-test asserts a bijection between
# it and the codes the arms name, in both directions (E0).
CENSUS_CODES = ("UNREGISTERED", "ABSENT", "UNDECLARED", "DUPLICATE", "UNTRIGGERED")

# Every reason the census refuses. A refusal is exit 2 and never exit 1: "I cannot
# vouch for this" is not "the workflows and the declaration disagree". The
# self-test asserts a bijection between this set and the refusals the arms name (E10).
REFUSAL_CODES = (
    "NO-PARSER", "NO-WORKFLOWS", "UNREADABLE", "YAML11-BREAK", "UNPARSEABLE",
    "NOT-ONE-DOCUMENT", "NO-JOBS", "NO-JOB", "KEY-TWICE", "MERGE-KEY",
    "KEY-NOT-TEXT", "JOB-NOT-MAPPING", "NAME-NOT-TEXT",
    "RUNTIME-NAME", "RUNTIME-MATRIX", "RUNTIME-REUSABLE",
    "RUNTIME-CONDITION", "RUNTIME-NEEDS")

PR_TRIGGER = "pull_request"
# The branch a required check guards, and the activity type a push to an open pull
# request arrives as. A `branches:` or `branches-ignore:` filter written as literal
# names decides the first, and a `types:` filter decides the second.
PR_BRANCH = "main"
PR_PUSH_TYPE = "synchronize"
# GitHub's filter-pattern characters: `*`, `?`, `+`, a bracket, the escaping
# backslash, and `!` as a pattern's first character, the only place GitHub gives it
# a meaning. A branch filter carrying one is left to GitHub's grammar (X116).
_RE_PATTERN = re.compile(r"[*?+\[\]\\]|^!")
_NULL_TAG = "tag:yaml.org,2002:null"

_RE_MARKER = re.compile(r"^(\s*)#\s*gate-efficacy:\s*posture\s*=\s*(\S+)")
# YAML 1.1's line breaks -- the set PyYAML's marks count -- so a line index here is
# the parser's line index. str.splitlines() splits on characters YAML does not.
# The characters past `\n` are written as escapes so this file stays ASCII: a
# literal LINE SEPARATOR or PARAGRAPH SEPARATOR is invisible in most viewers, and
# a copy that lost one would narrow both patterns with no arm but X108 or X109
# noticing.
_RE_BREAK = re.compile("\r\n|[\r\n\x85\N{LINE SEPARATOR}\N{PARAGRAPH SEPARATOR}]")
# Line breaks to YAML 1.1 and ordinary characters to YAML 1.2 (X86, X108, X109).
_RE_YAML11_ONLY = re.compile("[\x85\N{LINE SEPARATOR}\N{PARAGRAPH SEPARATOR}]")

REFUSAL_TEXT = {
    "NO-PARSER": "this census reads workflows through PyYAML, and loading it failed under this interpreter, so nothing was read",
    "NO-WORKFLOWS": "no workflow file was found, and a census over an empty population asserts nothing",
    "UNREADABLE": "it could not be opened and read as UTF-8 text",
    "YAML11-BREAK": "it carries a character that YAML 1.1 reads as a line break and YAML 1.2 reads as content, so the parser here and a YAML 1.2 parser can read different names, or different jobs, from it",
    "UNPARSEABLE": "it does not parse as YAML",
    "NOT-ONE-DOCUMENT": "it does not hold exactly one YAML document, and what GitHub reads from a stream of several was not measured",
    "NO-JOBS": "it has no `jobs` mapping at its top level",
    "NO-JOB": "its `jobs` mapping holds no job",
    "KEY-TWICE": "a mapping this census reads writes the same key twice; the parsers measured keep the later copy, and what GitHub keeps was not measured",
    "MERGE-KEY": "a mapping this census reads carries a merge key, and which keys GitHub reads through it was not measured",
    "KEY-NOT-TEXT": "a key in a mapping this census reads is not a scalar",
    "JOB-NOT-MAPPING": "a job's value is not a mapping",
    "NAME-NOT-TEXT": "a job's `name:` is empty or is not a scalar, and what GitHub reports for it was not measured",
    "RUNTIME-NAME": "a job claiming required has a `name:` carrying an expression, so GitHub computes its context when the job runs",
    "RUNTIME-MATRIX": "a job claiming required carries a `strategy`, so GitHub extends its context with matrix values when it runs",
    "RUNTIME-REUSABLE": "a job claiming required calls a reusable workflow, so its checks report under names composed with the called workflow's jobs",
    "RUNTIME-CONDITION": "a job claiming required carries a job-level `if:`, and GitHub documents that a job skipped by its own `if:` reports Success, so the required check could pass without the job running",
    "RUNTIME-NEEDS": "a job claiming required `needs:` a job that does not itself claim required, and GitHub documents that a job skipped because a job it needs failed may not block the merge, so the required check could pass without the job running",
}

# NO-PARSER's remedy is not here: it turns on which interpreter failed to load the
# parser, so it is NO_PARSER_REMEDY's, chosen by _no_parser_remedy.
REFUSAL_REMEDY = {
    "NO-WORKFLOWS": "point --root at a repository whose .github/workflows holds its workflow files",
    "UNREADABLE": "save the file as UTF-8 text",
    "YAML11-BREAK": "delete the character, or write it inside a double-quoted scalar as the escape \\N, \\L or \\P, which both YAML versions read as content",
    "UNPARSEABLE": "fix the YAML; `Workflow SAST (actionlint)`, in this same job, names the line",
    "NOT-ONE-DOCUMENT": "keep one workflow per file, with no `---` line opening a second document",
    "NO-JOBS": "write the workflow's jobs under a top-level `jobs:` mapping, or move a file that is not a workflow out of .github/workflows",
    "NO-JOB": "give the `jobs` mapping at least one job",
    "KEY-TWICE": "delete the copy you did not mean",
    "MERGE-KEY": "write the job's keys out in full rather than merging them in with `<<:`",
    "KEY-NOT-TEXT": "write the key as a plain or quoted scalar",
    "JOB-NOT-MAPPING": "write the job as a mapping of its properties",
    "NAME-NOT-TEXT": "give the job a literal `name:`, or delete the key so that the job's key is its context",
    "RUNTIME-NAME": "give a job that claims required a literal `name:`, so the context it reports is the text the declaration carries",
    "RUNTIME-MATRIX": "declare the job advisory, or split the matrix into jobs that each carry a literal `name:`",
    "RUNTIME-REUSABLE": "declare the calling job advisory; a required check on a reusable workflow is registered under the composed name the run reports, which this census does not compute",
    "RUNTIME-CONDITION": "drop the job-level `if:`, so that the job runs whenever its workflow does, or declare the job advisory",
    "RUNTIME-NEEDS": "have each job it needs claim required too, or drop the dependency",
}

# On the runner the census runs under the system python3, the interpreter the
# image carries PyYAML for. When that interpreter fails to load the parser, the
# image has changed and no step in this repository put it there; when any other
# interpreter fails, it is one without PyYAML that sits ahead of the system python3
# on PATH. The two causes have different remedies, so the remedy is chosen by the
# interpreter's path -- as written, not resolved, because a virtual environment's
# python3 links to the system one and is exactly the second cause.
SYSTEM_PYTHON_DIR = "/usr/bin/"

NO_PARSER_REMEDY = {
    "SYSTEM": "the interpreter that failed is the system python3. On the runner that means the image no longer carries PyYAML, and no setup-python step is behind it: the remedy is a reviewed decision about the runner or the parser -- pin the job to an image that carries PyYAML, or read the workflows with a parser that image does carry -- made in a pull request of its own. Elsewhere, install PyYAML for this interpreter",
    "OTHER": "the interpreter that failed is not the system python3, so a Python without PyYAML sits ahead of it on PATH -- on the runner, a setup-python step placed before this one puts it there. Run the census under a python3 that carries PyYAML: on the runner the system python3, and locally an interpreter with PyYAML installed",
}

FINDING_TEXT = {
    "UNREGISTERED": "claims posture=required, but no such context is declared in CONTEXT_ORDER",
    "ABSENT": "declared in CONTEXT_ORDER, but no job claims posture=required under that name",
    "UNDECLARED": "no `# gate-efficacy: posture=` marker as the first line of the comment block directly above the job key",
    "UNDECLARED-VALUE": "posture value {value!r} is not one of {allowed}",
    "DUPLICATE-ONE-CLAIM": "{others} report(s) this context without claiming required, beside {claimant}, which claims it. Which of these jobs' check runs GitHub counts for the context was not measured, so {others} shadow(s) {claimant}: the requirement may be met by a job the declaration does not bind",
    "DUPLICATE-MANY-CLAIMS": "{jobs} all report this context and more than one of them claims required. Which of their check runs GitHub counts for the context was not measured, so each shadows the others and the declaration cannot say which one binds",
    "DUPLICATE-NO-CLAIM": "{jobs} report this declared context and none of them claims required; which of their check runs GitHub counts for the context was not measured",
    "UNTRIGGERED": "claims posture=required, but its workflow has no pull_request trigger, so its check can never report on a pull request",
    "UNTRIGGERED-BRANCHES": "claims posture=required, but the `branches:` filter on its workflow's pull_request trigger names no `main` and carries no pattern, so no pull request into `main` runs it and its check stays pending on every one",
    "UNTRIGGERED-IGNORED": "claims posture=required, but the `branches-ignore:` filter on its workflow's pull_request trigger names `main`, so no pull request into `main` runs it and its check stays pending on every one",
    "UNTRIGGERED-TYPES": "claims posture=required, but the `types:` filter on its workflow's pull_request trigger names no `synchronize`, so a push to a pull request starts no run on its new head commit and the check stays pending",
}

MARKER_NOTE = {
    "TWO": "the comment block above this job carries {n} `# gate-efficacy: posture=` lines ({where}). Two answers is not an answer, so neither binds -- leave exactly one, and delete the line it replaces rather than writing a second beneath it",
    "NOT-TOP": "a `# gate-efficacy: posture=` line sits inside the comment block above this job but is not that block's first line. A marker binds only as the FIRST line of the contiguous comment block directly above the job key, so this one answers for no job",
    "INDENT": "the marker above this job is indented {got} space(s); it binds only at the indentation of the job key's own line, {want}",
    "NOT-OWN-LINE": "a marker sits above this job, but the job key does not begin its own line, so no marker binds to it",
}

CENSUS_PRINT = {
    "BANNER": "REGISTRATION CENSUS -- offline. No network, no gh, no token.",
    "PARSER": "read through PyYAML {version} (pure-Python SafeLoader, composed, never constructed)",
    "SCANNED": "scanned {files} workflow file(s), {jobs} job(s): {required} claiming required, {advisory} advisory, {undeclared} undeclared",
    "GRADED": "graded against CONTEXT_ORDER: {declared} declared context(s)",
    "REFUSED-RUN": "REFUSED: {code} -- {why} ({detail}).",
    "REFUSED-FILES": "REFUSED: {refused} of {files} workflow file(s) this census cannot vouch for. No verdict is issued.",
    "REFUSED-FILE": "    {file} -- {code}: {why}{detail}",
    "REMEDY": "        Remedy: {remedy}.",
    "FAILED": "CENSUS FAILED -- {n} finding(s).",
    "CLEAN": "CENSUS CLEAN -- every job declares a posture; the jobs claiming required are set-equal to CONTEXT_ORDER in both directions; no declared or claimed context is reported by more than one job; and every workflow that holds a required job runs, so far as its file decides it, on each pull request into `main` and on each push to one.",
}

CENSUS_REMEDY = (
    "  UNREGISTERED  a job claims to bind and the declaration does not carry it.",
    "                Add the context to CONTEXT_ORDER in this file AND ask the",
    "                operator to register it in branch protection -- or declare",
    "                the job `posture=advisory` and say why in the line beneath.",
    "  ABSENT        the declaration carries a context no job claims. The job was",
    "                renamed or removed; protection now waits on a check that",
    "                can never report.",
    "  UNDECLARED    a job has not answered the question. Put exactly ONE",
    "                `# gate-efficacy: posture=required` or `=advisory` as the",
    "                FIRST line of the comment block directly above its job",
    "                key, indented to match the key. A marker anywhere else in",
    "                that block answers for no job -- otherwise a comment that",
    "                merely documents this grammar would answer for one -- and",
    "                a SECOND marker is two answers, so it is read as none.",
    "  DUPLICATE     more than one job reports one context, and which of their",
    "                check runs GitHub counts for it was not measured. Give each",
    "                job its own name, or drop the extra job.",
    "  UNTRIGGERED   a job claims required in a workflow that a pull request into",
    "                `main`, or a push to one, does not run: it has no",
    "                pull_request trigger, or a filter on that trigger leaves out",
    "                `main` or `synchronize`. Trigger the workflow on",
    "                pull_request with no such filter, or declare the job advisory.",
)


class CensusRefusal(Exception):
    """A workflow file, or the run, that the census cannot vouch for."""

    def __init__(self, code, detail=""):
        Exception.__init__(self, code)
        self.code = code
        self.detail = detail


def _load_yaml():
    """The YAML parser the census reads with: PyYAML, imported here and only here.

    A function rather than a module-level import, so --assert and --restore never
    need the parser -- --plan and --apply run the self-test first, and its census
    arms do -- and so the self-test can hand the census a loader that fails (X95)
    and watch it refuse.
    """
    import yaml
    return yaml


def _no_yaml():
    """A loader that cannot import the parser -- X95's, and no one else's."""
    raise ImportError("No module named 'yaml' (a loader built to fail)")


def _no_parser_remedy(executable):
    """NO-PARSER's remedy, chosen by the path of the interpreter that failed."""
    return NO_PARSER_REMEDY["SYSTEM" if executable.startswith(SYSTEM_PYTHON_DIR)
                            else "OTHER"]


def _pairs(yaml, node, where, not_mapping="NO-JOBS"):
    """(key text, key node, value node) for each entry of a mapping the census reads.

    It refuses a node that is not a mapping, a key that is not a scalar, a merge
    key, and a key written twice. The parsers measured keep the later copy of a
    repeated key; what GitHub keeps was not measured, so the census does not choose.
    """
    if not isinstance(node, yaml.MappingNode):
        raise CensusRefusal(not_mapping, "{} is not a mapping".format(where))
    out, seen = [], {}
    for key, value in node.value:
        line = key.start_mark.line + 1
        if not isinstance(key, yaml.ScalarNode):
            raise CensusRefusal("KEY-NOT-TEXT", "{}, line {}".format(where, line))
        if key.tag == "tag:yaml.org,2002:merge":
            raise CensusRefusal("MERGE-KEY", "{}, line {}".format(where, line))
        if key.value in seen:
            raise CensusRefusal("KEY-TWICE", "{} writes {!r} on lines {} and {}".format(
                where, key.value, seen[key.value], line))
        seen[key.value] = line
        out.append((key.value, key, value))
    return out


def _comment_lines(yaml, text, lines):
    """Indices of the lines the YAML scanner passed over as comments.

    A line counts when its first non-blank character is `#` AND no token the
    scanner emitted overlaps it. A quoted or block scalar may carry a line that
    begins with `#`; that line lies inside a token's span, so it is content and not
    a comment (X74, E12). The test reads the scanner's own decision rather than a
    pattern over the line.
    """
    candidates = {}
    for i, line in enumerate(lines):
        body = line.lstrip(" \t")
        if body.startswith("#"):
            candidates[i] = (len(line) - len(body), len(line.rstrip(" \t")))
    covered = set()
    for token in yaml.scan(text, Loader=yaml.SafeLoader):
        start, end = token.start_mark, token.end_mark
        for i in range(start.line, end.line + 1):
            if i in candidates and i not in covered:
                first, last = candidates[i]
                if (start.line, start.column) < (i, last) and \
                        (end.line, end.column) > (i, first):
                    covered.add(i)
    return set(candidates) - covered


def _events(yaml, node):
    """The event names a workflow's `on:` declares, written in any of its shapes."""
    if node is None:
        return set()
    if isinstance(node, yaml.ScalarNode):
        return {node.value}
    if isinstance(node, yaml.SequenceNode):
        return {item.value for item in node.value if isinstance(item, yaml.ScalarNode)}
    return {key for key, _, _ in _pairs(yaml, node, "the `on` mapping")}


def _names(yaml, node):
    """The texts a trigger filter or a `needs:` holds: one for a scalar, one each for
    a sequence of scalars, the shapes GitHub's schema gives them. None for any other
    shape -- a null, a mapping, or a sequence holding something other than text.
    """
    if isinstance(node, yaml.ScalarNode) and node.tag != _NULL_TAG:
        return [node.value]
    if isinstance(node, yaml.SequenceNode) and all(
            isinstance(item, yaml.ScalarNode) and item.tag != _NULL_TAG
            for item in node.value):
        return [item.value for item in node.value]
    return None


def _untriggered(yaml, on):
    """Why a pull request into `main`, or a push to one, does not run the workflow, as
    the file decides it: a FINDING_TEXT key, or None when nothing in the file stops it.

    Only `pull_request` is a trigger here, so a workflow triggered by
    `pull_request_target` or `merge_group` alone fails closed. A `branches:` filter
    admits `main` when it names it, and one carrying a pattern is left to GitHub's
    grammar (X116). A `branches-ignore:` filter shuts `main` out when it names it,
    unless an entry opens with `!`, which can negate an earlier entry under GitHub's
    pattern grammar. A `types:` filter admits a push when it names `synchronize`. A
    `branches:` or `types:` filter in a shape GitHub's schema does not give it names
    nothing, so it admits nothing; such a `branches-ignore:` filter, or a trigger
    whose value is neither null nor a mapping, is the schema's question, which
    actionlint answers in this same job.
    """
    if PR_TRIGGER not in _events(yaml, on):
        return "UNTRIGGERED"
    if not isinstance(on, yaml.MappingNode):
        return None
    trigger = {key: value for key, _, value in _pairs(yaml, on, "the `on` mapping")}
    if not isinstance(trigger[PR_TRIGGER], yaml.MappingNode):
        return None
    filters = {key: _names(yaml, value) for key, _, value in
               _pairs(yaml, trigger[PR_TRIGGER], "the `pull_request` trigger")}
    if "branches" in filters:
        names = filters["branches"]
        if names is None or not (PR_BRANCH in names
                                 or any(_RE_PATTERN.search(n) for n in names)):
            return "UNTRIGGERED-BRANCHES"
    if "branches-ignore" in filters:
        names = filters["branches-ignore"]
        if names is not None and PR_BRANCH in names and \
                not any(n.startswith("!") for n in names):
            return "UNTRIGGERED-IGNORED"
    if "types" in filters:
        names = filters["types"]
        if names is None or PR_PUSH_TYPE not in names:
            return "UNTRIGGERED-TYPES"
    return None


def _bind_marker(lines, comments, key_node, keys_on_line):
    """(raw, note) for one job key. `raw` is set only by a BOUND marker.

    A marker binds when it is the FIRST line of the contiguous run of comment lines
    directly above the job key, and its `#` sits at the indentation of the key's
    own line. Proximity alone is not enough: a comment that documents the grammar
    would otherwise answer for a job that never did (X10). More than one marker in
    the run binds none (X12). A key that does not begin its own line, as in a flow
    mapping written on one line, binds none, because keys sharing a line would share
    an answer. `note` explains a marker that is present and did not bind.
    """
    k = key_node.start_mark.line
    line = lines[k]
    indent = len(line) - len(line.lstrip(" "))
    column = key_node.start_mark.column
    begins = column == indent or (
        line[indent:indent + 1] == "?" and not line[indent + 1:column].strip(" \t"))
    top = k
    while top - 1 >= 0 and (top - 1) in comments:
        top -= 1
    if top == k:
        return (None, None)
    markers = [i for i in range(top, k) if _RE_MARKER.match(lines[i])]
    if not begins or keys_on_line[k] > 1:
        return (None, MARKER_NOTE["NOT-OWN-LINE"] if markers else None)
    if len(markers) > 1:
        where = ", ".join("{!r} {}".format(
            _RE_MARKER.match(lines[i]).group(2),
            "on the block's first line" if i == top
            else "{} line(s) below it".format(i - top)) for i in markers)
        return (None, MARKER_NOTE["TWO"].format(n=len(markers), where=where))
    first = _RE_MARKER.match(lines[top])
    if first and len(first.group(1)) == indent:
        return (first.group(2), None)
    if markers:
        if markers[0] != top:
            return (None, MARKER_NOTE["NOT-TOP"])
        return (None, MARKER_NOTE["INDENT"].format(got=len(first.group(1)), want=indent))
    return (None, None)


def _read_workflow(yaml, rel, path):
    """The job records of one workflow file, or a CensusRefusal naming why not."""
    try:
        with open(path, "rb") as fh:
            text = fh.read().decode("utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        raise CensusRefusal("UNREADABLE", type(exc).__name__)
    odd = _RE_YAML11_ONLY.search(text)
    if odd:
        raise CensusRefusal("YAML11-BREAK", "U+{:04X} on line {}".format(
            ord(odd.group(0)), len(_RE_BREAK.split(text[:odd.start()]))))
    lines = _RE_BREAK.split(text)
    try:
        documents = list(yaml.compose_all(text, Loader=yaml.SafeLoader))
        comments = _comment_lines(yaml, text, lines)
    except Exception as exc:
        # Every way the parser can fail to read the file is a refusal: a YAML
        # error, and an exception outside that class as well -- the
        # RecursionError that deep nesting raises among them (X110) -- because
        # an exception left to escape would end the run at exit 1, the finding
        # code.
        raise CensusRefusal("UNPARSEABLE", "{}: {}".format(
            type(exc).__name__, " ".join(str(exc).split())))
    if len(documents) != 1 or documents[0] is None:
        raise CensusRefusal("NOT-ONE-DOCUMENT", "{} document(s)".format(len(documents)))
    top = {key: value for key, _, value in _pairs(yaml, documents[0], "the top level")}
    if "jobs" not in top:
        raise CensusRefusal("NO-JOBS")
    untriggered = _untriggered(yaml, top.get("on"))
    entries = _pairs(yaml, top["jobs"], "the `jobs` mapping")
    if not entries:
        raise CensusRefusal("NO-JOB")
    keys_on_line = {}
    for _, key_node, _ in entries:
        line = key_node.start_mark.line
        keys_on_line[line] = keys_on_line.get(line, 0) + 1
    records, needs = [], []
    for key, key_node, value in entries:
        where = "job `{}`".format(key)
        props = {p: node for p, _, node in
                 _pairs(yaml, value, where, not_mapping="JOB-NOT-MAPPING")}
        name = key
        if "name" in props:
            node = props["name"]
            if not isinstance(node, yaml.ScalarNode) or node.value == "":
                raise CensusRefusal("NAME-NOT-TEXT", where)
            name = node.value
        raw, note = _bind_marker(lines, comments, key_node, keys_on_line)
        posture = raw if raw in POSTURE_VALUES else None
        if posture == "required":
            if "${{" in name:
                raise CensusRefusal("RUNTIME-NAME", where)
            if "strategy" in props:
                raise CensusRefusal("RUNTIME-MATRIX", where)
            if "uses" in props:
                raise CensusRefusal("RUNTIME-REUSABLE", where)
            if "if" in props:
                raise CensusRefusal("RUNTIME-CONDITION", where)
            if "needs" in props:
                needs.append((where, props["needs"]))
        records.append({"file": rel, "key": key, "name": name, "posture": posture,
                        "raw": raw, "note": note, "line": key_node.start_mark.line + 1,
                        "untriggered": untriggered})
    # A required job may need a job written below it, so the jobs it needs are
    # checked once every posture in the file is known.
    bound = set(r["key"] for r in records if r["posture"] == "required")
    for where, node in needs:
        needed = _names(yaml, node)
        if needed is None:
            raise CensusRefusal("RUNTIME-NEEDS", "{}: its `needs:` names no job as "
                                                 "text".format(where))
        unbound = [n for n in needed if n not in bound]
        if unbound:
            raise CensusRefusal("RUNTIME-NEEDS", "{} needs {}".format(
                where, ", ".join("`{}`".format(n) for n in unbound)))
    return records


def census_scan(root, load=_load_yaml):
    """(records, refused) for every workflow file under `root`.

    Records come from the files read in full; `refused` holds (file, code, detail)
    for each file this census cannot vouch for. A refused file never stops the
    rest from being read, so one run names every file at fault (E11). `load`
    returns the parser; an exception from it propagates to the caller, which
    census_verdict refuses as NO-PARSER.
    """
    yaml = load()
    records, refused = [], []
    for rel, path in workflow_files(root):
        try:
            records.extend(_read_workflow(yaml, rel, path))
        except CensusRefusal as exc:
            refused.append((rel, exc.code, exc.detail))
    return records, refused


def _job_label(job):
    return "`{}` ({}, {})".format(job["key"], job["file"], job["posture"] or "undeclared")


def census_findings(jobs):
    """(code, file, context, why) for every disagreement. Empty is clean."""
    findings = []
    for job in sorted(jobs, key=lambda j: (j["file"], j["key"])):
        if job["posture"] is not None:
            continue
        if job["raw"] is not None:
            why = FINDING_TEXT["UNDECLARED-VALUE"].format(
                value=job["raw"], allowed="|".join(POSTURE_VALUES))
        else:
            why = job["note"] or FINDING_TEXT["UNDECLARED"]
        findings.append(("UNDECLARED", job["file"], job["name"], why))
    claimed = {}
    for job in jobs:
        if job["posture"] == "required":
            claimed.setdefault(job["name"], []).append(job)
    for ctx in sorted(set(claimed) - EXPECTED_CONTEXTS):
        findings.append(("UNREGISTERED", claimed[ctx][0]["file"], ctx,
                         FINDING_TEXT["UNREGISTERED"]))
    for ctx in sorted(EXPECTED_CONTEXTS - set(claimed)):
        findings.append(("ABSENT", "-", ctx, FINDING_TEXT["ABSENT"]))
    reported = {}
    for job in jobs:
        reported.setdefault(job["name"], []).append(job)
    for ctx in sorted(reported):
        group = sorted(reported[ctx], key=lambda j: (j["file"], j["key"]))
        claims = [j for j in group if j["posture"] == "required"]
        if len(group) < 2 or not (ctx in EXPECTED_CONTEXTS or claims):
            continue
        if len(claims) == 1:
            others = ", ".join(_job_label(j) for j in group if j is not claims[0])
            why = FINDING_TEXT["DUPLICATE-ONE-CLAIM"].format(
                others=others, claimant=_job_label(claims[0]))
        elif claims:
            why = FINDING_TEXT["DUPLICATE-MANY-CLAIMS"].format(
                jobs=", ".join(_job_label(j) for j in group))
        else:
            why = FINDING_TEXT["DUPLICATE-NO-CLAIM"].format(
                jobs=", ".join(_job_label(j) for j in group))
        findings.append(("DUPLICATE", group[0]["file"], ctx, why))
    for job in sorted(jobs, key=lambda j: (j["file"], j["key"])):
        if job["posture"] == "required" and job["untriggered"]:
            findings.append(("UNTRIGGERED", job["file"], job["name"],
                             FINDING_TEXT[job["untriggered"]]))
    return findings


def census_verdict(root, load=_load_yaml):
    """(rc, records, findings, refusals, version) -- the census's whole result, unprinted.

    rc 0 clean, 1 findings, 2 refused. `refusals` is a list of (file, code, detail);
    a refusal of the whole run carries "-" for its file. The self-test grades this,
    and run_census prints it, so the two cannot disagree about the verdict.
    """
    try:
        yaml = load()
    except Exception as exc:
        # Any failure to load the parser is a refusal -- ImportError, or anything
        # else the import raises -- never an exception left to end the run at
        # exit 1, the finding code.
        return (2, [], [], [("-", "NO-PARSER", "{}: {}".format(
            type(exc).__name__, exc))], None)
    version = getattr(yaml, "__version__", "unknown")
    if not workflow_files(root):
        return (2, [], [], [("-", "NO-WORKFLOWS",
                             os.path.join(root, ".github", "workflows"))], version)
    records, refused = census_scan(root, lambda: yaml)
    if refused:
        return (2, records, [], refused, version)
    findings = census_findings(records)
    return (1 if findings else 0, records, findings, [], version)


def run_census(root, stream=sys.stdout, load=_load_yaml):
    """Grade the workflows against CONTEXT_ORDER. 0 clean / 1 findings / 2 refused."""
    def out(msg):
        stream.write(msg + "\n")

    def limit():
        # On EVERY exit, the refusal included: the limits are a standing property
        # of the instrument, not a gloss on a green result.
        out("")
        for line in _CENSUS_LIMIT:
            out(line)

    rc, records, findings, refusals, version = census_verdict(root, load)
    out("=" * 78)
    out(CENSUS_PRINT["BANNER"])
    out("=" * 78)
    if rc == 2 and refusals[0][0] == "-":
        code, detail = refusals[0][1], refusals[0][2]
        if code == "NO-PARSER":
            detail = "{}; interpreter {}".format(detail, sys.executable)
            remedy = _no_parser_remedy(sys.executable)
        else:
            remedy = REFUSAL_REMEDY[code]
        out(CENSUS_PRINT["REFUSED-RUN"].format(code=code, why=REFUSAL_TEXT[code],
                                               detail=detail))
        out(CENSUS_PRINT["REMEDY"].format(remedy=remedy).strip())
        limit()
        return 2
    files = workflow_files(root)
    if rc == 2:
        out(CENSUS_PRINT["REFUSED-FILES"].format(refused=len(refusals), files=len(files)))
        for rel, code, detail in refusals:
            out(CENSUS_PRINT["REFUSED-FILE"].format(
                file=rel, code=code, why=REFUSAL_TEXT[code],
                detail=" ({})".format(detail) if detail else ""))
            out(CENSUS_PRINT["REMEDY"].format(remedy=REFUSAL_REMEDY[code]))
        limit()
        return 2
    required = sum(1 for j in records if j["posture"] == "required")
    advisory = sum(1 for j in records if j["posture"] == "advisory")
    out(CENSUS_PRINT["PARSER"].format(version=version))
    out(CENSUS_PRINT["SCANNED"].format(files=len(files), jobs=len(records),
                                       required=required, advisory=advisory,
                                       undeclared=len(records) - required - advisory))
    out(CENSUS_PRINT["GRADED"].format(declared=EXPECTED_COUNT))
    out("")
    if findings:
        for code, where, ctx, why in findings:
            out("FINDING {:<12} {:<42} [{}]".format(code, ctx, where))
            out("        {}".format(why))
        out("")
        out("-" * 78)
        out(CENSUS_PRINT["FAILED"].format(n=len(findings)))
        for line in CENSUS_REMEDY:
            out(line)
    else:
        out(CENSUS_PRINT["CLEAN"])
    limit()
    return rc


# The limit block, printed on EVERY exit path. It states what a parser cannot
# decide, as structural limits with the instances measured so far, and it never
# counts them: a count of an open set goes false the moment the next instance is
# measured. E9, in the self-test, fails on a number written in
# front of a class, a way, a mechanism or a member here, in any docstring in this
# module, in any arm label and in any text the census prints; a count of a closed
# set is written as a measured tally in numerals, as in 5 of 5.
_CENSUS_LIMIT = (
    "WHAT THIS DOES NOT ESTABLISH: `GITHUB_TOKEN` cannot read the branch protection",
    "API, so this census cannot confirm that any context is REGISTERED.",
    "Registration remains an operator act outside any pull request.",
    "",
    "HOW IT READS. Every workflow file is read through a YAML parser -- PyYAML's",
    "pure-Python SafeLoader, composed to nodes and never constructed into objects --",
    "so the set of jobs, and each job's context (its `name:`, or its key where it",
    "has none), are the parser's, not a reading of lines. The posture marker is a",
    "comment, and no YAML document carries a comment, so the marker is read from",
    "the lines the parser's own scanner passed over as comments, directly above a",
    "job key the parser located. A file this census cannot vouch for is",
    "refused at exit 2 and never read as clean; each refusal names the file, its",
    "code and its remedy.",
    "",
    "WHAT A CLEAN RESULT MEANS. Every job declares a posture; the contexts of the",
    "jobs claiming required are set-equal to CONTEXT_ORDER in both directions; no",
    "declared or claimed context is reported by more than one job; every job",
    "claiming required sits in a workflow that, so far as its file decides it, runs",
    "on each pull request into `main` and on each push to one; and no job claiming",
    "required carries a job-level `if:` or needs a job that does not itself claim",
    "required.",
    "",
    "WHAT A PARSER CANNOT DECIDE, so this census does not grade it. These are",
    "structural limits, each stated with the instances measured so far. The list",
    "carries no count, and an instance measured later extends it rather than",
    "contradicting it.",
    "Whether a required job runs on a given pull request, where the file alone does",
    "not decide it. The census grades what the file decides -- the `pull_request`",
    "trigger, its `branches:`, `branches-ignore:` and `types:` filters written as",
    "literal names, and a required job's own `if:` and `needs:` -- and each case",
    "below turns on something more. Each reads CLEAN here, measured; each outcome is",
    "GitHub's documented behaviour, not measured by this census.",
    "- A `paths:` filter on the `pull_request` trigger. A pull request that touches",
    "  no matching path never runs the job, so the check stays pending and the merge",
    "  is blocked. Only each pull request's diff decides it (X96).",
    "- A pattern in a branch filter. Whether `release/**`, or any pattern, matches",
    "  `main` is GitHub's filter grammar to decide, and this census does not",
    "  evaluate it; a filter that leaves `main` out leaves the check pending on",
    "  every pull request into `main` (X116).",
    "Nor does it grade a job that claims no posture of required and whose `name:` is",
    "computed at run time: that job is compared to no declared context here, so one",
    "whose expression evaluates to a declared context reads CLEAN (X105), while at",
    "run time it reports that context beside the job that claims it, and which of",
    "their check runs GitHub counts was not measured.",
    "How GitHub's own parser reads the file. It was not run. Where YAML 1.1 and YAML",
    "1.2 read a character differently -- a line break to YAML 1.1 and content to",
    "YAML 1.2 -- this census refuses the file (X86, X108, X109); a disagreement not",
    "yet measured is read the way PyYAML reads it.",
    "Whether GitHub accepts the workflow at all. A parser decides the document, not",
    "the workflow schema. `Workflow SAST (actionlint)`, in this same job, checks the",
    "schema: a job carrying a key GitHub does not define reads CLEAN here and is",
    "rejected there.",
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
    shapes that a weaker "the right number of contexts, zero nulls" check
    certifies as SUCCESS.
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
    extra = correct + [("Extra check (never declared)", APP_ID)]

    return [
        # id,  what it models,                                   raw,                      rc, conjuncts
        ("S0", "the live pre-change state: one context unpinned", _checks(_pre_pairs()), 1, {"C3", "C4"}),
        ("S1", "an empty checks array -- the shape a failed read produces", '{"checks": []}', 1, {"C1", "C2"}),
        ("S2", "an empty object -- the other shape a failed read produces", "{}", 2, {"C0"}),
        ("S3", "the write dropped one context ({} contexts, 0 null)".format(EXPECTED_COUNT - 1), _checks(dropped), 1, {"C1", "C2"}),
        ("S4", "every context pinned to the WRONG app ({}, 0 null)".format(EXPECTED_COUNT), _checks(wrong_app), 1, {"C4"}),
        ("S5", "app_id stored as the STRING form ({}, 0 null)".format(EXPECTED_COUNT), _checks(stringy), 1, {"C4"}),
        ("S6", "one context RENAMED by the write ({}, 0 null, right app)".format(EXPECTED_COUNT), _checks(renamed), 1, {"C2"}),
        ("S7", "a context duplicated: {} entries, {} distinct".format(EXPECTED_COUNT, EXPECTED_COUNT - 1), _checks(duped), 1, {"C2", "C2b"}),
        ("S8", "an unexpected extra context, all pinned", _checks(extra), 1, {"C1", "C2"}),
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

    drifted = _checks(_correct_pairs()[:-1] + [("Extra check (never declared)", APP_ID)])
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
    """A workflow whose one job is written with the key presentation in `key_lines`.

    `key_lines` is emitted VERBATIM in place of the job key line, so an arm
    models a presentation by passing the presentation and nothing here needs to
    know how any of them is spelled.

    The job's real answer -- `posture=required` -- sits above its key, where a
    contributor writes it. A SECOND marker, `posture=advisory`, sits directly
    above the job's own `steps:` line, at the property indentation. The parser
    reads the key as the job it names, and the second marker sits above no job
    key, so it binds nothing. It stays for the reader these arms were written
    against: the line reader missed each presentation and recorded a job off the
    `steps:` line instead, where that marker bound, so a missed key reached a
    POSTURE rather than reading UNDECLARED.

    `beside` puts a plainly written job ahead of the one under test, so the file
    holds a job every reader reads. Under the line reader each presentation sat
    at exit 0 in that position until its file-level refusal grew a second limb.
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
        ("X14", "READER: a SINGLE-QUOTED job key, the other quoting character beside "
                "X13's double quote. The parser reads it as the job `new-suite`, the "
                "key E4 asserts, which claims required under a name the declaration "
                "does not carry: UNREGISTERED. The line reader matched a quoted key "
                "by pattern, and this arm kept a pattern admitting only the double "
                "quote from passing",
         single_quoted, 1, {"UNREGISTERED"}),
        ("X15", "FAIL-OPEN SHAPE, read by the parser: a quoted job key claiming "
                "required, with an `advisory` marker on the comment line directly "
                "above its own `steps:`. The parser reads the key as the job "
                "`new-suite`, and the `advisory` line sits above no job key, so it "
                "binds nothing and the job keeps its claim, under a name the "
                "declaration does not carry: UNREGISTERED. The line reader recorded "
                "a phantom job off that `steps:` line, bound the `advisory` marker "
                "to it and reached CLEAN at exit 0",
         phantom_marker, 1, {"UNREGISTERED"}),
        ("X16", "FAIL-OPEN SHAPE, read by the parser: a quoted job key claiming "
                "required whose `steps:` is a flow sequence, so the block carries no "
                "bare `key:` line. The parser reads the job `new-suite` all the "
                "same, under a name the declaration does not carry: UNREGISTERED. "
                "The line reader dropped the whole file in silence on that one "
                "ordinary formatting choice",
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
        ("X35", "SPECIFICITY for X26-X34: the plain form of their two-job file -- two "
                "plainly written jobs, BOTH read, the second claiming required under "
                "a name the declaration does not carry. The parser grades it "
                "UNREGISTERED at rc 1, as it grades each of X26-X34. Under the line "
                "reader those arms were refusals, and this one kept a reader that "
                "refused every file holding two jobs from passing them", two_readable, 1,
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
                "column deeper, at an indentation where no job key sits. The parser "
                "reads the continuation as the rest of the name and grades the file "
                "UNREGISTERED at rc 1, as it grades X37-X41 and the continuations "
                "one column SHALLOWER than the job keys in X64 and X65. Under the "
                "line reader X37-X41 were accepted false refusals, and this arm "
                "confined them from the deeper side",
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
        ("X47", "UNREADABLE: a workflow file written in Latin-1, so it is not UTF-8 "
                "at all. The census cannot decode it, so it refuses the file, "
                "UNREADABLE, by name, after reading every other file in the tree, "
                "and prints the remedy and the limit block like any refusal. Under "
                "the line reader an uncaught decode error ended the run before any "
                "verdict, naming no file", not_utf8, 2, set(), "UNREADABLE"),
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
                "open there in YAML: the parser reads the `'` as text and both jobs, "
                "the second claiming required under a name the declaration does not "
                "carry, so the tree gets rc 1 UNREGISTERED. The line-sparing "
                "variants of the line reader measured while it shipped passed "
                "X48-X63 and lost that job here", span_flow, 1,
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
    before = ".github/workflows/synth-{:02d}.yml".format(len(CONTEXT_ORDER) - 2)
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
        ("X93", "DUPLICATE, the shadow: an advisory job reports the declaration's last context beside the required job that claims it. Which job's check run GitHub counts for the context was not measured, so the census finds DUPLICATE and names the advisory job as the one that shadows",
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
        ("X97", "TRIGGER, the literal-branches member: a job claiming required under the declaration's last context, in a workflow whose `pull_request` trigger carries `branches: [develop]`, literal names without `main`. No pull request into `main` runs it, so its check would stay pending on every one; the census finds UNTRIGGERED. This arm read CLEAN at rc 0 until the census read the filter",
         tree(drop=True, add={wf("branches"): "name: Synthetic\n\non:\n  pull_request:\n    branches: [develop]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         1, {"UNTRIGGERED"}),
        ("X98", "RUN-TIME CONDITION, refused: a job claiming required under the declaration's last context that carries a job-level `if:`, false on a pull request. GitHub documents that a job skipped by its own `if:` reports Success, so the required check could pass without the job running; the census refuses, RUNTIME-CONDITION. This arm read CLEAN at rc 0 until the census read the `if:`",
         tree(drop=True, add={wf("job-if"): head + job("hygiene-v2", tenth, "required", "    if: github.event_name == 'push'\n")}),
         2, set(), "RUNTIME-CONDITION"),
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
        ("X105", "RUN-TIME LIMIT, pinned as emitted, the advisory-expression member: an advisory job whose `name:` is an expression that evaluates to the declaration's last context, beside the job that claims it. The census compares the expression text, which matches nothing declared, so it reads CLEAN at rc 0; at run time the job reports that context, and which of the jobs' check runs GitHub counts was not measured. A close turns this red and must re-label it",
         tree(add={wf("advisory-expr"): head + job("lookalike", "${{ '" + tenth + "' }}", "advisory")}),
         0, set()),
        ("X106", "RUN-TIME NEEDS, refused: a job claiming required under the declaration's last context that `needs:` an advisory job. GitHub documents that a job skipped because a job it needs failed may not block the merge; the census refuses, RUNTIME-NEEDS. This arm read CLEAN at rc 0 until the census read the `needs:`",
         tree(drop=True, add={wf("needs"): head + job("build", "Build", "advisory") + job("hygiene-v2", tenth, "required", "    needs: build\n")}),
         2, set(), "RUNTIME-NEEDS"),
        ("X107", "TRIGGER, the types member: a job claiming required under the declaration's last context, in a workflow whose `pull_request` trigger carries `types: [opened]`, without `synchronize`. A push to a pull request then starts no run on its new head commit, so the check would stay pending; the census finds UNTRIGGERED. This arm read CLEAN at rc 0 until the census read the filter",
         tree(drop=True, add={wf("types"): "name: Synthetic\n\non:\n  pull_request:\n    types: [opened]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         1, {"UNTRIGGERED"}),
        ("X108", "YAML VERSION DIVERGENCE, the LINE SEPARATOR member: a comment line carrying U+2028 directly ahead of the text of a job key `hidden`. PyYAML, a YAML 1.1 parser, ends the comment at that character and reads `hidden` as a job, where YAML 1.2 reads the character as part of the comment; the census refuses, YAML11-BREAK",
         tree(add={wf("line-sep"): head + job("a", "A", "advisory") + "  # a note\N{LINE SEPARATOR}  hidden:\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n"}),
         2, set(), "YAML11-BREAK"),
        ("X109", "YAML VERSION DIVERGENCE, the PARAGRAPH SEPARATOR member: the comment line of X108 carrying U+2029 instead. PyYAML reads `hidden` as a job after it, where YAML 1.2 reads the character as part of the comment; the census refuses, YAML11-BREAK",
         tree(add={wf("para-sep"): head + job("a", "A", "advisory") + "  # a note\N{PARAGRAPH SEPARATOR}  hidden:\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'true'\n"}),
         2, set(), "YAML11-BREAK"),
        ("X110", "UNPARSEABLE, an exception outside the parser's error class: a job property holding flow sequences nested 1000 deep. Composing it exhausts the interpreter's recursion limit, which raises RecursionError rather than a YAML error; the census refuses, UNPARSEABLE, rather than leave at exit 1, the finding code",
         tree(add={wf("deep"): head + job("a", "A", "advisory", "    env:\n      DEEP: " + "[" * 1000 + "]" * 1000 + "\n")}),
         2, set(), "UNPARSEABLE"),
        ("X111", "SPECIFICITY for X98: the same job with its `if:` on a step rather than on the job. A step-level `if:` does not skip the job, so there is no RUNTIME-CONDITION: CLEAN at rc 0",
         tree(drop=True, add={wf("step-if"): head + "  # gate-efficacy: posture=required\n  hygiene-v2:\n    name: " + tenth + "\n    runs-on: ubuntu-latest\n    steps:\n      - if: github.event_name == 'push'\n        run: 'true'\n"}),
         0, set()),
        ("X112", "SPECIFICITY for X106: a job claiming required under the declaration's last context that `needs:` the job claiming the context before it, in the same file, which itself claims required. A failure there blocks the merge on that job's own check, so there is no RUNTIME-NEEDS: CLEAN at rc 0",
         tree(drop=True, replace={before: head + job("job{:02d}".format(len(CONTEXT_ORDER) - 2), prev, "required") + job("hygiene-v2", tenth, "required", "    needs: job{:02d}\n".format(len(CONTEXT_ORDER) - 2))}),
         0, set()),
        ("X113", "SPECIFICITY for X97: a job claiming required under the declaration's last context, in a workflow whose `pull_request` trigger carries `branches: [main]`. A pull request into `main` runs it, so there is no UNTRIGGERED: CLEAN at rc 0",
         tree(drop=True, add={wf("branches-main"): "name: Synthetic\n\non:\n  pull_request:\n    branches: [main]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X114", "TRIGGER, the branches-ignore member: the same job in a workflow whose `pull_request` trigger carries `branches-ignore: [main]`. It shuts `main` out, read by the same predicate X97's `branches:` filter is, so no pull request into `main` runs it; the census finds UNTRIGGERED",
         tree(drop=True, add={wf("branches-ignore"): "name: Synthetic\n\non:\n  pull_request:\n    branches-ignore: [main]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         1, {"UNTRIGGERED"}),
        ("X115", "SPECIFICITY for X107: the same job in a workflow whose `pull_request` trigger carries `types: [opened, synchronize, reopened]`. A push to a pull request starts a run, so there is no UNTRIGGERED: CLEAN at rc 0",
         tree(drop=True, add={wf("types-sync"): "name: Synthetic\n\non:\n  pull_request:\n    types: [opened, synchronize, reopened]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X116", "PATTERN LIMIT, pinned as emitted: the same job in a workflow whose `pull_request` trigger carries `branches: ['release/**']`, a pattern that leaves out `main` under GitHub's filter grammar. Deciding it needs that grammar, which this census does not evaluate, so it reads CLEAN at rc 0. A close turns this red and must re-label it",
         tree(drop=True, add={wf("branches-pattern"): "name: Synthetic\n\non:\n  pull_request:\n    branches: ['release/**']\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X117", "SPECIFICITY for X114: the same job in a workflow whose `pull_request` trigger carries `branches-ignore: [develop]`, which leaves `main` in. A pull request into `main` runs it, so there is no UNTRIGGERED: CLEAN at rc 0",
         tree(drop=True, add={wf("branches-ignore-other"): "name: Synthetic\n\non:\n  pull_request:\n    branches-ignore: [develop]\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X118", "TRIGGER, the branches-ignore member beside a pattern: the same job in a workflow whose `pull_request` trigger carries `branches-ignore: [main, 'x*']`. The literal `main` shuts `main` out whatever the pattern matches, and no entry opens with `!`, so the list is not left to the pattern limit; no pull request into `main` runs it, and the census finds UNTRIGGERED",
         tree(drop=True, add={wf("branches-ignore-pattern"): "name: Synthetic\n\non:\n  pull_request:\n    branches-ignore: [main, 'x*']\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         1, {"UNTRIGGERED"}),
        ("X119", "PATTERN LIMIT, pinned as emitted, the negation member in `branches-ignore:`: the same job in a workflow whose `pull_request` trigger carries `branches-ignore: [main, '!main']`. The literal `main` would shut `main` out, but an entry that opens with `!` can negate an earlier entry under GitHub's pattern grammar, which this census does not evaluate, so it reads CLEAN at rc 0. A close decides it and must re-label it",
         tree(drop=True, add={wf("branches-ignore-negation"): "name: Synthetic\n\non:\n  pull_request:\n    branches-ignore: [main, '!main']\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
         0, set()),
        ("X120", "PATTERN LIMIT, pinned as emitted, the negation member in `branches:`: the same job in a workflow whose `pull_request` trigger carries `branches: [develop, '!main']`. An entry that opens with `!` makes the list a pattern, and whether the list admits `main` turns on how GitHub's pattern grammar reads a negation against the entries before it, which this census does not evaluate, so it reads CLEAN at rc 0. A close decides it and must re-label it",
         tree(drop=True, add={wf("branches-negation"): "name: Synthetic\n\non:\n  pull_request:\n    branches: [develop, '!main']\n\njobs:\n" + job("hygiene-v2", tenth, "required")}),
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
    except Exception as exc:
        failures.append("E: NOT-EVALUATED -- the census arms need PyYAML, and loading "
                        "it failed under {} ({}: {}); this is not a clean "
                        "result".format(sys.executable, type(exc).__name__, exc))
        out("  FAIL E: NOT-EVALUATED -- the census arms need PyYAML, and this "
            "interpreter has none. This is not a clean result.")
        return c_arms

    seen = {}
    for arm in c_arms:
        aid, what, files, want_rc, want_codes = arm[:5]
        want_refusals = [arm[5]] if len(arm) > 5 and arm[5] else []
        load = arm[6] if len(arm) > 6 else _load_yaml
        with tempfile.TemporaryDirectory(prefix="prc-census-") as root:
            _materialise(files, root)
            rc, jobs, findings, refusals, _version = census_verdict(root, load)
            with open(os.devnull, "w") as sink:
                printed = run_census(root, stream=sink, load=load)
        seen[aid] = (jobs, refusals)
        got = set(f[0] for f in findings)
        got_refusals = sorted(set(r[1] for r in refusals))
        if (rc, got, got_refusals, printed) != (want_rc, want_codes, want_refusals, want_rc):
            failures.append("{}: rc {} codes {} refusing {} (printed rc {}) -- want rc {} "
                            "codes {} refusing {}".format(
                                aid, rc, sorted(got), got_refusals, printed, want_rc,
                                sorted(want_codes), want_refusals))
            out("  FAIL {}: rc {} on {} refusing {} -- want rc {} on {} refusing {} -- "
                "{}".format(aid, rc, sorted(got), got_refusals, want_rc,
                            sorted(want_codes), want_refusals, what))
        else:
            out("  PASS {}: rc {} on exactly {} -- {}".format(
                aid, rc, ",".join(sorted(want_codes) + want_refusals) or "no findings",
                what))

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

    # E11: a refused file does not stop the rest of the tree from being read, so a
    # per-file refusal is told apart from X8's empty population.
    jobs, refusals = seen["X81"]
    codes = [(r[0], r[1]) for r in refusals]
    if len(jobs) != EXPECTED_COUNT + 1 or codes != [(".github/workflows/synth-bad.yml",
                                                     "UNPARSEABLE")]:
        failures.append("E11: X81 read {} job(s) and refused {} -- want {} job(s) and "
                        "the one unparseable file".format(len(jobs), codes,
                                                          EXPECTED_COUNT + 1))
        out("  FAIL E11")
    else:
        out("  PASS E11: X81 refuses the one file it cannot parse after reading the "
            "other {} job(s) -- a partly-read tree, not X8's empty one".format(len(jobs)))

    # E12: a comment line is the scanner's decision. In X74's file the line that
    # begins with `#` inside a quoted scalar is content, and the genuine marker is a
    # comment.
    yaml = _load_yaml()
    text = [a for a in c_arms if a[0] == "X74"][0][2][".github/workflows/synth-hash-cont.yml"]
    lines = _RE_BREAK.split(text)
    comments = _comment_lines(yaml, text, lines)
    inside = [i for i, ln in enumerate(lines)
              if ln.startswith('  # gate-efficacy: posture=required "')]
    genuine = [i for i, ln in enumerate(lines) if ln == "  # gate-efficacy: posture=advisory"]
    if len(inside) != 1 or len(genuine) != 1 or inside[0] in comments or \
            genuine[0] not in comments:
        failures.append("E12: in X74's file the scalar line {} and the genuine marker "
                        "{} were read as comment={} and comment={}".format(
                            inside, genuine, [i in comments for i in inside],
                            [i in comments for i in genuine]))
        out("  FAIL E12")
    else:
        out("  PASS E12: in X74's file the `#`-leading line inside a quoted scalar is "
            "content and the genuine marker is a comment -- the scanner decides, not a "
            "pattern over the line")
    return c_arms


def self_test(stream=sys.stdout):
    def out(msg):
        stream.write(msg + "\n")

    failures = []
    out("=" * 78)
    out("SELF-TEST -- offline. No network, no gh, no token. It reads one file of "
        "this repository: SECURITY.md.")
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
    # or any noun outside those four. It reads every text the census prints,
    # because each is a module constant -- REFUSAL_TEXT, REFUSAL_REMEDY,
    # NO_PARSER_REMEDY, FINDING_TEXT, MARKER_NOTE, CENSUS_PRINT, CENSUS_REMEDY --
    # rather than a string built inside a function. It goes red wherever
    # --self-test runs: in CI, where the census step runs it on every pull
    # request, and in --plan and --apply, which refuse at exit 5.
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
    texts += [("census text {} {}".format(table, key), value)
              for table, entries in (("REFUSAL_TEXT", REFUSAL_TEXT),
                                     ("REFUSAL_REMEDY", REFUSAL_REMEDY),
                                     ("NO_PARSER_REMEDY", NO_PARSER_REMEDY),
                                     ("FINDING_TEXT", FINDING_TEXT),
                                     ("MARKER_NOTE", MARKER_NOTE),
                                     ("CENSUS_PRINT", CENSUS_PRINT))
              for key, value in sorted(entries.items())]
    texts.append(("the census remedy block", " ".join(CENSUS_REMEDY)))
    texts += [("F control {}".format(cid), what) for cid, what, _want in SECURITY_CONTROLS]
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
        out("  PASS E9: no text E9 reads -- the limit block, every text the census "
            "prints, every docstring in this module and every arm label, {} texts "
            "scanned -- writes a number in front of a class, a way, a mechanism or a "
            "member".format(len(texts)))

    _security_group(out, failures)

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
        "SECURITY.md's required-check list is set-equal to CONTEXT_ORDER in both "
        "directions, and no text E9 reads counts an open set.")
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
                      help="offline validation of the assertion, the guards, the census "
                           "and the SECURITY.md list")
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
