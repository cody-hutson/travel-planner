# ADR-022: The interview session model — derived resumption, a three-valued read of the unanswered class, and one write per answer

- **Status:** Proposed (2026-09-20)
- **Deciders:** repo maintainer
- **Driving work:** the *interviewer becomes a component* milestone. This record is one of that
  milestone's two Wave-0 gating records, in the shape `ADR-012-people-library.md` and
  `ADR-016-reusable-groups.md` already ship: it lands before any feature slice and settles a
  cross-cutting question every slice would otherwise answer separately. The two records split
  one subject on a stated axis — **this record decides behaviour over time**, and its sibling
  `ADR-023` decides **structure**. Slices are cut after both close.
- **What this record is.** A decision about **what an interview session does over time**: what it
  reads, what it writes and when, how it resumes, who it may interview, and what it must never
  utter in a conversational channel. Its subject is a session, not a file and not a sentence.
- **What this record is not. It decides no placement, no form declaration, and no conduct.** It
  does not decide where conduct is authored, which command surface reaches it, whether a form's
  guide moves, what a conforming form must carry, or how conduct reaches a reader with no
  repository — those are `ADR-023`'s. It decides no tone and no wording: § *Decision* 5 states
  **prohibitions on the interviewer's output**, testable by reading a transcript, and a sentence
  that would change how a question *feels* belongs to the engagement slice rather than here.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the operator's, taken at this milestone's close, and it moves **both** halves of
  a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  `reference/adr/README.md`. No required check here grades either half or their agreement, so the
  obligation travels with this line rather than with a gate. `ADR-021-installable-capability.md`
  carries the same clause for the same reason, and names the predecessor that was flipped in its
  own file while its index cell was left behind.

## Context

**The engine already owns both halves of a resumable interview and joins them nowhere.**

`reference/data-model.md` § *`ANSWERED()`* defines the predicate that decides whether a field
carries an answer, and `scripts/test-artifact-schema.sh` already computes it. Both intake forms
tell their reader *"you can come back for the rest."* Nothing interviews against the predicate,
and the promise is kept by the filesystem rather than by any interviewer.

**The promise is broken on exactly one of the three create routes, and the narrowing is
load-bearing rather than cosmetic.** `skills/trip-record/SKILL.md` § `profile <name>` offers three
create routes. Route 2 writes the blank form to its path and the traveller edits it in a text
editor; route 3 hands that same file to someone else. For those readers the promise is kept
perfectly today — the file is on disk carrying its placeholders and they reopen it. It is **route
1** — *walk through it here, then write the file* — that breaks it, and it breaks it by holding the
whole interview in conversation until a single terminal write.

That reframes the fix. **The substrate routes 2 and 3 already use is the correct session state, and
route 1's defect is that it declines to use it.** The lifecycle in § *Decision* 1 is therefore an
alignment of route 1 with its two siblings, not an invention.

**`ANSWERED()` is necessary and it is not sufficient, and this is the record's central finding.**
`reference/data-model.md` states the limit in its own terms: *"`ANSWERED()` is an instance property;
presence is a document property. They share the word *present* and answer different questions."* A
resumable interview needs **both** — the *document* question (what does this form ask?) to know the
question set, and the *instance* question to know what is left of it. The document half is read from
the **form**, not from the instance; otherwise a hand-deleted line silently retires a question,
which is what the forms' own *do not drop sections or fields* rule exists to prevent.

**On the question side the predicate collapses two states that resumption has to tell apart.**
`ANSWERED()` is total and three-valued on the record side, but every unanswered shape falls into one
class: a surviving `[bracketed placeholder]`, a lone `—`, a blank, and an absent line are alike to
it. An interviewer reading only `ANSWERED()` cannot distinguish **nobody has asked this** from
**they were asked and declined**.

**That distinction is the binding constraint, and the naive design fails it silently.** The
milestone's inherited constraint is *`Skip` stays valid and nothing pushes twice*. Under
write-at-the-end, and under any resumption that reads `ANSWERED()` alone, a skip leaves no trace —
so every resumed session re-asks every skipped field. **The constraint is violated by the resumption
mechanism itself, and no gate in this repository can see it**, because `ANSWERED()` reports the same
value either way. This is the real defect, and it sits one level beneath the one that motivated the
work.

**The discriminator is already in the bytes and the engine already sanctions reading it.**
`ADR-007-command-entry-point.md` § 2 requires that a branch meaning *not yet decided* test the
**value** against the placeholder form, and holds that absence is a different condition and never
the same branch. Both forms ship every field bracketed. The forms say the same thing to their own
readers: a leftover `[bracketed placeholder]` *"reads as unanswered, exactly like an empty line, and
a profile still carrying its brackets reads as one nobody has filled in yet."*

**Voice turns a convenience into a correctness property, and the reason is mechanical rather than
atmospheric.** Under write-at-the-end the artifact does not exist until the interview ends, so the
loss bound on abandonment is the whole session **on every modality**; voice merely removes the
consolation that the traveller can scroll back. A conversational channel also attacks the engine's
central prohibition from a new direction: *never invent* is enforced today against a reader filling
a form, and in conversation the failure mode is **paraphrase** — a confirmation that supplies a
value the traveller did not say.

## Decision drivers

**The four inherited operator-set constraints, held rather than weighed:**

- **The engine never invents, on any modality.**
- **`Skip` stays valid and nothing pushes twice.**
- **The artifact set stays contained and closely maintained.**
- **No new privilege.** The grant set stays what `skills/trip-record/SKILL.md` already holds.

**The drivers this record adds:**

- **No new artifact class.** A stored session cursor is not merely a cost; it is a durable record of
  a person's interview progress, and § *Options considered* shows what it drags behind it.
- **`ANSWERED()` is not redefined, not forked, and not touched.** `reference/data-model.md` already
  records what happens when a second predicate is built over one vocabulary: two predicates
  legitimately disagree and the divergence is asserted nowhere. That warning binds this record too.
- **Route 3 is not dropped.** A channel with no write path is a supported channel, and the contract
  it already ships stays.
- **A prohibition must be gradeable by reading a transcript.** *Do not add meaning* is guidance;
  two reviewers disagree about meaning, and the failure mode is precisely a confirmation that
  *feels* meaning-preserving.

## Options considered

Two choices carry more than one candidate. Every other cluster has a single forced approach once
these land, and each says so where it lands.

### Choice 1 — where resumption state lives

| | **O1 — derived from the artifact** | **O2 — stored cursor artifact** | **O3 — frontmatter cursor key** | **O4 — derived answers, stored ordering** |
|---|---|---|---|---|
| New artifact class | **none** | **one** — needing a class id, a path pattern, a `reference/schemas/` member, a row in the class enumeration, a lifecycle, a publish posture and a witness | none | none |
| Cascade into `reference/data-architecture.md` § 1.1 | **none** | the heading numeral **and** the validator constant that must equal it, plus the bijection arm and the delta log | none | none |
| Schema change on the two interview target classes | **none** | none | **required** — and `reference/data-architecture.md` § *Schema evolution* declares those two classes permanently tolerated at version 0 and *"Never engine-upgraded. This is a rule, not an omission."* A `required` key makes every existing file non-conforming; an `optional` key is advisory, so the derivation is still needed and the key is dead weight | none |
| Row in the `erase` reach table | **none** | **one** | none | none |
| Distinguishes skipped from un-asked | **yes**, by § *Decision* 1's refinement | yes | yes | yes |
| Survives a hand-edit between sessions | **yes** — the artifact *is* the state, so an edit is absorbed by construction | **no** — a cursor and a hand-edited file disagree and nothing arbitrates | no | partial |
| Survives the file being mailed out and returned | **yes** | no | yes | no |
| **Verdict** | **SELECTED** | rejected | rejected | rejected |

**Ground for rejecting O2 — reachability, not cost.** A cursor recording what a person was asked is
person data at a new address, so `erase` must reach it; reaching it adds a row to a table that
`skills/trip-record/SKILL.md` standing rule 10 makes **total** — *a location absent from that table
is not reachable by omission, it is unreachable*. And the cursor cannot be reconciled against a
hand-edit, which routes 2 and 3 make the **normal** authoring path rather than an edge case.

**Ground for rejecting O3 — forced by the schema's own reasoning.**
`reference/schemas/traveler-profile.md` says of its one optional key that *"`optional` is forced,
not stylistic, and it is the whole of the compatibility guarantee."* The same argument applies to
any new key, which converts O3 into O1 plus an unused field.

**Ground for rejecting O4.** The ordering it would store is the form's section order, which the form
already carries. Storing it gives that order a second home.

### Choice 2 — write cadence

| | **W1 — per answer** | **W2 — per section** | **W3 — once at the end** | **W4 — per answer, buffered, flushed on idle** |
|---|---|---|---|---|
| Loss bound on abandonment | **one answer** | one section | **the whole session** | one answer *if* the flush fires; a session killed mid-buffer loses the buffer |
| Makes derived resumption sufficient | **yes** | yes | **no** — nothing is written, so every field reads un-asked | yes |
| Voice-safe | **yes** | partial — a section's answers are held in conversation over exactly the window a dropped call destroys | no | no — *idle* is indistinguishable from *gone* |
| Write shape available today | `Edit`, under standing rule 2's second condition | the same | `Write`, under rule 2's first condition | the same |
| **Verdict** | **SELECTED**, with the block carve-out below | rejected | rejected | rejected |

**Ground for rejecting W2 and W4.** Both hold answers in conversation across exactly the interval
the failure occupies. W4 additionally needs an idle timer, which is session state by another name
and lands back on O2.

**The cost of W1 is real and is accepted rather than minimised.** A slot-scoped form is walked one
`Edit` at a time, so a fully-canvassed trip form is a long run of tool calls where W3 was one. It is
accepted because the alternative buys a smaller number by re-opening the loss bound this record
exists to close, and because the block carve-out in § *Decision* 2 collapses the worst section on a
principle `reference/data-model.md` already declares rather than as a negotiated compromise.

## Decision

Six clusters. The decision count is **5 + 6 + 6 + 4 + 6 + 5 = 32**, one series per cluster.

### 1. Session lifecycle and resumption

**D1.1 — Resumption state is DERIVED. No new artifact class is created.**

The derivation reads three inputs, all of which exist today:

1. the **form's** ordered question set and its per-field placeholder form — the *document* half,
   enumerated in § *The seam* as S1 through S3;
2. the **instance's** per-field value;
3. `reference/data-model.md` § *`ANSWERED()`*, applied to (2) and **read live, never re-authored** —
   the same live-read discipline `skills/trip-record/SKILL.md` already declares for this predicate.

Nothing else is read and nothing is stored. No class id, no path pattern, no schema member, no row
in the class enumeration, no lifecycle, no publish posture, no witness, and **no row in the `erase`
reach table** — the receipt stays total over the table it already declares.

*Rejected:* O2, O3 and O4, on the grounds in § *Options considered*.

**D1.2 — The lifecycle is seed-then-edit. Route 1 becomes route 2 followed by field-scoped edits.**

- **Starts.** After `profile`'s ordered checks pass, the **create** branch writes the form to the
  target path **once, complete, before the first question is asked**. That is route 2's shipped act.
  The **edit** branch writes nothing at start.
- **Resumes.** Resumption is **not a verb, not a mode and not a flag** — it is what the verb does
  when the file-existence probe finds a file. The precedent is in the engine:
  `skills/trip-new/SKILL.md` § *Resume — repair only* is likewise selected by a probe and never
  typed. *Rejected:* a `resume` sub-verb — it adds a token the operator must know in order to select
  a branch a probe already decides, and a wrongly-typed `resume` against an absent file would need a
  further branch that the probe makes unreachable.
- **Abandons.** **There is no abandon event and nothing marks one.** A session that stops has
  stopped; the artifact is the state. A mark would be stored session state, which is O2 renamed.
- **Completes.** **"Complete" is not a state of the artifact, and this record declines to invent
  one.** **Every bulleted field on both forms is skippable** — each form says as much in its own
  words — so there is no predicate over the *answers* that the engine may evaluate to mean *done*.
  The one field a form does require is the **person form's title line**, which `S6` carries and which
  that form calls the one thing the record cannot do without; it is a requirement on the artifact's
  **identity**, not a completion predicate over the canvass, and satisfying it establishes that the
  record can be addressed rather than that the interview has finished. What is computable is
  **fully-canvassed**: every field is answered or declined and none is un-asked. The interview
  *ends* when the traveller ends it or when the question set is
  exhausted. **Completeness is a property of the canvass, never of the answers**, and no engine
  branch may block on it — which is the flow-side reading of `agents/00-enrichment.md` § *Missing or
  blank profile*, where a file still left as unfilled placeholders is a normal state that must never
  halt reconciliation.

*Rejected for the seed:* keeping route 1's terminal `Write`. It is the mechanism that breaks the
promise, and it forces the create-or-edit branch to be re-decided at the *end* of a session rather
than at its start, when the collision check already ran.

*Accepted cost, stated:* seed-then-edit creates a file for a traveller who may answer nothing. That
state is already sanctioned twice — by `profile` route 2, where a file of unfilled placeholders is a
legitimate state, and by the enrichment blank-profile branch — and the branch that absorbs it is
unchanged.

**D1.3 — The three-valued refinement. `ANSWERED()` is not redefined.**

This is the join the milestone assigned to this record: the bridge between the instance-side
predicate and the document-side contract. `ANSWERED()` stays exactly as `reference/data-model.md`
states it, total and untouched. This record defines a refinement **of its false class only**,
downstream of it, for the interview's use and no other consumer's:

| Instance value of a field | `ANSWERED()` | Interview state | Interview behaviour |
|---|---|---|---|
| anything else, including `none` | **true** | `ANSWERED` | never re-asked; changed only under D2.3 |
| matches the form's own bracketed-placeholder form for that field | false | **`UNASKED`** | **ask** |
| exactly `—` | false | **`DECLINED`** | **do not re-ask** |
| blank, or the line is absent | false | **`INDETERMINATE`** | **ask** |

- The discriminator is **sanctioned, not invented.** `ADR-007-command-entry-point.md` § 2 requires
  that a branch meaning *not yet decided* test the **value** against the placeholder form, and holds
  that absence is *"a different condition — a malformed or truncated file — and it is never the same
  branch."* `UNASKED` is that value test; `INDETERMINATE` is that different condition, kept separate
  exactly as the bound requires.
- The refinement is **invisible to every existing consumer**, because every one of them branches on
  `ANSWERED()`, which is unchanged: the composition lattice, the extractor's partition, the
  promotion refusal, the enrichment defaults, and the assertion groups that read the forms. No
  consumer distinguishes the placeholder from the em dash today, so nothing reads differently after
  this record.
- `INDETERMINATE` is asked rather than skipped on the engine's own tie-breaker —
  `reference/data-model.md` § *The decision rule*, *"The cheap error is the safe one."* A re-asked
  question costs one question; a silently retired one costs an unasked need.

*Rejected:* **(a)** extending `ANSWERED()` itself to three values — it is consumed by the
composition lattice, by extractor groups parsing by column position, and by assertion groups;
widening it to carry an interview concern would make a planning predicate answer an intake question,
which is the exact defect `reference/data-model.md` records against reusing its sibling predicate.
**(b)** a per-field marker such as a literal `[SKIPPED]` token — it is a new token in a
human-authored file, it would need a publish disposition and an `ANSWERED()` ruling, and the em dash
already means it. **(c)** reading skip-ness from `trip-log.md` — the log is a decision register, and
a traveller's answers are not decisions (see D6.5).

**D1.4 — Re-running over an already-filled artifact resumes it; it never re-opens it.**

Answered fields are not re-asked. Declined fields are not re-asked. Un-asked and indeterminate
fields are asked, in the form's order. To change an answer the traveller names it, which routes to
D2.3. **A re-run never re-asks an answered field and never rewrites one without the echo**, so
re-invocation is idempotent on the answered set — which is what makes it safe to re-invoke after a
partial session without the operator having to remember where it stopped.

**D1.5 — The partially-filled artifact remains legitimate, and this record bounds it rather than
re-deciding it.** It is legitimate today, by `profile` route 2 and by
`agents/00-enrichment.md` § *Missing or blank profile*. The bound this record adds is that **a
partially-filled artifact is legitimate at every instant, including mid-write** — which is D2.5's
subject and is where the bound is discharged.

### 2. The write model

**D2.1 — Cadence: one write per answer, for a `slot`-scoped field.** Selected as W1. The tool is
`Edit` under standing rule 2's second condition — *the target path exists and only the named field's
lines change* — which is the shape `profile`'s edit route already ships. **No new tool grant is
taken, and the grant union is unchanged.**

**D2.2 — Cadence: one write per completed unit, for a `block`-scoped field.** A repeat unit is
appended **whole**, when the unit is complete, with **every label of the unit present** and
unanswered labels keeping their bracketed placeholder. The tool is `Edit` under **standing rule 7**,
whose admitted shape is *"the target exists, no existing line changes, and the write adds lines at
the end of the file **or under the block's own repeat unit**."* The shape is `fact`'s, verbatim: a
new block written with all of the template's fields present, the unanswered ones keeping their
bracketed placeholders.

The `slot` / `block` split is **read live from `reference/data-model.md`'s `Scope` column and is not
restated here.** A half-written unit is not a legal unit, which is why per-answer cadence cannot
apply inside a block.

**Rule 7 admits the append of a unit that is not there, and only that.** A write *inside* a unit that
already exists changes existing lines, so it fails rule 7's own condition that *no existing line
changes* and is therefore not an append: its shape is **`Edit` under standing rule 2's second
condition, at unit granularity** — the target exists, and the lines that change are exactly the named
unit's labels. D3.3's spare-unit em dash is the case this record decides on that shape, and the
granularity is the unit for the same reason the cadence above is: a half-written unit is not a legal
unit. **Two write shapes, one cadence**, and no new standing clause is proposed for either.

**D2.3 — Changing an answer is one mechanism, within a session and across sessions.** Name the
field, **echo the outgoing value verbatim**, `Edit` only that field's lines, confirm. This is
`profile`'s shipped edit route, and the echo shape standing rule 9 requires of the one write that
leaves the trip. Within a session the outgoing value is what the file holds *now*, not what the
session remembers saying — see D2.6. **One rule, not two**, because a rule that differed across the
session boundary would need that boundary to be observable, which D1.2 declines to make it.

**D2.4 — A field returns to unanswered by taking the em dash, and this record resolves a live
contradiction between shipped surfaces that no gate can see.**

**The finding.** The disagreement is on the same byte, and it runs in opposite directions:

| Surface | What it says |
|---|---|
| `skills/trip-record/SKILL.md` standing rule 3, and § `profile` → *Edit* | *"An unanswered field is a skipped field and **keeps its bracketed placeholder**. A field the user says does not apply takes a single em dash."* |
| `templates/traveler-intake.template.md` and `templates/person-intake.template.md`, § *Assistant — producing the finished file* | *"For a field they **skipped**, keep the line and put a single em dash where the answer would go … **Do not leave the placeholder text in**, and do not delete the line."* |

Route 1 runs the interview *from the template's own script* — the template is the authority on its
own questions — and would emit the em dash; standing rule 3 says keep the placeholder. **`ANSWERED()`
collapses both, so no gate in this repository can see the disagreement.**

**The decision. Reconcile toward the templates: a skip writes `—`, and a surviving bracket means
nobody has asked.** Grounds, in order of force:

1. It is the only assignment under which a skip is observable, and therefore the only one under
   which *nothing pushes twice* survives a session boundary without a stored cursor.
2. It makes `agents/00-enrichment.md`'s blank-profile predicate **precise** rather than approximate:
   a heavily-skipped profile stops reading as untouched.
3. It preserves the distinction standing rule 3 exists to protect. Rule 3's real subject is *never
   collapse two states into one*, and this decision keeps two states; it reassigns which byte
   carries which, toward the surface a traveller actually reads.
4. `reference/data-model.md` already ships the em dash as the canonical un-answer in the one place
   it decides the question — the override-removal equivalence class, where deleting the line,
   blanking it, or writing `—` are alike, *"which is what the form's own instruction produces."*
5. The forms say it to their own readers in terms: a leftover `[bracketed placeholder]` *"reads as
   unanswered, exactly like an empty line, and a profile still carrying its brackets reads as one
   nobody has filled in yet."* That sentence is already the `UNASKED` semantics, written for a human.

**The consequence is named with its owner.** `skills/trip-record/SKILL.md` standing rule 3 and
§ `profile` → *Edit* must be amended in the same change that implements this. That amendment is
Wave-1 work, carried in § *Residuals*. **This record edits no file but its own.**

*Rejected:* **(a)** reconciling toward standing rule 3 — it makes a skip unobservable and forces O2.
**(b)** a third byte meaning *does not apply*, distinct from a skip — it is a new token, and the form
already declines the distinction for every field except the one block that carries `none` for
exactly this reason. **(c)** leaving the contradiction and letting each route follow its own surface
— it makes the artifact's meaning depend on which route wrote it, which no later reader can recover.

**D2.5 — A partially-written artifact conforms at every instant, and this is provable from the
validator's declared scope rather than asserted.**

Three independent grounds, each read live:

1. **Scope.** `scripts/validate-artifacts.sh` declares its coverage boundary in terms: prose is
   **out of scope, by name** — *"The schema constrains frontmatter. It never constrains narrative
   body content."* Every interview write is a **body** write, so no sequence of body writes can
   produce a non-conforming artifact.
2. **Frontmatter is written once and whole.** D1.2's seed emits the complete fence before the first
   question, and no later write touches it. There is therefore no interval in which the fence is
   partial.
3. **Skip predicate.** The two interview target classes are the ones
   `reference/data-architecture.md` § *Schema evolution* declares permanently valid at version 0 and
   never engine-upgraded, and the gate reads an absent schema version as version 0 and skips. Even a
   seed that lost its fence would skip rather than fail.

**The one way to break it, stated as a hard requirement because it is the single path by which this
claim fails.** `scripts/test-artifact-schema.sh` group `AR3` asserts that no template reaches the
selector, and states why: a template's `trip:` value is the placeholder and would fail the
frontmatter arm.

**The requirement is per form, and it is not the same requirement on both.** On the **trip form**,
whose template ships `trip: <trip-slug>`, the seed **MUST substitute** that value with the trip's
directory name at seed time — that placeholder is the one `AR3`'s warrant names. On the **person
form** the seed **MUST NOT touch `trip:` at all**: that form ships `trip: cross-trip`, a **reserved
sentinel** that `reference/schemas/person-record.md` declares as this class's narrowing of the
required `slug`, that resolves to no trip directory, and that the form's own fence instruction says
to leave exactly as it stands. Substituting it would turn a conforming cross-trip record into one
claiming a trip — a corruption of the very field the class narrows, and the failure this
qualification exists to prevent. What the person form's seed **MUST** do instead is mint the
record's own stem, which is a **filename** transform and not a frontmatter value: `artifact:` keeps
its class string with its angle token on both forms, and both shipped worked records show exactly
that shape.

**Both directions are defects.** A verbatim template copy is a conforming *template* and a
non-conforming *artifact*; an unqualified substitution is the opposite failure and is no less a
defect. Route 2 today reads *write it to the path unmodified* while the template's own guidance
says to replace the placeholder with the trip's directory name;
the two sentences are reconcilable if *unmodified* means *do not edit the questions*, and the
reconciliation is named in § *Residuals* rather than asserted here as a defect.

**What a green from the suite does and does not say.** This record makes partially-written artifacts
**routine rather than occasional** on the local scope arm. The verdict is unchanged, on ground 1,
and this paragraph exists so a green is not read as more than it is.

**D2.6 — Hand-edit reconciliation: re-read the field in the same turn as the write, and the file
wins.**

**The interviewer never writes a field whose current on-disk line it has not read in that same
turn.** Where the on-disk line differs from what the session believes, **the file is authoritative**,
and the traveller is told what the file says before anything is written.

Ground: the artifact is human-authored in a git-ignored tree with no history, so
`ADR-007-command-entry-point.md` § 2 classes a clobber **IRREVERSIBLE** — recoverable from nothing,
not from a revert, not from the repo, not from the log. The per-field re-read is the smallest read
that discharges it, and it is already the shape `profile`'s edit route and `fact`'s replacement
shape take.

*Rejected:* a whole-file snapshot taken at session start and diffed at write time — it holds a copy
of the artifact in conversation, it cannot see an edit made *during* the session, and the per-field
re-read subsumes it at lower cost.

### 3. Question sequencing and the form's own shape

**D3.1 — The starred fast-pass is a flow with a mandatory three-branch decision point.** The starred
set is **read from the form's own star markers and is never restated by the interviewer** — a
restatement would create one more home for a set the sibling record is already adjudicating. After
the last starred field the interviewer states what remains and offers exactly three branches —
**continue · stop · jump to a named section** — and **all three are complete answers**, which is the
templates' own rule. The named-section namespace is seam datum S9.

**D3.2 — One session covers exactly one form.** The two forms are different artifact classes at
different paths with different publish postures and different erasure reaches. A traveller filling
both gets two fast-passes and two sessions. *Rejected:* a unified interview spanning both forms — it
would have to decide, per answer, which artifact the answer lands in, which is the classification
`reference/data-model.md` § *Field Scope* owns; an interviewer re-deriving it would be a second home
for that classification. The tier-crossing case is handled by D4.3 instead.

**D3.3 — Repeatable blocks: add, skip, remove.**

- **Add** — D2.2's whole-unit append.
- **Spare units are never deleted; they are em-dashed.** The forms' instruction to *delete the
  unused repeated blocks* is addressed to a **hand-filler**. The interviewer's parallel act is to
  leave the spare unit in place with `—` on each of its labels. Grounds: a delete on a
  human-authored, history-less file is IRREVERSIBLE under `ADR-007-command-entry-point.md` § 2 and
  buys only cosmetics; `Scope: block` makes repetition user data rather than a defect; the
  malformed-slot finding reaches slot-scoped fields only; and leaving the unit preserves the labels
  the planner parses. **The write shape is the one D2.2 states for a write inside an existing
  unit — `Edit` under standing rule 2's second condition, taken per unit**, so the labels of one
  spare unit are em-dashed in a single write and no line outside that unit changes. It is **not**
  rule 7, which admits appends alone; replacing a placeholder with `—` changes an existing line.
  Nor is it D2.1's cadence, which is `slot`-scoped by its own terms. **Without a stated shape this
  write would have no sanctioned tool**, which is the gap rule 7 was itself written to close for
  appends.
- **Remove an instance** — reuse `fact`'s removal shape verbatim: name the unit, **echo it verbatim
  before writing**, remove no more than the named unit, and never remove a whole section.

**Accepted cost, stated:** an interviewed file looks different from a hand-filled one — spare units
present and em-dashed, rather than absent. Both shapes are legal under the block-scope rule, and the
divergence is visible rather than silent.

**D3.4 — A volunteered answer is recorded in its own field, immediately, and that field is then not
re-asked.** The templates' first rule — *one section at a time, in the order they appear* — binds the
interviewer's **asking**, not the traveller's **answering**. Discarding a volunteered answer would
make the traveller say it twice, which is pushing twice from the other side, and recording it is
precisely what derived resumption reads back. Section order remains the default for the
interviewer's *next* question, taken over the remaining un-asked set. A traveller who refuses the
order entirely is exercising D3.1's *jump* branch, generalized: **section order is a default, never a
constraint on the traveller.**

**D3.5 — Computed fields are never asked.** The fields the form itself declares as computed carry no
durable value beneath them and are `TRIP`-class by construction. The never-asked set is seam datum
S12 and is read, not restated.

**D3.6 — Instance-side block cardinality: a conforming instance carries its repeat units em-dashed
rather than absent, and zero units is not a state the interview produces.**

This question was raised as an open seam item on the ground that the forms are silent on the
empty-block case, and it was **disposed to this record** at the scope-lock that closed Stage 5: the
field-level `slot` / `block` classification resolves by join against `reference/data-model.md`, and
the *instance unit-count* question is behaviour and therefore this record's.

The decision, stated as the behaviour it is:

- **The interview never reduces a block below the unit count the seeded form carries.** The seed
  writes the form whole, so whatever repeat units the form ships with are present from the first
  instant, and D3.3's em-dash rule keeps them.
- **An empty block is expressed by em-dashing its units, never by deleting them** — in the write
  shape D3.3 states, which is `Edit` under standing rule 2's second condition at unit granularity
  rather than rule 7's append. Zero units is therefore a shape the interview does not produce, on
  either form.
- **Where a block's own form makes a word the load-bearing empty answer — the needs block, whose
  form offers `none` in words — that word is offered and recorded, and it is an answer.** `none` is
  answered; the em dash is not. The two are distinct states and this record keeps them distinct.
- **This is a bound on the instance, not a declaration about the contract.** Whether a conforming
  form *may* carry zero units is the form contract's question and is not decided here. The
  behaviour above is conformant under any contract that admits the seeded shape, which is the shape
  the form itself ships.

*Rejected:* **(a)** deleting spare units to match the hand-filled shape — an IRREVERSIBLE delete
bought for cosmetics, and it discards labels the planner parses. **(b)** treating an em-dashed unit
as absent for counting purposes — that is a second predicate over the same bytes, which is the
defect D1.3 refuses on `ANSWERED()`'s behalf.

### 4. Who is interviewed, and by whom

**D4.1 — A proxy-collected answer is marked, at field granularity, with the mark the engine already
ships.** Proxy interviewing already ships: route 1 has the operator running `profile` for a named
traveller. The mark is `agents/00-enrichment.md`'s `[OPERATOR-PROVIDED]`, which exists to make clear
that an entry came from the operator rather than the traveller's own file, and which `promote`
already carries across a write — *it travels with the value into the record, at field granularity,
through the inline mark the value already carries*.

*Rejected:* a frontmatter `collected-by:` key — **(a)** it is file-granular and a file is rarely
wholly proxy-collected; **(b)** it changes the frontmatter contract on the two never-upgraded
classes, which Choice 1 forecloses; **(c)** a field-granular mark already ships and is already
carried by two verbs.

**D4.2 — The subject's own later session treats a proxy-marked answer as an ordinary answered field,
and drops the mark when the subject changes the value.** Not re-asked; changed only through D2.3's
echo-and-confirm. When the subject themselves supplies a different value, **the mark is removed in
the same write**, because the mark is a provenance claim about the *current* value and it has
stopped being true. *Rejected:* retaining the mark as history — the mark is not a log, `trip-log.md`
is where this engine keeps history, and a field mark that accumulated history would become a second
register.

**D4.3 — Live tier routing: the interview routes at capture and never promotes after. It carries no
value across a form boundary.**

When an answer's field class puts it on the *other* form, the interviewer **(i)** does not record it
on this form, **(ii)** names the other form and the field, and **(iii)** carries, quotes and offers
**no value** — the traveller re-states it there.

This **confirms and bounds behaviour the corpus already ships in both directions** rather than
inventing any. The person form's guide already says that an answer shaped like one trip belongs on
that trip's own form and is not recorded here, and the trip form already instructs the interviewer
to name the other route out loud when it reaches the crossing point.

**The decision is forced by three independent bounds, and each is dispositive alone.**

1. `ADR-015-durable-field-validity-horizon.md` § *Decision* clause 7 — *"A report line may name a
   field and a remedy; it may never carry, quote, or offer a candidate value."*
2. `skills/trip-record/SKILL.md` § `promote` — no rendered line pairs a field with an offer to
   promote it, and no pass suggests running that verb, on the stated ground that such a prompt would
   satisfy the store's no-agent-writes rule literally while defeating it in practice. **The interview
   names no promote verb.**
3. **A direct cross-form write is mechanically unavailable.** A write outside the trip directory is
   bounded by standing rule 9, whose fifth condition is that *"the value written already exists in
   this trip, so the write **moves** a value and authors none."* An answer spoken aloud in an
   interview exists nowhere yet, so a cross-form write fails that condition **by construction**. No
   new standing clause is proposed: the Extension rule's bar — that a rule belongs there only where
   it genuinely binds every verb — is not met by an interview-specific widening.

**Where the routing statement is read from.** The landing decision taken at Stage 5 relocates the
interviewer-facing guide out of the form and into a verb section of `skills/trip-record/SKILL.md`,
so the cross-form routing prose this decision consumes is **verb-body prose rather than form-side
prose**. This record states the behaviour and not the placement: routing happens **at capture**,
wherever the statement that names the destination form is authored. The consequence for the seam is
carried on S16 in § *The seam*, which is withdrawn from the form-side requirement for this reason.

**Accepted cost, stated plainly:** the traveller states a tier-crossing answer twice. The mitigation
that adds no state is that the interviewer **names the field** on the other form, so the second
statement is prompted rather than remembered — which is exactly the *name a field and a remedy* that
clause 7 admits.

*Rejected:* **(a)** holding the words and offering to write them when the traveller opens the other
form — cross-session state, which is O2. **(b)** writing directly into the other artifact — fails
standing rule 9's fifth condition. **(c)** offering a promote after recording trip-side — forbidden
by `promote`'s own bound, and it is the drift-one-click-at-a-time failure that bound exists to
prevent.

**D4.4 — Third-party bounds, stated as prohibitions on the interviewer.**

1. **No session may have as its subject a person who is not present and has no form.** A session
   writes an artifact, and the artifact for such a person is the proxy profile
   `ADR-006-third-party-data-capture.md` rejected — a durable identity artifact for a person who
   never asked for one — with `ADR-014-cross-trip-consent-refusal.md` closing the cross-trip reading
   permanently rather than deferring it.
2. Within a **present** traveller's session, a question about a third party is admitted only for the
   trip form's party field, which is the shipped field for exactly this, and for needs relayed
   through the enrichment operator-provided path. **Never for the passport field, and never for any
   `PERSON`-class identity value**, per `ADR-006-third-party-data-capture.md` § *Identity*.
3. **The passport narrowing is the single admitted exception to *keep their words*, and it is
   field-scoped.** The person form already states it — the field covers this person alone, never
   their party, and it is the one field where the interviewer narrows what was said rather than
   keeping it. This record confirms that and bounds it: **no other field admits a narrowing.**
4. A third-party need reaches the composed traveller model through enrichment carrying its
   `[THIRD-PARTY]` mark. **The interview creates no file for that person**, and the entry's own
   bound is the one `ADR-006-third-party-data-capture.md`'s amendment already sets: trip-scoped,
   git-ignored, non-publishable, and never promoted to a cross-trip record.

### 5. Conversational integrity

These are **prohibitions on the interviewer's output**, decidable by a reviewer reading a transcript.
They decide no tone and no wording.

**D5.1 — The confirmation-content rule, stated as a decidable test.**

> A confirmation may contain only: **(i)** tokens the traveller uttered in this turn; **(ii)** the
> field's own label, as the form spells it; and **(iii)** words that carry no field value — the
> connective and framing material a sentence needs. **Test:** strike (ii), then strike every
> remaining word that **carries no field value**; what remains must be a **subsequence of the
> traveller's utterance in this turn**. **The discriminator is the word itself, never a list:** a
> word that carries a field value is never struck, so a confirmation cannot pass by calling the
> value it supplied a frame word.

A worked pair, so a reviewer can grade a transcript without exercising judgement:

| | Utterance | Confirmation | Verdict |
|---|---|---|---|
| ✗ | *"I don't like being rushed in the mornings."* | *"So, a slow morning — shall I put that down?"* | **non-conforming** — `slow` is not a token they uttered, so the confirmation supplies the value |
| ✓ | *"I don't like being rushed in the mornings."* | *"You said 'I don't like being rushed in the mornings.' Record that under **Desire**?"* | conforming |

*Rejected:* *a confirmation must not add meaning* — rejected explicitly as **guidance rather than a
test**. Two reviewers disagree about meaning, and the failure mode is precisely a confirmation that
*feels* meaning-preserving. *Rejected:* declaring (iii) as an enumerated word list. Nothing in the
corpus declares such a set, and a record that declared one would carry a closed vocabulary no surface
reads — under which a word would be non-conforming for being **unlisted** rather than for carrying a
value, which is not the property this test exists to decide. The test is written against the word's
content instead, so it needs no list and grades the same transcripts.

**D5.2 — *Keep their words* is operationalised as delete-only.** The templates' rule to *tighten the
wording and not rewrite the meaning* becomes: **tightening may delete tokens and may never add one.**
This is D5.1 seen from the recording side, so there is one rule and not two.

**D5.3 — An offer may contain only option text the form itself carries, quoted.** The templates'
instruction to *offer the choices* is bounded: **every offered option is a substring of the form.**
**The interviewer never offers an option for a field whose form carries no option list** — an open
question stays open. An offer that paraphrases the form's options is D5.1's invention, one step
earlier.

**D5.4 — Closed-enum fields: offer the members, record the member the traveller selected, and never
map a free-form utterance onto a member.** Where the utterance names no member, say so and re-offer;
**do not choose the nearest**. This generalises a discipline the engine already ships wherever the
question arises — `agents/00-enrichment.md`'s instruction to record a value *"verbatim, never
normalize it to a neighbouring value"*, and the trip form's recurrence rule, which records the
recurring value only when the traveller says so. **Test:** the recorded value is a member of the
declared set **and** the utterance contains that member's text or an unambiguous ordinal selection.

**What makes D5.3 and D5.4 gradeable.** Both branch on form-side data — which text is *the* form's
option list, and which fields are closed rather than merely suggestive. Those were raised as open
seam items because the corpus declares neither. They are supplied by the joint amendment recorded at
the Collective Review that closed Stage 5: the sibling record adds a **per-field closed/open marker**
and names the **bracketed placeholder** the authoritative home for option text. D5.3 and D5.4 stand
**unchanged** and acquire a source. Seam data S13 and S14 carry the detail.

**D5.5 — A skip is recognised from an utterance, never from its absence. Silence is not a skip, on
any modality.**

Two prohibitions, each the inverse of the other:

> **P1 — The interviewer never writes `—` on a turn in which the traveller uttered nothing.**
> **P2 — The interviewer never leaves an uttered skip unwritten**: the `—` is written **before the
> next question is asked**.

P2 is not politeness. Under D1.1 an unwritten skip is byte-identical to an un-asked question and
**will be asked again in the next session**, which is the constraint violation § *Context* identifies
as the real defect.

**On silence or ambiguity: re-offer exactly once, naming the three branches — answer, skip, stop —
and write nothing until one is uttered. A second silence ends the session**, and ending writes
nothing new, because the artifact already holds everything answered. This does **not** violate
*never push twice*: the templates bound pushing **after a skip**, and no skip has been given. The
one-re-offer cap is what keeps it from becoming a push.

**D5.6 — On doubt, ask.** The templates' instruction — if you are not sure what they meant, ask, and
do not paraphrase your way past it — is retained unchanged and is the terminal branch of D5.1: a
confirmation that cannot be constructed from (i), (ii) and (iii) is not a confirmation the
interviewer may offer, so the only remaining move is a question.

**Which of the guides' numbered rules this record governs.** The numbered rules in the forms' guides
are a mixed block: some are conduct and some are session behaviour. **This record governs the
semantics of rules 4 through 8** — the starred decision point at D3.1, the skip at D5.5, *never
invent* at D5.1, *keep their words* at D5.2, and the never-asked field at D3.5. Rule 3's instruction
to offer the choices is conduct; what an offer may **contain** is bounded by D5.3, and that bound is
on the content rather than on the instruction. **This record says nothing about where any of those
rules live** — placement is the sibling record's, and the split is executed as one coordinated act so
that neither record's decisions land inside a region it does not own.

### 6. Modality contracts

**D6.1 — The modality contract branches on exactly one observable: does the channel hold a write
path to the artifact?**

| Tier | Predicate | Contract |
|---|---|---|
| **W — write-capable** | the session can read and write the target path | D1.2's seed-then-edit. The artifact **is** the session state, resumption is derived, and there is **no output act at all**, because the answers were never held in conversation. This is what route 1 becomes. |
| **T — transcript-only** | no write path, but the channel can return text the traveller can save | the contract the forms already ship: one markdown code block carrying the profile and nothing below its end marker. This is route 3, unchanged and not dropped. |
| **refuse** | no write path **and** no text-returnable surface | **the interview does not run.** |

*Rejected:* naming one output shape globally preferred. The candidate shapes are not competitors;
**the write model decides between them.** Per-answer writes require a write path, so one shape is
what tier W *is*, and the others are what tier T *is*.

*Rejected for the refuse branch:* running a voice-only interview and reading the finished artifact
aloud for the traveller to transcribe — a long form read aloud is not a deliverable, and it maximises
D6.4's residue while delivering nothing. The refusal has shipped precedent in the same command:
`promote` and `extract` both refuse a non-interactive run rather than degrading.

**D6.2 — Tier T states, before the first question, that the answers live only in this conversation
until the block is returned and saved.** One line, once. Tier T **cannot** offer resumption, because
the artifact does not exist until the block returns, and this record says so rather than implying
otherwise.

**D6.3 — In a spoken channel, `PERSON`-class questions get one offer and one narrowed
confirmation.**

- **The trigger is the field's class, read live** from `reference/data-model.md` — class `PERSON` —
  and never a hand-written list of field names. A field newly classified `PERSON` is covered with no
  edit here. This is the same *membership is data — nothing branches on the field's name* discipline
  `ADR-015-durable-field-validity-horizon.md` § *Decision* clause 4 uses for its own axis.
- **Before the first `PERSON`-class question of a spoken session**, the interviewer names that the
  next questions cover health- or document-shaped detail, and offers to move that section to text or
  to defer it. **Once per session, not per field** — per field would be pushing twice.
- **In a spoken channel the confirmation of a `PERSON`-class field does not re-voice the value.** It
  names the field and asks for assent. This is a *narrowing* of D5.1 for one channel and one class,
  and it is admissible because D5.1's purpose — no invention — is satisfied a fortiori by saying
  less. The precedent is `extract`'s preview, which is name-only for the same reason.

*Rejected:* refusing `PERSON`-class questions in voice outright — it makes the most valuable half of
the person form unreachable by the modality this milestone exists to open, and it substitutes the
engine's judgement for the traveller's about who is in the room. The offer respects that; a refusal
does not.

**D6.4 — Transcript residue: the posture is unchanged and the disclosure is added.** Route 3 already
accepts that a third-party assistant holds the answers. **Voice does not change the posture** — the
residue is the same class at the same boundary. What voice changes is the traveller's *expectation*,
because a spoken session leaves a text history the traveller may not have in mind. So **a tier-T
session states, in one line, that the answers remain in that assistant's history**, combined with
the line D6.2 requires, so that the traveller hears one disclosure rather than a pair of them.

**The residual is stated rather than minimised.** The engine has **no reach** into a third-party
assistant's history. `erase`'s reach table is total over the locations it *can* reach, and its own
rule is that a location absent from that table is not reachable by omission but unreachable, and the
receipt says so. A third-party transcript is such a location. Disclosure is the only available
control, and this record says so rather than implying a reach it does not have.

**D6.5 — An interview session writes no `trip-log.md` entry.** The statement that **nothing makes a
log entry mandatory** is `skills/trip-record/SKILL.md` § `log`'s, not the log file's — no
`trip-log.md` in the corpus carries it — and the attribution is corrected here rather than carried
forward. More decisively, `trip-log.md` is the **decision register**, and
a traveller's answers are not decisions — they are the artifact's content, and putting them in the
register would give the register a second source for a fact the traveller's own file owns.
*Rejected:* logging the session's start and stop as the resumption record — that is O2 wearing the
log's clothes.

## The seam — what this record requires a conforming form to expose

**Every form-side datum the session model must read**, one row per datum, each assigned to exactly
one primary purpose so that the cross-walk authored against this table has one row to match per
line. The sibling record supplies these. **This record neither decides where they are declared, nor
how, nor in what file.** The rows are requirements on the *reader*, phrased as such.

The table is grouped by purpose and its row count is **7 + 10 + 2 = 19**.

### A. To resume a session

| # | Datum | Why the session model needs it | Consumed by |
|---|---|---|---|
| **S1** | The **ordered question set** — every section-and-label pair the form asks, in ask order | the *document* half of the derivation; the instance cannot supply it without silently retiring a hand-deleted question | D1.1, D1.4 |
| **S2** | The **profile/guide boundary**, machine-readable, so the question set stops at it | without it the question set runs into prose addressed to the interviewer | D1.1 |
| **S3** | The **bracketed-placeholder form per field** | makes `UNASKED` decidable by the value test `ADR-007-command-entry-point.md` § 2 requires | D1.3 |
| **S4** | The **frontmatter block the seed writes**, and which of its values are **substituted at seed time** versus fixed facts about the artifact class | a verbatim copy carries the trip placeholder and fails the frontmatter arm; group `AR3` states this | D1.2, D2.5 |
| **S5** | The **artifact path rule** — the filename transform, and for the person form the minted record stem | under derived resumption the path *is* the session identity | D1.2, D3.2 |
| **S6** | The **title-line field**, borne by the heading and by no bullet | it is invisible to any bullet-derived question set, and on the person form it is the one field that must be answered | D1.1 |
| **S7** | The **contract version**, so a skill and a form can disagree **detectably** | a silent disagreement is a question set that is wrong with no symptom | D1.1 |

### B. To sequence questions

| # | Datum | Why the session model needs it | Consumed by |
|---|---|---|---|
| **S8** | The **star marker per field**, and the per-form starred count | the fast-pass set, read and never restated | D3.1 |
| **S9** | The **section order and section names** | the namespace for the *jump to a named section* branch | D3.1, D3.4 |
| **S10** | **`Scope` per field**, and for a block-scoped field its **repeat-unit boundary and constituent labels** | decides per-answer against per-unit write cadence | D2.1, D2.2, D3.3 |
| **S11** | **Block cardinality as the form ships it** — the repeat units a seeded instance starts with | D3.6 bounds the instance against the seeded shape, so the seeded shape must be readable | D3.3, D3.6 |
| **S12** | The **never-asked computed field set** | the interview must not ask a field the form computes | D3.5 |
| **S13** | The **option list per field, verbatim, in one authoritative home** | an offer must quote the form and never paraphrase it. Supplied by the joint amendment: the bracketed placeholder is the authoritative home | D5.3 |
| **S14** | **Which fields are closed enums**, as a per-field marker, distinct from an open suggestion list | the two license different recording behaviour, and D5.4's test branches on it. Supplied by the joint amendment's per-field closed/open marker | D5.4 |
| **S15** | The **skip-if condition** per field or section | a section whose precondition fails is not asked, and the condition is form-side | D3.1 |
| **S16** | The **cross-form routing statement** — which other form a tier-crossing answer belongs to | **Withdrawn from the form-side seam.** The landing decision relocates the interviewer-facing guide into the verb body, so this statement is no longer form-side and the sibling record is not asked to expose it. The datum is still *read*; its home is the verb body. The row is kept rather than deleted so the cross-walk records a withdrawal rather than a gap | D4.3 |
| **S17** | The **field's class**, read live from `reference/data-model.md` and **not restated by the form** | the spoken-channel trigger and the routing test | D4.3, D6.3 |

### C. To distinguish unanswered from `none` from the em dash

| # | Datum | Why the session model needs it | Consumed by |
|---|---|---|---|
| **S18** | The **em dash as the declined marker**, and per field whether the form overrides it | the whole of D2.4 | D1.3, D2.4, D5.5 |
| **S19** | The **field set where a word stands in for the em dash** — today the needs block's `none` | that word is an answer and the em dash is not; it is offered where the form makes it load-bearing and nowhere else | D1.3, D3.3, D3.6 |

## Open seam items and their disposition

Every item this record's design raised is recorded here with the disposition it received at the
Collective Review that closed Stage 5. **None is left dangling, and none was resolved unilaterally
by either record.**

| # | The item | Disposition |
|---|---|---|
| **OS-1** | Block cardinality is unstated in both forms, so the empty-block case has no contract | **Decided here**, as D3.6. The instance-side unit-count question is behaviour; the field-level scope classification resolves by join against `reference/data-model.md` |
| **OS-2** | Closed enum against open suggestion list is distinguished nowhere, and D5.4 branches on it | **Resolved jointly.** The sibling record adds a per-field closed/open marker. D5.4 stands unchanged and becomes gradeable |
| **OS-3** | The trip-context form carries no profile/guide boundary and no guide at all | **Reclassified out of scope for this epic**, on measurement rather than preference — it is misclassified by kind rather than by size. The consequence is carried in § *Residuals* as a mandatory statement at plan review |
| **OS-4** | Option lists exist in more than one non-identical home per field, and D5.3 requires exactly one | **Resolved jointly**, by the same amendment as OS-2: the bracketed placeholder is the authoritative home, and option text is not relocated |
| **OS-5** | Cross-form routing is prose inside the guide, which may move | **Settled by the landing decision.** D4.3 is stated against the verb-body placement, and S16 is withdrawn from the form-side seam |
| **OS-6** | The guides' numbered rules are a mixed block of conduct and session behaviour, and the split is a joint act | **Executed jointly.** This record states which numbered rules it governs — 4 through 8, in § *Decision* 5 — and states nothing about where they live. The sibling relocates the block |
| **OS-7** | The skip-byte contradiction D2.4 resolves obliges an amendment to a standing rule, and needs an owner | **Wave-1 backlog**, owner assigned at Wave-1 planning. This record decides the semantics and edits no file but its own |

## Consequences

### What this buys, stated as the surfaces the decisions leave untouched

This is the payoff of D1.1 and it is listed first because it is the part a reader can audit.

| Surface | Why it is untouched |
|---|---|
| `reference/data-model.md` § *`ANSWERED()`* | D1.3 refines the false class downstream; the predicate is not redefined. A change here would cascade into the composition lattice, the bullet extractor and its consumers, and the extract, promote and link verbs |
| `reference/data-architecture.md` § 1.1 | no new artifact class, so no heading numeral, no validator constant, and no bijection or delta cascade |
| `reference/schemas/traveler-profile.md`, `reference/schemas/person-record.md` | no new frontmatter key on the two never-upgraded classes |
| `skills/trip-record/SKILL.md` § `erase` reach table | no new location; the receipt stays total |
| the `allowed-tools` grant on any command | read, write and edit are already granted, so the grant union is unchanged |
| `agents/00-enrichment.md` § *Missing or blank profile* | its predicate still fires correctly on a seeded-but-unanswered file, and D2.4 makes it **more** precise rather than less |
| `scripts/validate-artifacts.sh` | no change; D2.5 is discharged against the script's own declared scope |

### What later slices must change, each with an owner

| Surface | Change | Owner |
|---|---|---|
| `reference/adr/README.md` | one index row for this record | this milestone's corpus step |
| `skills/trip-record/SKILL.md` standing rule 3, and § `profile` → *Edit* | the skip byte, per D2.4 | Wave 1 |
| `skills/trip-record/SKILL.md` § `profile` route 1 | seed-then-edit, per D1.2 | Wave 1 |
| `skills/trip-record/SKILL.md` § `profile` **Reads:** block | **easily missed.** That block is an enumerated read-scope ceiling stated at purpose granularity. Per-answer writes and D2.6's re-read-before-write add **no new path** but do add new **purposes** — the resumption read, and the pre-write re-read — so the ceiling must be amended even though the path set is unchanged | Wave 1 |
| `skills/trip-record/SKILL.md` § `profile` route 2 | reconcile *write it to the path unmodified* with the seed's placeholder substitution, per D2.5 | Wave 1 |
| the forms' numbered guide rules | wherever the sibling record places them | Wave 1 |
| an assertion grading the three-valued refinement | **named as a residual, not designed here.** No group grades placeholder-against-em-dash today | Wave 1 |

### Two facts a small-looking change would hide

1. **The verb file this behaviour lands in is already far over the body-size budget `CLAUDE.md`
   records.** A resumable interview authored inline in the `profile` verb grows the widest
   over-budget body in the engine. This record states **behaviour** and deliberately leaves
   **placement** to the sibling, which may move conduct out entirely. That is the mitigation, and it
   is the sibling's to render rather than this record's.
2. **The local scope arm of the schema verb now meets partially-written artifacts routinely rather
   than occasionally.** Its verdict is unchanged, on D2.5 ground 1, but the population it walks
   changes character — and a future assertion written against *most trip files are complete* would be
   written against a premise this record retires.

### Reversibility summary

| What | Tier | Why |
|---|---|---|
| The decisions themselves | **CHEAP** | a decision record, revertible in one commit, moving no artifact |
| This record's number and filename | **IRREVERSIBLE** | numbers are never reused or renumbered, and sibling prose cites a record by filename |
| D2.4's skip-byte reconciliation, once a slice implements it | **MODERATE** | reversing it after instances exist leaves files whose meaning depends on which route wrote them |
| Anything this record edits outside itself | **n/a — nothing is edited** | the deliverable is this file |

## Residuals

Every residual is named with its owner. A residual with no owner is not a residual; it is a gap.

| # | Residual | Owner |
|---|---|---|
| **R1** | The standing-rule amendment D2.4 obliges — standing rule 3 and § `profile` → *Edit* must be reconciled toward the em dash in the same change that implements the semantics | **Wave 1**, owner assigned at Wave-1 planning |
| **R2** | Route 2's *write it to the path unmodified* against the seed's placeholder substitution, per D2.5. The two sentences are reconcilable; the reconciliation is not written | **Wave 1** |
| **R3** | No assertion grades the three-valued refinement. Placeholder-against-em-dash is graded nowhere today, which is exactly why the contradiction D2.4 resolves survived in the corpus | **Wave 1** |
| **R4** | The trip-context form is out of scope for this epic, so **the session model ships unexercised on the form the scalability claim rests on.** This is said here rather than discovered later, and it is a **mandatory statement at plan review** rather than a design defect. It is an operator call about milestone scope | **plan review**, then the first consumer slice |
| **R5** | The split of the guides' numbered rules is a joint act: this record owns the semantics of rules 4 through 8 and the sibling owns their placement. Neither half is complete alone | **joint**, this milestone |
| **R6** | D5.4's gradeability depends on the per-field closed/open marker landing in the sibling record. The prohibition is written; its source is the sibling's to supply | **the sibling record** |
| **R7** | **Third-party transcript reach — accepted, unreachable, disclosed.** The engine cannot reach a third-party assistant's history, `erase` cannot enumerate it, and no control exists beyond D6.4's disclosure. This is not deferred work; it is a permanent boundary of the deployment | **accepted**, stated by D6.4 |

## References

- [ADR-006](ADR-006-third-party-data-capture.md) — needs-only capture, identity refused, and the
  bound on a third-party entry that D4.4 confirms rather than widens
- [ADR-007](ADR-007-command-entry-point.md) § 2 — the clobber bound that makes D2.6 and D3.3's
  no-delete rule irreversible-class, and the placeholder value test that is the **sanction for
  D1.3** and the single most load-bearing citation in this record
- [ADR-012](ADR-012-people-library.md) — the person store's identity and erasure reach, which
  D4.3's refusal to write across a form boundary leaves untouched
- [ADR-013](ADR-013-count-assertion-basis.md) — the admitted basis forms that govern how every count
  in this record is written
- [ADR-014](ADR-014-cross-trip-consent-refusal.md) — the cross-trip record for a party member is
  closed permanently rather than deferred, which is why D4.4's first prohibition is absolute
- [ADR-015](ADR-015-durable-field-validity-horizon.md) § *Decision* clauses 4, 6 and 7 — membership
  is data rather than a name list, no mechanical write is added, and a line may name a field and a
  remedy but never carry, quote or offer a candidate value
- [ADR-019](ADR-019-discriminating-evidence-rule.md) — why the assertion named in R3 has to require
  evidence its subject could only have produced by running, rather than merely reporting green
- [ADR-021](ADR-021-installable-capability.md) — the two-location status-flip obligation this
  record's head block reuses
- `ADR-023` — the sibling Wave-0 record. It decides **structure**: what a conforming form declares,
  where conduct is authored, and how conduct reaches a reader with no repository. It is named as the
  supplier of every form-side datum in § *The seam*, and **no clause of it is quoted or predicted
  here**
- `reference/adr/README.md` — the record convention, the status lifecycle, and the
  amendment-versus-supersession split this record's head block is authored against
- `reference/data-model.md` — § *`ANSWERED()`* for the predicate and for the instance-against-document
  distinction this record joins; § *Field Scope* for class and scope per field, read live and never
  restated; § *The starred pass*; § *The decision rule* for the cheap-error tie-break behind
  `INDETERMINATE`; § *The override lifecycle* for the em dash as the shipped un-answer
- `reference/data-architecture.md` § *Schema evolution* — the two interview target classes are
  permanently tolerated at version 0 and never engine-upgraded, which grounds D2.5 and forecloses O3
- `reference/schemas/person-record.md` — the `trip: cross-trip` narrowing: a reserved sentinel that
  type-checks as the required `slug`, resolves to no trip directory, and is therefore the one value
  D2.5's seed requirement must **not** substitute
- `skills/trip-record/SKILL.md` — standing rules 2, 3, 7 and 9 for the write conditions, the surface
  D2.4 reconciles, and the mechanical ground for D4.3; § `profile` for the ordered checks and the
  three create routes; § `promote` for the never-reached-from-a-report bound; § `fact` for the
  whole-unit append and the echoed removal; § `extract` for the name-only preview behind D6.3;
  § `log` for the statement that nothing makes a log entry mandatory, which is D6.5's and is cited
  to that section rather than to the log file
- `skills/trip-new/SKILL.md` § *Resume — repair only* — resumption selected by a probe and never
  typed, which is D1.2's precedent
- `agents/00-enrichment.md` — § *Missing or blank profile* for the normal-state branch and the
  operator-provided mark; the recurrence and familiarity defaults for the never-normalize discipline
  D5.4 generalises
- `templates/traveler-intake.template.md`, `templates/person-intake.template.md` — cited as the
  authority on their own questions, for the finished-file rules, the numbered guide rules, the word
  that stands in for the em dash, and the passport narrowing. **Not restated**
- `scripts/validate-artifacts.sh` — the coverage boundary, the skip predicate and the template
  exclusion that together discharge D2.5
- `scripts/test-artifact-schema.sh` group `AR3` — the placeholder-substitution requirement the seed
  must satisfy

## Follow-on build slices

Named, and deliberately not scoped. Scoping is Wave-1 planning's.

- **The conduct slice.** Authors the interviewer's conduct against the behaviour this record decides
  and the structure the sibling decides, in the landing site the Stage-5 landing decision names.
- **The skip-byte reconciliation.** Carries R1 and R2 — the standing-rule amendment and the route-2
  reconciliation — as one change, because they touch the same verb section.
- **The refinement assertion.** Carries R3: an assertion that grades the placeholder against the em
  dash, written to require evidence its subject could only have produced by running.
- **The first trip-context consumer.** Carries R4, and is the slice at which the session model is
  first exercised on the form it has not met.
