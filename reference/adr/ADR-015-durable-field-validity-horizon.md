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
| **`R = max(clock month, window-end month)`** | **Selected.** Reduces to the trip's end for a future trip and to the clock for a past-dated or date-less one. **Monotone**: it can only move a value from usable to not-usable, so nothing currently `EXPIRED` becomes `ANSWERED` and no audit of existing records is owed. It is the minimal construction that adds the trip guarantee without withdrawing the clock one. |

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
| **Two dispositions** | **Selected.** `EXPIRED` narrows to *a horizon earlier than the reference month*, remedy unchanged. `HORIZON-UNCONFIRMED` is added for the boundary month, and for a field whose `Horizon` axis is `required` carrying no parseable mark; its remedy is *state the horizon on the record*. Both compose to `UNKNOWN` — the projection is shared and the report is not, which is what § *The discriminator that must not collapse* already requires of this shape. |

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

1. **A horizon is compared against a reference month, `R = max(clock month, window-end month)`,
   resolved from the trip's own `trips/<slug>/trip-context.md` by the ladder stated in
   `reference/data-model.md` § *The reference month — what a horizon is compared against*.** The
   ladder reads the traveller's own derived window first and the trip-level derived window second,
   falling back to the clock. It is deterministic, terminating, and performs no search.

2. **`COVERS(H, R)` iff `H > R`.** The boundary month does not cover. Comparison stays a
   zero-padded string comparison, lexicographic and chronological at once, with no date library.

3. **The record side stays three-valued.** The 110-cell totality proof and the class and scope
   totals are arithmetically untouched.

4. **A per-field `Horizon` axis is added to the classification table in
   `reference/data-model.md` § *Field Scope → The classification*, immediately after `Scope`.**
   `Passport` is `required`; every other field is `admissible`. **To admit a second member, set that
   field's cell to `required` — no rule, no script, no agent prompt and no fixture outside that
   member's own changes.**

5. **`HORIZON-UNCONFIRMED` joins the report's disposition set**, routed to the enrichment
   reconciler's composed-value-moved exit. No signal class is added to the command surface's router,
   because a passport is a journey facet and that class already reports without naming a command.

6. **No mechanical write is added, no command verb is created, and the person-record schema is not
   edited to admit one.** Re-confirmation is a human editing the record — the path the corpus
   already names.

7. **A report line may name a field and a remedy; it may never carry, quote, or offer a candidate
   value.** This is the bound that keeps a horizon prompt from becoming the solicitation
   § *One-way* forbids, and it is stated so it cannot widen.

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
composed `ANSWERED` silently — the defect this record exists to close.

**Behaviour that does not change.** No record is written by this change. Nothing composes to a new
sentinel; `UNKNOWN` is unchanged and the publish guard is untouched. The person-record schema's
fence is untouched and its schema version does not move. The reference verb keeps its narrower read
scope and passes the clock, because it answers *which record* rather than *is this record usable for
this trip*; that divergence is designed and is documented at both surfaces.

**Debt created and stated.** The reference-month divergence between that verb and composition is
bounded and documented rather than resolved. And the `Passport` slot path still has no tracked
witness carrying a real horizon, because the class forbids a passport value in a tracked file —
**a permanent residual by design**, and the reason the fixture demonstrates the mechanism on a
different field.

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
