# ADR-053: A field keeps its key — an authored key on its row of the classification table, its former labels declared beside it, and a test that decides which readers name a field by it

- **Status:** Accepted (2026-11-20)
- **Deciders:** repo maintainer
- **Driving work:** #2244, at the head of the *A form field keeps its key when its label is reworded*
  milestone. The build that reads the key is #2211. The operator ruled the direction on 2026-11-13,
  in the card's *Settled direction* section, after a decision packet tested four homes for the key
  against the cards' criteria and against `ADR-023`. This record transcribes that ruling as
  decisions. It adds the operator's refinement of the key's grammar from the release's plan gate,
  decides the two items the ruling left to it, and states the precedence and couplings the ruling's
  test needs; the operator confirmed those at the release's scope-lock.
- **What this record is.** A decision about where a form field's identity is declared, which readers
  name a field by it, and how a field stays readable after its label is reworded. It is addressed to
  whoever adds, rewords or classifies a form field, and to whoever writes a reader that names one.
- **What this record is not.** It moves no reader by itself, changes neither intake form, supersedes
  nothing in `ADR-023`, and decides nothing about a field's class, scope or horizon.

## Context

A field is counted and addressed by its `(section, label)` pair. `reference/data-model.md`
§ *Field Scope* counts and classifies fields by that pair, and
[ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) D2.6 question 3 joins a form's bullet
to its row on it, reading the section as a leading segment of the bullet's heading. Readers that mean
"this field" use the pair, or the label alone: the classification table, the private-site declaration
in [ADR-030](ADR-030-what-the-private-site-may-show.md) and the readers of that record's prose, the
suite's form model, the test conversations' `<section> › <label>` field reference, and the
publish-guard selectors.

Three things follow, each met in the tree:

- **A reword is a key change.** Every reference to the old pair moves with it. `Solo, I'd` was named
  27 times in 14 files when #2211 was filed, and 45 times in 17 files at `fe637d8`.
- **A label can hold a separator.** The test-conversation format separates the fields a turn puts with
  commas, so `People dynamics › Solo, I'd` cannot be written as designed. Milestone 61 met this at
  Stage 6 (#2201, finding F-1) and quoted that name as a stopgap.
- **One label is carried by two rows.** At `fe637d8`, `Applies to` is the label of a `Needs` row and
  of a `Hard Constraints` row, which differ only by section.

A profile already written does not say which version of its form it came from: no tracked example
profile or person record carries the form's fence. So a reword leaves written profiles holding the old
label, and a reader keyed on the new one reads that answer as absent. For a need, an absent constraint
reads as compliance.

[ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) has touched this ground twice. D2.4
weighed and rejected **(b)**, a per-field key in the `intake-form` fence, as a home for the
closed/open marker: a per-field value in a per-form declaration grows with the field count in the one
place D6.1 keeps flat. And D6.1 counts one new row in the classification table per new label: "the
irreducible cost, and it is the data model's".

The data architecture does not settle a field's key. `reference/data-architecture.md` § 3 states its
identity rule for the entities of § 2's model, and a form field is not one of them: it is an element of
the schema, authored in a specification document. Read by analogy, the rule's natural branch would give
a field its label, which is exactly the key a reword moves.

**Why this is a record.** `reference/adr/README.md` § *Convention* asks for one where a decision is
cross-cutting or hard to reverse. This one is both. It reaches every form-shaped surface and every
reader that names a field, and a key's spelling is expensive to change once readers cite it.

## Decision drivers

- **A person filling a form sees no key** (#2211 criterion 2), and the forms keep the shape
  [ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) D2.1 gave them: the fence, and
  nothing else new.
- **The fence stays flat as fields grow.** `ADR-023`'s rejected (b) stands for this purpose too.
- **One home for a field's identity**, beside the per-field axes it already carries (`Class`,
  `Scope`, `Horizon`), so the identity is total over the fields and graded where they are.
- **A reword costs a known set of edits**, not a census of references.
- **A value written under an old label stays readable**, and absence is never read as an answer.
- **What a guard matches in rendered text never shrinks.**
- **Which readers move is a test, not a list** (`CLAUDE.md` § *Rules over an enumeration*;
  [ADR-047](ADR-047-rules-over-an-enumeration.md)).

## Options considered

Where the key is declared:

1. **(A) A `Key` column, appended last, on every row of the classification table.** **Chosen — see
   below.** The forms do not change, and the table already holds one row per field.
2. **(B) A key carried on the form**, as a comment line above each bullet. **Rejected.**
   *Kill-reason: it shows in the raw file a person fills in, it changes both forms, and it reopens*
   `ADR-023` *D2.1.* It is the only home that meets #2211's original criterion 4, which the ruling
   rewords instead.
3. **(C) A key in the form's `intake-form` fence.** **Rejected.** *Kill-reason: it is* `ADR-023`*'s
   rejected option (b).* It is also dominated by (A), which already holds a row per field.
4. **(D) No key, with former labels alone.** **Rejected.** *Kill-reason: the comma-bearing label and
   the growth in references both stay.*

The key's shape:

5. **(E) A readable authored slug.** **Chosen — see below.** A key is written into declarations and
   fixtures that people read.
6. **(F) An opaque minted token, like a person's id.** **Rejected.** *Kill-reason: a minted token is
   for a record the engine creates, as* `reference/data-architecture.md` *§ 3 has it, and an opaque
   token would make every fixture and declaration that names a field unreadable.*

How the move proceeds, and how wide the key goes:

7. **(G) The registry, with new references written by key while existing ones stay on labels until a
   later move.** **Rejected.** *Kill-reason: it leaves two ways to name a field inside one reader's
   population for as long as the later move waits.* Each reader here moves its whole population at
   once.
8. **(H) A key only on the guided forms' rows.** **Rejected.** *Kill-reason: the column would be
   partial where `Class`, `Scope` and `Horizon` are total*, and a trip-context field would take its key
   in a second migration the first time a reader needed one.

## Decision

**1. A field's key is declared in a `Key` column, appended last, on every row of the classification
table in `reference/data-model.md` § *Field Scope*.** The forms do not change. A form's bullet still
finds its row by `(section, label)`, as
[ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) D2.6 question 3 selects. Every other
reader that names a field to the suite cites the key, and Decision 4's test says which readers those
are. The column stands last because the suite reads the table by column position, and a column
inserted before another shifts every axis read after it.

**2. The key is a readable authored slug.** It is written once, in ASCII lowercase letters and digits,
in segments joined by single hyphens, with no empty segment and no hyphen at either end. It is unique
across the whole table, and it is never re-derived from the label. The ruling of 2026-11-13 gave the
character set, and the operator settled the slug form at the release's plan gate on 2026-11-19, so
that `-` and `a--b` are not keys. § *Field Scope* states the grammar, and the convention by which a key
is first written, as settled design.

**3. A reworded field's former labels are declared beside the table.** A row exists only for a field
that has been reworded, so the declaration starts empty and grows with rewording, not with the field
count. A profile already written, or a form sent out before a reword and returned after it, is read by
its current or former label, and the engine never rewrites it. A former label is never reused for
another field in its section.

**4. Which readers move to the key is a test** (`CLAUDE.md` § *Rules over an enumeration*). A reader
moves to the key when it names a field in a line the suite parses as a declaration or a fixture. A
reader stays on label text when it reads what a person wrote or will read, when it scans rendered text
for the word, when it is byte-identical evidence, or when it is a record. Where more than one limb
holds for a name, they rank in this order:

1. A name that is matched against text a person wrote or will read stays on the label, even where a
   suite also parses its line. That covers a form's and a profile's bullets, the publish guard's and
   the traveller projection's selectors, and a prompt or skill line that tells a model which line of a
   person's file to read.
2. Otherwise, a name that identifies a field to a reader — one the reader resolves against the
   classification table, in a declaration or a fixture — moves to the key, even inside a record or in
   a file that also holds a person's words. The record's prose and those words stay as written.
3. Decision 5 bounds both: only the guided forms' fields are in reach.

A *declaration* is a fenced or tabular block that a reader parses to learn which fields a rule covers.
A *fixture* is a file the suite reads as input to grade a reader. The suite's own literals are neither:
an arm that names a field is a reader of its subject, decided by limb 1 or limb 2 like any other. A
reader nobody has classified is decided by the test, never by being absent from the examples.

Today the test moves the private-site declaration inside `ADR-030` and the test conversations' field
references. Those two are examples. These stay on labels:

- the forms and written profiles;
- the interviewer's asks;
- the guard and projection selectors;
- the trip-resolution evidence;
- the decision records;
- the changelog;
- the agent prompts and skill prose that point at a person's file.

**5. Every row takes a key now, so the column is total.** Readers move only for the two guided forms'
fields, and no trip-context reader moves.

**6. A reworded guarded label keeps its old spelling as a guard selector for good.** A reword adds a
word the publish guard and the traveller projection match, and never removes one.

**7. Declarations and fixtures are rewritten once. Example profiles and decision records are not
rewritten.**

**8. Nothing is superseded.** `ADR-023`'s rejected option (b) stands, and its D2.6 question 3 stays as
how a form's bullet finds its row. The pair stays how a field is counted and addressed. What the key
adds is the field's identity, which a reword leaves alone, and § *Field Scope* states both.

**9. An edit that keys `ADR-030`'s live fence takes the form of an amendment.** It is an entry in that
record's `## Amendment history`, in the consolidated-decision form. `reference/adr/README.md`
§ *What an amendment may add* admits it as a machine-readable declaration that restates exactly what
`ADR-030` § *Decision* 2 states:

- a row that names a field names it by key, in place of its section and label cells;
- every row keeps its class and its `as-written` words;
- no row is added or removed;
- the entry quotes every comment line it replaces, and states that a row's former section and label
  are those of its key's row in the table.

No decision of `ADR-030` changes, and the edit is not a supersession.

**10. A reader that holds a decision record's prose to a declaration accepts a field's former labels
wherever it accepts its current one.** Every comparison such a reader makes between the record's text
and a field's label accepts each of that field's former labels as well: placing an item, tying a row to
an item by the first word of its label, and checking that the words a row cites are not a label. The
readers of `ADR-030`'s prose are of this kind. The record is not amended at a reword, because
Decision 7 does not rewrite decision records.

## Consequences

**Positive**

- Once its readers move, a reword touches the label's two statements, the form's bullet and its row,
  plus one former-label row. A guarded label also gains its new spelling in the guard's selectors
  (Decision 6).
- A fixture can name the comma-bearing field by key, and the quoting stopgap retires.
- The two `Applies to` rows are told apart by key, with no section needed.
- A new field is born with a key, at the cost `ADR-023` D6.1 already counts: one row.

**Costs, and what holds them**

- **A key's spelling is expensive once readers cite it.** Keys are written once, and the suite grades
  their shape and their uniqueness across the table.
- **A former-label row for every reword, kept for good.** The suite grades that each row names a key
  the table carries, that it differs from the field's current label, and that it is not reused in its
  section.
- **A label still has two statements**, the bullet and the row, because a bullet finds its row by its
  label.
- **Guard selectors only grow** (Decision 6).
- **Residual: a reader that stays on labels goes stale at a reword unless something reports it.** The
  agent prompts and the skill prose are such readers. Nothing reports a former label still named
  there, so a reword leaves them stale silently, until a check of that kind exists.
- **Residual: nothing marks which form version a written profile came from.** The former-label rows
  carry what a reader needs instead.

**What this decision makes false or necessary elsewhere**

- `reference/data-model.md` § *Field Scope*: the `Key` column on every row, the former-label
  declaration, the key's grammar and first-writing convention, the current-or-former reading rule, and
  the statement that a field is identified by its key.
- `scripts/test-artifact-schema.sh` group FT: the key column graded as total, well-formed and unique,
  and the former-label declaration graded as resolving and never reused.
- The test conversations, which hold 796 field references in 61 files at `fe637d8`, and group `CF`'s
  field-reference grammar: a field named by key, and the comma quoting retired.
- `ADR-030`'s private-site declaration, whose 38 field-naming rows at `fe637d8` name fields by key
  under Decision 9, and the readers of that record's prose, groups `MC` and `NC`, under Decision 10.
- Every reader of a written profile that reads it by label accepts a former label (Decision 3).

**Couplings a reader of the plan must keep, each with its reason**

- **No reader moves before the column exists**, because a key a reader cites has to resolve in the
  table.
- **`ADR-030`'s fence moves with group `MC`**, because a keyed fence read by a label-resolving reader
  fails that group. The test conversations move with group `CF`'s grammar for the same reason.
- **No field is reworded, and no former-label row is added, before every reader of a written profile
  accepts a former label.** An answer that reads as absent drops a need silently, and an absent
  constraint reads as compliance.
- **A guarded label is not reworded before its new spelling is a guard selector.** Until it is, a
  value under the new label is unguarded.
- **The prose readers accept a former label no later than the first reword of a field that
  `ADR-030`'s prose names**, because until then that reword fails their verdicts.

**The reach, measured.** Measured by what it moves, the build this decision opens covers:

- 796 field references in 61 conversation files and group `CF`'s grammar;
- 38 declaration rows and the two prose readers;
- the readers of written profiles;
- the registry itself.

That is above the largest size this repository's scale gives one card. The build's size and its
slices are written on #2211, because an Accepted record carries no schedule (`reference/adr/README.md`
§ *Scheduling content*).

## References

- The ruling: #2244, § *Settled direction* (the operator, 2026-11-13). The refinement of the key's
  grammar, and the operator's confirmation of Decision 4's ranking, of the guarded-label consequence
  and of where the build's slices are written: the Stage 4 and Stage 5 decision records on the release's
  planning sub-task, #2376, and its scope-lock record.
- [ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) D2.1 (the form's shape), D2.4
  (rejected option (b)), D2.6 question 3 (the join), D6.1 (the row a new label costs).
- [ADR-030](ADR-030-what-the-private-site-may-show.md) § *Decision* 2, and its amendment of
  2026-10-08, which added the `private-site-field-declaration` fence.
- `reference/data-architecture.md` §§ 2–3, the entity model and its identity rule.
- `CLAUDE.md` § *Rules over an enumeration*, and [ADR-047](ADR-047-rules-over-an-enumeration.md).
- `reference/adr/README.md` § *Convention*: *Scheduling content* and *What an amendment may add*.
- The cards and the observation: #2211, the build; #2201's finding F-1, the comma stopgap.
- Implementation: `reference/data-model.md` § *Field Scope*. Regression coverage:
  `scripts/test-artifact-schema.sh` group FT.
