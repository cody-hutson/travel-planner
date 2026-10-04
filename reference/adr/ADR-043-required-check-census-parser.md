# ADR-043: The required-check census reads a parsed document — PyYAML on the runner, a marker read from the comment layer, and a refusal wherever it cannot vouch

- **Status:** Accepted (2026-10-04)
- **Deciders:** repo maintainer
- **Driving work:** the *release scaffolding grades itself* milestone — the card that re-implements
  the registration census in `scripts/pin-required-checks.py` against a YAML parser.

## Context

`scripts/pin-required-checks.py --census` is the one assertion over the required-check set that
runs with no token. Every job under `.github/workflows/` says in place whether it binds a merge,
on a `# gate-efficacy: posture=` comment above its key, and the census compares the jobs that claim
`required` with the script's `CONTEXT_ORDER` declaration in both directions. It runs in the job
`Workflow SAST (actionlint)` in `.github/workflows/security.yml`, which is itself a required check,
so a red census blocks a merge into `main`.

Until this decision the census read workflow YAML line by line, with patterns and no parser. It
asks about YAML *values* — which jobs exist, and what each job reports as its name — and a reader
of lines answers only about lines. At `e743113` the script ran to 4,130 lines and its self-test
carried 77 census arms, 11 of which pinned a tree that the line reader read CLEAN at exit 0 and
from which a YAML parser reads a different set of jobs, names or markers. At that commit,
`e743113`, the limit block it printed on every run was 222 lines long. The reviews of the *release
and publish mechanics integrity* milestone, which built that census, kept naming further classes
on which the reader and a parser disagree. None of them was live in this repository's workflows,
and the census's own printed text had come to say that the set could not be enumerated.

The card's premise was that a parser closes the generator rather than its members. Where the
parser could come from was already constrained. The census step makes no network call, by an
operator decision that predates this one, and it runs ahead of the actionlint install so that a
network failure there cannot mask a registration finding. So the parser had to be on the runner
image already. That image's published software list names `yq` and does not name PyYAML, and an
availability probe therefore ran before any design: on the release's draft pull request, in the
census job, immediately ahead of the census step, with its result recorded on the card. The
`ubuntu-24.04` image at version `20260927.320.1` carried Python 3.12.3, PyYAML 6.0.1 and `yq`
v4.53.6. The operator's machine, where `--self-test`, `--plan` and `--apply` run, carried PyYAML
6.0.3 under Python 3.9.6, and no `yq`.

The design graded what a parser reads about jobs and their names, and its review found that a
workflow file decides more than that about whether a required check reports at all. GitHub
documents that a job skipped by its own `if:` reports Success, so a required check could pass
without its job running, and that a job skipped because a job it needs failed may not block the
merge. A trigger's `branches:`, `branches-ignore:` and `types:` filters, written as literal names,
decide whether a pull request into `main` runs the workflow at all. The operator widened the card at
the release's engineering stage, so that the census grades what the file decides and its printed
limits keep only what a parser cannot decide.

## Decision drivers

- **Offline, and ahead of the actionlint install.** The census step makes no network call, so its
  parser is something the runner image already carries, and it stays ahead of every install in its
  job, so nothing it needs may arrive in a later step.
- **A parsed document, never guessed lines.** The set of jobs and each job's context come from a
  YAML parser's own reading of the file.
- **What the file decides is graded.** Whether a required job runs on a pull request into `main` is
  decided in part by its workflow file — the trigger, the trigger's filters written as literal
  names, and the job's own `if:` and `needs:` — and the census grades that part. Only what a parser
  cannot decide is printed as a limit.
- **A refusal, never a clean read, where the census cannot vouch.** A missing parser, a file the
  census cannot say it read in full, and a job claiming required whose context, or whose effect on
  the merge, GitHub settles only when it runs end the run at exit 2 with a named reason. Exit 1
  keeps its meaning: the workflows and the declaration disagree.
- **The operator's own runs keep working.** `--plan` and `--apply` run the self-test first and stop
  at exit 5 when it fails, so a parser the operator's machine lacks would stop the tool's write
  path there.
- **The marker grammar stays as it is.** Every job already carries the marker, and `CONTRIBUTING.md`
  tells contributors its grammar.
- **Every new rule fails closed.** Where what GitHub does with a shape was not measured, the census
  refuses or reports a finding. It never reads the shape as clean on an assumption.

## Options considered

**What reads the workflows.**

| Option | What it is | Outcome |
|---|---|---|
| PyYAML, in process | `compose_all` and `scan` under `SafeLoader`, behind the record seam the census already had | **selected** |
| `yq`, as a subprocess | `yq -o=json` on each file, with its line operators for the marker | rejected — the opposing view, below |
| A vendored parser | a pure-Python YAML parser committed under `scripts/` | rejected: thousands of third-party lines in a public repository, outside the only dependency tracker it runs (`SECURITY.md` § *Defenses Currently in Place*), where a parser the image provides plus a refusal reaches the same verdicts |
| A hand-written subset parser | standard-library code for the YAML subset that workflows use | rejected: it is the generator the card retires, a reader whose residual set again cannot be enumerated |
| Both readers, refusing where they disagree | the line reader kept beside a parser | rejected: the limit block would still have to describe the line reader, and each disagreement would become a refusal, bringing back the false refusals a parser removes |
| A shared workflow model | a new module with a typed model for later gates to consume | rejected: a new abstraction with one consumer |
| A parser fetched at run time | actionlint's own parser, `pip install`, or a `setup-python` step | rejected on the standing constraints: actionlint installs after the census by design, `pip` and `setup-python` need the network, and `setup-python` would also put a Python without PyYAML ahead of the system one |
| A fallback chain | PyYAML, else `yq`, else the line reader | rejected: a verdict that depends on which parser the image carries is not one instrument, and a fall-back to lines reopens every closed shape at the moment the parser disappears |

**The opposing view: `yq` is the parser the image lists.** The runner image's published software
list names `yq` and does not name PyYAML, so `yq` is the dependency the image's maintainers have
said they carry. That is the strongest argument against the selected option. It lost on
measurability, on the operator's side and on the marker. `yq` was absent from the operator's
machine, so no census arm could be measured with it before the decision. Choosing it would also
have stopped `--self-test` there, and with it `--plan` and `--apply`, until the operator installed
it. And the marker would have been bound through go-yaml's comment-attachment model, which was not
measured. What PyYAML lacks, a place on the published list, is what the refusal and the runner pin
below exist to carry.

**Where the posture lives.**

| Option | Outcome |
|---|---|
| Keep the comment marker, read it from the scanner's comment layer and bind it to a key the parser located | **selected** |
| Move the posture into the document, as a job-level key | rejected: it rewrites every marker in the repository and the grammar contributors are told, and GitHub validates the keys a job may carry |
| Keep a pattern for "comment": a line whose first non-blank character is `#` | rejected: measured fail-open. A line inside a quoted scalar that begins with `#` and is shaped like a marker is read as the job's answer, and the tree reads CLEAN at exit 0 |

**What the census grades about whether a required job runs.**

| Option | Outcome |
|---|---|
| Grade what the file decides — the `pull_request` trigger, its `branches:`, `branches-ignore:` and `types:` filters written as literal names, and a required job's own `if:` and `needs:` — and print as a limit only what a parser cannot decide | **selected** |
| Leave those shapes in the printed limit block, as cases the census shows and does not grade | rejected: the card asks that the limit block hold only what a parser cannot decide, and a required check could pass without its job running while the census read CLEAN |
| Admit a job claiming required that runs under a job-level `if: always()` over its `needs:`, the pattern GitHub documents for a required check that depends on other jobs | rejected: whether such a job fails when a job it needs fails is decided by its own steps, which the census does not read, so admitting it would trust step logic the census cannot grade |

## Decision

**D1 — The census reads every workflow through PyYAML's pure-Python `SafeLoader`, composed to nodes
and never constructed.** It calls `yaml.compose_all` and `yaml.scan`, and no other function of the
library; `yaml.load` and `yaml.safe_load` are never called. So no object is constructed, a key
written twice survives to be seen, and no scalar is coerced to a boolean or a number — a workflow's
`on` stays text. The C loader is never used, so the reading does not depend on the C bindings.
PyYAML is imported inside one function, `_load_yaml`, and never at module top, so `--assert` and
`--restore` never need it, and the self-test can hand the census a loader that fails. A file is
decoded as UTF-8 and split on YAML 1.1's line-break set rather than with `str.splitlines()`, so a
line index in the census is the parser's own.

**D2 — The marker stays a comment, and it is read from the scanner's comment layer.** No YAML
document carries a comment, so the marker cannot come from the nodes. A line is a comment line when
its first non-blank character is `#` and no token the scanner emitted overlaps it, and the key the
marker binds to is found by the parser's own mark. The grammar is unchanged: exactly one
`# gate-efficacy: posture=required` or `# gate-efficacy: posture=advisory`, as the first line of
the contiguous comment block directly above the job key, at the key line's indentation. More than
one marker in that block binds none. One rule is new, and flow style forces it: a key that does not
begin its own line binds no marker, because keys that share a line would share an answer.

**D3 — Exit 2 means "the census cannot vouch", and every refusal carries a code.** The codes are
the module constant `REFUSAL_CODES`. A refusal prints its code and a remedy, and names the file
where the refusal is a file's. At `6e801e2` that constant holds 18 codes:

- for the run: `NO-PARSER`, when loading PyYAML fails with an import error or with any other
  exception; and `NO-WORKFLOWS`, when there is no workflow file to read;
- for a file as bytes and as a stream: `UNREADABLE`, when it cannot be opened and decoded as UTF-8;
  `YAML11-BREAK`, when it carries U+0085, U+2028 or U+2029, which YAML 1.1 reads as the end of a
  line and YAML 1.2 reads as content; `UNPARSEABLE`, when composing or scanning it raises a YAML
  error or any other exception, the `RecursionError` of deep nesting among them; and
  `NOT-ONE-DOCUMENT`, when the stream holds anything other than one document;
- for the document's shape: `NO-JOBS`, `NO-JOB`, `KEY-TWICE`, `MERGE-KEY`, `KEY-NOT-TEXT`,
  `JOB-NOT-MAPPING` and `NAME-NOT-TEXT`;
- for a job that claims required and whose context GitHub computes when it runs: `RUNTIME-NAME`,
  for a `name:` carrying an expression; `RUNTIME-MATRIX`, for a `strategy`; and `RUNTIME-REUSABLE`,
  for a call to a reusable workflow;
- for a job that claims required and that GitHub can skip without its check blocking the merge:
  `RUNTIME-CONDITION`, for a job-level `if:` — a step-level `if:` does not skip the job and is not
  read; and `RUNTIME-NEEDS`, for a `needs:` naming a job that does not itself claim required in the
  same file, a job the file does not hold, or no job as text.

A refusal is never a finding. A finding says the workflows and the declaration disagree, and the
census cannot establish a disagreement about a file it did not read in full, about a name GitHub
has not computed yet, or about a job GitHub may skip without blocking the merge. The catch-alls
behind `NO-PARSER` and `UNPARSEABLE` exist for the same reason: an exception left to escape would
end the run at exit 1, the finding code. A refused file does not stop the others from being read,
so one run names every file at fault, and any refusal withholds the verdict for the whole run. The
run-time refusals bind jobs that claim required only, so an advisory matrix job stays legal, and so
does an advisory job carrying an `if:` or a `needs:`. `RUNTIME-CONDITION`'s remedy is to drop the
job-level `if:` or to declare the job advisory, and `RUNTIME-NEEDS`'s is to have each job it needs
claim required too, or to drop the dependency. `NAME-NOT-TEXT` is an accepted false refusal:
actionlint accepts an empty `name:`, and what GitHub reports for one was not measured.

**D4 — `DUPLICATE`: a context that more than one job reports.** For each context the census counts
every job that reports it, whatever its posture, and reports a finding when that context is
declared or when any of those jobs claims required. The finding names every job. Where one job
claims the context, the others are named as the jobs that shadow it. Where several claim it, each
shadows the others, and the declaration cannot say which one binds. Where none claims it, the
reporters are named and `ABSENT` is reported beside the finding. Which of those jobs' check runs
GitHub counts for the context was not measured, and the finding says so rather than asserting that
any of them satisfies it. Set equality alone cannot see this: a second job claiming a context that
is already claimed leaves the set of claimed contexts unchanged.

**D5 — `UNTRIGGERED`: a job claiming required in a workflow that a pull request into `main`, or a
push to one, does not run, as far as the file decides it.** The census reports such a job when its
workflow's `on:` names no `pull_request` event, written as a scalar, a sequence or a mapping; when
that trigger's `branches:` filter names no `main` and carries no pattern; when its
`branches-ignore:` filter names `main` and holds no entry that opens with `!`; and when its `types:`
filter names no `synchronize`. Each leaves the check with no run to report from, on a pull request
into `main` or on the head commit a push to one makes, so the requirement would wait for ever. A
filter written as a single name is read as a list of one. A pattern is an entry carrying `*`, `?`,
`+`, `[`, `]` or `\`, or opening with `!`, the characters GitHub's filter-pattern grammar gives a
meaning. A `branches:` filter carrying one is left to that grammar, and so is a `branches-ignore:`
filter holding an entry that opens with `!`, which can negate an earlier entry; any other pattern
beside a literal `main` in a `branches-ignore:` filter leaves `main` shut out, so it defers nothing.
A `branches:` or `types:` filter in a shape GitHub's schema does not give it names nothing, so it
admits nothing; such a `branches-ignore:` filter, or a trigger whose value is neither null nor a
mapping, is the schema's question, which actionlint answers in the same job. `pull_request_target`
and `merge_group` are not admitted, because whether their check runs land on a pull request's head
commit was not measured; a required job triggered only by one of them reads `UNTRIGGERED`, which
fails closed.

**D6 — There is no fall-back.** Where the parser cannot be loaded the census refuses, `NO-PARSER`,
having read nothing. It never reads lines instead. In the self-test the census group then reports
itself `NOT-EVALUATED` and fails, and never reports a pass over arms it did not run.

**D7 — The limit statement is structural limits with measured instances, and no count.** The
census prints it on every exit path, a refusal included. Its last part is headed *WHAT A PARSER
CANNOT DECIDE* and keeps only what no reading of the file decides: whether a pull request touches a
path that a `paths:` filter names, which only that pull request's diff settles; whether a pattern in
a branch filter matches `main`, which is GitHub's filter grammar to decide and which this census
does not evaluate; and the context that a job not claiming required reports when its `name:` is
computed at run time, which is compared with no declared context. Each reads CLEAN, and each is
stated with GitHub's documented outcome: for a `paths:` filter or a branch pattern, a check left
pending and a merge blocked; for a computed name, a context reported beside the job that claims it,
where which of their check runs GitHub counts was not measured. Each outcome is documented
behaviour that this census did not measure. A self-test arm holds each case at its CLEAN, and the
block cites them: X96 for the `paths:` filter, X116, X119 and X120 for a branch pattern, and X105
for the computed name. The same part says that GitHub's own parser was not run, and that the
workflow schema is actionlint's to check, in the same job. What the file decides — the trigger, its
filters written as literal names, and a required job's own `if:` and `needs:` — is graded under D3
and D5 and is not printed as a limit. The limit that predates the parser stands above them all: the
token CI runs with cannot read branch protection, so no census confirms that a context is
registered.

**D8 — The census stays strict on a required job that runs under `always()` over its needs.**
GitHub documents a pattern for a required check that depends on other jobs: a job that claims the
check, `needs:` the others and runs under a job-level `if: always()`, so that it reports even when
one of them fails. `RUNTIME-CONDITION` and `RUNTIME-NEEDS` both refuse that shape — the first for
its `if:`, and, written without one, the second wherever a job it needs does not itself claim
required. Whether such a job fails when a job it needs fails is decided by its own steps, which
this census does not read, so admitting the shape would trust step logic the census cannot grade
and move the fail-open D3 closes one job over. The operator kept the census strict on this shape at
the release's plan review. A required check that depends on other jobs is therefore written
without the `if:`, over jobs that each claim required themselves, or is declared advisory.

### How a census verdict reaches a merge

| Step | From | To | What passes |
|---|---|---|---|
| 1 | each `*.yml` and `*.yaml` file directly under `.github/workflows/` | PyYAML `SafeLoader` — `compose_all` and `scan` | the node graph with its marks, and the token stream |
| 2 | nodes and token spans | `_read_workflow` | one record for each job: key, context, posture, whether a pull request into `main` runs it — or a refusal |
| 3 | records | `census_findings`, or a refusal | finding codes, or a refusal code |
| 4 | `census_verdict` | `run_census` | exit 0, 1 or 2, and the printed report |
| 5 | the exit status | step *Required-check registration census* | the step's conclusion |
| 6 | the step | job `Workflow SAST (actionlint)` | the job's conclusion |
| 7 | the job | branch protection on `main` | a required context: red blocks the merge |
| 8 | `SECURITY.md` § *Branch Protection Posture* | `--self-test` group F | set equality with `CONTEXT_ORDER`, in both directions; a failure enters step 5, because the step runs the self-test ahead of the census and fails when either fails |

## Consequences

- **The self-test's census arms were graded again, and none moved toward CLEAN.** Of the 77 arms
  the self-test carried at `e743113`, 48 moved to the verdict their tree owes under a parser and 29
  kept the verdict they had, and each of the 11 that had pinned a CLEAN at exit 0 now wants a
  finding. At `3267f43`, the commit that shipped the parser census, the self-test carried 111
  census arms and the census 16 refusal codes. Grading what the file decides moved X97, X98, X106
  and X107, each of which had pinned a limit at CLEAN, to the finding or refusal its tree now gets,
  and each new rule gained an arm that must fire and an arm that must not. At `6e801e2` the
  self-test carries 121 census arms, and the census 18 refusal codes and 5 finding codes. Every
  finding code and every refusal code is named by an arm, checked in both directions, and an arm
  that wants exit 2 names the refusal it wants, so a file refused for the wrong reason fails its
  arm.
- **The limit block shrank to what it can state as structure.** It went from 222 printed lines at
  `e743113` to 56 at `3267f43`, and to 52 at `6e801e2`, where it keeps only what a parser cannot
  decide. Every text the census prints is a module constant, and the self-test's count guard reads
  each of them.
- **The census depends on a package the runner image carries and does not list, and the refusal
  carries its absence.** Without PyYAML the census exits 2, `NO-PARSER`, and reads nothing. The
  remedy it prints turns on which interpreter failed, read from that interpreter's path as written.
  When the system `python3` fails, the image no longer carries PyYAML, and the remedy is a reviewed
  decision about the runner or the parser, made in a pull request of its own. When any other
  interpreter fails, a Python without PyYAML sits ahead of the system one on `PATH`, and the remedy
  is to run the census under a `python3` that carries it. The path is not resolved first, because a
  virtual environment's `python3` links to the system one and is exactly the second cause.
- **The census job is pinned to `ubuntu-24.04`, so an OS move is a reviewed pull request.** That is
  the image the probe measured, and the census depends on a package it carries and does not list.
  Moving the job to another image is therefore a change somebody proposes, and on that pull request
  the census step itself proves the parser again, on the new image. The floating `ubuntu-latest`
  label would instead have moved the job on GitHub's schedule, to an image nobody had probed. The
  pin fixes the operating-system release and not the image within it: images roll within the
  pinned label, so a run reads through the PyYAML its own image carries, and the version it prints
  says which. The operator chose the pin at the milestone's Collective Review, over probing the
  label's next image once and keeping the label. The cost is that the job differs from the other
  jobs in its file, and that a deliberate pull request is owed when that image retires.
- **A `setup-python` step ahead of the census step breaks it, and the step says so.** Such a step
  puts a Python without PyYAML first on `PATH`. The census then refuses at exit 2 and the self-test
  reports its census group `NOT-EVALUATED`. The step's comment in `.github/workflows/security.yml`
  records this where the edit would be made.
- **A red census does not hide actionlint.** `UNPARSEABLE`'s remedy points at actionlint in the
  same job, so the actionlint steps run even when the census step fails. The job still fails.
- **The census prints which parser graded the run.** The design was measured under PyYAML 6.0.3 on
  Python 3.9.6, and the runner image carried 6.0.1 on Python 3.12.3. Only the scanner and composer
  of the pure-Python loader are used, each clean or finding run prints the PyYAML version it read
  through, and the census step runs the self-test's census arms on the runner's own parser on every
  pull request into `main`.
- **What a job that claims required must look like.** To read CLEAN it needs its marker as the
  first line of the comment block directly above its key; a literal `name:` that `CONTEXT_ORDER`
  carries, or no `name:` and a key that `CONTEXT_ORDER` carries; no `strategy`, no call to a
  reusable workflow and no job-level `if:`; a `needs:` naming only jobs that claim required too, or
  none; a workflow that `pull_request` triggers, with no literal `branches:` list that leaves out
  `main`, no literal `branches-ignore:` list that names it and no `types:` list that leaves out
  `synchronize`; and a context no other job reports. For its check to report on every pull request
  into `main`, which the census does not grade, its `pull_request` trigger must also carry no
  `paths:` filter and no branch pattern that leaves out `main`.
- **The limits the census does not grade stay open, and each is pinned.** A self-test arm holds
  each named case at the CLEAN the census gives it today, so a later change that grades one turns
  its arm red and has to re-label it.
- **Registration is still the operator's act.** Nothing here confirms that a context is registered
  in branch protection, and the census says so on every run.

## References

- `scripts/pin-required-checks.py` — the census, its finding and refusal codes, the texts it
  prints, its limit block, and the self-test's census arms and guards
- `.github/workflows/security.yml` — the step *Required-check registration census* in the job
  `Workflow SAST (actionlint)`, its runner pin and the comment above it
- `SECURITY.md` § *Branch Protection Posture* — the required-check list the self-test holds to
  `CONTEXT_ORDER`; § *Defenses Currently in Place* — what the dependency tracker reaches
- `CONTRIBUTING.md` — what a contributor adding or renaming a workflow job is told about the census
- [`ADR-013`](ADR-013-count-assertion-basis.md) — a count carries a basis that can be re-derived:
  why the limit statement carries no count, and why each count in this record names its commit
- [`ADR-019`](ADR-019-discriminating-evidence-rule.md) — a PASS must require evidence its subject
  could only have produced by running: why a missing parser refuses, and why each code has an arm
  that must fire
- The card this record's header names, in the *release scaffolding grades itself* milestone — the
  runner availability probe, the design and its review
