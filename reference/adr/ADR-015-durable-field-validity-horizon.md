# ADR-015: The durable-field validity horizon — a trip-relative predicate, a declared axis, and no fifth write

- **Status:** Accepted (2026-09-07)
- **Deciders:** repo maintainer
- **Driving work:** the Person data lifecycle milestone. `reference/adr/ADR-012-people-library.md`
  § 7 routed *"the passport validity horizon"* to a later slice and decided nothing about it. This
  record is that slice. It settles what a horizon is compared against, which fields owe one, how a
  lapsed value is reported, and why re-confirming one adds no write to the person store.

## Context

### What shipped, and the gap in it

The durable person record admits a suffix mark, `[VALID-THROUGH <YYYY-MM>]`, on a field bullet.
`reference/schemas/person-record.md` declares its grammar; `reference/data-model.md` § *`ANSWERED()`
— the presence predicate the lattice rests on* makes it the record side's third state, `EXPIRED`,
alongside `UNSTATED` and `ANSWERED`. An `EXPIRED` value composes to `UNKNOWN` and is reported —
never silently used, never silently dropped.

Two things about that were incomplete, and both were found by reading the shipped text rather than
by reasoning about the design.

**The predicate was clock-relative.** `EXPIRED` was defined as a horizon *earlier than
`strftime('%Y-%m')`* — today. Every surface that described expiry described it the same way:
`reference/schemas/person-record.md`, `agents/00-enrichment.md` in its trigger table, and
`people/README.md` § *Retention*. No shipped sentence anywhere compared a horizon to the trip it
was being used for. So a passport valid today and lapsed before a trip six months out composed
`ANSWERED` and passed **silently** — checked against, not merely stored, because the field exists so
entry requirements can be checked against a traveller's nationality and document dates. That is the
whole of the gap: a record correct in 2026 is wrong in 2030, and nothing asked.

**The mark was permitted, not declared.** The schema makes it *"admissible on any field bullet and
required on none"*. An instance **may** carry a mark; no field **declares** that one is owed. So an
absent horizon was indistinguishable from a field that never needed one, which is fail-open on
exactly the field the class exists to protect. And a mark permitted everywhere and owed nowhere had
never been exercised: the tracked witness records it as *not exercised here*, and the real store is
git-ignored, so no instance the schema gate can reach carried one.

### Trip-scoped capture hid this

Before the person store existed, a passport's validity was re-entered on every trip form, so a stale
value could not survive into a later trip. Making the field durable is what creates the decay. The
mechanism is therefore owed by the durability decision itself rather than bolted onto it.

## Decision drivers

- **Fail-safe, not fail-open.** An absent or unparseable horizon must read *unknown and prompt*,
  never *valid*. The cheap error is one prompt; the expensive one is a traveller turned away at a
  border.
- **General over the field set, not special-cased to one field.** A passport-shaped mechanism cannot
  admit a second member without a code change, and would re-teach the scoping the class exists to
  break.
- **No new write to the store, and no new solicitation of one.** `reference/data-model.md`
  § *One-way — composition never writes the store* forbids composition from soliciting a write, and
  `reference/schemas/person-record.md` closes the permitted mechanical writes at a set qualified
  *"none authoring a value"*. A re-confirmation mechanism must live inside both, not beside them.
- **Monotone, so nothing already on disk needs auditing.** A predicate change that could move a
  value from unusable to usable would require re-reading every record. One that can only move a
  value the other way does not.
- **Determinism preserved.** `reference/data-model.md` § *Determinism* carries three obligations, and
  the third is where a design goes quietly order-dependent. A new input must not introduce a
  traversal, a file order, or a second value for one argument.
- **Precision the form actually collects.** The intake form asks for *"the month it's valid through
  — never the number"*. A design may not manufacture precision the form declined to ask for.

## Options considered

### What the horizon is compared against

| Option | Verdict |
|---|---|
| The trip's **start** date | **Rejected.** A document lapsing mid-trip passes. Strictly weaker than the option below and dominated by it. |
| The trip's **end** date alone | **Rejected.** It covers the span, but it *un-expires* a lapsed document for a past-dated `ACTIVE` trip — fail-open, and it withdraws a guarantee the corpus already ships. |
| **`R = max(clock month, the trip term)`** | **Selected.** Reduces to the trip's own term for a future trip and to the clock for a past-dated or unresolvable one. **Monotone**: it can only move a value from usable to not-usable, so nothing currently `EXPIRED` becomes `ANSWERED` and no audit of existing records is owed. It is the minimal construction that adds the trip guarantee without withdrawing the clock one. |

### Where the trip term is read from

The first attempt resolved the term from the trip's `[DERIVED]` planning-day blocks, by a first-match
ladder. It was implemented faithfully and **could not resolve a month at all**, because neither of
those blocks carries a year in any shipped instance or in the template — so the fallback fired
universally and the predicate silently reverted to the clock. Two facts, established by reading the
corpus rather than by reasoning about it, decided the replacement:

- **The `[DERIVED]` blocks have no writer.** `CLAUDE.md` § *Write ownership* assigns them to *"no
  writer exists … Not a gap to fill opportunistically"*, and states that until an owner is decided
  they are read-only to every command. Emitting a year from them is therefore not expensive but
  **unreachable**: nothing regenerates those blocks, so a format change would have no producer and
  every existing file would predate it permanently.
- **The frozen regression witness is not an instance of this mechanism.** The earlier design cited
  the frozen example tree as evidence that the trip-level ladder step was exercised in practice. That
  tree is byte-pinned by the freeze declaration in `reference/data-architecture.md` § 10, it does not
  conform to its own class schema, and it carries no traveller directory and no person reference —
  so composition is **structurally unreachable** in it and it was never a witness for this mechanism
  at all. It is not cited as evidence of live behaviour anywhere in this record.

| Option | Verdict |
|---|---|
| The `[DERIVED]` block's own date | **Rejected on evidence, not on cost** — no writer exists, per the above. |
| The trip-directory slug | **Rejected.** The slug form names a year by convention, but the creating verb's slug gate validates neither a year nor a shape that implies one, so a design resting on it rests on an unenforced convention — and extracting the year would be a scan of a free string. |
| A logistics date bullet | **Rejected.** Carried by a minority of instances, in a shape the template does not declare and nothing governs. |
| A frontmatter date key | **Rejected.** Absent by design rather than by oversight — the one date-shaped frontmatter key is optional and narrowed away from human-authored classes. |
| **The title line's month and year** | **Selected.** `templates/trip-context.template.md` declares the slot, `CLAUDE.md` § *Write ownership* assigns the line to the trip-creating verb and then to `/trip-record`, and `.claude/commands/trip-record.md` § `## destination` states in its own words that a destination, a month and a year are the line's only variable content. It is the one candidate that is both **governed** and **has a writer**. |

### The boundary month

Whether `H == R` covers the trip. The shipped predicate is a strict `<` against the clock, which
implies an **inclusive** reading — a horizon equal to the current month passes.

**Selected: not covered. `H > R` is required, so `H == R` prompts.** Under the inclusive reading a
document expiring on the fifth and a trip running to the twentieth of the same month pass silently —
the very failure this mechanism closes, arriving at day granularity inside the mechanism built to
close it. Month precision is a *deliberate under-capture*, so the design cannot resolve the boundary
by asking for a day; it can only decide which way to fail. **The cheap error is the safe one** —
the corpus's own tie-breaker for this shape, and the same phrase that settles the equality relation
for a redundant override. **This is the one behaviour change beyond the clock-to-trip swap: a
passport lapsing in the current month now prompts where it previously passed.**

### How a lapsed value is reported

| Option | Verdict |
|---|---|
| Keep one disposition and reword its remedy | **Rejected.** A traveller who never recorded a validity month reads identically to one whose passport has already lapsed, and their remedies differ by weeks of lead time — in the mechanism whose whole purpose is surfacing that lead time. |
| **Two dispositions** | **Selected.** `EXPIRED` narrows to *a horizon earlier than the reference month*, remedy unchanged. `HORIZON-UNCONFIRMED` carries every other way a value fails to be shown usable — the boundary month; a present but unparseable mark on any field; a `required` field's value carrying no mark; an unresolvable trip term; and the disputed New-Year window — each selecting its own remedy on the same line rather than minting a further disposition. Both compose to `UNKNOWN` — the projection is shared and the report is not, which is what § *The discriminator that must not collapse* already requires of this shape. |

### Where field membership lives

| Option | Verdict |
|---|---|
| Every unmarked bullet prompts | **Rejected.** Unusable. The witness alone carries bullets whose subject cannot expire. |
| Only already-marked fields are checked | **Rejected.** Fail-open, and it makes the fail-safe rule vacuous: the absent case is the one it exists for. |
| A net-new horizon registry | **Rejected.** A second home for a field property, where one already exists. |
| **A per-field `Horizon` axis on the classification table** | **Selected.** Values `required` and `admissible`, both lifted verbatim from the schema sentence that defines the mark. The table already carries per-field, single-valued, totally-assigned axes and is read **live** by every consumer, so membership becomes data rather than code. `Passport` is the sole `required` member. |

### The state count

Adding a fourth record-side state was rejected: the library-configuration term of the 110-cell
totality proof is derived from the record-side state count, so a fourth forces a re-derivation of a
proof for a distinction the value function never reads. Renaming the third was rejected as a naming
preference that would break a fixed-string assertion elsewhere. **Selected: keep three and
re-parameterise the third.** The corpus already splits the axes — *conflict detection keys on
statedness; composition keys on usability* — and the third state is a usability state.

### The re-confirmation write

This is the option set the acceptance criterion appeared to force, and the finding is that it forces
none of them.

| Option | Verdict |
|---|---|
| Amend the permitted-writes set to admit a fifth | **Rejected — it breaks that set's own predicate.** The permitted writes are qualified *"all operator-initiated and none authoring a value"*, and a re-confirmation authors one. It is therefore **outside that enumeration's subject matter**, not an exception to it. Recording an exception would make the store's write rule read as negotiable. |
| Add a command verb for re-confirmation | **Rejected.** It creates a command-surface route a report would be pressed to name — the solicitation the promotion verb is already barred from. |
| **No new write and no new verb** | **Selected, and forced rather than chosen.** The path already exists and is already named: *the record's dominant write path is a human editing it in an editor*, and § *Retention* already says a lapsed field stays that way *until someone updates it*. That **is** the normal one-writer path. |

## Decision

1. **A horizon is compared against a reference month, `R = max(clock month, T)`, where `T` is the
   trip term resolved from the trip's own `trips/<slug>/trip-context.md` as stated in
   `reference/data-model.md` § *The reference month — what a horizon is compared against*.** The term
   is taken from the title line's month and year, then refined upward — within that same year only —
   by the derived departure month where one falls later: **`T = Y_title-max(M_title, M_dep)`**. The
   inner `max` is the outer one applied a level down, monotone for the same reason, which is why a
   first-match ladder was replaced by an expression: a ladder's wrong first step is decisive, an
   expression's is not. The resolution consults one file, scans no directory and terminates.

   **Where no month-and-year pair is on the title line, `T` does not resolve and `R` is the clock —
   the condition is the pair's absence, not the year's, because a bare year that no month name
   precedes is never selected.** A value the clock alone would already have expired stays `EXPIRED`;
   a value the clock would have passed composes the third state on a `required` field and is
   reported, with the remedy naming the title line. **The degraded case prompts; it never passes
   silently** — which is the acceptance criterion the earlier ladder failed by falling back quietly.

2. **`COVERS(H, R)` iff `H > R`.** The boundary month does not cover. Comparison stays a
   zero-padded string comparison, lexicographic and chronological at once, with no date library.

3. **The record side stays three-valued.** The 110-cell totality proof and the class and scope
   totals are arithmetically untouched.

4. **A per-field `Horizon` axis is added to the classification table in
   `reference/data-model.md` § *Field Scope → The classification*, immediately after `Scope`.**
   `Passport` is `required`; every other field is `admissible`. **To admit a second member, set that
   field's cell to `required` and amend the membership arm's declared expectation in the same
   commit — no rule, no extractor, no agent prompt and no fixture outside that member's own
   changes.** The guard's re-read is deliberate rather than an exception to the generality: an arm
   that accepted any membership would let a field acquire an obligation nobody declared. **The
   generality is that membership is data — nothing branches on the field's name.**

5. **`HORIZON-UNCONFIRMED` joins the report's disposition set**, routed to the enrichment
   reconciler's composed-value-moved exit. No signal class is added to the command surface's router,
   because a passport is a journey facet and that class already reports without naming a command.

6. **No mechanical write is added, no command verb is created, and the person-record schema is not
   edited to admit one.** Re-confirmation is a human editing the record — the path the corpus
   already names.

7. **A report line may name a field and a remedy; it may never carry, quote, or offer a candidate
   value.** This is the bound that keeps a horizon prompt from becoming the solicitation
   § *One-way* forbids, and it is stated so it cannot widen.

8. **A present but unparseable mark is a finding on any field, whatever its `Horizon` axis.** A
   payload is well-formed only where it matches a zero-padded four-digit year, a hyphen, and a
   two-digit month in the range one to twelve. The axis governs whether a mark is **owed**, never
   whether a present one may be ignored — so a mark reading `later` or a bare year composes the
   third state rather than passing a raw string comparison. Admitting a malformed month would
   withdraw the lexicographic-equals-chronological property clause 2 rests on, so this is a
   precondition of that clause rather than an addition beside it.

9. **A trip whose title month is later in the year than its derived departure month prompts only
   where the two readings of it disagree.** Such a trip is either a year-spanner or a stale title,
   and at month precision the two are indistinguishable, so the design declines to guess. Let `W`
   be the **wrapped term** the year-spanning reading would produce — defined only where the title
   year, title month and departure month all resolve and the departure month is earlier — and let
   the **disputed window** be the half-open interval above `R` and up to and including `W`. A value
   whose horizon lands in that window, on a `required` field, where the comparison against `R` would
   otherwise pass, composes the third state; the remedy is to restate the title line so its month
   and year name the month the trip ends in. Elsewhere the clause is silent.

   **The clock enters only by clipping the window from below**, because `W` is a function of the
   title and departure months alone: where the clock has not reached the trip term the window is the
   whole disagreement interval; where the clock sits inside it the window is clipped, and horizons
   at or below the clock keep their own remedy rather than being re-labelled with this one; and
   where the clock has overtaken `W` the window is **empty and the clause unreachable** — on a
   past-dated or overtaken trip the year-boundary question is moot, and the clock guarantee already
   covers everything the wrapped reading would have asked for.

   **The window covers the full disagreement interval, whatever its size**, rather than being capped
   or restricted to the December-to-January case. The narrower readings were considered and
   rejected: each leaves a genuine multi-month year-spanner silently uncovered, which is the gap this
   clause exists to close. The accepted cost is the other tail — where the two months are far apart
   the window is correspondingly wide, and a stale title on a past trip can prompt. That cost is
   taken deliberately, on the ground that the prompt is never a false positive **about the record**:
   a title month later than the derived departure month is a self-inconsistent trip file either way,
   and one edit to the title line clears every prompt on that trip at once.

   **Clause 9 is purely additive and disjoint from the unresolved-term case.** It requires the
   comparison against `R` to *otherwise pass*, so it never re-labels a value another clause already
   caught with a different remedy; it presupposes a resolved title year and month, which is exactly
   what the unresolved-term case lacks; and it can only move a value from `ANSWERED` to the third
   state, so it is monotone in the direction clause 1 already is. Where the term resolves but the
   trip carries no derived departure month, `W` is undefined and the clause is silent — a stated
   residual, and the alternative would be the benign-staleness prompt this clause was narrowed to
   avoid.

### Why clause 7 is not a carve-out

§ *One-way* forbids composition from soliciting a write to the store. The harm it names is
**promotion** — a record drifting toward whatever the most recent trip said, one confirmed click at
a time. A horizon line moves nothing that way, and the reason is structural. `Passport` is
`PERSON`-class; a trip-side `PERSON` value is a class violation that is refused and never composed;
so **there is no promotable candidate for such a line to offer**. What the line names is the
record's own answer and the document behind it.

The discriminator is the corpus's own shipped rule, already given three independent grounds where it
is stated: the report never restates a conflicting value. Under clause 7 the divergence prompt
§ *One-way* forbids stays forbidden — it necessarily carries the trip's value as its candidate — and
the horizon line is admitted, carrying none. **A bounded exception to a drift-prevention invariant
was considered and rejected**: an exception invites the next one, and the posture the corpus already
takes is that recording one makes the rule read as negotiable.

### Position of the new column, which is load-bearing

`scripts/test-artifact-schema.sh` parses the classification table **by positional index** in both of
its extractor groups. Placing `Horizon` immediately after `Scope` preserves every index they read.
Placed anywhere earlier it shifts the class or scope field, and both groups then grade a class-blind
table **while the suite reports green** — a failure their own sensitivity arms cannot reach from
that direction. The rationale column moves one position right, and the single arm that reads it
moves with it. That coupling is recorded in a comment beside the table itself, where an editor
reordering columns will meet it.

## Consequences

**Paid down.** The mark ships exercised for the first time, in a tracked fixture that carries no
passport value — which is possible **only because** the mechanism is field-general. AC1's verb,
*declare*, becomes literally true. The horizon acquires a machine-graded axis rather than living
only in prose.

**Behaviour that changes.** A horizon lapsing in the current month now prompts where it previously
passed. A horizon lapsing after today but before a future trip's end now prompts where it previously
composed `ANSWERED` silently — the defect this record exists to close. A present but unparseable
mark now prompts on any field rather than passing a raw string comparison. A trip whose term cannot
be resolved now prompts on a `required` field rather than reverting quietly to the clock. And a
horizon inside the disputed New-Year window now prompts, where the resolved term alone would have
been silent.

**The predicate is graded by a declared case table rather than by a fixture, and the reason is
structural.** No tracked tree pairs a person reference with a trip window — the one tree carrying a
reference has no trip-context file, and every tree with a trip-context file carries no reference —
so no end-to-end witness for this mechanism exists or can cheaply be made to exist. The verdict
cases are therefore declared in `reference/data-model.md` § *The reference month*, in the same
declaration-in-the-document form the freeze and count-assertion fences already use, and each case
carries its verdict under the trip predicate **and** under a clock-forced control side by side. The
grading arm that matters most **fails when every row's two verdicts agree**: a table that
distinguishes nothing is what let the first implementation of this record ship as a no-op with a
green suite, and that failure mode is now an assertion rather than a hope.

**Behaviour that does not change.** No record is written by this change. Nothing composes to a new
sentinel; `UNKNOWN` is unchanged and the publish guard is untouched. The person-record schema's
fence is untouched and its schema version does not move. The reference verb keeps its narrower read
scope and passes the clock, because it answers *which record* rather than *is this record usable for
this trip*; that divergence is designed and is documented at both surfaces.

**Debt created and stated.** The reference-month divergence between that verb and composition is
bounded and documented rather than resolved. The `Passport` slot path still has no tracked witness
carrying a real horizon, because the class forbids a passport value in a tracked file — **a
permanent residual by design**, and the reason the fixture demonstrates the mechanism on a different
field. The trip term depends on a title line a human writes, so a trip whose title is never restated
resolves a stale term; that is a self-inconsistent trip file, it is what clause 9 prompts on where
it changes a verdict, and it is not otherwise repaired here. And clause 9's own two residuals stand
as written there: a year-spanning trip with no derived departure month is undetectable at month
precision, and a widely-separated title and departure month prompts across a correspondingly wide
window.

**Reversibility: CHEAP, confidence HIGH.** The change is content-only. No data migration, no record
written, the store git-ignored, and reverting the release merge restores prior behaviour completely.

**Not decided here.** The retention posture of the trips directory's own README, which
`reference/adr/ADR-012-people-library.md` § 7 marks unowned, is untouched and stays open.

## References

- `reference/adr/ADR-012-people-library.md` — § 7 routes the passport validity horizon to a later
  slice and decides nothing about it; this record is that slice. **It is not amended**, and the
  § 7 entry stays true: it states what *that* record does not decide.
- `reference/adr/ADR-006-third-party-data-capture.md` — bounds a party member's data to needs only.
  Untouched: this record adds a predicate to fields on records, never a record to a person.
- `reference/data-model.md` — § *`ANSWERED()` — the presence predicate the lattice rests on*,
  § *The reference month — what a horizon is compared against*, § *Field Scope → The classification*,
  § *The report — where it lands, and what it never says*, § *The `Needs` overlay — union, because
  two needs never contradict*, § *Determinism — three obligations, and the third is where a design
  goes quietly order-dependent*, § *One-way — composition never writes the store*.
- `reference/schemas/person-record.md` — the mark's grammar, and the permitted-writes set whose own
  qualifier places re-confirmation outside it.
- `agents/00-enrichment.md` — the trigger set and the report-routing exits.
- `people/README.md` — § *Retention*, which names the human write path this record relies on.
- `CLAUDE.md` — § *Write ownership*, which assigns the title line to the trip-creating verb and then
  to `/trip-record`, and assigns the `[DERIVED]` planning-day blocks to *no writer*. Both
  assignments are load-bearing for clause 1: the first is why the title line is a governed source,
  the second is why the derived blocks could not become one.
- `templates/trip-context.template.md` — declares the title line's shape, including the month and
  year slot the trip term is read from, and the ordering of the derived planning-day bullets that
  makes the departure day the trip's last.
- `.claude/commands/trip-record.md` — § `## destination` states the title line's content model; the
  person and travellers verbs declare the reads the reconciler performs, which is where the
  no-new-read claim in clause 1 is grounded. **This file is not edited by this record.**
- `reference/data-architecture.md` — § 10's freeze declaration, which is why the frozen example tree
  is cited only as the non-conformer it is and never as evidence of live behaviour, and the
  count-assertion fence whose per-path census any prose change here must respect.
