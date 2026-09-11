# ADR-019: The Discriminating-Evidence Rule — an assertion's PASS must require evidence its subject could only have produced by running

- **Status:** Proposed (2026-09-11)
- **Deciders:** repo maintainer
- **Driving work:** the privacy-control-integrity milestone. That milestone exists because
  six controls each read as enforcing and were not. This record ratifies the authoring rule
  its keystone card derived, and the rule is written down here rather than living inside one
  test suite because the milestone's own evidence is that the defect is not local to a suite:
  it recurred in a card's acceptance criterion, in an architecture record, in a mitigation
  assertion, and in the release's own success criterion. A rule enforced in one file and
  unwritten everywhere else is a rule that will be re-derived, differently, by whoever next
  meets it.

## Context

**An assertion that cannot fail is worse than no assertion.** It costs the same to run, it
reports the same green, and it recruits the reader's trust for a claim nobody is checking.
The failure is silent by construction: nothing about a passing test announces which of its
branches it took, so an assertion whose PASS is reachable without its subject ever running
looks exactly like one whose PASS is earned.

**The shape is ordinary and it is everywhere.** Its commonest form is a negative-polarity
verdict:

```bash
if f "$input"; then FAIL "X: f accepted something it should reject"; else PASS "X: f rejects it"; fi
```

That reads as "f must reject this input". What it actually says is "f must not exit zero",
and a shell reports rc 127 for a command that does not exist, rc 126 for one that cannot be
executed, and rc 2 for a `grep` whose file it could not read. Every one of those lands on
the PASS limb. Delete the function and the assertion congratulates it. An introspection
assertion carries the same defect one level over: `grep -q PATTERN <<<"$(declare -f f)"` on
an absent `f` scans an EMPTY haystack, matches no pattern, and reads as a clean subcommand.

**This was measured on this repository, not reasoned about.** During the release before this
one, `verify_ciphertext` was deleted outright from the publish script and four assertions
that exist to grade it stayed green; `cmd_list` was deleted entirely and the guard suite
finished with zero failures. Both mutations were re-run by an independent probe at the
milestone's own baseline and reproduced exactly.

**The suite did go red under the first of those mutations, and that is the trap.** It went
red through assertions that point the other way — the clean-ciphertext limb, the
real-StatiCrypt limb, and a boundary check on an unrelated decision — none of which the
defect is about, and two of which skip entirely on a runner without `npx`. So the redness
was accidental *and* environment-dependent. A suite-level red/green oracle over that
mutation would have certified a fix that changed nothing. The second mutation produced no
redness at all.

**Six instances, one class, gathered inside a single release.** Each was found by a
different card's design or implementation pass, none of them looking for it, and every one
was a control that reads as enforcing and is not. They are recorded here because the
promotion from "a defect we fixed" to "a rule we author against" rests on the recurrence,
not on the argument.

| # | Where it was found | The control | How it was defeated |
|---|---|---|---|
| 1 | The release's own **Success Indicator** | *"mutation-deleting `verify_ciphertext` or `cmd_list` turns the suite red rather than green"* | Already satisfied at baseline while all five named defects were live. Deleting `verify_ciphertext` turned the suite red through collateral assertions; deleting `cmd_list` was wholly invisible. Amended to a per-assertion form and operator-ratified before any work began |
| 2 | The **branch-protection card's** Stage-4 mitigation | *"read back and assert nine contexts, zero null"* | Satisfied by three separate wrong outcomes, each constructed and run — among them a write that pins the gate to the **wrong app** and still reads nine contexts and zero nulls |
| 3 | The **abort-locator card**, and the architecture record it cites | Both describe an abort naming a member — `third-party` or `passport` | That shape is never produced. Column one of the record stream is only ever the declaring parse limb, from every emitter; the documented coordinate did not exist and never had |
| 4 | The **residual-findings card** | An arm whose failure text says *"stripping the marks silently empties the class"* | Its PASS is carried by an unrelated supersession path and is independent of the strip it claims to guard. Its two fixtures are byte-identical in every observable the arm reads |
| 5 | The **false-abort card's** own acceptance criterion | *"a destination-guidance line never aborts a publish"* | Defeated twice. A matcher stubbed to match nothing was measured passing four of four false-abort arms and zero of two true-carry-through arms; a one-limb fix passed exactly the same set while the class survived |
| 6 | Caught **during implementation**, not design | A fail-closed word floor on a degraded text extraction | A new per-line sentinel would have been counted as a word, so a render of near-empty lines would have cleared a floor requiring at least twenty words — a floor that exists precisely to catch an extraction yielding nothing — with every assertion in the suite still green |

**What the six have in common is not carelessness.** Every one was written by someone
stating a real requirement, and every one is defeated the same way: the PASS is reachable on
a branch that a *degenerate outcome* also reaches. The author asserted the outcome they
wanted and not the evidence that distinguishes it.

## Decision drivers

- **Detectability must not depend on noticing.** Five of the six were caught by a person
  reading closely under an adversarial mandate. That is not a control; it is a run of good
  luck with a review budget behind it.
- **The rule must be decidable by a machine, at least in part.** A behavioural statement —
  *"every assertion has an input for which it fails"* — is true and unenforceable. A
  structural statement of the same property can be scanned.
- **It must reach assertions nobody registers.** As of the release before this one, two
  sibling suites had grown by 499 and 278 lines. A mechanism that grades only the sites
  enumerated today closes today and reopens on the next merge.
- **It must not over-fire.** A rule that flags every zero-valued verdict would convict the
  large, sound population of assertions whose PASS legitimately means *nothing found* and
  which already state a denominator and carry a control arm. A gate that convicts correct
  work trains contributors to reach for its exemption marker.
- **It must be reusable by every card in the release, immediately.** The milestone
  sequenced this card first precisely so the others could be written against a suite whose
  green is evidence.

## Options considered

| # | Option | Catches the known sites | Catches sites added later | New CI surface | Verdict |
|---|---|---|---|---|---|
| A | One-time remediation of the flagged sites | Yes | **No** | none | **Rejected.** The addition-blind half is the half that recurs |
| B | An external linter and a workflow to run it | Yes | Yes | **a further required check** | **Rejected.** The suites can assert this about themselves, and an external script would not inherit the strict-skip semantics the suites already carry |
| C | **A meta-assertion group inside each suite** | Yes | Yes | none | **SELECTED.** The pattern already ships here — a self-reading group with a readability guard, a sensitivity arm and a stated denominator was present in four of the five suites when this record was written, and this is the same pattern with a different predicate |
| D | A shared library sourced by all the suites | Yes | Yes | none, but a **first shared library** | **Rejected on measurement.** No such directory exists; the suites deliberately duplicate their verdict harness rather than share it. Introducing a library is a structural change this rule should not carry |
| E | An external mutation harness — copy the tree, delete a function, assert the suite reddens | Yes | Partly | a further workflow, and minutes per run | **Rejected as the mechanism, retained as the verification instrument.** It is how the decision below was proved; it is too slow and too coarse to enforce per assertion |

Option C wins on reuse. Nothing structural is invented: the meta-assertion group, the
vacuity guard that runs first, the two-piece needle that keeps a self-reading scan from
matching itself, and the control arm that must fire before a zero is read as a measurement
are all idioms this repository already ships.

## Decision

**1. The rule.**

> An assertion is **mutation-detectable** if and only if every path to its `PASS` requires
> evidence that the subject could only have produced by running. Equivalently: `PASS` may
> never be reached on a branch that a **degenerate outcome** also reaches — an absent
> subject, an empty haystack, an unreadable input, or an empty population.

This is the structural statement of the behavioural criterion *"every assertion has an input
for which it fails"*. The behavioural form is what the rule means; the structural form is
what a scanner can decide, and the two are kept together deliberately so the scanner is
never mistaken for the whole rule.

**2. Five shapes, and the degenerate input that defeats each.** This is the taxonomy the
suites implement against and a review grades against.

| Shape | Form | Degenerate input that reaches `PASS` | Class |
|---|---|---|---|
| **S1** exit-polarity-negative | `if f …; then FAIL; else PASS` | any non-zero status — 127 absent, 126 not executable, 2 unreadable | **Defective.** Status conflation: *rejected* and *never ran* are the same branch |
| **S2** exit-polarity-positive | `if f …; then PASS; else FAIL` | none for the absence class — 127 lands on `FAIL` | **Sound** for this class |
| **S3** introspection-negative | `grep -q PAT <<<"$(f)"` … `else PASS` | an **empty haystack** — an absent subject yields an empty body, which matches nothing | **Defective.** Emptiness conflation |
| **S4** rule-presence | `grep -q 'rule' file && PASS` | an **added** negating or widening clause leaves the rule present | **Defective.** Addition-blind |
| **S5** zero-population | `[ "$n" -eq 0 ] && PASS` | a probe that matched nothing **because it was broken** | **Conditional.** Sound only with a stated denominator and a firing control arm |

S4 and S1 are the same rule reached from opposite sides: an addition-blind assertion has no
*input* for which it fails, exactly as a 127-satisfiable one has no *subject state* for
which it fails.

**3. Four remedies, each named so a reviewer can ask for one by name.**

- **R1 — grade an exact status.** Replace bare truthiness with a named expected code through
  an `expect_rc` helper, which reports 127 as the distinct diagnosis it is: *the subject is
  ABSENT, not rejecting*. An exact code is normally available rather than merely stricter —
  `verify_ciphertext` returns only zero or one, `git check-ignore -q` returns one for
  not-ignored and 128 for an error, and `grep -q` returns one for no-match and two for an
  unreadable input. Read the subject's return codes before choosing the code you expect.
- **R2 — declare the subject present and the haystack non-degenerate** before grading
  content, and grade the probe's own status too. A body floor distinguishes *scanned a real
  body and found nothing* from *scanned nothing*.
- **R3 — carry a complement arm.** A rule-presence assertion is paired with an arm asserting
  the rule's complement is absent, so an added negating clause fails it.
- **R4 — carry a sensitivity arm and state the denominator.** Any assertion whose `PASS`
  means *nothing found* names its population and carries an arm over a known-positive input
  that is observed firing, in the message text.

**4. Group `MD` is the standing oracle, and it ships in every suite.** It carries a dynamic arm and a static arm,
because they close different halves.

- The **dynamic** arm re-runs a registered assertion in a subshell with its subject removed
  and requires exactly one `FAIL` and no `PASS`. It is the criterion made executable, and it
  is graded **per assertion**: for assertion X over subject S, removing S must flip X
  *specifically*. The aggregate verdict is not acceptable evidence, for the reason instance
  1 above records.
- The **static** arm scans the suite for the defective shape itself, so an assertion added
  later in that shape is caught with nobody registering it.

The group's controls ship as **standing arms**, not as checks performed once while
authoring: one proving the scanner tells the defective shape from the sound one, one proving
the oracle convicts a legacy shape, one proving the same oracle certifies a remediated one.
A meta-assertion without its own control proves only that it ran.

**5. What the static arm decides is an enumeration with a stated boundary, not a closed
class.** It matches three written-down forms of the negative polarity over a condition that
can report an absent subject, and it deliberately does not flag a condition that is a shell
test, because a shell test cannot report absence. What it does **not** decide is written
down beside it — a condition carrying an embedded separator, a verdict reached through a
`case` arm, a verdict whose identifier is only known at call time, a limb separated from its
opener by a statement, and anything inside a here-document. It fails open on each, and the
dynamic arm is what covers a registered assertion regardless of shape. **Writing the
boundary down is part of the decision**: an enumeration that presents itself as complete
invites the next vector to be read as a surprise rather than as a documented exclusion.

**6. The residual is declared, diffed in both directions, and can only shrink.** Sites that
keep the defective shape and are out of a given change's scope are named in the suite
itself, and the scan is compared against that declaration **both ways** — an undeclared site
fails, and a declaration whose site no longer scans fails too. That second direction is what
makes it a pin rather than an allowlist: an allowlist blinds a file permanently, while a
pinned set still fails when a file gains one more, and obliges the declaration to come out
when the remediation lands.

**7. S5 is reported, never failed.** A zero-population verdict is conditional rather than
defective, and a large share of them here are already sound. Each suite counts its own S5
population with a denominator on every run, so the residual rides on the artifact instead of
in a comment, and it is remediated when the site is next touched rather than swept in bulk.
A sweep of that population across the suites would be a mechanical mass edit over code
nobody read, which this repository's own discipline forbids.

**8. The authoring contract, for anything written after this record.**

1. Assert an exact status, never bare truthiness. A 127 is an absent subject, never a
   rejection.
2. Never put `PASS` on the `else` limb of a live invocation or probe. If the assertion is
   that the subject *rejects*, that is an expected status, not an else limb.
3. An introspection assertion declares its subject present and its haystack non-degenerate
   before grading content.
4. Every *nothing found* verdict states its denominator and carries a sensitivity arm that
   is observed firing, in the message text.
5. A rule-presence assertion carries a complement arm.
6. Register the assertion with group `MD`, naming the subject whose removal must flip it.
   Where the subject is not a shell function — a file, an external binary — record an
   explicit opt-out with its reason and a compensating positive control. Never omit
   silently.

## Consequences

**What this buys.** A deleted or renamed subject now turns its own assertions red, by
identifier, rather than turning some other assertion red somewhere else. The two mutations
that motivated this record were re-run against the remediated suite: removing
`verify_ciphertext` fails each of the four assertions that grade it, every one carrying an
explicit *the subject is ABSENT, not rejecting* diagnosis, and removing `cmd_list` produces
exactly one failure where it previously produced none at all.

**What it costs.** Every suite gains a helper set and a meta-assertion group, duplicated
rather than shared, because the suites duplicate their harness by existing convention and
this record is not the place to reverse that. The duplication is real and is accepted; the
alternative was a first shared library introduced as a side effect of a testing rule.

**What it does not do.** The static arm decides a shape, not a meaning. An assertion can
satisfy every structural rule here and still assert the wrong thing, and no scan closes
that. The dynamic arm is stronger — it observes a real flip — but it only covers what is
registered, and registration requires remediation first, because an oracle asked to certify
a still-blind assertion turns a suite red for a defect it is reporting rather than causing.

**The residual, stated rather than discovered later.** As of the change that introduces this
record, the declared residual across the suites was the population that keeps the defective
shape and was outside that change's locked scope, dominated by a single repeated form: a
finding-lookup helper called as a condition with the `PASS` on the else limb. Each suite's
declaration is its own remediation queue, it is asserted in both directions, and every entry
that leaves it gains a registered oracle arm in the same edit.

**A known self-reference.** The meta-assertion group reads its own source, so the fixture
that proves its scanner works is written from assembled pieces, and its deliberately
legacy-shaped control probe is written in a form the scanner does not reach. Both are stated
where they occur. The alternative — a scanner that convicts its own test fixtures — is worse,
and the sibling group that reads its own source for a different property solved it the same
way.

**Relationship to the count-assertion rule.** [ADR-013](ADR-013-count-assertion-basis.md)
says a count in prose must carry a basis a reader can re-derive. This record says a verdict
must carry evidence a reader can attribute to the subject. They are the same instinct at
different scales — *do not state a conclusion whose support cannot be reconstructed* — and
they compose: an assertion reporting a zero satisfies both only when it states its
denominator **and** its control arm is observed firing.

## References

- [ADR-008](ADR-008-publish-content-guard.md) — the publish-path content guard, whose
  assertions supplied the first four measured instances of this defect, and whose own record
  of the abort shape was instance 3. This record does not amend it.
- [ADR-013](ADR-013-count-assertion-basis.md) — count assertions carry a re-derivable basis;
  the sibling rule, and the model for declaring a residual rather than allowlisting it.
- `scripts/test-publish-guard.sh`, `scripts/test-artifact-schema.sh`,
  `scripts/test-command-taxonomy.sh`, `scripts/test-corpus-hygiene.sh` and
  `scripts/test-trip-resolution-contract.sh` — group `MD` in each, where this rule is
  enforced rather than described.
- `.github/workflows/publish-guard.yml` — the coverage boundary that declares group `MD`,
  and the roster gate that requires any emitting group to be declared there.
