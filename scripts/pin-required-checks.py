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
    2  input was malformed (a read that returned a shape with no checks array)
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

    out("")
    out("-" * 78)
    if failures:
        out("SELF-TEST FAILED -- {} arm(s):".format(len(failures)))
        for f in failures:
            out("  " + f)
        return 1
    out("SELF-TEST PASSED -- 11 degenerate arms all failed on exactly their named "
        "conjuncts, the positive arm passed, every named conjunct is individually "
        "load-bearing, and every capture failure refused the write.")
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
    rsc_path = prot_path + SUBRESOURCE_SUFFIX
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
    ap.add_argument("--staging", help="directory for the capture artifacts")
    ap.add_argument("--repo", help="OWNER/NAME; default: the origin remote")
    ap.add_argument("--branch", default="main")
    ap.add_argument("--confirm-write", dest="confirm", action="store_true",
                    help="required before any write is attempted")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()

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
