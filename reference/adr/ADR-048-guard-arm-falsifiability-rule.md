# ADR-048: The guard-arm falsifiability rule — no verdict guard reaches PASS through a disjunction, graded by group FZ in each guard suite over its own top-level code, with the tautological class declared out of reach

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *Controls point at the population at risk* milestone — its card that
  carries the falsifiability rule from the suite where it was founded to the sibling guard suites
  (#981), and its card on the tautological-guard class (#982). The operator ruled at that
  milestone's Collective Review that the rule those cards install is written down as a record, on
  the threshold this corpus sets for one: a decision that is cross-cutting or hard to reverse. What
  the rule forbids, where it is graded, what the grading leaves ungraded and why the rule was not
  placed in group `MD` were decided in the two cards' designs and in the operator's rulings on
  them. This record transcribes them.
- **What this record is.** A decision about **what a verdict guard in a guard suite may not reach
  PASS through, where that is graded, and what the grading does not see.** It is addressed to
  whoever writes or edits a verdict in `scripts/test-artifact-schema.sh`,
  `scripts/test-publish-guard.sh`, `scripts/test-command-taxonomy.sh`,
  `scripts/test-corpus-hygiene.sh` or `scripts/test-trip-resolution-contract.sh`.
- **What this record is not.** It does not amend
  [`ADR-019`](ADR-019-discriminating-evidence-rule.md): group `MD`, its dynamic and static arms,
  the forms its static arm decides and its authoring contract read after it as they read before.
  It carries no
  walker, plant or grammar. How the rule is graded, and the full list of what the grading leaves
  ungraded, are stated in group `FZ`'s banner in each suite, which is their home; this record
  decides them and does not restate them.

## Context

**Group `FZ` was founded in one suite, over one file.** The trip-resolution-contract suite shipped
two verdict arms that could not fail, and both were found by a person reading predicates in review
rather than by a check. In both, the guard reached PASS through a disjunction whose second disjunct
was implied by the first's negation, so the conjunction the failure branch needed — every disjunct
false at once — could never hold. The group installed in that suite enforces the shape: no verdict
guard there reaches PASS through a disjunction. Its banner said its scan set was that one file, and
that the sibling guard suites were not covered.

**The sibling suites were exposed, and the walker that shipped could not say where.** Run unmodified
over every guard suite at `a9366e8`, it flagged twelve guards in the artifact-schema suite and two
in the publish-guard suite. Read one by one, three of the fourteen carried the banned shape: the
three `CTL-FT6` controls in the artifact-schema suite. The other eleven were misreads of two kinds.
An `if` inside an embedded `awk` program carries no `then`, so the walker took it for a guard
waiting for one, swallowed every line up to the next shell guard's `then`, and graded that guard
under the awk line; 76 real guards were misattributed that way in the artifact-schema suite alone.
And a one-line guard that names FAIL first and PASS after its `else` was read as reaching PASS.

**Carried into every guard suite, the rule is cross-cutting.** Each of those suites is a required
check, and each then rejects a guard written `if A or B; then PASS`. When this record was written
the rule appeared in no tracked file outside the founding suite's own banner, so a contributor
would first meet it as a red check.

**A second class of unfirable arm has no shape to find.** A guard that reaches PASS through a
tautology — a count compared against zero with `-ge`, a value tested non-empty just after a literal
was assigned to it, a comparison between two values the suite constructs to be equal — carries no
disjunction, and reports PASS forever exactly as the disjunctive shape does.

## Decision drivers

- **A finding is reported by the suite whose arm it is.** Each guard workflow gives failure
  attribution as a reason it is a separate workflow. A rule graded from one suite over another's
  source turns the wrong check red.
- **No sourced shared fate across required checks.** A walker every suite sources makes the
  required checks one point of failure, and `ADR-019` rejected a first shared library for these
  suites (its option D).
- **No written decision of `ADR-019` is reversed.** Its Decision 5 says that the static arm of
  group `MD` deliberately does not flag a condition that is a shell test, and its fourth and fifth
  decisions enumerate what the group carries. The guards this rule grades are shell tests.
- **The meta-check does not depend on the awk engine,** which is itself a source of variance
  between a developer's host and the runner.
- **An overclaiming meta-arm is the same defect one level up.** What the group does not grade is
  written where its reader meets it, and counted on every run where a count is possible.

## Options considered

Where the rule lives:

| # | Option | Verdict |
|---|---|---|
| A | One walker in a shared library that each suite sources | **Rejected.** It makes the required checks one point of failure, and `ADR-019` rejected a first shared library (option D) |
| B | One suite scans its siblings | **Rejected.** A defect in one suite turns another suite's check red, which breaks per-suite failure attribution |
| C | **Port group `FZ` into each guard suite, each over its own source** | **SELECTED.** The per-suite meta-group convention groups `PF` and `MD` already follow, and the pattern `ADR-019` option C selected. No record is superseded and no shared code is introduced |
| D | Extend group `MD` with the walker, as a further static form | **Rejected.** `ADR-019` Decision 5 says `MD`'s static arm deliberately does not flag a shell-test condition, and the guards this rule grades are shell tests, while its fourth and fifth decisions enumerate the group's contents. Placing the rule there supersedes part of an Accepted decision, and puts rules with disjoint shapes under one group id |
| E | A corpus-hygiene class graded over every guard suite, reusing that suite's shell lexer | **Rejected.** It breaks per-suite attribution, and the rule grades a suite's own verdicts — the convention by which `PF`, `MD` and `FZ` each assert against their own file |
| F | A CI-only step running one walker over every suite | **Rejected.** It adds a required context, and `ADR-019` rejected an external linter (option B) because the suites assert this of themselves under their own strict-skip semantics |

How the walk steps over what is not a shell guard:

| # | Option | Verdict |
|---|---|---|
| i | **A bash lexer that keeps a stack of the constructs open at each point, and a walk of top-level code only** | **SELECTED.** It steps over embedded programs, substitutions, quoted payloads and here-documents by construction, and keeps the group pure bash |
| ii | A narrow rule: an `if` followed by `(` is not a guard | **Rejected.** It misses here-document bodies, an operator inside a substitution or a quoted literal, and a verdict token inside a printed string |
| iii | A lexer written in awk | **Rejected.** It makes the meta-check depend on the awk engine |

The guards that carried the banned shape when the rule was carried:

| # | Option | Verdict |
|---|---|---|
| — | **Rewrite each as a chain, one condition and one message per branch** | **SELECTED** |
| — | Record them as reachable with a reason, in a declared residual list | **Rejected.** It invents an allow-list for a rule whose banner says the shape is never necessary |

The case a disjunct existed to excuse, where a chain keeps it as its own branch:

| # | Option | Verdict |
|---|---|---|
| — | Render it `VACUOUS` | **Not chosen.** It leaves the artifact-schema suite's existing control that keeps PASS on a red a live arm already carries contradicting the rule's own text |
| — | **Keep PASS where a live arm already carries that red and the message names it, and say so in the rule's text** | **SELECTED** |

The verdict forms the walker does not locate:

| # | Option | Verdict |
|---|---|---|
| — | **Name them in the coverage boundary, and print on every run a count of the PASS lines no located guard reads** | **SELECTED** |
| — | Also locate the list form as a guard, behind a plant of its own | **Not chosen.** A new parse path, with its own plant, in every copy of the group |

The tautological class:

| # | Option | Verdict |
|---|---|---|
| — | A detector for the class | **Rejected.** Whether a guard can fail is whether its negation is satisfiable over the values the file can produce, which is not decidable in general, and a detector for a few literal spellings grades those spellings while reading as coverage of the class. The card's literal forms had no instance in the guard suites when they were measured, at `a9366e8`, so such a detector would grade an empty population |
| — | **A declared residual, with its reason, in the coverage boundary of every suite the rule grades** | **SELECTED** |

## Decision

### 1. The rule

**A verdict guard in a guard suite does not reach PASS through a disjunction.** Written
`if A or B; then PASS … else FAIL`, the failure branch needs every disjunct false at once — a
conjunction nobody wrote down, and where both founding instances hid an arm that could not fail.
Such an arm is written as a chain instead, one condition and one message per branch. The same
disjunction reaching FAIL is permitted, because it fires whenever either side holds. A guard's
polarity is its first verdict after `then`, so a guard that names FAIL first reaches FAIL. Where a
disjunct exists to excuse an empty population, the verdict for that case is never PASS unless a live
arm already carries that red and the message names it; otherwise it is `VACUOUS` where the suite
has that verdict, or a FAIL that names the empty population.

The rule decides a shape. It never decides reachability.

### 2. Where it is graded

Group `FZ` grades the rule in each required guard suite, each over its own source, so
a finding is reported by the suite whose arm it is. The group is one text in every suite that
carries it, apart from the paragraph saying why it is there, by the convention group `MD` follows.
It walks top-level code only, and its controls are standing plants rebuilt and graded on every run,
each read before the file's own verdict is: a zero whose controls did not fire is not a
measurement, and a file the walk could not account for to its end is refused. The advisory sixth
suite, `scripts/test-adr-conformance.sh`, does not carry the group.

### 3. What the grading leaves ungraded

The coverage boundary in the group's banner is part of this decision, and it states:

- **The tautological class, as a declared residual.** A tautological guard reaches PASS without a
  disjunction and is invisible to the group, and no detector for the class ships, for the reason in
  § *Options considered*. Group `MD`'s static arm leaves every shell-test condition unflagged by
  design; its dynamic arm convicts a registered assertion whose PASS survives its subject's removal,
  which some tautological guards do. An unregistered tautological guard is seen by nothing in the
  suite.
- **The verdict forms the walker never locates**: a list-form verdict, a guard whose `if` is not
  the first word on its line, and a disjunction decided in a helper or an assignment and compared
  afterwards. Their remainder is counted on every run, by a count that also takes in every PASS
  reached through an `else` or first appearing deeper in a branch, so it bounds the three forms
  from above and does not census them.
- **What the walk does not read**: a guard whose first verdict lies deeper in its branch, anything outside
  top-level code, a disjunction spelled other than with two bars, and nesting. A here-document
  delimiter that is neither a word nor quoted is refused rather than guessed at.
- **Its scan set**: each suite's own file. Nothing asserts that the copies of the group agree.

### 4. Why the rule is carried as a group of its own rather than placed in group `MD`

`ADR-019` Decision 5 says that the static arm of group `MD` deliberately does not flag a condition
that is a shell test, because a shell test cannot report an absent subject. The guards this rule
grades are shell tests. Placed in `MD`, the rule would reverse that sentence of an Accepted
decision. The rules are siblings: `MD` asks whether a PASS requires evidence its subject could only
have produced by running; `FZ` asks whether the condition a guard's failure branch needs was ever
written down.

### 5. What this record does not do

It does not amend `ADR-019`. It does not decide reachability, and it ships no detector for the
tautological class. It does not assert that the copies of the group agree. It does not grade
`scripts/test-adr-conformance.sh`.

## Consequences

**What it makes necessary elsewhere.**

- A verdict guard that reaches PASS through a disjunction, written in any suite that carries the
  group, turns that suite's required check red, and is written as a chain instead.
- A correction to the walker is owed to every copy of the group in the change that makes it,
  because nothing asserts the copies agree.
- A `<<` written in a suite's code with a delimiter that is neither a word nor quoted — the
  shift-assign `<<=` is one — turns that suite's check red, because the group refuses the file.

**What it buys.** Every guard suite grades its own verdict arms for the shape, so the growth of any
of them is graded as it lands. The fourteen sites the walker flagged were each read and
dispositioned, the three that carried the shape are chains, and the misattribution of real guards
under embedded programs is gone.

**What it costs.** Five copies of one block of a few hundred lines, duplicated rather than shared,
the same accepted duplication `ADR-019` records for group `MD`. The walk adds seconds to each run:
about four for the largest suite, as measured under macOS's stock bash.

**What stays open.** The tautological class; the verdict forms the walker never locates, counted
from above; a verdict first appearing deeper in a branch; and the agreement of the copies. Each is
written in the coverage boundary where the group's reader meets it.

**Relationship to the discriminating-evidence rule.** [`ADR-019`](ADR-019-discriminating-evidence-rule.md)
says a PASS must require evidence its subject could only have produced by running. This record says
the branch a verdict fails on must have been written down. They are graded by different groups over
the same files, and they compose: an arm satisfies both only when its subject's removal flips
it and its failure branch is a condition somebody wrote.

## References

- The rule this record sits beside, and the decision it does not reverse:
  [`ADR-019`](ADR-019-discriminating-evidence-rule.md), Decisions 4 and 5, and options B, C and D.
- Where the rule is graded, and the home of how: group `FZ`'s banner in
  `scripts/test-artifact-schema.sh`, `scripts/test-publish-guard.sh`,
  `scripts/test-command-taxonomy.sh`, `scripts/test-corpus-hygiene.sh` and
  `scripts/test-trip-resolution-contract.sh`.
- The rosters that declare the group: `.github/workflows/artifact-schema.yml` and
  `.github/workflows/publish-guard.yml`.
- The threshold this record was written on: `reference/adr/README.md` § *Convention*, *When to
  write one*.
- Driving work: #981 and #982.
