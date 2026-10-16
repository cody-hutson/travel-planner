#!/usr/bin/env python3
"""check-integration-note.py -- asks a pull request that adds much to a file and removes little
for a note on what it reconciled.

    ./scripts/check-integration-note.py --check
    ./scripts/check-integration-note.py --check --base REV --head REV --body-file PATH   (local)
    ./scripts/check-integration-note.py --self-test [--root DIR]

THE PREDICATE. Per tracked markdown file changed between the merge base of the pull request's
base and head, and its head -- CHANGELOG.md excluded by the pathspec -- a file is FLAGGED when
all three hold: its additions are at least LINE_THRESHOLD lines; its deletions are under
DELETION_PERCENT of its additions; and its size at the merge base is at least the class floor
that reference/load-class-model.md declares in its load-class-parameters fence. Per file, never
summed over the pull request. A file absent at the merge base is new and is never flagged. The
range starts at the merge base and never at the base tip: a pull request with no merge base is
refused, and the two-dot range is never substituted for one.

THE FLOOR. Read from the declaration at the merge base, through the grammar of the one reader
that declaration's fences have (the corpus-hygiene suite's fence reader), matched here rather
than reused: a fence opens on a line that is exactly three backticks and the tag, and closes on
a line that is exactly three backticks; inside it a line whose first non-blank character is #
is a comment, a blank line is skipped, and a row is its first two whitespace-separated fields.
Every numeric <class>.floor must agree. Floors that differ are a refusal, never flattened, and
so is a declaration with no numeric floor. This file states no value of the floor.

THE NOTE. A flag asks the body for its "Integration note" section. The body is read in one pass
that tracks fenced code and HTML comments together, in the order CommonMark resolves them: a
fence opened outside a comment is literal until its closer; a comment block opens only where
<!-- begins a line (up to three spaces of indent) outside a fence, and ends at the line holding
--> -- or, when none follows, at the end of the body, as GitHub renders that line-leading form;
an inline <!-- is removed only together with a --> on the same line, and never inside a code
span. The section runs from its heading -- any level, any case, an optional trailing colon and
an optional closing # run -- to the next heading of any level, a thematic break or the end of
the body, whichever comes first. Fenced code inside it is content; a fence's delimiter lines are
not. It is empty unless a letter or digit remains. Three forms GitHub renders are not modelled,
and are a stated residual rather than a reading this file claims: a setext heading (the words
underlined) and a heading inside a blockquote are no heading here, so the note reads absent; and
a note written as an indented code block is read as plain lines, so an HTML comment in it is
removed though GitHub shows it, and a note made only of such a line reads empty. Each errs toward
asking for a note, never toward passing without one; the self-test pins all three as they read
today, and the template's own '## Integration note' heading is the form that is read. GRADED:
that the note is present and not empty. NOT GRADED: whether it is true -- this job cannot see
that, and says so on every run that asks for a note.

INPUTS. In --check, PR_BASE_SHA, PR_HEAD_SHA and PR_BODY come from the environment the workflow
step sets; the body never passes through a shell and is never printed. --base, --head and
--body-file replace them for a local run, which is how to know before a pull request opens
whether it will be asked for a note. The repository graded is the one this file lives in,
found from the file's own location and never from the caller's working directory.

EXIT. 0 -- nothing flagged, or flagged with a note present and not empty. 1 -- a flag with the note
absent or empty; in --self-test, an arm that misread. 2 -- not a measurement: a refusal, which
names its cause and grades nothing, or a self-test that could not run. A refusal is never a pass.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

# CONSTANTS of the detector, deliberately not environment knobs: each is changed by editing its
# line, in a diff. LINE_THRESHOLD and DELETION_PERCENT were derived over the first-parent merges
# of main, per file and per merge; re-derive them there before changing either. The floor is NOT
# here: it is read from the declaration, and this file states no value of it.
LINE_THRESHOLD = 100
DELETION_PERCENT = 20  # flagged only when deletions * 100 < additions * DELETION_PERCENT

PARAM_DOC = "reference/load-class-model.md"
PARAM_TAG = "load-class-parameters"
TEMPLATE = ".github/PULL_REQUEST_TEMPLATE.md"
PATHSPEC = ("*.md", ":(exclude)CHANGELOG.md")
PREFIX = "integration-note: "

HEADING_RE = re.compile(r"^ {0,3}#{1,6}[ \t]+integration[ \t]+note[ \t]*:?(?:[ \t]+#+)?[ \t]*$",
                        re.IGNORECASE)
REFS_RE = re.compile(r"^ {0,3}#{1,6}[ \t]+issue[ \t]+references[ \t]*:?[ \t]*$", re.IGNORECASE)
ATX_RE = re.compile(r"^ {0,3}#{1,6}(?:[ \t]|$)")
BREAK_RE = re.compile(r"^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$")
FENCE_OPEN_RE = re.compile(r"^ {0,3}(?:(`{3,})[^`]*|(~{3,}).*)$")
COMMENT_OPEN_RE = re.compile(r"^ {0,3}<!--")
PUNCTUATION = set("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")

# The three ::error:: lines a reader can meet, one per outcome, each fixed text plus counts.
FLAG_ERROR = "::error::integration note {} while {} file(s) are flagged"
REFUSAL_ERROR = "::error::integration-note check not evaluated: a refusal, not a finding"
SELF_TEST_ERROR = ("::error::the self-test of scripts/check-integration-note.py failed: the "
                   "instrument is at fault, not this pull request")
GRADED = "Graded: that a note is present and not empty. Not graded: whether it is true."


class Refusal(Exception):
    """Not a measurement. Exit 2, the cause named, nothing graded."""


def show(text):
    """One printable line: control characters and backslashes escaped, so no path can open a line."""
    out = []
    for ch in text:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif o < 0x20 or o == 0x7F or 0xDC80 <= o <= 0xDCFF:
            out.append("\\x{:02x}".format(o & 0xFF))
        else:
            out.append(ch)
    return "".join(out)


def git(root, *args, ok=(0,)):
    """(exit status, stdout bytes) of one git command in `root`; any other status is a refusal."""
    try:
        proc = subprocess.run(["git", "-C", root] + list(args), stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError as exc:
        raise Refusal("git could not be run: {}".format(show(str(exc))))
    if proc.returncode not in ok:
        raise Refusal("git {} exited {}: {}".format(
            args[0], proc.returncode, show(proc.stderr.decode("utf-8", "replace").strip())))
    return proc.returncode, proc.stdout


# ---------------------------------------------------------------- the floor
def fence_lines(text, tag=PARAM_TAG):
    """Every line inside every `tag` fence, by the suite's fence grammar exactly: open on a line
    that is exactly three backticks and the tag, close on a line that is exactly three backticks.
    A line is split on newline alone, so a carriage return stays part of it, as it does there."""
    inner, inside = [], False
    for line in text.split("\n"):
        if line == "```" + tag:
            inside = True
            continue
        if inside and line == "```":
            inside = False
            continue
        if inside:
            inner.append(line)
    return inner


def fence_row(line):
    """(key, value) from one fence line, or None: blank, a comment (first non-blank character #)
    or fewer than two fields. Blank means spaces and tabs only, as it does in the suite."""
    stripped = re.sub(r"[ \t]+$", "", re.sub(r"^[ \t]+", "", line))
    if not stripped or stripped[0] == "#":
        return None
    fields = re.split(r"[ \t]+", stripped)
    return (fields[0], fields[1]) if len(fields) >= 2 else None


def floor_from_text(text):
    """(floor, how many keys declared it) from the declaration's text, or a Refusal naming why not."""
    rows = [row for row in (fence_row(line) for line in fence_lines(text)) if row]
    if not rows:
        raise Refusal("{} carries no {} rows, so no floor is declared".format(PARAM_DOC, PARAM_TAG))
    floors = []
    for key, value in rows:
        if not key.endswith(".floor") or value == "-":
            continue
        if not re.fullmatch(r"[0-9]+", value):
            raise Refusal("{} = {} is neither a whole number nor -".format(show(key), show(value)))
        floors.append((key, int(value)))
    if not floors:
        raise Refusal("{} declares no numeric floor".format(PARAM_TAG))
    if len(set(value for _, value in floors)) > 1:
        raise Refusal("the declared floors differ ({}); this job reads one floor and will not "
                      "flatten them -- it needs each file's class, through the corpus-hygiene "
                      "suite's classifier or the size fence's own rows".format(
                          ", ".join("{} {}".format(show(k), v) for k, v in floors)))
    return floors[0][1], len(floors)


# ---------------------------------------------------------------- the range and the rows
def commit_of(root, name, rev):
    """The full commit id `rev` names, or a Refusal: empty, option-shaped, or not present."""
    if not rev:
        raise Refusal("the {} commit is empty, so there is no range".format(name))
    if rev.startswith("-"):
        raise Refusal("the {} revision {} is not a revision".format(name, show(rev)))
    rc, _ = git(root, "cat-file", "-e", rev + "^{commit}", ok=(0, 1, 128))
    if rc:
        raise Refusal("the {} commit {} is not present in this checkout: history was rewritten, "
                      "or the fetch is too shallow".format(name, show(rev)))
    return git(root, "rev-parse", "--verify", "--quiet", rev + "^{commit}")[1].decode().strip()


def evaluate(root, base, head):
    """The range, the floor and every row, or a Refusal."""
    base, head = commit_of(root, "base", base), commit_of(root, "head", head)
    rc, out = git(root, "merge-base", base, head, ok=(0, 1))
    if rc:
        raise Refusal("the base and head share no merge base (unrelated histories); there is "
                      "no range, and the two-dot range is never substituted for one")
    mb = out.decode().strip()
    rc, text = git(root, "cat-file", "blob", "{}:{}".format(mb, PARAM_DOC), ok=(0, 128))
    if rc:
        raise Refusal("the merge base carries no {}, so no floor is declared".format(PARAM_DOC))
    floor, nfloors = floor_from_text(text.decode("utf-8", "replace"))
    sizes = {}
    for ent in git(root, "ls-tree", "-r", "-l", "-z", mb)[1].decode("utf-8", "surrogateescape").split("\0"):
        if not ent:
            continue
        meta, path = ent.split("\t", 1)
        mode, kind, _sha, size = meta.split()
        if kind == "blob" and mode in ("100644", "100755"):
            sizes[path] = int(size)
    raw = git(root, "diff", "--numstat", "-z", "--no-renames", mb, head, "--", *PATHSPEC)[1]
    rows = []
    for tok in raw.decode("utf-8", "surrogateescape").split("\0"):
        if not tok:
            continue
        added, deleted, path = tok.split("\t", 2)
        if added == "-":
            continue  # a binary row carries no line counts
        a, d, s = int(added), int(deleted), sizes.get(path)
        why = []
        if s is None:
            why.append("new file")
        if a < LINE_THRESHOLD:
            why.append("lines")
        if d * 100 >= a * DELETION_PERCENT:
            why.append("deletions")
        if s is not None and s < floor:
            why.append("floor")
        rows.append({"path": path, "a": a, "d": d, "size": s, "flag": not why, "why": why})
    return {"mb": mb, "base": base, "head": head, "floor": floor, "nfloors": nfloors, "rows": rows}


# ---------------------------------------------------------------- the note
def strip_inline(line):
    """A line as it renders: every <!-- ... --> closed on the same line removed, except inside a
    code span, which is kept whole. An opener with no closer on its line stays, as text."""
    out, i, n = [], 0, len(line)
    while i < n:
        ch = line[i]
        if ch == "\\" and i + 1 < n and line[i + 1] in PUNCTUATION:
            out.append(line[i:i + 2])
            i += 2
            continue
        if ch == "`":
            j = i
            while j < n and line[j] == "`":
                j += 1
            run, k, close = j - i, j, -1
            while k < n:
                if line[k] != "`":
                    k += 1
                    continue
                m = k
                while m < n and line[m] == "`":
                    m += 1
                if m - k == run:
                    close = k
                    break
                k = m
            if close < 0:
                out.append(line[i:j])  # no closing run of the same length: literal backticks
                i = j
            else:
                out.append(line[i:close + run])
                i = close + run
            continue
        if line.startswith("<!--", i):
            end = line.find("-->", i + 2)
            if end >= 0:
                i = end + 3
                continue
            out.append("<!--")
            i += 4
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _closes(fence, line):
    return re.match(r"^ {0,3}" + re.escape(fence[0]) + "{" + str(len(fence)) + r",}[ \t]*$", line)


def read_lines(body):
    """One pass over the body: a (kind, text) per line. Kinds: text (as it renders), fence (a
    delimiter line), code (inside a fence, literal), comment (inside a comment block; its text is
    whatever follows the --> that closes it on that line)."""
    lines = body.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    out, fence, in_comment = [], None, False
    for line in lines:
        if fence:
            if _closes(fence, line):
                fence = None
                out.append(("fence", ""))
            else:
                out.append(("code", line))
            continue
        if in_comment:
            end = line.find("-->")
            if end < 0:
                out.append(("comment", ""))
            else:
                in_comment = False
                out.append(("comment", strip_inline(line[end + 3:])))
            continue
        m = FENCE_OPEN_RE.match(line)
        if m:
            fence = m.group(1) or m.group(2)
            out.append(("fence", ""))
            continue
        m = COMMENT_OPEN_RE.match(line)
        if m:
            end = line.find("-->", m.end() - 2)
            if end < 0:
                in_comment = True
                out.append(("comment", ""))
            else:
                out.append(("comment", strip_inline(line[end + 3:])))
            continue
        out.append(("text", strip_inline(line)))
    return out


def note_block(body):
    """(status, info) -- status is absent, empty or present."""
    lines = read_lines(body)
    head, refs, extra = None, None, 0
    for n, (kind, text) in enumerate(lines):
        if kind != "text":
            continue
        if HEADING_RE.match(text):
            if head is None:
                head = n
            else:
                extra += 1
        elif REFS_RE.match(text) and refs is None:
            refs = n
    info = {"head": head, "refs": refs, "extra": extra, "end": None, "why": None, "words": 0}
    if head is None:
        return "absent", info
    content, end, why = [], len(lines), "end of body"
    for n in range(head + 1, len(lines)):
        kind, text = lines[n]
        if kind == "text" and ATX_RE.match(text):
            end, why = n, "heading"
            break
        if kind == "text" and BREAK_RE.match(text):
            end, why = n, "thematic break"
            break
        if kind != "fence":
            content.append(text)
    info["end"], info["why"] = end, why
    info["words"] = sum(1 for text in content if any(ch.isalnum() for ch in text))
    return ("present" if info["words"] else "empty"), info


# ---------------------------------------------------------------- the verdict
def grade(result, body, out):
    """Print the verdict; return 0 (no flag, or a note) or 1 (a flag with no note)."""
    rows, flagged = result["rows"], [r for r in result["rows"] if r["flag"]]
    out(PREFIX + "range {}..{} (merge base of base {} and head {})".format(
        result["mb"][:12], result["head"][:12], result["base"][:12], result["head"][:12]))
    out(PREFIX + "LINE_THRESHOLD {} . DELETION_PERCENT {} . floor {}, read from {} ({}) at the "
        "merge base -- {} numeric floor(s), all equal".format(
            LINE_THRESHOLD, DELETION_PERCENT, result["floor"], PARAM_DOC, PARAM_TAG,
            result["nfloors"]))
    out(PREFIX + "{} tracked .md file(s) changed in the range, CHANGELOG.md excluded by pathspec; "
        "{} existed at the merge base".format(len(rows), sum(1 for r in rows if r["size"] is not None)))
    for r in rows:
        ratio = "{:.3f}".format(r["d"] / r["a"]) if r["a"] else "-"
        size = r["size"] if r["size"] is not None else "-"
        tail = "" if r["flag"] else "  ({})".format(", ".join(r["why"]))
        out(PREFIX + "{}  +{} -{}  ratio {}  size-at-merge-base {}  {}{}".format(
            "FLAG" if r["flag"] else "pass", r["a"], r["d"], ratio, size, show(r["path"]), tail))
    if not flagged:
        out(PREFIX + "PASS -- no file meets all three conjuncts, so no note is asked for.")
        return 0
    status, info = note_block(body)
    if status == "absent":
        out(PREFIX + "note: no 'Integration note' heading in the body")
    else:
        out(PREFIX + "note: heading at body line {}; block ends at line {} ({}); {} line(s) with a "
            "letter or digit once comments are removed".format(
                info["head"] + 1, info["end"] + 1, info["why"], info["words"]))
        if info["extra"]:
            out(PREFIX + "WARNING: {} further 'Integration note' heading(s); the first is read".format(
                info["extra"]))
        if info["refs"] is not None and info["refs"] < info["head"]:
            out(PREFIX + "WARNING: the note sits below the Issue References heading, where the "
                "close-keyword gate does not scan it; move it above the --- rule")
    if status == "present":
        out(PREFIX + "PASS -- {} file(s) flagged; the integration note is present and not empty. "
            "{}".format(len(flagged), GRADED))
        return 0
    out(FLAG_ERROR.format(status, len(flagged)))
    out(PREFIX + "FAIL -- {} file(s) flagged and the integration note is {}. {}".format(
        len(flagged), status, GRADED))
    if status == "empty" and info["why"] == "heading":
        out(PREFIX + "A heading of any level ends this section, and one follows the note's heading "
            "before any line with a letter or digit: write the note as plain lines, with no "
            "sub-heading.")
    out(PREFIX + "To clear this, add the note to this pull request's body now, under the "
        "'## Integration note' heading above the --- rule that precedes Issue References: what "
        "this change removed, merged or superseded to make room, or in a sentence why nothing "
        "could be. Editing the body re-runs this check; CONTRIBUTING.md admits this note as an "
        "addition to a release pull request's body after it opens.")
    out(PREFIX + "Next time, write it when the pull request opens: run ./scripts/check-integration-"
        "note.py --check --base origin/main --head HEAD --body-file <draft body> first to know "
        "whether a note will be asked for.")
    return 1


def check(root, base, head, body, out):
    """The whole check, as the workflow step runs it: 0, 1, or 2 for a refusal."""
    try:
        result = evaluate(root, base, head)
    except Refusal as exc:
        out(REFUSAL_ERROR)
        out(PREFIX + "NOT EVALUATED -- " + str(exc) + ". Nothing was graded.")
        return 2
    return grade(result, body, out)


def repo_root():
    """The repository this file lives in, derived from the file's own location."""
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run_check(args):
    base = args.base if args.base is not None else os.environ.get("PR_BASE_SHA", "")
    head = args.head if args.head is not None else os.environ.get("PR_HEAD_SHA", "")
    lines = []
    if args.body_file is not None:
        try:
            with open(args.body_file, encoding="utf-8", errors="replace") as fh:
                body = fh.read()
        except OSError as exc:
            body = None
            lines.append(REFUSAL_ERROR)
            lines.append(PREFIX + "NOT EVALUATED -- the body file could not be read: {}. Nothing "
                         "was graded.".format(show(str(exc))))
            rc = 2
    else:
        body = os.environ.get("PR_BODY", "")
    if body is not None:
        rc = check(repo_root(), base, head, body, lines.append)
    for line in lines:
        print(line)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        shown = [line for line in lines if not line.startswith("::")]
        longest = max([len(m) for line in shown for m in re.findall(r"`+", line)] + [2])
        fence = "`" * (longest + 1)
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(fence + "text\n" + "\n".join(shown) + "\n" + fence + "\n")
    return rc


# ---------------------------------------------------------------- self-test
ISOLATED = {"GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_AUTHOR_NAME": "self-test", "GIT_AUTHOR_EMAIL": "self-test@example.invalid",
            "GIT_COMMITTER_NAME": "self-test", "GIT_COMMITTER_EMAIL": "self-test@example.invalid",
            "GIT_AUTHOR_DATE": "2000-01-01T00:00:00+0000",
            "GIT_COMMITTER_DATE": "2000-01-01T00:00:00+0000"}


def lines_of(size, tag):
    """Exactly `size` bytes of unique ten-byte lines."""
    n, r = divmod(size, 10)
    text = "".join("{}{:0{w}d}\n".format(tag, i, w=9 - len(tag)) for i in range(n))
    return text + ("x" * (r - 1) + "\n" if r else "")


def added(m, tag):
    return "".join("{}{:0{w}d}\n".format(tag, i, w=9 - len(tag)) for i in range(m))


class Repo:
    """A synthetic history in the self-test's temporary directory."""

    def __init__(self, tmp, name, params):
        self.root = os.path.join(tmp, name)
        self.paths = set()
        os.makedirs(self.root)
        git(self.root, "init", "-q", "-b", "main")
        if params is not None:
            self.write(PARAM_DOC, "# parameters\n\n```" + PARAM_TAG + "\n" + params + "```\n")

    def write(self, path, text):
        full = os.path.join(self.root, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        self.paths.add(path)

    def read(self, path):
        with open(os.path.join(self.root, path), encoding="utf-8") as fh:
            return fh.read()

    def commit(self, msg):
        if self.paths:
            git(self.root, "add", "--", *sorted(self.paths))
        git(self.root, "-c", "commit.gpgsign=false", "commit", "-q", "--allow-empty", "-m", msg)
        return git(self.root, "rev-parse", "HEAD")[1].decode().strip()

    def branch(self, name, at):
        git(self.root, "checkout", "-q", "-b", name, at)

    def switch(self, name):
        git(self.root, "checkout", "-q", name)


class Arms:
    """The self-test's shared state: the real declaration, the real template, the temporary
    directory, and the verdict of every arm."""

    def __init__(self, tmp, params, floor, nfloors, template):
        self.tmp, self.params, self.floor, self.nfloors = tmp, params, floor, nfloors
        self.template, self.big, self.results = template, floor + 5000, []

    def arm(self, label, fn):
        try:
            ok, detail = fn()
        except Exception as exc:  # an arm that crashes has misread, and says how
            ok, detail = False, "raised {}: {}".format(type(exc).__name__, show(str(exc)))
        self.results.append(ok)
        print("{} {}: {}".format("PASS" if ok else "FAIL", label, detail))

    def repo(self, name):
        return Repo(self.tmp, name, self.params)

    def fixture(self, name, size=None, add=LINE_THRESHOLD, delete=0, path="ref/big.md"):
        """A file at `size` bytes (the floor + 5000 by default) and one under the floor; the
        branch deletes `delete` lines of the first and appends `add`."""
        repo = self.repo(name)
        repo.write(path, lines_of(self.big if size is None else size, "b"))
        repo.write("ref/small.md", lines_of(500, "s"))
        base = repo.commit("base")
        repo.branch("pr", base)
        text = repo.read(path)
        repo.write(path, "".join(text.splitlines(True)[delete:]) + added(add, "a"))
        return repo, base, repo.commit("pr")

    def flagged_result(self):
        return {"mb": "m" * 40, "base": "b" * 40, "head": "h" * 40, "floor": self.floor,
                "nfloors": self.nfloors,
                "rows": [{"path": "x.md", "a": LINE_THRESHOLD, "d": 0, "size": self.big,
                          "flag": True, "why": []}]}


def flags(res):
    return sorted(r["path"] for r in res["rows"] if r["flag"])


def refuses(fn):
    try:
        fn()
    except Refusal as exc:
        return str(exc)
    return None


def status(body):
    return note_block(body)[0]


def arms_predicate(t):
    def whole():
        repo, base, head = t.fixture("whole")
        res = evaluate(repo.root, base, head)
        return (flags(res) == ["ref/big.md"] and res["floor"] == t.floor and res["nfloors"] == t.nfloors,
                "positive control: +{} -0 on a file of {} B flags it; the fixture's re-emitted "
                "declaration reads floor {} from {} key(s), as the real one does".format(
                    LINE_THRESHOLD, t.big, res["floor"], res["nfloors"]))
    t.arm("ST-WHOLE", whole)

    def printed():
        repo, base, head = t.fixture("print")
        lines = []
        grade(evaluate(repo.root, base, head), "", lines.append)
        hit = [l for l in lines if " FLAG " in l]
        pat = r"FLAG  \+{} -0  ratio 0\.000  size-at-merge-base \d+  ref/big\.md$".format(LINE_THRESHOLD)
        return (len(hit) == 1 and re.search(pat, hit[0]) is not None,
                "the FLAG line carries both counts, the ratio, the base size and the file")
    t.arm("ST-PRINT", printed)
    t.arm("ST-ESCAPE", lambda: (show("a\nb\x1b.md") == "a\\x0ab\\x1b.md"
                                and show("c\udcff.md") == "c\\xff.md",
                                "a control character or an undecodable byte in a path prints "
                                "escaped, on one line"))

    for label, kw, want in (
            ("ST-LINES-AT", {"add": LINE_THRESHOLD}, ["ref/big.md"]),
            ("ST-LINES-UNDER", {"add": LINE_THRESHOLD - 1}, []),
            ("ST-DELETIONS-UNDER", {"add": 100, "delete": 19}, ["ref/big.md"]),
            ("ST-DELETIONS-AT", {"add": 100, "delete": 20}, []),
            ("ST-FLOOR-AT", {"size": t.floor}, ["ref/big.md"]),
            ("ST-FLOOR-UNDER", {"size": t.floor - 1}, [])):
        def one(label=label, kw=kw, want=want):
            repo, base, head = t.fixture(label.lower(), **kw)
            got = flags(evaluate(repo.root, base, head))
            return got == want, "{} -> flagged {}".format(kw, got)
        t.arm(label, one)

    def aggregate():
        repo = t.repo("aggregate")
        repo.write("ref/one.md", lines_of(t.big, "o"))
        repo.write("ref/two.md", lines_of(t.big, "t"))
        base = repo.commit("base")
        repo.branch("pr", base)
        for p in ("ref/one.md", "ref/two.md"):
            repo.write(p, repo.read(p) + added(60, "a"))
        res = evaluate(repo.root, base, repo.commit("pr"))
        total_a = sum(r["a"] for r in res["rows"])
        total_d = sum(r["d"] for r in res["rows"])
        return (flags(res) == [] and total_a >= LINE_THRESHOLD
                and total_d * 100 < total_a * DELETION_PERCENT,
                "silent, while the summed reading (+{} -{}) would cross every threshold".format(
                    total_a, total_d))
    t.arm("ST-AGGREGATE", aggregate)

    def phantom():
        repo = t.repo("phantom")
        repo.write("ref/big.md", lines_of(t.big, "b"))
        repo.write("ref/small.md", lines_of(500, "s"))
        fork = repo.commit("base")
        repo.branch("pr", fork)
        repo.write("ref/small.md", repo.read("ref/small.md") + "one more line\n")
        head = repo.commit("pr")
        repo.switch("main")
        repo.write("ref/big.md", "".join(repo.read("ref/big.md").splitlines(True)[150:]))
        tip = repo.commit("main deletes 150 lines")
        res = evaluate(repo.root, tip, head)
        two = git(repo.root, "diff", "--numstat", "--no-renames", tip, head, "--", "ref/big.md")[1]
        return (flags(res) == [] and two.decode().split()[:2] == ["150", "0"],
                "silent over the merge base, while base-tip..head shows ref/big.md +150 -0 (phantom)")
    t.arm("ST-TWO-DOT-PHANTOM", phantom)

    def mask():
        repo = t.repo("mask")
        repo.write("ref/big.md", lines_of(t.big, "b"))
        fork = repo.commit("base")
        repo.branch("pr", fork)
        repo.write("ref/big.md", repo.read("ref/big.md") + added(120, "p"))
        head = repo.commit("pr adds 120")
        repo.switch("main")
        repo.write("ref/big.md", repo.read("ref/big.md") + added(150, "m"))
        tip = repo.commit("main adds 150")
        res = evaluate(repo.root, tip, head)
        two = git(repo.root, "diff", "--numstat", "--no-renames", tip, head, "--", "ref/big.md")[1]
        return (flags(res) == ["ref/big.md"] and two.decode().split()[:2] == ["120", "150"],
                "flagged over the merge base, while base-tip..head shows +120 -150 and would hide it")
    t.arm("ST-TWO-DOT-MASK", mask)

    def changelog():
        repo = t.repo("changelog")
        repo.write("CHANGELOG.md", lines_of(t.big, "c"))
        repo.write("NOTES.md", lines_of(t.big, "n"))
        base = repo.commit("base")
        repo.branch("pr", base)
        for p in ("CHANGELOG.md", "NOTES.md"):
            repo.write(p, added(150, "a") + repo.read(p))
        res = evaluate(repo.root, base, repo.commit("pr"))
        return (flags(res) == ["NOTES.md"] and "CHANGELOG.md" not in [r["path"] for r in res["rows"]],
                "CHANGELOG.md never enters the rows; NOTES.md, given the same +150, flags")
    t.arm("ST-CHANGELOG", changelog)

    def changelog_nested():
        repo = t.repo("changelog-nested")
        repo.write("CHANGELOG.md", lines_of(t.big, "c"))
        repo.write("docs/CHANGELOG.md", lines_of(t.big, "d"))
        base = repo.commit("base")
        repo.branch("pr", base)
        for p in ("CHANGELOG.md", "docs/CHANGELOG.md"):
            repo.write(p, added(150, "a") + repo.read(p))
        res = evaluate(repo.root, base, repo.commit("pr"))
        return ([r["path"] for r in res["rows"]] == ["docs/CHANGELOG.md"] and flags(res) == ["docs/CHANGELOG.md"],
                "only the root CHANGELOG.md is excluded: docs/CHANGELOG.md, given the same +150, enters "
                "the rows and flags as ordinary content")
    t.arm("ST-CHANGELOG-NESTED", changelog_nested)

    def new_file():
        repo = t.repo("newfile")
        repo.write("ref/big.txt", lines_of(t.big, "x"))
        base = repo.commit("base")
        repo.branch("pr", base)
        repo.write("ref/fresh.md", added(500, "f"))
        repo.write("ref/big.txt", repo.read("ref/big.txt") + added(500, "a"))
        res = evaluate(repo.root, base, repo.commit("pr"))
        fresh = [r for r in res["rows"] if r["path"] == "ref/fresh.md"]
        return (flags(res) == [] and len(fresh) == 1 and "new file" in fresh[0]["why"]
                and all(r["path"] != "ref/big.txt" for r in res["rows"]),
                "a new file's row is read and passed as new; big.txt never enters the rows")
    t.arm("ST-NEW-FILE", new_file)

    # The floor and the file's size are read at the merge base, and at neither of the two other
    # commits the range names. The head raises every floor above the file; then main moves past the
    # fork, as ST-ENTRY moves it, raising every floor to a third value and cutting the file under
    # the merge base's floor. A read at the head or at the base tip, of the declaration or of the
    # size, leaves the file unflagged, and the floor it reports names which commit was read.
    def floor_at_merge_base():
        repo = t.repo("floor-at-merge-base")
        repo.write("ref/big.md", lines_of(t.big, "b"))
        fork = repo.commit("base")
        repo.branch("pr", fork)

        def declaring(floor):
            out = []
            for line in t.params.split("\n"):
                row = fence_row(line)
                if row and row[0].endswith(".floor") and re.fullmatch(r"[0-9]+", row[1]):
                    line = "{} {}".format(row[0], floor)
                out.append(line)
            return "# parameters\n\n```" + PARAM_TAG + "\n" + "\n".join(out) + "```\n"
        repo.write(PARAM_DOC, declaring(t.big + 1))
        repo.write("ref/big.md", repo.read("ref/big.md") + added(LINE_THRESHOLD, "a"))
        head = repo.commit("pr raises every floor and adds to ref/big.md")
        at_head = floor_from_text(repo.read(PARAM_DOC))
        repo.switch("main")
        repo.write(PARAM_DOC, declaring(t.big + 2))
        repo.write("ref/big.md", lines_of(t.floor - 1, "b"))
        tip = repo.commit("main raises every floor again and cuts ref/big.md under the floor")
        at_tip = floor_from_text(repo.read(PARAM_DOC))
        tip_size = int(git(repo.root, "cat-file", "-s", tip + ":ref/big.md")[1].decode().strip())
        res = evaluate(repo.root, tip, head)
        row = [r for r in res["rows"] if r["path"] == "ref/big.md"]
        return (res["mb"] == fork and res["base"] == tip and fork != tip
                and flags(res) == ["ref/big.md"] and res["floor"] == t.floor
                and len(row) == 1 and row[0]["size"] == t.big
                and at_head == (t.big + 1, t.nfloors) and at_tip == (t.big + 2, t.nfloors)
                and tip_size < t.floor,
                "the head declares every floor {} B and the base tip, past the fork, {} B, both above "
                "the file's {} B, and the base tip cuts the file to {} B; flagged {} against floor {} "
                "at a size of {} B, which must be the merge base's {} and {}: a pull request is graded "
                "by neither the declaration it edits nor one main wrote after it forked".format(
                    at_head[0], at_tip[0], t.big, tip_size, flags(res), res["floor"],
                    row[0]["size"] if row else None, t.floor, t.big))
    t.arm("ST-FLOOR-AT-MERGE-BASE", floor_at_merge_base)


def orphan_repo(t, name):
    repo = t.repo(name)
    repo.write("a.md", "a\n")
    base = repo.commit("main")
    git(repo.root, "checkout", "-q", "--orphan", "other")
    repo.write("b.md", "b\n")
    return repo, base, repo.commit("unrelated")


def arms_refusals(t):
    def no_merge_base():
        repo, base, other = orphan_repo(t, "orphan")
        why = refuses(lambda: evaluate(repo.root, base, other))
        return bool(why and "no merge base" in why), "refused: {}".format(why)
    t.arm("ST-NO-MERGE-BASE", no_merge_base)

    def absent_commit():
        repo, base, _ = t.fixture("absent")
        why = refuses(lambda: evaluate(repo.root, base, "0" * 40))
        return bool(why and "not present" in why), "refused: {}".format(why)
    t.arm("ST-ABSENT-COMMIT", absent_commit)

    def floors_diverge():
        why = refuses(lambda: floor_from_text("```{}\na.floor {}\nb.floor {}\n```\n".format(
            PARAM_TAG, t.floor, t.floor + 1)))
        return bool(why and "differ" in why), "refused: {}".format(why)
    t.arm("ST-FLOORS-DIVERGE", floors_diverge)

    def unreadable():
        why = refuses(lambda: floor_from_text("```{}\na.floor {}B\n```\n".format(PARAM_TAG, t.floor)))
        return bool(why and "whole number" in why), "refused: {}".format(why)
    t.arm("ST-FLOOR-UNREADABLE", unreadable)

    def no_parameters():
        why = refuses(lambda: floor_from_text("no fence here\n"))
        return bool(why and "no floor" in why), "refused: {}".format(why)
    t.arm("ST-NO-PARAMETERS", no_parameters)

    def no_declaration():
        repo = Repo(t.tmp, "bare", None)
        repo.write("a.md", "a\n")
        sha = repo.commit("x")
        why = refuses(lambda: evaluate(repo.root, sha, sha))
        return bool(why and "carries no" in why), "refused: {}".format(why)
    t.arm("ST-NO-DECLARATION", no_declaration)

    # Parity with the suite's fence reader at both edges of the fence.
    def opener_trailing_space():
        exact = "```{}\na.floor {}\n```\n".format(PARAM_TAG, t.floor)
        spaced = "```{} \na.floor {}\n```\n".format(PARAM_TAG, t.floor)
        why = refuses(lambda: floor_from_text(spaced))
        return (bool(why and "no floor is declared" in why) and floor_from_text(exact) == (t.floor, 1),
                "an opener with a trailing space opens no fence, so no rows and a refusal ({}); "
                "the same text without the space reads the floor".format(why))
    t.arm("ST-FENCE-OPENER-TRAILING-SPACE", opener_trailing_space)

    def inner_backticks():
        text = "```{}\na.floor {}\n```text\nb.floor {}\n```\n".format(PARAM_TAG, t.floor, t.floor + 1)
        why = refuses(lambda: floor_from_text(text))
        return (bool(why and "differ" in why and "a.floor" in why and "b.floor" in why),
                "a line opening with three backticks inside the fence closes nothing: both floors "
                "are read, and they differ: {}".format(why))
    t.arm("ST-FENCE-INNER-BACKTICKS", inner_backticks)


def arms_reader(t):
    template = t.template

    def template_arm():
        st, info = note_block(template)
        lines = read_lines(template)
        between = [] if info["refs"] is None or info["end"] is None else lines[info["end"] + 1:info["refs"]]
        return (st == "empty" and info["head"] is not None and info["why"] == "thematic break"
                and info["refs"] is not None and info["end"] < info["refs"]
                and all(not text.strip() for _, text in between),
                "the real template: heading present, placeholder reads empty, the block ends at "
                "the --- above Issue References")
    t.arm("ST-TEMPLATE", template_arm)

    filled = template.replace("## Integration note\n",
                              "## Integration note\n\nMerged the two duplicate tables into one.\n", 1)
    t.arm("ST-NOTE-CONTENT", lambda: (status(filled) == "present",
                                      "the template with one sentence typed into the note reads present"))
    t.arm("ST-NOTE-ABSENT", lambda: (status("## Summary\n\nWhat changed.\n") == "absent",
                                     "no heading reads absent"))

    end_rule = "## Integration note\n\n<!-- asked for on a flag -->\n\n---\n\n### Issue References\n\nCloses #N\n"

    def end_rule_arm():
        naive = [text for _, text in read_lines(end_rule)[1:]]
        return (status(end_rule) == "empty" and any(ch.isalnum() for l in naive for ch in l),
                "an empty note above --- and the issue lines reads empty; read to end-of-body it "
                "would not")
    t.arm("ST-END-RULE", end_rule_arm)
    t.arm("ST-END-HEADING", lambda: (status(end_rule.replace("---\n\n", "", 1)) == "empty",
                                     "with the --- deleted, the block ends at the Issue References heading"))
    t.arm("ST-END-NEXT-SECTION", lambda: (status("## Integration note\n\n## Checklist\n\n- done\n") == "empty",
                                          "a heading straight after the note ends it"))
    t.arm("ST-END-OF-BODY", lambda: (status("## Integration note\nSuperseded the old list.") == "present",
                                     "a note running to end-of-body is read"))
    t.arm("ST-CRLF", lambda: (status(filled.replace("\n", "\r\n")) == "present"
                              and status(end_rule.replace("\n", "\r\n")) == "empty",
                              "CRLF bodies read as their LF twins"))

    def fence_arm():
        fenced = "## Integration note\n```text\n# not a heading\n---\n```\nRemoved the duplicate table.\n\n---\nafter\n"
        st, info = note_block(fenced)
        return (st == "present" and info["end"] == 7,
                "headings and rules inside a fence are content; the block ends at line {}".format(
                    (info["end"] or 0) + 1))
    t.arm("ST-FENCE", fence_arm)
    t.arm("ST-PUNCTUATION", lambda: (status("## Integration note\n-\n\n---\n") == "empty",
                                     "a lone bullet is not a note"))
    t.arm("ST-COMMENT-FIRST", lambda: (
        status("## Integration note\n<!--\n---\n# x\n-->\nKept the old table; it is still read.\n---\n") == "present",
        "a --- or # inside a comment neither ends nor opens the note"))
    t.arm("ST-UNTERMINATED-COMMENT", lambda: (
        status("## Integration note\n<!-- started\nand never closed\n") == "empty",
        "a line-leading comment never closed runs to end-of-body, as GitHub renders that form"))
    t.arm("ST-HEADING-IN-FENCE", lambda: (status("```\n## Integration note\nx\n```\n") == "absent",
                                          "a heading inside a fence is not the note"))
    t.arm("ST-LENIENT", lambda: (status("### integration NOTE:\nMerged.\n") == "present",
                                 "any level, any case, a trailing colon"))

    def below_refs():
        lines = []
        grade(t.flagged_result(),
              "### Issue References\n\nCloses #N\n\n## Integration note\nSuperseded the old list.\n",
              lines.append)
        return (any("WARNING: the note sits below" in l for l in lines),
                "a note below Issue References is read and warned")
    t.arm("ST-BELOW-REFS", below_refs)

    # One pass over fences and comments together, checked against GitHub's own renderer: each
    # body below renders its note heading and the note's text, and each reads present here.
    t.arm("ST-COMMENT-IN-FENCE", lambda: (status(
        "```\n<!-- an opener quoted in a fence\n```\n\n## Integration note\n\n"
        "Merged the two duplicate tables into one.\n\n<!-- Check all that apply -->\n") == "present",
        "an opener inside a fence is literal; it opens no comment, so a later --> pairs with nothing"))
    t.arm("ST-COMMENT-IN-CODE-SPAN", lambda: (status(
        "Quote `<!--` when you mean a comment.\n\n## Integration note\n\n`<!-- superseded -->`\n\n"
        "<!-- trailing template comment -->\n") == "present",
        "an opener in a code span opens nothing, and a whole comment inside a code span is "
        "visible text, so it is kept"))
    t.arm("ST-INLINE-OPENER", lambda: (status(
        "A bare <!-- opener mid-paragraph.\n\n## Integration note\n\n"
        "Merged the two duplicate tables into one.\n\n<!-- trailing template comment -->\n") == "present",
        "an inline opener with no --> on its own line is text, not a comment"))
    t.arm("ST-EMPTY-FENCE", lambda: (status("## Integration note\n```text\n```\n\n---\n") == "empty",
                                     "a fence's delimiter lines, its info string included, are not a note"))
    t.arm("ST-CLOSING-HASHES", lambda: (status("## Integration note ##\nMerged the two duplicate tables into one.\n") == "present",
                                        "a heading with a closing # run is the note's heading"))

    def sub_heading():
        body = "## Integration note\n### What was removed\nThe old table.\n"
        st, info = note_block(body)
        told, untold = [], []
        grade(t.flagged_result(), body, told.append)
        grade(t.flagged_result(), template, untold.append)
        hint = "write the note as plain lines"
        return (st == "empty" and info["why"] == "heading" and any(hint in l for l in told)
                and not any(hint in l for l in untold),
                "a note under a sub-heading reads empty, and the FAIL says why; an empty note "
                "ending at the --- is not told about headings")
    t.arm("ST-SUB-HEADING", sub_heading)

    def remedy():
        lines = []
        rc = grade(t.flagged_result(), "", lines.append)
        text = "\n".join(lines)
        return (rc == 1 and "add the note to this pull request's body now" in text
                and "CONTRIBUTING.md" in text and "--body-file" in text
                and "when the pull request opens" in text,
                "the FAIL names adding the note to the open pull request's body, the "
                "CONTRIBUTING.md exception, and the --body-file run that answers before opening")
    t.arm("ST-REMEDY", remedy)

    def disclaimer():
        # The sentence is written out here rather than read from GRADED: an arm that compared the
        # printed line with the constant would pass whatever the constant said.
        said = "Graded: that a note is present and not empty. Not graded: whether it is true."
        failed, passed = [], []
        grade(t.flagged_result(), "", failed.append)
        grade(t.flagged_result(), filled, passed.append)
        fail_line = [l for l in failed if l.startswith(PREFIX + "FAIL -- ")]
        pass_line = [l for l in passed if l.startswith(PREFIX + "PASS -- ")]
        return (len(fail_line) == 1 and fail_line[0].endswith(said)
                and len(pass_line) == 1 and pass_line[0].endswith(said),
                "a flag's FAIL line and its PASS line each end by saying what is graded and that "
                "whether the note is true is not")
    t.arm("ST-DISCLAIMER", disclaimer)

    def first_heading():
        body = "## Integration note\n\n## Integration note\nMerged the two duplicate tables into one.\n"
        st, info = note_block(body)
        lines = []
        grade(t.flagged_result(), body, lines.append)
        warned = PREFIX + "WARNING: 1 further 'Integration note' heading(s); the first is read"
        return (st == "empty" and info["head"] == 0 and info["extra"] == 1 and warned in lines,
                "two note headings, the first empty: the first is the note, so it reads empty, and "
                "the second is warned about rather than read")
    t.arm("ST-FIRST-HEADING", first_heading)

    # Declared residuals, named in the docstring's THE NOTE paragraph: three forms GitHub renders as
    # a note that this reader does not model. Each arm pins today's reading beside a twin the reader
    # does read, so the disagreement is declared, and a change to the reader on these forms is a
    # visible change rather than a silent one.
    t.arm("ST-RESIDUAL-SETEXT", lambda: (
        status("Integration note\n----------------\nMerged the two duplicate tables into one.\n") == "absent"
        and status("## Integration note\nMerged the two duplicate tables into one.\n") == "present",
        "declared residual: a setext heading, which GitHub renders, is no heading here and reads "
        "absent; its ## twin reads present"))
    t.arm("ST-RESIDUAL-BLOCKQUOTE", lambda: (
        status("> ## Integration note\n> Merged the two duplicate tables into one.\n") == "absent"
        and status("## Integration note\nMerged the two duplicate tables into one.\n") == "present",
        "declared residual: a heading inside a blockquote, which GitHub renders, is no heading here "
        "and reads absent; the same lines outside the blockquote read present"))
    t.arm("ST-RESIDUAL-INDENTED-CODE", lambda: (
        status("## Integration note\n\n    <!-- kept the old table -->\n") == "empty"
        and status("## Integration note\n\n    kept the old table\n") == "present",
        "declared residual: a note that is an indented code block holding a comment, which GitHub "
        "shows as text, reads empty; the same block holding the words alone reads present"))


def arms_exit(t):
    filled = t.template.replace("## Integration note\n",
                                "## Integration note\n\nMerged the two duplicate tables into one.\n", 1)

    def e2e():
        repo, base, head = t.fixture("e2e")
        quiet = []
        codes = tuple(check(repo.root, base, head, body, quiet.append) for body in ("", t.template, filled))
        repo, base, head = t.fixture("e2e-quiet", add=10)
        codes += (check(repo.root, base, head, "", quiet.append),)
        return (codes == (1, 1, 0, 0),
                "flag+no body, flag+template, flag+note, no flag -> exits {}".format(codes))
    t.arm("ST-E2E", e2e)

    def separation():
        repo, base, other = orphan_repo(t, "separation-orphan")
        refused, flagged = [], []
        rc_refusal = check(repo.root, base, other, "", refused.append)
        repo, base, head = t.fixture("separation")
        rc_flag = check(repo.root, base, head, "", flagged.append)
        errors = {l for l in refused + flagged if l.startswith("::error::")}
        return (rc_refusal == 2 and rc_flag == 1 and REFUSAL_ERROR in refused
                and not any(l.startswith("::error::integration note ") for l in refused)
                and any(l.startswith("::error::integration note ") for l in flagged)
                and REFUSAL_ERROR not in flagged and len(errors) == 2 and SELF_TEST_ERROR not in errors,
                "a refusal exits {} and a flag with no note exits {}, each with its own ::error:: "
                "line, and neither is the self-test's".format(rc_refusal, rc_flag))
    t.arm("ST-EXIT-SEPARATION", separation)

    # The process entry the workflow step runs: main, then run_check, which reads the environment
    # and hands the exit status back to the shell. Every arm above calls check() in-process; this one
    # runs this file as a subprocess, copied into a fixture repository's scripts/ so its root resolves
    # there, from a working directory outside that repository, with argv --check alone and an
    # environment holding PATH, the self-test's isolated git settings and the three PR_ variables
    # and nothing else. The base tip has moved past the fork, so the range line's base is not its
    # merge base, and the order it names them in is read.
    def entry():
        repo, fork, head = t.fixture("entry")
        repo.switch("main")
        repo.write("ref/small.md", repo.read("ref/small.md") + "one more line\n")
        tip = repo.commit("main moves past the fork")
        copy = os.path.join(repo.root, "scripts", os.path.basename(__file__))
        os.makedirs(os.path.dirname(copy), exist_ok=True)
        shutil.copyfile(os.path.abspath(__file__), copy)

        def run(body):
            env = dict(ISOLATED, PATH=os.environ.get("PATH", os.defpath),
                       PR_BASE_SHA=tip, PR_HEAD_SHA=head, PR_BODY=body)
            proc = subprocess.run([sys.executable, copy, "--check"], cwd=t.tmp, env=env,
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, timeout=300)
            return proc.returncode, proc.stdout.decode("utf-8", "replace").splitlines()
        rc_bare, bare = run("")
        rc_note, noted = run(filled)
        span = PREFIX + "range {}..{} (merge base of base {} and head {})".format(
            fork[:12], head[:12], tip[:12], head[:12])
        return (rc_bare == 1 and FLAG_ERROR.format("absent", 1) in bare and span in bare
                and rc_note == 0 and span in noted
                and any(l.startswith(PREFIX + "PASS -- 1 file(s) flagged") for l in noted),
                "run as the step runs it, from PR_BASE_SHA, PR_HEAD_SHA and PR_BODY alone: a flag "
                "with an empty body exits {} and with a note exits {}, and the range line names "
                "the merge base, then the base, then the head".format(rc_bare, rc_note))
    t.arm("ST-ENTRY", entry)


def self_test(root):
    """Exit 0 when every arm passes, 1 when one misread, 2 when the self-test could not run."""
    try:
        with open(os.path.join(root, PARAM_DOC), encoding="utf-8") as fh:
            real = fh.read()
        floor, nfloors = floor_from_text(real)
        # The fixtures' declaration is re-emitted from the real one by the same fence grammar,
        # so every boundary arm runs at the declared floor and no fixture states one of its own.
        params = "".join(line + "\n" for line in fence_lines(real))
        with open(os.path.join(root, TEMPLATE), encoding="utf-8") as fh:
            template = fh.read()
    except (OSError, UnicodeDecodeError, Refusal) as exc:
        print("SELF-TEST NOT EVALUATED -- a file this job reads could not be read: {}".format(
            show(str(exc))))
        return 2
    saved = dict(os.environ)
    for key in list(os.environ):
        if key.startswith("GIT_"):
            del os.environ[key]
    os.environ.update(ISOLATED)
    tmp = None
    try:
        tmp = tempfile.mkdtemp(prefix="integration-note-selftest-")
        git(tmp, "--version")
        t = Arms(tmp, params, floor, nfloors, template)
        for group in (arms_predicate, arms_refusals, arms_reader, arms_exit):
            group(t)
    except (OSError, Refusal) as exc:
        print("SELF-TEST NOT EVALUATED -- the self-test could not run: {}".format(show(str(exc))))
        return 2
    finally:
        if tmp:
            shutil.rmtree(tmp, ignore_errors=True)
        os.environ.clear()
        os.environ.update(saved)
    passed = sum(1 for ok in t.results if ok)
    print("SELF-TEST: {} of {} arms passed".format(passed, len(t.results)))
    return 0 if t.results and passed == len(t.results) else 1


class Parser(argparse.ArgumentParser):
    def error(self, message):
        print(__doc__)
        print(PREFIX + "usage: " + message)
        sys.exit(2)


def main(argv):
    parser = Parser(add_help=False, allow_abbrev=False)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--self-test", action="store_true")
    parser.add_argument("--base")
    parser.add_argument("--head")
    parser.add_argument("--body-file")
    parser.add_argument("--root")
    args = parser.parse_args(argv)
    if args.self_test:
        if args.base is not None or args.head is not None or args.body_file is not None:
            parser.error("--base, --head and --body-file apply to --check only")
        rc = self_test(args.root or repo_root())
        if rc:
            print(SELF_TEST_ERROR)
        return rc
    if args.root is not None:
        parser.error("--root applies to --self-test only")
    return run_check(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
