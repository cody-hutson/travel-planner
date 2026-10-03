# ADR-042: Accepted records after acceptance — what an amendment may add, the consolidated-decision form, and where settled design belongs

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *A surface's cost is a stated property* milestone — its card on what
  Accepted decision records gained after acceptance (#1179), under the corpus read-cost epic
  (#1169).

## Context

`reference/adr/README.md` § *Convention* makes an Accepted record immutable as to its decisions, and
has it edited in place to correct a claim, to narrow a scope or coverage statement, or to repair a
citation. The partial-supersession form adds a fourth edit: recording a decision taken in another
record. The convention says what kind of edit is admitted. It does not say where the account of an
edit is put, or what a record does with text that is neither a decision nor a correction.

**What that produced.** Each record was read at its first Accepted revision and again at `e743113`,
following renames, and the lines added between the two were sorted by where they sit, by how they
arrived and by what they state.

| Measured at `e743113` | Value |
|---|---|
| Records, and how many had changed since acceptance | 39, of which 20 |
| Records accepted on or before 2026-09-23, and how many had changed | 25, of which 20 |
| Net growth since acceptance | 215,956 bytes |
| Added lines, the base of every share below | 257,438 bytes |
| By where they sit: in a `Status:` line | 11.7% |
| …in a dated amendment paragraph inside a section | 36.0% |
| …rewritten in place, with no amendment marker on them | 48.4% |
| …under References, or as a note inside a sentence | 3.9% |
| By how they arrived: in place of 39,061 bytes of accepted text | 62.6% |
| …inserted beside the accepted text | 37.4% |
| By what they state, coded by hand: settled design — a rule, table, mechanism or measured boundary — added beside a correction or restated inside one | 33.9% |
| …a corrected claim, a narrowed scope statement or a repaired citation | 33.7% |
| …of those, a repaired citation | 6.2% |
| …an amendment's account, a rejected alternative, a recorded supersession, a closed open item or removed scheduling content | 19.3% |
| …too small to sort: unmarked runs under 800 bytes, and notes inside a sentence | 13.1% |

**The exception had become the normal path.** Of the records old enough to have been amended, four
in five had been, as the table's second row measures at `e743113`. The other fourteen were at most
eight days old on 2026-10-02.

**Part of that growth predates publication.** A record's first Accepted revision is often a commit
on the branch of the release that carried it, so what was revised before that release merged counts
in the table as growth after acceptance. Cut instead at the commit on `main` that first carried each
record's first Accepted revision, measured at `e743113`, 89,535 bytes of added lines came before
publication, in 10 records, and 178,306 bytes after it, in 20. A line added before publication and
rewritten after it counts in both, so the two exceed the table's base. Every record that changed
also changed after it reached `main`.

**The status line was the visible form, and not the main one.** At `e743113` the `Status:` line of
`ADR-009` ran to 16,448 bytes and narrated nine amendments ahead of the record's own Context, and
`ADR-008` carried 10,082 bytes the same way. Most of `ADR-009`'s was there before the record reached
`main`: at `ed9d88b`, the commit that first put it there, the line ran to 14,195 bytes and narrated
seven. Measured at `e743113`, three times as much added text sat in dated paragraphs inside
sections, most of it under Decision, where a section's text and the paragraphs that amend it stand
one after the other, so a reader assembles the decision in force from both.

**Most of what records gained was settled design, and much of it arrived inside a correction.**
Settled design is the shape a decision takes once it is built, restated as the thing it describes
changes. Measured at `e743113`, 77.1% of it sat in `ADR-008` and `ADR-007`. Nearly all of what
`ADR-008` gained replaced accepted text — 63,149 bytes of added lines in place of 4,292, against 634
inserted, measured at `e743113` — so its settled design arrived as corrections and narrowings of
claims the record had made, kinds the convention admits, each restating the shape of what it
corrected. Its coverage passage is the largest instance: one replacement of a five-line claim, which
restates the guard's measured boundary beside accounts of its own corrections and of the remedies it
rejected. What `ADR-007` gained came mostly beside its text, measured at `e743113` as 31,981 bytes
inserted against 14,545 replaced.

**The specification tier did not hold it.** What `ADR-008` and `ADR-007` gained — the publish
guard's matching rules and measured coverage, and where the command surface admits inference and
what crosses its privilege boundary — was stated in no specification document: probed at `e743113`,
none of the seven terms that design is written in occurred in the documents under `reference/`
outside the records, and six of them occurred in the scripts that implement it and the suites that
pin it. A record whose subject has a specification followed its mechanisms too: correcting its
passage on reserved keys, `ADR-009` restated the guard's list, which `reference/data-model.md`
§ *Reserved keys* declares.

**Where settled design lives when it has a home.** `reference/data-architecture.md` § 12 states the
boundary between a specification and its record: the record is authoritative for the decision and
the document for the shape, and where they overlap they must agree. Probed at `e743113`, that
document cited 10 distinct records, `reference/data-model.md` 6, `reference/site-layout-spec.md` 3
and the engine-root `SKILL.md` 1. At `e743113` the first of them stated that boundary, for the whole
document and for single rows; the second stated it for the parts that `ADR-012` and `ADR-022`
decided; the other two cited records and stated no boundary. A suite can hold a shape as well:
`ADR-008` says of its own coverage passage that every claim in it is pinned by a case in
`scripts/test-publish-guard.sh`.

## Decision drivers

- **A reader wants the decision in force, without replaying how it came to be.**
- **A rejected alternative, with its reason, is what only a record holds.** Everything else in a
  record has another possible home; that does not.
- **A record is read to learn why. A specification is read in order to act.** Text a session needs
  before it acts belongs where a session is told to read.
- **One byte bound for a file, declared in one place.** A second figure here would be a second
  bound that can disagree with the first.
- **Deciding the rule restructures nothing.** The rule has to hold for the records as they stand.

## Options considered

**For what an Accepted record may gain.**

1. **Freeze it: every correction is a new record.** Rejected. A repaired citation would cost a
   number, an index row and a file, a reader would learn the decision in force only by following a
   chain of records, and a number is the one thing two branches already race for.
2. **Leave the convention as it stands.** Rejected. It names the kinds of edit and bounds neither
   their place nor what arrives beside them, and it is what the table above measures.
3. **A byte or percentage cap stated here.** Rejected. Growth since acceptance ran from nothing to
   +449% of a record's accepted size at `e743113`, so any figure is arbitrary; a figure refuses a
   long true correction and admits a short new decision; and it would be a second byte bound on
   files whose size instrument and parameters `reference/load-class-model.md` already declares.
4. **A cap on how many amendments a record takes.** Rejected. The count is not the cost: at
   `e743113` a single amendment of `ADR-007` ran past 12,000 bytes while `ADR-023` carried thirteen
   of about a thousand each. A cap also turns the last permitted amendment into a reason to leave a
   false claim standing.
5. **Bound the kind of edit and the form it takes, and leave bytes to the table that declares
   them.** Chosen.

**For where settled design belongs.**

1. **A section of its own inside the record.** Rejected. It is the present arrangement under a
   heading: the record still grows with the thing it describes, and a session still reads rejected
   alternatives to reach a grammar.
2. **A new tier of design documents beside the records.** Rejected. `reference/` already holds
   specification documents and one of them already states the boundary, so a second tier would hand
   every subject a rival home.
3. **The surfaces that instruct a session — the charter, a verb's file, an agent's prompt.**
   Rejected as the home. They are the reads paid for most often, an instruction belongs there and
   its reasons and measured limits do not, and a measured boundary is not an instruction at all.
4. **The specification document for the subject, under `reference/`.** Chosen.

## Decision

### 1. What an Accepted record may gain

An amendment is bounded by what it states, and never by its size. **The bound is stated once, as
the rule an author follows, in `reference/adr/README.md` § *Convention*, in the bullet *What an
amendment may add*.** That bullet is its home and its one statement; this record decides it and
does not restate it. It keeps the edits the convention already admits — correcting a claim,
narrowing a scope or coverage statement, repairing a citation, recording a decision taken in
another record — and closes the two ways the records measured above grew past them: a rule or a
mechanism added beside a correction, and settled design restated inside one. It names the edits
this record itself orders as inside it, and it applies to a record from the change on `main` that
ratifies it.

**The bound is on what an edit states, and not on bytes.** This record states no byte figure. The
byte parameters a size assertion reads for these files are declared in
`reference/load-class-model.md`, and nothing here restates them. The two answer different
questions, so neither can contradict the other: a change outside the bound is refused at any size,
and headroom never admits one.

### 2. An amended record reads at its current state

Amendment stays in place, so a record owes its reader the decision in force without a replay. The
form that gives it is the consolidated-decision form. `reference/adr/README.md` § *Convention*
states it as the rule an author follows, and is its home; this record decides what that form
guarantees.

- **Every new amendment is an entry.** From the change that adds the form to § *Convention*, the
  account of each new amendment of a record Accepted on `main` is a dated entry in a closing section
  after References, and no new account is written into the `Status:` line or into a section.
- **What was written before stays until it is moved.** A record already amended keeps its earlier
  accounts where they stand, in either earlier form or in both, until a consolidation moves them,
  and a record changed without an account takes no entry for that history.
- **An entry is still found by what cites it.** It keeps the date and the ordinal the amendment is
  cited by, and it quotes the wording it replaced where that wording still stands, in the record or
  in an earlier account, so moving an account there deletes nothing a reader can still read.
- **The body is current where it is amended.** A corrected claim stands corrected in the sentence
  that makes it.
- **The `Status:` line is status.** It carries the lifecycle value, its date and the record of any
  partial supersession — what tells a reader whether a decision is in force.
- **Consolidating is optional, and it is not deciding.** A change may move every earlier account
  of a record into entries and rewrite its sections to what those amendments left in force. Nothing
  schedules it, and it changes no decision.
- **Superseded text does not move.** The partial-supersession form is the one `ADR-029` § 7
  codified, and it is unchanged in every record, consolidated or not: the supersession is recorded
  where that form says, the form governs wherever it and this one differ, and the text it retains
  stays where it stands, with its marker.

### 3. Settled design belongs in the specification, and the record keeps the decision

Settled design is the shape a decision takes once it is built: its tables, grammars, enumerations,
procedures, measured boundaries and ledgers of what remains open. **Its home is the specification
document for its subject under `reference/`**, and never a record. The boundary is the one
`reference/data-architecture.md` § 12 states for itself: the record is authoritative for the
decision, the specification for the shape, and where the two overlap they must agree. Each side
says so. The specification names the record that decided its subject. The record states the
decision, its drivers, the options with the reasons each was rejected and the consequences, and
points at the specification for the shape, or at the suite group that already pins it.

This governs a correction as much as an addition: § *Convention* says how a correction of settled
design is made, and the shape stays in its home. Where a subject has no specification document and
no suite pins its shape, the change that would otherwise write settled design into a record names
the `reference/` document that takes it, creating one if none fits. An instruction a session
follows stays in the surface that instructs it; this rule is about the text that specifies, and
moves none of that.

A machine-readable declaration that restates a decision exactly is not settled design: it is the
decision, in a form a program reads. § *Convention* says when one is admitted.

### 4. Rejected alternatives are out of scope for any reduction

A rejected alternative is an option a record weighed and did not take, together with the reason it
gives. **No consolidation, relocation or reduction that follows from this record removes or rewords
one.** It stays in the record, in the record's own words, wherever it stands: under Options
considered, in a passage inside a decision, in a cell of a table. The line a later change has to
draw is between *why an option was rejected*, which only the record holds, and *how the chosen
option behaves*, which is settled design and has a home elsewhere. A change that cannot draw it for
a passage leaves that passage where it is.

### 5. What this record does not do

It restructures, reduces and re-states no record: every record reads after it as it read before,
`ADR-007` included. It moves no settled design and creates no specification document. It adds no
check. And it does not decide whether a record may carry scheduling content, which is a separate
rule about what a record contains.

## Consequences

**Positive**

- A reader of a record amended after this one finds each new amendment's account after References,
  and a consolidated record carries nothing between its title and its Context but its status.
- A record stops being the place a mechanism is specified, so it stops growing when the mechanism
  changes: a correction of settled design leaves a pointer, not the shape.
- The content only a record holds — why an option was rejected — is named as the one thing no
  later reduction may take.
- These files keep one byte bound, and its parameters stay declared in one table.

**Trade-offs**

- The author who would have added a rule to an Accepted record now writes a new record or edits a
  specification. That costs a number or a second file each time, and the cost is the point.
- A correction of settled design whose shape has no home costs a specification document first.
- A record already amended keeps its earlier accounts where they stand, beside its new entries, and
  is still replayed until a change consolidates it; no change is scheduled here. Its next amendment
  costs one new section and restructures nothing.
- Other files cite an amendment by its date or its ordinal. An entry keeps both, so those citations
  still find it; one that locates an amendment by the section it stood in finds it in the appendix
  instead.
- The partial-supersession form is `ADR-029`'s decision, and an amendment cannot change it, so the
  account of a supersession can still stand in a `Status:` line.
- Nothing in this repository checks any clause of this record. Decisions 1, 3 and 4 are applied by
  whoever reviews a change, and the form in Decision 2 is checkable by reading and by nothing else.
- `ADR-008` and `ADR-007` keep the settled design they hold. A change that later moves it has
  readers to move in the same change: `scripts/test-command-taxonomy.sh` reads the disposition
  table in § 4 of `ADR-007`.

## References

- The convention this record extends, and the home of the bound and of the consolidated-decision
  form: `reference/adr/README.md` § *Convention*.
- The partial-supersession form Decision 2 leaves as it is:
  `reference/adr/ADR-029-group-approval-return-and-threshold.md` § 7.
- The boundary Decision 3 generalizes: `reference/data-architecture.md` § 12.
- The byte parameters Decision 1 defers to: the parameter table in `reference/load-class-model.md`.
- The measurement in § *Context*: the first Accepted revision of each record found by
  `git log --follow -M` over its path, compared with `e743113` and with the commit on `main` that
  first carried it; what the added lines state was coded by hand.
- Driving work: #1179, under #1169.
