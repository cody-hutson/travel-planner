# ADR-044: A record's number is taken on `main` before the record is written — a register row that names its record, a required check that grades it, and the shapes it was chosen over

- **Status:** Accepted (2026-10-09)
- **Deciders:** repo maintainer
- **Driving work:** the *Decision records hold their number and their spine* milestone — its card
  on holding a record number across unmerged branches (#1363), under the decision-tier epic
  (#1499).

## Context

`reference/adr/README.md` § *Convention* assigns record numbers monotonically and forbids reuse
and renumbering, and § *Number declarations* says a number is spent when it is published. Neither
said how a number is taken. Practice filled that in: a release took the number after the highest
record on `main` and on every open release head when it first wrote the file, and renumbered on
its own branch if another release reached `main` with that number first.

**That is a choice made on a branch, and nothing outside the branch holds it.** During the
traveller-journey founding-decision release, separate branches each carried a different record
at `ADR-024`. The files had different names, so the merge had nothing to conflict on, and the
collision was caught by hand. `scripts/test-corpus-hygiene.sh` group **D** has graded the
numbering since: a number carried by more than one record is a finding. It grades the tree it is
handed.

**A green is as old as the branch's last push.** The required check grades a branch as it was
pushed and, where the branch has a pull request open, that branch merged into `main` as `main`
then stood. Branch protection here, as read from the host when this record was written, does
not require a branch to be up to date with `main` before it merges, so neither grading is
repeated when `main` moves, and branches that each carry a record at the same number are each
green alone. Where the change is a release, what keeps that collision off `main` is the release
procedure. A release writes its entry at the head of `CHANGELOG.md` on its own branch, so the
release that lands second conflicts there with the first, cannot merge until it has merged
`main`, and is graded again when it does: group D fails it before its merge, and it renumbers —
a file name, a title, an index row and every citation it has written. A change that carries a
record and no such entry need meet no conflict at all: the records are different files, and
their index rows can stand in different tables. It then merges on a run that never saw the
earlier record, group D fails on `main` afterwards, and a collision that has reached `main` is
the one this convention cannot repair, because neither record may be renumbered.

**A hold was improvised, and it held nothing.** At `feaa7f8`, and again at `b998a36`, a release
carrying a higher number declared the lower numbers of a release still in flight as gaps in the
`adr-number-declaration` fence, so that its own tree would grade; at `12cb57d` and `39114d4` it
took those rows out on its own branch, once the other release had merged. No such row stood on
`main` at any commit up to `5d50eb5`. That fence cannot carry a hold for the next free number in
any case: group D fails a declared number that sits above the highest record, because it excepts
a gap the sequence does not have.

**The version runs the same race and loses nothing by it.** `CONTRIBUTING.md` § *Cutting a
release* has the version stamped last and claimed by the tag push, which the host either creates
or refuses. A version lost before the tag is restamped, and nothing published has to change. A
record number is written into a file name, a title, an index row and every citation of the
record, and once it is published it does not move.

## Decision drivers

- **The hold has to act on a branch that never looked.** A rule that binds only a careful
  claimant is the practice this record replaces.
- **A number that is held is held somewhere a branch cannot write alone** — on `main`, or on the
  host.
- **A number cannot be claimed twice and both claims land.**
- **The merge-time grading of the numbering stays.** Whatever holds a number before the merge
  stands beside group D, and anything it takes from group D is stated and bounded.
- **A shape this corpus already reads, before a new mechanism.** It declares sets in fenced
  blocks that one reader parses and a suite grades in both directions.
- **A claim is a change like any other.** Nothing reaches `main` here outside a pull request and
  its required checks.

## Options considered

1. **State the practice as the rule, and change nothing else.** Rejected. It holds nothing: the
   number still lives on the branch that chose it. A release that has lost its number learns so
   when it merges `main`, which the conflict at the head of `CHANGELOG.md` forces before it can
   merge and nothing asks for sooner — after the number is in its file name, its title and its
   citations. A change with no entry there need never be asked, and then learns after its merge.
2. **Allocate at the merge, with the number written in the last change before it.** Rejected as
   the hold, and kept as the fallback it already was. It shrinks the window and does not close
   it — releases that write their last change in the same hour pick the same number — and a
   record with no number is graded by neither suite until it has one.
3. **A hold row in the `adr-number-declaration` fence.** Rejected. That fence declares a gap the
   sequence has: group D fails a row whose number is above the highest record, and fails a row
   whose number a record then occupies. Admitting holds would mean exempting a class of row from
   both directions of the pin that makes the fence a declaration and not an allowlist.
4. **A ledger in a file of its own.** Rejected. It would be read by the same reader and graded
   by the same group as a fence in the index, and would add a path, a link to keep and a second
   place to look for what the index's own section on numbers already owns.
5. **An atomic claim on a ref — a tag outside `v*`, or a branch.** Rejected. The host does
   create such a ref or refuse it, with no window, and that is the property the version relies
   on. But tags on this host can be moved and deleted; the claim would be made outside any pull
   request and any check; a verdict that read the claims would depend on state outside the tree
   it grades, so the same tree could pass in one checkout and fail in another; and a second tag
   family would stand in the namespace the release procedure reads.
6. **Assign the number in the tracker when the record's card is bundled.** Rejected. One
   planner sees every claimant inside a release and none outside it, an issue is not a
   compare-and-swap, and nothing in the tree could grade a number held there.
7. **Number a record when it is ratified.** Rejected. A record would land with no number, so
   its file name would break the convention and neither suite would grade it while it is
   `Proposed`; every citation written before ratification would be rewritten on `main`; and
   ratifying changes can race for a number exactly as releases do.
8. **A stub record as the claim.** Rejected. The claim would be a published record that decides
   nothing, the spine check would fail it until it was written, and stubs claimed on separate
   branches meet nowhere in the tree: their files differ and their index rows sit in different
   tables, which is the collision this record exists for.
9. **Require a branch to be up to date before it merges.** Not rejected, and not this record's
   to decide. It is a branch-protection setting, changed outside any pull request; `SECURITY.md`
   § *Branch Protection Posture* is where this repository records that posture, and it does not
   state this setting. It would make group D's merge-time verdict a fresh one, which closes the collision at the merge; it holds no number before the merge, and
   it charges every open pull request a merge of `main` and a full run each time `main` moves.
   The register does not need it and is not weakened by it.
10. **A register on `main`: a row per number taken, naming its record, graded by a required
    check on each branch as it is pushed and on its merge into `main`.** Chosen.

## Decision

### 1. A number is taken on `main`, by a row that names its record

A record's number is taken before the record is written under it, by a row in the
`adr-number-register` fence in `reference/adr/README.md`, landed in a pull request of its own.
**The rule an author follows is stated once, in that file's § *Number declarations*, from
*Taking a number* to *What a row becomes*; that is its home, and this record decides it and does
not restate it.** The row names the record's file. A row that said only that a number was taken
would be the same line on every branch that wrote it, and identical lines merge as one: each
claimant would read its own claim on `main` and neither would be refused.

### 2. The register binds a branch that never looked

A required check grades the register against the directory: the number-register group of
`scripts/test-corpus-hygiene.sh`, whose banner entry is the home of what it grades and what it
reads past. A record above the register's floor is a finding unless its number's row names that
record's file. The check grades a branch as it was pushed, and that grading does not depend on a
merge of `main`: a branch cut before a number was claimed carries no row for its record, and a
branch cut afterwards carries a row that names another record's file. Where the branch has a
pull request open the check also grades it merged into `main` as `main` then stood, which is
where a branch older than the register meets the group at all.

**The other half is the place the row is written.** Rows are consecutive and each new one is the
last line of the fence, so rows written on separate branches meet at one place in one file. The
host does not merge a pull request whose branch conflicts with `main`, whether or not it requires
that branch to be up to date. The conflict stops the merge and does not say which claim gives
way, and no check can: which row came first is a fact about history, and the check reads one
tree. The order is therefore a rule, kept by whoever resolves the conflict and whoever reviews
the result. The row already on `main` stands; the later claimant takes the next number; and a
row that names another record's file is changed only by a pull request that changes nothing
else. A conflict resolved by keeping both rows is a finding, and so is one resolved by keeping
the row on `main` over a record still filed under its number.

### 3. A row is never removed

The register is a record of what was taken, not a list of what is pending. A row stays when its
record lands, so a row deleted under a landed record is a finding and the population the check
grades cannot be lowered by an edit to the fence. A row whose record has not landed is kept by
the rule in Decision 2 and by review, and Decision 6 states that limit. A number whose record
will not be written stays taken, with a reason token in place of the file name: it is spent, as
`020` is, and what tells a reader so is in the fence and not in somebody's memory. Records
numbered at or below the last number taken before the register existed carry no row.

### 4. Group D reads the register

A number taken and not yet landed is unoccupied, and a later record can be numbered above it.
Group D treats a number a register row names as accounted for, beside the gaps the declaration
fence declares. Its codes, its arms and both directions of its declaration pin are unchanged,
and it remains the grading of the numbering at the merge. What the read gives up is decided
with it. Above the register's floor every number up to the highest record has a row wherever
the register passes its own check, so group D's finding for a number that nothing accounts for
no longer fires there: such a number reads as a hold, which is reported on every run and never
failed. The improvised hold in § *Context* is retired by this: a release no longer writes
another release's number into the declaration fence in order to grade.

### 5. The record that decides this takes its number the way it replaces

No register existed on `main` to take this record's number from. Its row reaches `main` in the
change that carries the register, the check and the record together, and until that change
merges its number is held by nothing but the practice in § *Context*. Every later record takes
its number under Decision 1.

### 6. What this record does not do

It does not make a hold tamper-evident. A row whose record has not landed can be rewritten to
name another record, or taken off the foot of the fence, in a tree that passes every check; the
rule in Decision 2, the conflict and the pull request's diff are what stand in the way. It does
not change the branch-protection setting in option 9. It does not give the declared gap a single
home: `ADR_NUM_EXEMPT` in `scripts/test-adr-conformance.sh` still pins its own copy and does not
read the register. It does not make a claim atomic on the host. And it does not decide when a
hold has been abandoned.

## Consequences

**Positive**

- A number is held from the merge of a one-row pull request, against every branch that follows
  the rule. A release whose hold stands writes its record's number into a file name, a title
  and its citations once.
- A record that leaves the register alone does not pass the required check under a number
  another record's row names, and that is graded on its branch as it was pushed — it does not
  rest on that branch having merged `main`.
- Claims of one number written on separate branches do not both land: they conflict where they
  are written, and keeping both rows is a finding.
- The declaration fence goes back to declaring gaps the sequence has.
- A reader finds what is taken and not yet landed in one place, on every run of the check.

**Trade-offs**

- A record costs a pull request before it is written, through every required check, to add one
  line. That is the price of the hold, and it is paid before the cost of losing a number would
  have been.
- Claims made at the same time conflict even when they take different numbers, because each is
  the last line of the fence. The later one merges `main`, moves down a line and, if its number
  was taken, takes the next.
- A hold is kept by a rule and by review, and by no check, until its record lands. A later
  claimant that rewrites the earlier row, or resolves the conflict between the rows in its own
  favour, passes every check. The change is one line of its pull request's diff, and the holder
  learns of it when it next merges `main` and finds its own record the one reported.
- The register is a third list of records above its floor, beside the directory and the index.
  It is graded against the directory in both directions, and it carries what neither of the
  others can: a number with no record yet.
- A record renamed before it lands needs its row edited in the same change.
- A hold that will never be used is not found by any check. A row with no record is reported on
  every run, and marking it spent is an edit somebody has to decide to make. Above the floor
  that report is what is left of group D's finding for a number nothing accounts for.
- A branch older than the register is graded as pushed by its own older copy of the suite, which
  has no such group, and by the copy on `main` only on its merge, at a push made after the
  register landed. A release that carries its changelog entry cannot merge until it has merged
  `main`, because of the conflict at the head of `CHANGELOG.md`, and from then on its own copy
  has the group. A change that carries a record and no entry there meets no such conflict, and
  is the remaining way a collision reaches `main`.
- Every branch that numbers a record above an unlanded hold has to add the held number to
  `ADR_NUM_EXEMPT` in the commit that writes its record, because the conformance suite fails
  that branch until it does. Branches that do so edit the same line, and the change that lands
  the held record has to take the number out again.
- Group D and the register's group share the fence. Taking group D's read of the register out
  is safe only in a change that also declares, in the declaration fence, every held number a
  record stands above; without that declaration the required check fails on each.
- `scripts/test-corpus-hygiene.sh` gains a group, and a floor that is a point in this corpus's
  history, pinned in the suite.

## References

- The convention this record extends: `reference/adr/README.md` § *Convention*, *File name*.
- The home of the rule this record decides, and of the register itself:
  `reference/adr/README.md` § *Number declarations*.
- What grades the register, and what that grading reads past: the number-register entry in the
  banner of `scripts/test-corpus-hygiene.sh`; and for the numbering at the merge, its class-D
  entry.
- What each run of that check grades, what that leaves open, and what a change that takes the
  group out has to carry: the header of `.github/workflows/corpus-hygiene.yml`.
- The race this one is set beside, and the step that names the claim:
  `CONTRIBUTING.md` § *Cutting a release*.
- Where this repository records its branch-protection posture, which option 9 would change:
  `SECURITY.md` § *Branch Protection Posture*.
- The account of the one gap declared before the register existed:
  `ADR-021-installable-capability.md` § *Costs and residual risks*.
- The measurement in § *Context*: the README at every first-parent commit of `main` up to
  `5d50eb5` was read for a hold row; the four commits named there are the ones that wrote and
  removed one, each on a release branch.
- Driving work: #1363, under #1499.
