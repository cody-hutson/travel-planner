#!/usr/bin/env python3
"""Grade what a release pull request's body gained after it was opened.

WHAT IT GRADES
    CONTRIBUTING.md, *Cutting a release*, carries the convention this tool
    grades:

        "The release PR body is a summary plus links, not a second copy of
        the work."

    and says where the rest goes instead: "a later slice, a remediation round
    or a re-review belongs where the rest of its stage's detail already
    lives, or in a comment on the PR -- not appended to the body."

    The tool reads two revisions of a pull-request body and reports what the
    later one ADDS, in the shapes appending takes. It grades an addition and
    never a size: a body that is long when it opens is simply that body, and
    the convention's instruction is to write it then and leave it that way.

THE CLASSES, AND WHY EACH IS READ AS IT IS
    H  heading (ATX, depths 1-6). Read as a SET DIFFERENCE on (depth, text),
       with multiplicity, so a section replaced by a new section is an
       addition even though the count of headings stays level. A net count
       reads that swap as nothing.
    B  bold-led block: a paragraph whose first line opens in ** or __ and
       then a non-blank character, or a list item, with or without a task
       box, whose text opens that way. Read as a NET COUNT, so a reworded
       bold lead keeps the count level and reads as the correction it is. A
       set difference on lead text fires on every reworded lead.
    T  task-list item: a list item opening [ ] or [x] whose text is not
       bold-led. Read as a NET COUNT, so ticking a box changes nothing and a
       new row of work is one more item.
    P  plain list item. MEASURED AND PRINTED, NEVER GRADED: a body that
       points at its records grows by list items of links, which is the form
       the convention asks for.
    Not read at all: prose added inside an existing block, and table rows.

    Each of H, B and T fires at 1. An edit FIRES when any graded class reads
    1 or more; it is BOUNDARY when none does and P does; otherwise it is
    SILENT. GRADED, below, is the one place the graded set is declared.

    The block grammar follows GitHub-rendered Markdown where the population
    measured needs it to: ATX headings with up to three spaces of indent;
    list markers -, + and *, or one to nine digits with . or ); task boxes
    [ ] and [x]; fenced code (``` or ~~~, closed by a run of the same
    character at least as long) and HTML comments are not read. A comment
    opens only outside a fence and outside a backtick code span, and runs to
    its first -->, or to the end of the body when it never closes, as the
    rendered page hides it. A thematic break written with * or _ (***, ___,
    * * *) is neither a bold lead nor a list item. Character classes are
    explicit ASCII throughout ([ \\t], never \\s), so the reading does not
    depend on the locale or the interpreter build.

MODES
    --self-test
        Offline: no network and no gh. Grades the decision function over
        synthetic fixtures, the edit grade over synthetic event payloads, the
        instrument checks over a synthetic revision record, and the
        population runner -- listing, batching, paging, the retry bound,
        --pr and the real-data arms -- over a scripted stand-in for gh. Ends
        with "SELF-TEST arms=<n> passed=<n> misread=<n>". Exit 0 when every
        arm reads as expected, else 2.

    --pair BEFORE AFTER
        Grades the edit from file BEFORE to file AFTER, and prints one PAIR
        line plus one line per added heading. Exit 1 on FIRE, else 0.

    --event PATH
        Grades one edit from a pull_request event payload file. Only an
        `edited` event carries the prior body (changes.body.from), so every
        other event, a head that is not a release/* branch, and an edit that
        did not change the body each print one NOT GRADED line and exit 0.
        A graded edit prints an EDIT line and its added headings, a remedy on
        FIRE, and a SCOPE line saying what the grade covers. Exit 1 on FIRE.

    --population [--repo OWNER/NAME] [--pr N]
                 [--must-fire N,...] [--must-silent N,...]
        Needs an authenticated gh. Runs --self-test first and refuses on a
        misread. Lists every pull request through REST, keeps those whose
        head is a release/* branch, and reads each one's revision history
        through GraphQL userContentEdits, five pull requests to a query (the
        shape the design-time population read was measured in), paging any
        history longer than one page. Without --pr it grades every
        consecutive pair of revisions; a pull request FIRES when any pair
        does. --pr N narrows the graded set to pull request N, which must be
        a listed release-head pull request, and grades its body as opened
        against its body now -- the cumulative read, so a body restored to
        its opening shape reads SILENT however it got there. The listing is
        never narrowed, so the population line and DENOM still name the
        whole release-head count. The repo defaults to gh repo view's.

        --must-fire and --must-silent are real-data arms, passed on the
        command line so the tool holds no pull-request number. Each named
        pull request must be a listed release-head pull request; under --pr
        it is read and graded as a control, by the same grade as the
        subject, and stays out of the subject's DENOM and RESULT. A
        must-fire that does not FIRE, a must-silent that does not read
        SILENT, a must-silent with no edit pair (VACUOUS) and an arm naming a
        pull request that is not listed (ABSENT) each refuse the run.

        Instrument checks, each refusing the run and naming the pull request
        and the check: I1 the nodes read equal totalCount; I2 no revision is
        deleted or null; I3 the newest revision equals the current body; I4
        the oldest revision's editedAt equals the pull request's createdAt.
        A gh call that fails with HTTP 502 or 503 or a secondary-rate-limit
        message is retried, at most twice, printing a RETRY line each time;
        any other failure, and a GraphQL errors key, refuses at once.

        Output, in order: SELF-TEST; POPULATION repo= read-at= listed=
        pages= release-head=; SELECT; one SCAN line per pull request read;
        FINDING lines with their added headings; BOUNDARY-ONLY lines; ARM
        lines; DENOM release-head= graded= edited= pairs= not-edited= | FIRE=
        BOUNDARY= SILENT=, whose three verdict counts are asserted to sum to
        edited; RESULT FINDINGS or CLEAN. A refusal prints a REFUSED line in
        place of what it could not establish, and never a RESULT.

WHERE EACH MODE RUNS, AND WHAT EACH DELIVERS
    CI runs --self-test on every pull-request event, and --event on an
    `edited` event, in the advisory "PR body accretion probe" job of
    .github/workflows/pr-body-parser-clean.yml. What that job delivers is an
    EDIT-TIME grade, not a standing control of the body's history: the grade
    is read from that one event's payload, it attaches to the check run on
    the head commit of that moment, and it is visible there only until the
    next push or event runs the job again -- which does not re-grade the
    edit. A green check on a later head says nothing about edits made before
    it, and the job never sees an edit made before it existed.

    --population runs on a host with an authenticated gh, by a person. It is
    the ONLY cumulative read: over the whole release-head population (the
    Stage 7 record), or with --pr N over one pull request's body as opened
    against its body now (the Stage 12 read of a release's own pull request,
    before it merges).

EXIT
    0 clean / 1 finding(s) / 2 refused: a fixture arm misread, an input that
    cannot be read, an instrument check or a real-data arm that failed, or a
    gh call that did not return.

REQUIREMENTS
    Python 3.9 or later, standard library only. --population needs gh,
    authenticated to the repository, for one REST listing and the GraphQL
    history reads (revision history has no REST path).

THE DECLARED BOUNDARY -- what this reading passes over
    - setext headings; HTML headings; HTML blocks other than comments;
    - a bold lead behind > or inside a link;
    - table rows: an added row and a flipped cell are both silent;
    - indented code blocks: their list markers count as P, and a <!-- in one
      opens a comment;
    - a code span that runs across lines: only a span opened and closed on
      one line shields a <!-- inside it;
    - a line that opens with an HTML comment is classified by the text left
      once the comment is removed, where the rendered page shows that line
      as raw HTML;
    - a fence opener whose info string carries a backtick is still read as
      a fence;
    - a thematic break written with - (---, - - -): --- is read as nothing
      and - - - as a plain list item, which is P and ungraded;
    - a block that opens on the line directly after a thematic break or a
      --- line, with no blank line between, is read as a continuation of the
      block above and is not counted;
    - B and T are net, so a removal and an addition in one edit cancel;
    - H is keyed on (depth, text), so a reworded or re-levelled heading
      reads as an addition (it fails loud, not silent);
    - prose growth inside an existing block;
    - --event grades one edit at a time and only while the job exists; the
      body's history before it, and the whole of it, is --population's;
    - a deleted revision refuses --population rather than being skipped;
    - only pull requests whose head is a release/* branch are graded.

WORKED USAGE
    The Stage 7 population record, from a clone at the release head:

        python3 scripts/check-pr-body-accretion.py --population \\
            --repo cody-hutson/travel-planner \\
            --must-fire 881,824 --must-silent 754,985,1021,1148

    The Stage 12 cumulative read of one release pull request, N:

        python3 scripts/check-pr-body-accretion.py --population \\
            --repo cody-hutson/travel-planner --pr N \\
            --must-fire 881,824 --must-silent 754,985,1021,1148
"""

import argparse
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter
from datetime import datetime, timezone

GRADED = ("H", "B", "T")
CLASSES = ("H", "B", "T", "P")

NEWLINE_RE = re.compile(r"\r\n?")
FENCE_OPEN_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
BLANK_RE = re.compile(r"^[ \t]*$")
HEADING_RE = re.compile(r"^ {0,3}(#{1,6})[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$")
THEMATIC_BREAK_RE = re.compile(r"^ {0,3}([*_])([ \t]*\1){2,}[ \t]*$")
LIST_ITEM_RE = re.compile(r"^[ \t]*(?:[-*+]|[0-9]{1,9}[.)])[ \t]+(.*)$")
TASK_BOX_RE = re.compile(r"^\[[ xX]\](?:[ \t]+|$)")
BOLD_LEAD_RE = re.compile(r"^(?:\*\*|__)[^ \t]")
PARAGRAPH_BOLD_RE = re.compile(r"^ {0,3}(?:\*\*|__)[^ \t]")
SPACE_RUN_RE = re.compile(r"[ \t]+")

REPO_RE = re.compile(r"^([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)$")
RELEASE_PREFIX = "release/"

BATCH_SIZE = 5
EDITS_PAGE = 100
MAX_ATTEMPTS = 3
RETRY_WAIT_SECONDS = (10, 30)
TRANSIENT_RE = re.compile(r"HTTP 50[23]\b|secondary rate limit", re.IGNORECASE)
MAX_REST_PAGES = 200
MAX_EDIT_PAGES = 200

EDITS_FIELDS = ("totalCount pageInfo{hasNextPage endCursor} "
                "nodes{editedAt deletedAt diff}")
PAGE_QUERY = (
    "query($owner:String!,$name:String!,$number:Int!,$after:String)"
    "{repository(owner:$owner,name:$name){pullRequest(number:$number)"
    "{userContentEdits(first:%d,after:$after){%s}}}}" % (EDITS_PAGE, EDITS_FIELDS))


class Refused(Exception):
    """A read or an input this tool cannot vouch for. Always exit 2."""


# ---------------------------------------------------------------------------
# The decision function: shape, grade, verdict.
# ---------------------------------------------------------------------------

class Shape(object):
    __slots__ = ("headings", "order", "bold", "task", "plain")

    def __init__(self):
        self.headings = Counter()
        self.order = []
        self.bold = 0
        self.task = 0
        self.plain = 0

    def as_tuple(self):
        return (dict(self.headings), self.bold, self.task, self.plain)


def _strip_comments(text):
    """Remove the HTML comments on one line that open outside a code span.

    Returns (kept_text, still_open). A backtick run opens a code span only
    when a run of the same length closes it later on the line; inside such a
    span a <!-- is text. Once a comment is open it runs to its first -->,
    whatever lies between.
    """
    kept = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "`":
            j = i
            while j < n and text[j] == "`":
                j += 1
            width = j - i
            k = j
            close = -1
            while k < n:
                if text[k] == "`":
                    m = k
                    while m < n and text[m] == "`":
                        m += 1
                    if m - k == width:
                        close = k
                        break
                    k = m
                else:
                    k += 1
            if close < 0:
                kept.append(text[i:j])
                i = j
            else:
                kept.append(text[i:close + width])
                i = close + width
            continue
        if text.startswith("<!--", i):
            end = text.find("-->", i + 4)
            if end < 0:
                return "".join(kept), True
            i = end + 3
            continue
        kept.append(ch)
        i += 1
    return "".join(kept), False


def shape(body):
    """Read a body's blocks into (headings, bold, task, plain)."""
    body = NEWLINE_RE.sub("\n", body or "")
    result = Shape()
    state = {"fence": None, "para_start": True}

    def classify(text):
        m = FENCE_OPEN_RE.match(text)
        if m:
            state["fence"] = (m.group(1)[0], len(m.group(1)))
            return
        if BLANK_RE.match(text):
            state["para_start"] = True
            return
        m = HEADING_RE.match(text)
        if m and m.group(2) != "":
            key = (len(m.group(1)), SPACE_RUN_RE.sub(" ", m.group(2)))
            result.headings[key] += 1
            result.order.append(key)
            state["para_start"] = True
            return
        if THEMATIC_BREAK_RE.match(text):
            state["para_start"] = False
            return
        m = LIST_ITEM_RE.match(text)
        if m:
            rest = m.group(1)
            box = TASK_BOX_RE.match(rest)
            if box:
                rest = rest[box.end():]
            if BOLD_LEAD_RE.match(rest):
                result.bold += 1
            elif box:
                result.task += 1
            else:
                result.plain += 1
        elif state["para_start"] and PARAGRAPH_BOLD_RE.match(text):
            result.bold += 1
        state["para_start"] = False

    pending = None
    for raw in body.split("\n"):
        if state["fence"] is not None:
            char, width = state["fence"]
            close_re = r"^ {0,3}(?:%s){%d,}[ \t]*$" % (re.escape(char), width)
            if re.match(close_re, raw):
                state["fence"] = None
                state["para_start"] = True
            continue
        if pending is None:
            if FENCE_OPEN_RE.match(raw):
                classify(raw)
                continue
            text, still_open = _strip_comments(raw)
        else:
            end = raw.find("-->")
            if end < 0:
                continue
            text, still_open = _strip_comments(raw[end + 3:])
            text = pending + text
        if still_open:
            pending = text
            continue
        pending = None
        classify(text)
    if pending is not None:
        classify(pending)
    return result


def grade(before, after):
    """Grade the edit before -> after. Returns ({H, B, T, P}, added headings)."""
    added = after.headings - before.headings
    remaining = Counter(added)
    in_order = []
    for key in after.order:
        if remaining[key] > 0:
            in_order.append(key)
            remaining[key] -= 1
    g = {
        "H": sum(added.values()),
        "B": after.bold - before.bold,
        "T": after.task - before.task,
        "P": after.plain - before.plain,
    }
    return g, in_order


def verdict(g, graded=GRADED):
    if any(g[c] >= 1 for c in graded):
        return "FIRE"
    if any(g[c] >= 1 for c in CLASSES if c not in graded):
        return "BOUNDARY"
    return "SILENT"


def _counts(g):
    return "H=%d B=%d T=%d P=%d" % (g["H"], g["B"], g["T"], g["P"])


def _heading_lines(added):
    return ["  + h%d %s" % (depth, text[:60]) for depth, text in added]


# ---------------------------------------------------------------------------
# Revision records: instrument checks and per-record grading.
# ---------------------------------------------------------------------------

def check_instrument(record):
    """Return the instrument checks a revision record fails, in order."""
    nodes = record.get("nodes") or []
    failed = []
    if len(nodes) != record.get("totalCount"):
        failed.append("I1")
    if any(n is None or n.get("deletedAt") is not None or n.get("diff") is None
           for n in nodes):
        failed.append("I2")
    if nodes and nodes[0] is not None and nodes[0].get("diff") != (record.get("body") or ""):
        failed.append("I3")
    if nodes and nodes[-1] is not None and nodes[-1].get("editedAt") != record.get("createdAt"):
        failed.append("I4")
    return failed


def grade_record(record, graded=GRADED):
    """Grade every consecutive revision pair, and the body as opened against now."""
    nodes = record.get("nodes") or []
    if nodes:
        revisions = [n.get("diff") or "" for n in reversed(nodes)]
    else:
        revisions = [record.get("body") or ""]
    shapes = [shape(r) for r in revisions]
    pairs = []
    for i in range(1, len(revisions)):
        g, added = grade(shapes[i - 1], shapes[i])
        pairs.append({"index": i, "grade": g, "added": added,
                      "verdict": verdict(g, graded)})
    verdicts = [p["verdict"] for p in pairs]
    if not pairs:
        pairwise = "NOT-EDITED"
    elif "FIRE" in verdicts:
        pairwise = "FIRE"
    elif "BOUNDARY" in verdicts:
        pairwise = "BOUNDARY"
    else:
        pairwise = "SILENT"
    sums = {c: sum(max(p["grade"][c], 0) for p in pairs) for c in CLASSES}
    if pairs:
        cg, cadded = grade(shapes[0], shapes[-1])
        cumulative = verdict(cg, graded)
    else:
        cg, cadded, cumulative = {c: 0 for c in CLASSES}, [], "NOT-EDITED"
    return {
        "revisions": revisions,
        "pairs": pairs,
        "verdict": pairwise,
        "sums": sums,
        "open_now": {"grade": cg, "added": cadded, "verdict": cumulative},
    }


def apply_arms(observed, must_fire, must_silent):
    """Grade the real-data arms. observed maps number -> (pairs, verdict)."""
    rows = []
    for n in must_fire:
        if n not in observed:
            rows.append(("must-fire", n, 0, "-", "ABSENT"))
            continue
        pairs, v = observed[n]
        rows.append(("must-fire", n, pairs, v, "PASS" if v == "FIRE" else "MISREAD"))
    for n in must_silent:
        if n not in observed:
            rows.append(("must-silent", n, 0, "-", "ABSENT"))
            continue
        pairs, v = observed[n]
        if pairs == 0:
            status = "VACUOUS"
        elif v == "SILENT":
            status = "PASS"
        else:
            status = "MISREAD"
        rows.append(("must-silent", n, pairs, v, status))
    return rows


# ---------------------------------------------------------------------------
# --pair and --event
# ---------------------------------------------------------------------------

def _read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise Refused("cannot read %s: %s" % (path, e))


def grade_pair(before_path, after_path, out):
    before = _read_text(before_path)
    after = _read_text(after_path)
    g, added = grade(shape(before), shape(after))
    v = verdict(g)
    out.write("PAIR %s verdict=%s\n" % (_counts(g), v))
    for line in _heading_lines(added):
        out.write(line + "\n")
    return 1 if v == "FIRE" else 0


SCOPE_LINE = (
    "SCOPE: an edit is graded once, from its own event, at the moment it is made. "
    "This result shows on this event's run only, until the next push or event runs "
    "the job again, and that run does not re-grade it. The body as opened against "
    "the body now is graded only by --population --pr <number>, on a host with gh.\n")


def grade_event(path, out):
    try:
        payload = json.loads(_read_text(path))
    except ValueError as e:
        raise Refused("event payload %s is not JSON: %s" % (path, e))
    if not isinstance(payload, dict) or not isinstance(payload.get("pull_request"), dict):
        raise Refused("event payload %s carries no pull_request object" % path)
    pr = payload["pull_request"]
    action = payload.get("action")
    if action != "edited":
        out.write("NOT GRADED: event action is %s; only an edit carries the prior body\n"
                  % action)
        out.write(SCOPE_LINE)
        return 0
    head = pr.get("head") if isinstance(pr.get("head"), dict) else {}
    ref = head.get("ref") or ""
    if not ref.startswith(RELEASE_PREFIX):
        out.write("NOT GRADED: head %s is not a release/* branch\n" % ref)
        out.write(SCOPE_LINE)
        return 0
    changes = payload.get("changes") if isinstance(payload.get("changes"), dict) else {}
    if not isinstance(changes.get("body"), dict):
        out.write("NOT GRADED: this edit did not change the body\n")
        out.write(SCOPE_LINE)
        return 0
    before = changes["body"].get("from") or ""
    after = pr.get("body") or ""
    g, added = grade(shape(before), shape(after))
    v = verdict(g)
    out.write("EDIT #%s %s verdict=%s\n" % (pr.get("number"), _counts(g), v))
    for line in _heading_lines(added):
        out.write(line + "\n")
    if v == "FIRE":
        out.write("REMEDY: move what this edit added to the stage sub-task comment that "
                  "owns it, or to a comment on this pull request,\n"
                  "        then restore the body to its shape before the edit; that "
                  "restoring edit is graded too.\n")
    out.write(SCOPE_LINE)
    return 1 if v == "FIRE" else 0


# ---------------------------------------------------------------------------
# --population: the only network code.
# ---------------------------------------------------------------------------

def run_gh(args):
    try:
        p = subprocess.run(["gh"] + list(args), capture_output=True, text=True)
    except OSError as e:
        return 127, "", "gh could not be run: %s" % e
    return p.returncode, p.stdout, p.stderr


def _first_line(text):
    for line in (text or "").splitlines():
        if line.strip():
            return line.strip()[:200]
    return "(no message)"


def gh_json(gh, args, what, out, sleep):
    """Run one gh call; retry only a transient failure, at most MAX_ATTEMPTS."""
    for attempt in range(1, MAX_ATTEMPTS + 1):
        rc, stdout, stderr = gh(args)
        data = None
        parse_error = None
        try:
            data = json.loads(stdout) if (stdout or "").strip() else None
        except ValueError as e:
            parse_error = e
        errors = data.get("errors") if isinstance(data, dict) else None
        if rc == 0 and not errors and parse_error is None and data is not None:
            return data
        messages = stderr or ""
        if errors:
            messages += "\n" + "\n".join(str(e.get("message", e)) if isinstance(e, dict)
                                         else str(e) for e in errors)
        transient = TRANSIENT_RE.search(messages)
        if transient and attempt < MAX_ATTEMPTS:
            wait = RETRY_WAIT_SECONDS[attempt - 1]
            out.write("RETRY %s attempt=%d of %d after=%r wait=%ds\n"
                      % (what, attempt, MAX_ATTEMPTS, transient.group(0), wait))
            sleep(wait)
            continue
        if rc != 0:
            raise Refused("%s: gh exited %d: %s" % (what, rc, _first_line(messages)))
        if errors:
            raise Refused("%s: GraphQL returned errors: %s" % (what, _first_line(messages)))
        if parse_error is not None:
            raise Refused("%s: gh returned output that is not JSON: %s" % (what, parse_error))
        raise Refused("%s: gh returned no output" % what)
    raise Refused("%s: no attempt returned" % what)


def list_pulls(gh, repo, out, sleep):
    pulls = []
    seen = set()
    page = 0
    while True:
        page += 1
        if page > MAX_REST_PAGES:
            raise Refused("the REST listing ran past %d pages" % MAX_REST_PAGES)
        data = gh_json(gh, ["api", "repos/%s/pulls?state=all&per_page=100&page=%d"
                            % (repo, page)], "REST page %d" % page, out, sleep)
        if not isinstance(data, list):
            raise Refused("REST page %d is not a list" % page)
        if not data:
            return pulls, page
        for pr in data:
            n = pr.get("number") if isinstance(pr, dict) else None
            if not isinstance(n, int):
                raise Refused("REST page %d carries an entry with no number" % page)
            if n in seen:
                raise Refused("REST listing names #%d twice; the page walk cannot be trusted"
                              % n)
            seen.add(n)
            pulls.append(pr)


def _batch_query(numbers):
    parts = ["p%d:pullRequest(number:%d){number createdAt body userContentEdits(first:%d){%s}}"
             % (n, n, EDITS_PAGE, EDITS_FIELDS) for n in numbers]
    return ("query($owner:String!,$name:String!){repository(owner:$owner,name:$name){"
            + " ".join(parts) + "}}")


def fetch_histories(gh, owner, name, numbers, out, sleep):
    """Read each pull request's revision history, BATCH_SIZE to a query."""
    records = {}
    for start in range(0, len(numbers), BATCH_SIZE):
        chunk = numbers[start:start + BATCH_SIZE]
        what = "GraphQL batch %s" % ",".join("#%d" % n for n in chunk)
        data = gh_json(gh, ["api", "graphql", "-f", "query=" + _batch_query(chunk),
                            "-f", "owner=" + owner, "-f", "name=" + name],
                       what, out, sleep)
        repo = ((data.get("data") or {}).get("repository")) if isinstance(data, dict) else None
        if not isinstance(repo, dict):
            raise Refused("%s: no repository in the response" % what)
        for n in chunk:
            pr = repo.get("p%d" % n)
            if not isinstance(pr, dict) or not isinstance(pr.get("userContentEdits"), dict):
                raise Refused("%s: no record for #%d" % (what, n))
            edits = pr["userContentEdits"]
            records[n] = {
                "number": n,
                "createdAt": pr.get("createdAt"),
                "body": pr.get("body") or "",
                "totalCount": edits.get("totalCount"),
                "nodes": list(edits.get("nodes") or []),
                "pageInfo": edits.get("pageInfo") or {},
            }
    for n in numbers:
        info = records[n]["pageInfo"]
        pages = 1
        while info.get("hasNextPage"):
            pages += 1
            if pages > MAX_EDIT_PAGES:
                raise Refused("#%d: revision history ran past %d pages" % (n, MAX_EDIT_PAGES))
            what = "GraphQL history page %d of #%d" % (pages, n)
            data = gh_json(gh, ["api", "graphql", "-f", "query=" + PAGE_QUERY,
                                "-f", "owner=" + owner, "-f", "name=" + name,
                                "-F", "number=%d" % n,
                                "-f", "after=" + str(info.get("endCursor"))],
                           what, out, sleep)
            try:
                edits = data["data"]["repository"]["pullRequest"]["userContentEdits"]
            except (KeyError, TypeError):
                raise Refused("%s: no userContentEdits in the response" % what)
            records[n]["nodes"].extend(edits.get("nodes") or [])
            info = edits.get("pageInfo") or {}
    return records


def _pr_state(pr):
    if pr.get("merged_at"):
        s = "merged"
    else:
        s = pr.get("state") or "unknown"
    return s + ("-draft" if pr.get("draft") else "")


def run_population(repo, must_fire, must_silent, pr_filter, out,
                   gh=run_gh, sleep=time.sleep, preflight=True):
    """The population read. Returns the exit code; never raises Refused."""
    try:
        return _run_population(repo, must_fire, must_silent, pr_filter, out,
                               gh, sleep, preflight)
    except Refused as e:
        out.write("REFUSED: %s\n" % e)
        return 2


def _run_population(repo, must_fire, must_silent, pr_filter, out, gh, sleep, preflight):
    if preflight:
        buf = io.StringIO()
        rc = self_test(buf)
        summary = [l for l in buf.getvalue().splitlines() if l.startswith("SELF-TEST")]
        out.write((summary[-1] if summary else "SELF-TEST (no summary)") + "\n")
        if rc != 0:
            raise Refused("a fixture arm misread, so no population verdict from this "
                          "build can be trusted (run --self-test to see which)")
    if repo is None:
        rc, stdout, stderr = gh(["repo", "view", "--json", "nameWithOwner",
                                 "--jq", ".nameWithOwner"])
        if rc != 0:
            raise Refused("no --repo given and gh repo view failed: %s" % _first_line(stderr))
        repo = (stdout or "").strip()
    m = REPO_RE.match(repo or "")
    if not m:
        raise Refused("repo %r is not OWNER/NAME" % repo)
    owner, name = m.group(1), m.group(2)

    read_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    pulls, pages = list_pulls(gh, repo, out, sleep)
    by_number = {pr["number"]: pr for pr in pulls}
    release = sorted(n for n, pr in by_number.items()
                     if str(((pr.get("head") or {}).get("ref")) or "").startswith(RELEASE_PREFIX))
    out.write("POPULATION repo=%s read-at=%s listed=%d pages=%d release-head=%d\n"
              % (repo, read_at, len(pulls), pages, len(release)))

    release_set = set(release)
    if pr_filter is None:
        subjects = list(release)
        out.write("SELECT all %d release-head pull requests; per-PR verdict = any "
                  "consecutive revision pair\n" % len(release))
    else:
        if pr_filter not in release_set:
            raise Refused("--pr %d: ABSENT, not a release-head pull request in the listing "
                          "(%d release-head pull requests listed)" % (pr_filter, len(release)))
        subjects = [pr_filter]
        out.write("SELECT --pr #%d, 1 of %d release-head pull requests; per-PR verdict = "
                  "the body as opened against the body now\n" % (pr_filter, len(release)))
    subject_set = set(subjects)
    controls = sorted(n for n in set(must_fire) | set(must_silent)
                      if n in release_set and n not in subject_set)
    to_read = sorted(subject_set | set(controls))

    records = fetch_histories(gh, owner, name, to_read, out, sleep)

    anomalies = []
    for n in to_read:
        failed = check_instrument(records[n])
        if failed:
            anomalies.append("#%d %s" % (n, ",".join(failed)))
    if anomalies:
        for a in anomalies:
            out.write("INSTRUMENT %s\n" % a)
        raise Refused("instrument check(s) failed: %s" % "; ".join(anomalies))

    cumulative = pr_filter is not None
    graded = {}
    for n in to_read:
        r = grade_record(records[n])
        graded[n] = r
        revs = r["revisions"]
        s = r["sums"]
        out.write("SCAN #%d %s revisions=%d pairs=%d open=%d now=%d H+=%d B+=%d T+=%d P+=%d "
                  "verdict=%s open-to-now=%s%s\n"
                  % (n, _pr_state(by_number[n]), len(revs), len(r["pairs"]), len(revs[0]),
                     len(revs[-1]), s["H"], s["B"], s["T"], s["P"], r["verdict"],
                     r["open_now"]["verdict"], "" if n in subject_set else " role=control"))

    def per_pr(n):
        r = graded[n]
        return r["open_now"]["verdict"] if cumulative else r["verdict"]

    for n in subjects:
        r = graded[n]
        if cumulative:
            if r["open_now"]["verdict"] == "FIRE":
                out.write("FINDING #%d open->now %s\n" % (n, _counts(r["open_now"]["grade"])))
                for line in _heading_lines(r["open_now"]["added"]):
                    out.write(line + "\n")
        else:
            for p in r["pairs"]:
                if p["verdict"] == "FIRE":
                    g = p["grade"]
                    out.write("FINDING #%d pair=%d->%d H=%d B=%d T=%d\n"
                              % (n, p["index"] - 1, p["index"], g["H"], g["B"], g["T"]))
                    for line in _heading_lines(p["added"]):
                        out.write(line + "\n")
    for n in subjects:
        if per_pr(n) == "BOUNDARY":
            r = graded[n]
            p_plus = r["open_now"]["grade"]["P"] if cumulative else r["sums"]["P"]
            out.write("BOUNDARY-ONLY #%d P+=%d\n" % (n, p_plus))

    observed = {}
    for n in to_read:
        observed[n] = (len(graded[n]["pairs"]), per_pr(n))
    arm_rows = apply_arms(observed, must_fire, must_silent)
    for kind, n, pairs, v, status in arm_rows:
        out.write("ARM %s #%d pairs=%d %s %s\n" % (kind, n, pairs, v, status))
    failed_arms = [r for r in arm_rows if r[4] != "PASS"]
    if failed_arms:
        raise Refused("real-data arm(s) failed: %s" % ", ".join(
            "%s #%d %s" % (r[0], r[1], r[4]) for r in failed_arms))

    edited = [n for n in subjects if graded[n]["pairs"]]
    pair_total = sum(len(graded[n]["pairs"]) for n in subjects)
    f = sum(1 for n in edited if per_pr(n) == "FIRE")
    b = sum(1 for n in edited if per_pr(n) == "BOUNDARY")
    s = sum(1 for n in edited if per_pr(n) == "SILENT")
    if f + b + s != len(edited):
        raise Refused("DENOM does not close: FIRE %d + BOUNDARY %d + SILENT %d != edited %d"
                      % (f, b, s, len(edited)))
    out.write("DENOM release-head=%d graded=%d edited=%d pairs=%d not-edited=%d | "
              "FIRE=%d BOUNDARY=%d SILENT=%d\n"
              % (len(release), len(subjects), len(edited), pair_total,
                 len(subjects) - len(edited), f, b, s))
    out.write("RESULT %s\n" % ("FINDINGS" if f > 0 else "CLEAN"))
    return 1 if f > 0 else 0


# ---------------------------------------------------------------------------
# --self-test
# ---------------------------------------------------------------------------

BASE = """## Summary

A synthetic release that adds one widget. Its stage records live on the sub-tasks.

## Type of change

- [ ] Agent prompt (`agents/`)
- [x] Docs (`README`, `CLAUDE.md`, `SECURITY.md`)

## Checklist

- [ ] Markdown links resolve (local files exist; external links load)

## Implementation

**Card A - the widget.** The widget lands in one commit, wrapped
**onto a second line** that opens bold but continues the paragraph.

| Card | Status |
|---|---|
| A | in progress |

~~~text
## a heading inside a fence is not a heading
**a lead inside a fence is not a lead**
~~~

<!-- **a lead inside a comment is not a lead** -->

---

### Issue References

Refs the synthetic card.
"""


class FixtureError(Exception):
    pass


def _edit(body, old, new):
    """Replace old with new, asserting old occurs exactly once."""
    count = body.count(old)
    if count != 1:
        raise FixtureError("anchor %r occurs %d times, not once" % (old[:40], count))
    return body.replace(old, new)


AFTER_TABLE = "| A | in progress |\n"
BEFORE_RULE = "\n---\n"
ROUND_ONE = "\n## Remediation round 1\n\n**Round one - the re-run.** The suites ran again.\n"


def _pair_fixtures():
    """(arm, before, after, expected (H, B, T, P), expected verdict)."""
    rows = []
    e = _edit
    rows.append(("F1", BASE, e(BASE, BEFORE_RULE,
                               "\n## Remediation round 1\n\nThe round re-ran the suites.\n"
                               + BEFORE_RULE), (1, 0, 0, 0), "FIRE"))
    rows.append(("F2", BASE, e(BASE, "## Checklist\n",
                               "## What the verification pass changed\n"), (1, 0, 0, 0), "FIRE"))
    rows.append(("F3", BASE, e(BASE, AFTER_TABLE, AFTER_TABLE
                               + "\n**Card B - the gadget.** It lands in a second commit.\n"
                               + "\n**Card C - the gizmo.** It lands in a third commit.\n"),
                 (0, 2, 0, 0), "FIRE"))
    rows.append(("F4", BASE, e(BASE, AFTER_TABLE, AFTER_TABLE
                               + "\n- **Finding one.** The probe missed a shape.\n"
                               + "- **Finding two.** The fixture now carries it.\n"
                               + "\n**Closed since this section was first written:** both.\n"),
                 (0, 3, 0, 0), "FIRE"))
    rows.append(("F5", BASE, e(BASE, "- [ ] Markdown links resolve",
                               "- [x] Verification - the suites are green at the fix commit\n"
                               "- [ ] Markdown links resolve"), (0, 0, 1, 0), "FIRE"))
    rows.append(("S1", BASE, e(e(BASE, "- [ ] Agent prompt", "- [x] Agent prompt"),
                               "- [ ] Markdown links", "- [x] Markdown links"),
                 (0, 0, 0, 0), "SILENT"))
    rows.append(("S2", BASE, e(BASE, "**Card A - the widget.**",
                               "**Card A - the widget, landed.**"), (0, 0, 0, 0), "SILENT"))
    rows.append(("S3", BASE, e(e(BASE, "in one commit", "in two commits"),
                               "live on the sub-tasks.",
                               "live on the sub-tasks, one comment per stage."),
                 (0, 0, 0, 0), "SILENT"))
    rows.append(("S4", BASE, e(BASE, "| A | in progress |", "| A | landed |"),
                 (0, 0, 0, 0), "SILENT"))
    rows.append(("S5", BASE, e(e(BASE, "**a lead inside a fence is not a lead**\n",
                                 "**a lead inside a fence is not a lead**\n"
                                 "## another heading inside the fence\n"
                                 "**another lead inside the fence**\n"),
                               "<!-- **a lead inside a comment is not a lead** -->\n",
                               "<!-- **a lead inside a comment is not a lead** -->\n"
                               "\n<!-- ## a heading inside a comment is not a heading -->\n"),
                 (0, 0, 0, 0), "SILENT"))
    rows.append(("S6", BASE, e(BASE, "continues the paragraph.\n",
                               "continues the paragraph.\n"
                               "**and a third line** that continues it as well.\n"),
                 (0, 0, 0, 0), "SILENT"))
    rows.append(("B1", BASE, BASE + "- [Record one](records/one.md)\n", (0, 0, 0, 1),
                 "BOUNDARY"))
    # A thematic break written with * or _ is not a bold lead and not a list item.
    rows.append(("S7", BASE, e(BASE, BEFORE_RULE, "\n***\n"), (0, 0, 0, 0), "SILENT"))
    rows.append(("S8", BASE, e(BASE, BEFORE_RULE, "\n___\n"), (0, 0, 0, 0), "SILENT"))
    rows.append(("S9", BASE, e(BASE, BEFORE_RULE, "\n* * *\n"), (0, 0, 0, 0), "SILENT"))
    # ...and the exclusion is narrow: a bold-italic lead is still a bold lead.
    rows.append(("F6", BASE, e(BASE, AFTER_TABLE, AFTER_TABLE
                               + "\n***Card D - the doohickey.*** It lands last.\n"),
                 (0, 1, 0, 0), "FIRE"))
    # A comment opener inside a code span or a fence opens nothing, so what
    # follows it is still read. Each addition sits where a misread opener
    # would hide it: F7's between the code span and the body's real comment,
    # whose --> such an opener would pair with; F8's after the fence, whose
    # closing line such an opener would swallow.
    span_base = e(BASE, "live on the sub-tasks.",
                  "live on the sub-tasks; a marker opens with `<!--` there.")
    rows.append(("F7", span_base, e(span_base, AFTER_TABLE, AFTER_TABLE + ROUND_ONE),
                 (1, 1, 0, 0), "FIRE"))
    rows.append(("F7c", BASE, e(BASE, AFTER_TABLE, AFTER_TABLE + ROUND_ONE),
                 (1, 1, 0, 0), "FIRE"))
    fence_base = e(BASE, "**a lead inside a fence is not a lead**\n",
                   "**a lead inside a fence is not a lead**\n<!-- an opener inside a fence\n")
    rows.append(("F8", fence_base, e(fence_base, BEFORE_RULE, ROUND_ONE + BEFORE_RULE),
                 (1, 1, 0, 0), "FIRE"))
    # A real comment still hides what it holds when it spans lines.
    rows.append(("S10", BASE, e(BASE, BEFORE_RULE,
                                "\n<!-- a comment over several lines\n"
                                "## a heading inside it\n"
                                "**a lead inside it**\n"
                                "-->\n" + BEFORE_RULE), (0, 0, 0, 0), "SILENT"))
    return rows, span_base, fence_base


def _event_payload(action, ref, before, after, with_body_change=True):
    payload = {"action": action,
               "pull_request": {"number": 7, "head": {"ref": ref}, "body": after}}
    if with_body_change:
        payload["changes"] = {"body": {"from": before}}
    else:
        payload["changes"] = {"title": {"from": "an older title"}}
    return payload


def _record(created, revisions):
    """A synthetic GraphQL record: revisions oldest -> newest."""
    nodes = []
    for i, text in enumerate(revisions):
        stamp = created if i == 0 else "2026-01-%02dT00:00:00Z" % (i + 1)
        nodes.append({"editedAt": stamp, "deletedAt": None, "diff": text})
    nodes.reverse()
    return {"createdAt": created, "body": revisions[-1],
            "totalCount": len(nodes), "nodes": nodes}


class _FakeGh(object):
    """A scripted stand-in for gh: one REST listing and GraphQL histories."""

    def __init__(self, listing, histories, faults=None):
        self.listing = listing
        self.histories = histories
        self.faults = [dict(f) for f in (faults or [])]
        self.calls = []

    @staticmethod
    def _kind(args):
        if len(args) >= 2 and args[0] == "api" and args[1].startswith("repos/"):
            return "rest"
        if len(args) >= 2 and args[0] == "api" and args[1] == "graphql":
            query = [a for a in args if a.startswith("query=")][0]
            return "page" if "$number" in query else "batch"
        return "other"

    def _view(self, n, after):
        created, revisions = self.histories[n]
        if not revisions:
            # Never edited: GitHub records no revision, and the body is the record.
            return {"number": n, "createdAt": created, "body": BASE,
                    "userContentEdits": {"totalCount": 0,
                                         "pageInfo": {"hasNextPage": False,
                                                      "endCursor": None},
                                         "nodes": []}}
        rec = _record(created, revisions)
        start = int(after) if after else 0
        nodes = rec["nodes"][start:start + EDITS_PAGE]
        more = start + EDITS_PAGE < len(rec["nodes"])
        return {"number": n, "createdAt": rec["createdAt"], "body": rec["body"],
                "userContentEdits": {"totalCount": rec["totalCount"],
                                     "pageInfo": {"hasNextPage": more,
                                                  "endCursor": str(start + EDITS_PAGE)},
                                     "nodes": nodes}}

    def __call__(self, args):
        kind = self._kind(args)
        self.calls.append((kind, list(args)))
        for f in self.faults:
            if f["kind"] == kind and f["times"] > 0:
                f["times"] -= 1
                return f["rc"], f.get("stdout", ""), f.get("stderr", "")
        if kind == "rest":
            page = int(re.search(r"[?&]page=([0-9]+)", args[1]).group(1))
            chunk = self.listing[(page - 1) * 100:page * 100]
            return 0, json.dumps(chunk), ""
        if kind == "batch":
            query = [a for a in args if a.startswith("query=")][0]
            numbers = [int(x) for x in re.findall(r"pullRequest\(number:([0-9]+)\)", query)]
            repo = {}
            for n in numbers:
                repo["p%d" % n] = self._view(n, None)
            return 0, json.dumps({"data": {"repository": repo}}), ""
        if kind == "page":
            n = int([a for a in args if a.startswith("number=")][0].split("=", 1)[1])
            after = [a for a in args if a.startswith("after=")][0].split("=", 1)[1]
            view = self._view(n, after)
            return 0, json.dumps({"data": {"repository": {"pullRequest": {
                "userContentEdits": view["userContentEdits"]}}}}), ""
        return 1, "", "unexpected gh call"


def _fake_population():
    """101 FIRE, 102 never edited, 103 a non-release head, 104 SILENT,
    105 accreted then restored, 106 BOUNDARY, 107 a history of two pages."""
    created = "2026-01-01T00:00:00Z"
    rows, _, _ = _pair_fixtures()
    fx = {r[0]: r[2] for r in rows}
    ticked = fx["S1"]
    listing = [{"number": n, "state": "closed", "merged_at": "x", "draft": False,
                "head": {"ref": "feature/filler-%d" % n}} for n in range(1, 101)]
    heads = {101: "release/a", 102: "release/b", 103: "fix/c", 104: "release/d",
             105: "release/e", 106: "release/f", 107: "release/g"}
    for n, ref in heads.items():
        listing.append({"number": n, "state": "open", "merged_at": None,
                        "draft": n == 104, "head": {"ref": ref}})
    histories = {
        101: (created, [BASE, fx["F3"]]),
        102: (created, []),
        104: (created, [BASE, fx["S2"]]),
        105: (created, [BASE, fx["F1"], BASE]),
        106: (created, [BASE, fx["B1"]]),
        107: (created, [BASE if i % 2 == 0 else ticked for i in range(102)]),
    }
    return listing, histories


def _population_arms(check):
    listing, histories = _fake_population()
    no_sleep = []

    def run(pr=None, must_fire=(101,), must_silent=(104,), faults=None, listing_=None):
        gh = _FakeGh(listing_ if listing_ is not None else listing, histories, faults)
        out = io.StringIO()
        rc = run_population("owner/name", list(must_fire), list(must_silent), pr, out,
                            gh=gh, sleep=no_sleep.append, preflight=False)
        return rc, out.getvalue(), gh

    def kinds(gh, kind):
        return [c for c in gh.calls if c[0] == kind]

    full_denom = ("DENOM release-head=6 graded=6 edited=5 pairs=106 not-edited=1 | "
                  "FIRE=2 BOUNDARY=1 SILENT=2")

    rc, text, gh = run()
    batches = kinds(gh, "batch")
    widest = max(len(re.findall(r"pullRequest\(number:", [a for a in c[1]
                                if a.startswith("query=")][0])) for c in batches)
    check("Q1", rc == 1 and full_denom in text and "RESULT FINDINGS" in text
          and "listed=107 pages=3 release-head=6" in text
          and len(kinds(gh, "rest")) == 3 and len(batches) == 2 and widest <= BATCH_SIZE
          and len(kinds(gh, "page")) == 1 and "RETRY" not in text
          and "ARM must-fire #101 pairs=1 FIRE PASS" in text
          and "ARM must-silent #104 pairs=1 SILENT PASS" in text
          and "BOUNDARY-ONLY #106 P+=1" in text and "FINDING #105 pair=0->1" in text,
          "full population: 3 REST pages, 2 batches of at most 5, 1 history page; rc=%d" % rc)

    transient = {"kind": "batch", "times": 1, "rc": 1,
                 "stderr": "gh: HTTP 502: Bad Gateway (https://api.github.com/graphql)"}
    rc, text, gh = run(faults=[transient])
    check("Q2", rc == 1 and text.count("RETRY ") == 1 and full_denom in text,
          "an HTTP 502 is retried once with a RETRY line, then read; rc=%d" % rc)

    secondary = {"kind": "rest", "times": 1, "rc": 1,
                 "stderr": "gh: You have exceeded a secondary rate limit. (HTTP 403)"}
    rc, text, gh = run(faults=[secondary])
    check("Q3", rc == 1 and text.count("RETRY ") == 1 and full_denom in text,
          "a secondary rate limit is retried once with a RETRY line; rc=%d" % rc)

    content = {"kind": "batch", "times": 1, "rc": 1,
               "stdout": json.dumps({"data": None, "errors": [
                   {"message": "Could not resolve to a PullRequest with the number of 9."}]}),
               "stderr": "gh: Could not resolve to a PullRequest with the number of 9."}
    rc, text, gh = run(faults=[content])
    check("Q4", rc == 2 and "RETRY" not in text and "REFUSED:" in text
          and "RESULT" not in text and "DENOM" not in text,
          "a content error refuses at once, with no retry and no verdict; rc=%d" % rc)

    always = {"kind": "batch", "times": 99, "rc": 1, "stderr": "gh: HTTP 503: Service Unavailable"}
    rc, text, gh = run(faults=[always])
    check("Q5", rc == 2 and text.count("RETRY ") == MAX_ATTEMPTS - 1 and "REFUSED:" in text
          and "RESULT" not in text,
          "a transient failure on every attempt refuses after %d attempts; rc=%d"
          % (MAX_ATTEMPTS, rc))

    rc, text, gh = run(listing_=listing + [dict(listing[-1])])
    check("Q6", rc == 2 and "twice" in text and "RESULT" not in text,
          "a number listed twice refuses the page walk; rc=%d" % rc)

    gh_broken = _FakeGh(listing, histories)
    original_view = gh_broken._view

    def view_with_stale_body(n, after):
        v = original_view(n, after)
        if n == 104:
            v["body"] = v["body"] + "x"
        return v
    gh_broken._view = view_with_stale_body
    out = io.StringIO()
    rc = run_population("owner/name", [101], [104], None, out, gh=gh_broken,
                        sleep=no_sleep.append, preflight=False)
    text = out.getvalue()
    check("Q7", rc == 2 and "INSTRUMENT #104 I3" in text and "RESULT" not in text,
          "an instrument anomaly refuses, naming the pull request and the check; rc=%d" % rc)

    rc, text, gh = run(pr=105, must_fire=(101,), must_silent=(104,))
    check("PR1", rc == 0 and "SELECT --pr #105, 1 of 6" in text
          and "verdict=FIRE open-to-now=SILENT" in text
          and "DENOM release-head=6 graded=1 edited=1 pairs=2 not-edited=0 | "
              "FIRE=0 BOUNDARY=0 SILENT=1" in text
          and "RESULT CLEAN" in text and "role=control" in text
          and "ARM must-fire #101 pairs=1 FIRE PASS" in text
          and len(kinds(gh, "batch")) == 1,
          "--pr grades the body as opened against now: accreted then restored reads "
          "SILENT; rc=%d" % rc)

    rc, text, gh = run(pr=101, must_fire=(), must_silent=())
    check("PR2", rc == 1 and "FINDING #101 open->now H=0 B=2 T=0 P=0" in text
          and "RESULT FINDINGS" in text,
          "--pr on an accreted body reads FINDINGS; rc=%d" % rc)

    rc, text, gh = run(pr=103, must_fire=(), must_silent=())
    check("PR3", rc == 2 and "ABSENT" in text and "RESULT" not in text,
          "--pr naming a non-release head refuses as ABSENT; rc=%d" % rc)

    rc, text, gh = run(pr=102, must_fire=(), must_silent=())
    check("PR4", rc == 0 and "verdict=NOT-EDITED" in text
          and "DENOM release-head=6 graded=1 edited=0 pairs=0 not-edited=1" in text
          and "RESULT CLEAN" in text,
          "--pr on a never-edited body reads NOT-EDITED and CLEAN; rc=%d" % rc)

    rc, text, gh = run(must_fire=(103,), must_silent=())
    check("PR5", rc == 2 and "ARM must-fire #103 pairs=0 - ABSENT" in text
          and "RESULT" not in text,
          "an arm naming a pull request outside the release heads refuses; rc=%d" % rc)


def self_test(out):
    results = []

    def check(arm, ok, detail):
        results.append((arm, bool(ok), detail))

    def guarded(arm, fn):
        try:
            fn()
        except Exception as e:  # a fixture that cannot be built is a misread
            check(arm, False, "raised %s: %s" % (type(e).__name__, e))

    expected_s0 = ({(2, "Summary"): 1, (2, "Type of change"): 1, (2, "Checklist"): 1,
                    (2, "Implementation"): 1, (3, "Issue References"): 1}, 1, 3, 0)

    def s0():
        got = shape(BASE).as_tuple()
        check("S0", got == expected_s0, "shape(BASE) = %r" % (got,))
    guarded("S0", s0)

    def c1():
        check("C1", shape(BASE.replace("\n", "\r\n")).as_tuple() == shape(BASE).as_tuple(),
              "CRLF reads the same as LF")
    guarded("C1", c1)

    rows = []

    def build():
        rows.extend(_pair_fixtures()[0])
    guarded("FIXTURES", build)
    for arm, before, after, expect, expect_v in rows:
        def one(arm=arm, before=before, after=after, expect=expect, expect_v=expect_v):
            g, _ = grade(shape(before), shape(after))
            got = (g["H"], g["B"], g["T"], g["P"])
            v = verdict(g)
            detail = ("%s %s, expected H=%d B=%d T=%d P=%d %s"
                      % ((_counts(g), v) + tuple(expect) + (expect_v,)))
            check(arm, got == tuple(expect) and v == expect_v, detail)
        guarded(arm, one)

    def n1():
        fx = {r[0]: r for r in rows}
        s2_after = fx["S2"][2]
        new_lead = [l for l in s2_after.split("\n") if l.startswith("**Card A - the widget, landed")]
        f2_after = fx["F2"][2]
        check("N1", len(new_lead) == 1 and new_lead[0] not in BASE
              and sum(shape(f2_after).headings.values()) == sum(shape(BASE).headings.values()),
              "S2 carries a bold lead absent from BASE; F2 keeps the heading count")
    guarded("N1", n1)

    def n2():
        _, span_base, fence_base = _pair_fixtures()
        check("N2", "`<!--`" in span_base and "<!-- an opener inside a fence" in fence_base
              and shape(span_base).as_tuple() == shape(BASE).as_tuple()
              and shape(fence_base).as_tuple() == shape(BASE).as_tuple(),
              "an opener in a code span or a fence hides nothing that follows it")
    guarded("N2", n2)

    fx3 = {}

    def events():
        rws = {r[0]: r for r in rows}
        fx3["F3"] = rws["F3"][2]
        with tempfile.TemporaryDirectory() as d:
            cases = [
                ("E1", _event_payload("edited", "release/x", BASE, fx3["F3"]), 1,
                 "EDIT #7 H=0 B=2 T=0 P=0 verdict=FIRE"),
                ("E2", _event_payload("edited", "fix/x", BASE, fx3["F3"]), 0,
                 "NOT GRADED: head fix/x is not a release/* branch"),
                ("E3", _event_payload("edited", "release/x", BASE, fx3["F3"], False), 0,
                 "NOT GRADED: this edit did not change the body"),
                ("E4", _event_payload("synchronize", "release/x", BASE, fx3["F3"]), 0,
                 "NOT GRADED: event action is synchronize"),
            ]
            for arm, payload, want_rc, want_text in cases:
                path = os.path.join(d, arm + ".json")
                with open(path, "w", encoding="utf-8") as f:
                    json.dump(payload, f)
                buf = io.StringIO()
                rc = grade_event(path, buf)
                text = buf.getvalue()
                check(arm, rc == want_rc and want_text in text and "SCOPE:" in text,
                      "rc=%d, expected %d with %r" % (rc, want_rc, want_text))
            bad = os.path.join(d, "E5.json")
            with open(bad, "w", encoding="utf-8") as f:
                f.write("{not json")
            try:
                grade_event(bad, io.StringIO())
                check("E5", False, "a malformed payload was graded")
            except Refused:
                check("E5", True, "a malformed payload refuses")
            before_path = os.path.join(d, "before.md")
            after_path = os.path.join(d, "after.md")
            with open(before_path, "w", encoding="utf-8") as f:
                f.write(BASE)
            with open(after_path, "w", encoding="utf-8") as f:
                f.write(rws["F4"][2])
            buf = io.StringIO()
            rc = grade_pair(before_path, after_path, buf)
            check("P1", rc == 1 and "PAIR H=0 B=3 T=0 P=0 verdict=FIRE" in buf.getvalue(),
                  "rc=%d %s" % (rc, buf.getvalue().strip()))
    guarded("EVENTS", events)

    def instrument():
        rws = {r[0]: r for r in rows}
        f3 = rws["F3"][2]
        f3_f1 = _edit(f3, BEFORE_RULE, "\n## Remediation round 1\n" + BEFORE_RULE)
        created = "2026-01-01T00:00:00Z"
        good = _record(created, [BASE, f3, f3_f1])
        r = grade_record(good)
        check("I0", check_instrument(good) == [] and r["verdict"] == "FIRE"
              and len(r["pairs"]) == 2 and r["open_now"]["verdict"] == "FIRE",
              "a clean three-revision record reads clean and FIRE")
        cases = []
        bad = _record(created, [BASE, f3, f3_f1])
        bad["totalCount"] = 4
        cases.append(("I1", bad))
        bad = _record(created, [BASE, f3, f3_f1])
        bad["nodes"][1]["diff"] = None
        cases.append(("I2", bad))
        bad = _record(created, [BASE, f3, f3_f1])
        bad["body"] = bad["body"] + "x"
        cases.append(("I3", bad))
        bad = _record(created, [BASE, f3, f3_f1])
        bad["nodes"][-1]["editedAt"] = "2026-01-09T00:00:00Z"
        cases.append(("I4", bad))
        for arm, rec in cases:
            got = check_instrument(rec)
            check(arm, got == [arm], "check_instrument -> %r" % (got,))
    guarded("INSTRUMENT", instrument)

    def arms():
        observed = {1: (2, "SILENT"), 2: (0, "NOT-EDITED"), 3: (3, "FIRE"), 4: (2, "SILENT")}
        r1 = apply_arms(observed, [1], [])
        check("R1", r1[0][4] == "MISREAD", "a must-fire reading SILENT -> %s" % r1[0][4])
        r2 = apply_arms(observed, [], [2])
        check("R2", r2[0][4] == "VACUOUS", "a must-silent with 0 pairs -> %s" % r2[0][4])
        r3 = apply_arms(observed, [3], [4])
        check("R3", [r[4] for r in r3] == ["PASS", "PASS"], "a consistent set -> PASS")
        r4 = apply_arms(observed, [9], [])
        check("R4", r4[0][4] == "ABSENT", "a must-fire not observed -> %s" % r4[0][4])
    guarded("ARMS", arms)

    guarded("POPULATION", lambda: _population_arms(check))

    misread = [r for r in results if not r[1]]
    for arm, ok, detail in results:
        out.write("  %-7s %-5s %s\n" % ("ok" if ok else "MISREAD", arm, detail))
    out.write("SELF-TEST arms=%d passed=%d misread=%d\n"
              % (len(results), len(results) - len(misread), len(misread)))
    if misread:
        out.write("REFUSED: a fixture arm misread (%s), so no edit or population verdict "
                  "from this build can be trusted\n" % ", ".join(r[0] for r in misread))
        return 2
    return 0


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def _numbers(text):
    try:
        values = [int(x) for x in text.split(",") if x.strip()]
    except ValueError:
        raise argparse.ArgumentTypeError("expected a comma-separated list of numbers: %r" % text)
    if any(v <= 0 for v in values):
        raise argparse.ArgumentTypeError("pull-request numbers are positive: %r" % text)
    return values


def main(argv=None):
    try:
        sys.stdout.reconfigure(errors="backslashreplace")
    except AttributeError:
        pass
    parser = argparse.ArgumentParser(
        description="Grade what a release pull request's body gained after it was opened. "
                    "Exit 0 clean / 1 finding(s) / 2 refused.")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--pair", nargs=2, metavar=("BEFORE", "AFTER"))
    mode.add_argument("--event", metavar="PATH")
    mode.add_argument("--population", action="store_true")
    parser.add_argument("--repo")
    parser.add_argument("--pr", type=int)
    parser.add_argument("--must-fire", type=_numbers, default=[])
    parser.add_argument("--must-silent", type=_numbers, default=[])
    args = parser.parse_args(argv)
    if not args.population and (args.repo or args.pr is not None
                                or args.must_fire or args.must_silent):
        parser.error("--repo, --pr, --must-fire and --must-silent belong to --population")
    if args.pr is not None and args.pr <= 0:
        parser.error("--pr takes a positive pull-request number")
    out = sys.stdout
    try:
        if args.self_test:
            return self_test(out)
        if args.pair:
            return grade_pair(args.pair[0], args.pair[1], out)
        if args.event:
            return grade_event(args.event, out)
        return run_population(args.repo, args.must_fire, args.must_silent, args.pr, out)
    except Refused as e:
        out.write("REFUSED: %s\n" % e)
        return 2


if __name__ == "__main__":
    sys.exit(main())
