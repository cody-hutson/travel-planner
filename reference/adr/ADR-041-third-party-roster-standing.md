# ADR-041: A third-party member's roster standing — no `## Group` row, and one unnamed place in `Total travelers`

- **Status:** Accepted (2026-09-28)
- **Deciders:** repo maintainer
- **Driving work:** the *Erasure reaches every name, and a third-party member holds one standing*
  milestone — its card on whether a `[THIRD-PARTY]` party member holds a roster row. The operator
  chose the standing at that release's scope-lock, chose how the count reaches the total at its
  addenda briefing, and chose how a counted member leaves the total and how this record meets the
  records that bind a model-derived value at the render at a later briefing; this record is required
  because the answer supersedes parts of `Accepted` decisions.

## Context

A `[THIRD-PARTY]` party member is a person whose needs the operator supplied through
`## person <name>` and who will never file a profile. At `2a3e528` the corpus gave four answers on
whether such a member holds a `## Group` roster row and a place in `- **Total travelers:**`:
`reference/data-model.md` § *Traveler identity* rested the roster's totality on their *"still [having]
a roster row"*; `skills/trip-record/SKILL.md` § `group` gave them no row and no place in the total;
`agents/04-transport.md` § *Input* item 7 sized streams from the roster and read the model for depth
alone, so a member with no row rode no stream; and `CLAUDE.md` said such a value never escalates into
`trip-context.md`, naming constraint escalation only. `ADR-028` and `ADR-029` each worded a
population rule to hold under every reading.

Three shipped mechanics bear on the answer. The site renders `trip-context.md`'s `## Group`
(`reference/site-layout-spec.md` § 9.1). The publish guard's non-publishable class takes every value
of a `[THIRD-PARTY]` entry (`reference/data-architecture.md` § 5.3), and its parse keys the entry's
name as a token — for every name it can key, with the limits `ADR-008` § *Coverage boundary* states.
And `ADR-011` Decision 2 bounds transport's read of the model to the depth signal.

Three Accepted records bind a value derived from the traveller model at the render, each tracking
the `internal-hard` class `reference/data-architecture.md` § 5.1 defines: `ADR-030` keeps people who
did not fill in their own form off every page and binds what is derived from the leaning fields to
the model's class; `ADR-010` reads any signal that lets a reader tell one traveller from another as
an anonymized projection of a model value, which § 5.1 forecloses; and `ADR-025`'s never-carry 2
keeps the model from any render in any form, anonymized included. A published total that counts
such a member carries a number the engine derives from that model.

## Decision drivers

- **No name in a publish-bound file.** A row prints the member's name where the site build reads it.
- **No proxy profile.** A row's `Traveler file` cell asserts a profile the member never filed — the
  artifact `ADR-006` rejected.
- **An honest published party size** — the operator's call at scope-lock.
- **A count the engine keeps** — the operator's call at the addenda briefing: the total counts such
  a member without the operator restating it.
- **Nobody counted twice** — not a member a stated total already carries, and not a person the
  roster already names.
- **A member who stops travelling leaves the count** through a verb this command already has, rather
  than staying counted until one exists.
- **No passenger dropped** from a stream transport sizes, through a source that publishes nothing.
- **A departure from Accepted text is recorded where it is taken**, never read around.
- **One owner, cited everywhere.** The card's defect is one rule drifting across its restatements.

## Options considered

**The standing.**

| Option | For | Against | Verdict |
|---|---|---|---|
| O1 — a named row, counted | the roster stays total over every model entry | the name reaches a `bound`, rendered file; the `Traveler file` cell asserts a proxy profile; the member becomes declarable as an approver (`ADR-029` step 1) | rejected |
| O2 — a row whose `Person` cell is a placeholder | no name published | a placeholder row is unreachable as evidence in `## group` — it enters no count and is never removed — so the member would sit on the roster as a row nothing reads | rejected |
| **O3 — no row, counted in `Total travelers` as an unnamed member** | the published party size stays honest; no name and no need reaches a publish-bound file | a total above the named rows tells a reader that the party holds someone the roster does not name | **decided — the operator's choice at scope-lock** |
| O4 — no row, not counted | nothing about the member reaches any publish-bound file | the published party understates the real one, and every sizing consumer must count from the model | weighed and not chosen |

**The owning surface.** `skills/trip-record/SKILL.md` § `group`: the roster's writer under
`CLAUDE.md` § *Write ownership*, and the verb-section home the standing clause's Extension rule gives
a rule that binds only some verbs. Not `reference/data-model.md` (then carrying the contrary answer),
`CLAUDE.md` (a summary surface), the trip-context template, or this record (a record, not an
operational rule).

**How the count reaches the total.** No writer of `- **Total travelers:**` read the model.

| Option | Verdict |
|---|---|
| **W-b — `## group`'s table reads the model's count of such members, and every verb that writes the total applies that table** | **decided — the operator's choice at the addenda briefing.** The total counts them without the operator restating it. Its price is a read of an `internal-hard` file by the verbs that write a `bound` one, held to one count (decision 5) |
| W-a — the operator states the total; `## person` names `/trip-record group` and does not run it | weighed and not chosen: every member recorded after the scaffold leaves the published total short until an operator act |
| W-c — `## person` writes the total by a rule of its own | rejected: a second reconciliation of `## Group` beside `## group`'s table |

**Which verb brings the total up at admission.** `## person`, applying `## group`'s table once its
reconcile has written the model — chosen: the count it reads is fresh by construction, and it is the
shape `## group-expand` already takes. `## person` naming `/trip-record group` — weighed: it leaves
every admission lagging. A report alone — rejected: it counts nobody.

**How a counted member leaves the total.** A firm floor with the withdrawal left to a verb no card
builds — weighed: a member who stops travelling stays counted, and a departure removed from the
roster re-enters the count at the next reconcile. A stated total below the floor written as stated —
weighed: the next admission, or a go-ahead at the table's asking row, raises it back. **Chosen:**
`## person` carries the operator's statement that a member is not travelling to the reconciler,
whose second exit already drops the entry, and applies the table once with a withdrawal row — the
shape it takes at admission. **Where the roster names such a member and they leave the party,** the
departure naming that withdrawal for the operator to run — weighed: until it runs, their entry
stands, re-enters the count at the next reconcile once no row shares its key, and the next admission
or removal judged against that count counts them again, unflagged. **Chosen:** `## group` carries
the same statement in the act that removes their row, to a reconcile it runs once the row is off,
and its removal rows lower the total once — the operator's choice at the briefing that settled how a
removal is judged. Its price is a second reconcile on such a departure, and a departure answered by
mistake drops the entry with the row.

**Keeping a person the roster names out of the count.** A mark the reconciler writes on such an
entry's heading while a roster row shares its key — chosen: the readers count marks and never
names, and the one component that holds both sets decides. A note in the entry's body — rejected:
the publish guard takes every body line of such an entry into its non-publishable class. A key
comparison by each reader — rejected: it reads names, and re-implements the reconciler's join.

**How the count keeps pace with a roster change.** `[ROSTERED]` is written only by a reconcile, and
`## group` changes the roster without one, so between the two the count is a reconcile stale: one
high after a row is added for such a member, and one low after a stale row comes off. Three
mechanisms were weighed. The `/trip` verbs that dispatch transport running the reconcile first, as
`/trip plan` does — weighed: it keeps transport's count fresh, but leaves a removal judged against a
floor one off, adds a dispatch to every run of three verbs that change no roster, and alters what
they dispatch. A name-free fingerprint of the roster, recorded in the model and compared at read
time — rejected: a fingerprint of counts cannot tell a removal and an addition from no change, and a
sound one tells a reader only that the model predates the roster, never which mark is stale, so
transport could flag the gap but not size it, and a removal could only be refused. `## group`
running the reconcile after every roster change — weighed: it closes both directions, but a
reconcile on every row added would make N runs of `## group` do what one `## group-expand` does not
(`ADR-016` § 4), and the one direction it closes beyond the choice below errs toward sizing a member
twice, which transport's brief already flags. **Chosen:** a removal reconciles — before the row comes
off, and after a stale one — because it is the one roster change whose stale count errs low. The run
before the row comes off is the verb's own read before it judges, the shape `/trip plan` takes when
it runs the reconcile at the head of its chain, and it precedes the change `ADR-035`'s step R0 is
triggered by. The runs once the row is off — after a stale row, and after a departure whose
withdrawal the verb carries — are where it takes the one supersession it needs: `ADR-035` has the
verb that changes the roster name the reconcile for a later act and leaves automating it to the
living-site milestone, and in those cases `## group` runs it itself (decision 4). That record's
sentence that a refusal, a removal or a withdrawal is recorded only through a verb that runs the
reconcile step is not read as covering them: it concerns a traveller's refusal, removal or
withdrawal of what the private site shows, recorded by a verb `ADR-030` leaves to a later slice.

**A row whose own stop holds the reconcile.** The reconcile before a removal stops on a roster row
that reduces to nothing, that shares its key with another row, or that shares a third-party entry's
key under a different display name; removing that row is what would clear the stop. Removing
nothing until the stop clears — weighed: the row could then never come off through the engine, and
where it holds a member's name under another spelling it stays in a publish-bound file until a hand
edit. Giving the engine the rename the stop asks for — rejected: it writes the member's name into
that file by an engine act, unguarded where the name is made only of stopwords. Removing the row
and judging the total against the count the last completed reconcile left — rejected: a row added
for such a member after the stopped row stood leaves that count one high, and a departure judged
against it ends one above the party, unflagged. Removing the row, reconciling, and judging against
the count that run leaves, plus the row — weighed: it lowers the total in the act, but adds a third
case to the supersession of `ADR-035`'s step R0. **Chosen:** the row comes off on the operator's
answer, and no total is judged against a count: a row the operator says is such a member's own
comes off as a stale row does, whose disposition compares the total with no floor, and if the
member is leaving, their withdrawal is the one `## person` carries; any other such row comes off
with the total left as it stands, which the act says may still count it, for the operator to
restate. Where the member has since filed their own profile, which nothing `## group` reads can
tell, so it asks, the row is theirs: keeping it — weighed: every reconcile then stays stopped until
a hand edit renames it; taking it off as any other such row, and naming its addition under the
entry's name, which the join can confirm — chosen.

**How this record meets the records that bind a model-derived value at the render.** A stated
reading — that a count of entries is a property of the file and not a value of any entry, so none
of them reaches it — weighed: `ADR-030` binds the counts derived from the leaning fields to the
model's class, and the reading would leave three Accepted texts standing unmarked beside a decision
that departs from them. **Chosen:** a supersession in part, for exactly one integer, recorded in
each of them (decision 5).

**Transport's source for a third-party passenger.** The roster alone drops them.
`- **Total travelers:**` is publish-bound, cannot tell them from any other member the roster does
not name, and can lag the model. A count passed down by every dispatcher widens every dispatcher.
**Chosen:** item 7 reads the same count from the model.

## Decision

1. **The standing.** A `[THIRD-PARTY]` party member holds no `## Group` roster row, and is counted in
   `- **Total travelers:**` as an unnamed member. `skills/trip-record/SKILL.md`
   § *Roster standing of a third-party member* states the rule once, with its three states and their
   dispositions; this record cites it and does not restate it.
2. **What `ADR-006` § *Q3* bars.** Q3 bars a third-party-sourced **constraint** from any published
   artifact, in attributed or anonymized form, and its anonymization clause is about a need —
   *"one traveler needs an afternoon rest"*. It does not bar a headcount. Nor does `CLAUDE.md`'s rule
   that a `[THIRD-PARTY]` value is never published: the party's size is a fact about the trip, not a
   value of the member's entry, and a count of entries is not a value of one. Q3's heading reads
   more widely than its decision text; this record reads it by its decision text. **No decision of
   `ADR-006` changes.**
3. **An entry with no roster row takes its name authority from the operator statement that
   admitted it**, and its record is its own carried-forward heading in `outputs/traveler-model.md`.
   Where a roster row shares its key, the reconciler's join in `agents/00-enrichment.md`
   § *Traveler identity* decides which record stands: a usable profile — one the person has filled,
   not the intake template left unfilled — supersedes the entry, and where none does, the join writes
   `[ROSTERED]` on its heading for that pass, and no pass carries the mark across. A shared key under
   differing display names is stopped, never joined.
4. **The engine keeps the count.** The **outside-roster count** is the number of
   `outputs/traveler-model.md` headings carrying both `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]` and
   not `[ROSTERED]`. `skills/trip-record/SKILL.md` § `group`'s reconciliation table compares
   `- **Total travelers:**` with the **counted floor**, the named-traveler count plus that count.
   `## person` applies the table once its reconcile has recorded a member, so the total counts them
   from the act that admits them; `## group` and `## group-expand` apply it on every write. A total
   at or above the floor is left as it stands, so a member a stated total already carries is never
   counted twice. **A counted member leaves the count the way they entered it, on the operator's
   statement that they are not travelling, carried to the reconciler, which drops their entry:**
   `## person` carries it and applies the table once, whose withdrawal rows lower a total that
   equalled the floor they were in; and where the roster names such a member and they leave the
   party, `## group` carries it in the act that removes their row, whose removal rows lower the total
   once, save where a stop on their row held the reconcile before it, when `## group` names the
   statement for `## person` to carry. The engine lowers no total on its own — only on that
   statement, or on a roster row `## group` removes. **A removal is judged on a fresh count:** before
   it judges a removal, `## group` runs the reconcile as its own read, so the pre-removal floor its
   rows compare with is the roster's own; that run precedes the change `ADR-035`'s step R0 is
   triggered by, and where it cannot complete, nothing is removed but a row one of that run's stops
   names, which is judged against no count: a row the operator says is such a member's own, under a
   display name the join cannot confirm, comes off as a stale row does unless the member has since
   filed their own profile, and any other with the total left as it stands. **Once the row is off,
   `## group` runs the reconcile again in two cases:** a row taken off as a stale row, so the member
   it named is counted outside the roster before the act ends; and the departure of a member recorded
   through `## person` where no stop on their row held the run before the removal, carrying the
   statement above. **For those two runs this supersedes in part `ADR-035`'s refresh obligation, step
   R0,** whose signal has the verb that changed the roster name `/trip-record travelers` for a later
   act, and which leaves automating any step to the living-site milestone: in those two cases the
   verb runs it, and names it only where that run does not complete. Every other removal still names
   it, as R0 states; every other trigger's signal, R1 to R3, and the rest of `ADR-035` stand.
5. **What crosses the publish boundary — a supersession in part, for exactly one integer.** One
   integer crosses from C12 (`internal-hard`) into C1 (`bound`): the outside-roster count, as a
   summand of the published total. The published `- **Total travelers:**` may therefore carry the
   count of operator-recorded third-party members derived from the traveller model, and this record
   decides that as a **supersession in part, for exactly one integer**, by the operator's decisions
   to count such a member (at the scope-lock) and to have the engine keep the count (at the addenda
   briefing). For that integer alone it supersedes:
   - `ADR-030` § 2's exclusion of people who did not fill in their own form, as it applies to a
     headcount, and § 4's source binding, as it would bind this count to the traveller model's
     class;
   - `ADR-010` § 4's reading that a signal derived from a traveller-model value is an anonymized
     projection § 5.1 forecloses, as it applies to this count;
   - `ADR-025`'s never-carry 2, which keeps C12 from any render in any form including anonymized,
     as it applies to this count.

   **The rest of each stands.** No name, no need, no other value of such an entry and no other count
   derived from the model reaches a render by this decision, and `reference/data-architecture.md`
   § 5.3's non-publishable class is unchanged. The verbs that take the count read that file for the
   count and nothing else, counting headings by their marks and never by their names — a bound they
   follow, as transport follows `ADR-011`'s. The publish guard (`ADR-008`) stays the mechanical
   backstop; its coverage boundary is unchanged, and its parse reads `[ROSTERED]` as metadata. Each
   superseded record carries the supersession on its `Status:` line and an inline marker at the
   superseded text, per `reference/adr/README.md` § *Convention*.
6. **Transport reads the same count** and carries it on the anchor stream. Where the published total
   is smaller than the named travelers plus that count, its brief flags the gap and names nobody.
7. **Supersession in part — `ADR-011` Decision 2.** Its item-7 sentence, that transport reads the
   model *"for the depth signal and for nothing else"*, is superseded in part: item 7 also reads the
   count in 4, and nothing else. The bound on reading stream membership or origin from the model
   stands, as do the rest of Decision 2 and every other decision of `ADR-011`.
8. **What the hub may carry** into the bound itinerary. Where a stream's `**Passengers:**` line ends
   in `+ <n> party member(s) outside the roster`, the itinerary names each booking that stream needs
   and points to the brief for each booking's quantity, the stream's bag and traveller counts, and
   its per-person and group prices; it states the party's size only as the published total, never
   the clause and never a count of part of the party that includes such a member; and it carries the
   brief's lagging-total flag with no number and no name. A brief with no such clause is carried as
   before. For the cost estimate a line ending in that clause is not a determinable participant set,
   so its `group-total` lands on the `unallocated` line, the refusal path `ADR-018` § 4 already
   states.
9. **`ADR-028` and `ADR-029` stand.** The presence file never carries a `[THIRD-PARTY]` entry, and a
   count of entries is not a value on one; approvers are declared from `Person` cells, which such a
   member does not hold once no roster row names them.
10. **Graded** by `scripts/test-corpus-hygiene.sh` group `E`.

**How a third-party member's existence flows.**

| Step | Producer → consumer | What crosses | What never crosses |
|---|---|---|---|
| 1 | operator → `## person <name>`, or `## group [<name>]` when such a member the roster names leaves the party | a name and needs, or the statement that they are not travelling, in the session; `## group` carries only the second | — |
| 2 | enrichment → `outputs/traveler-model.md` (`internal-hard`) | one `## <Name> [OPERATOR-PROVIDED] [THIRD-PARTY]` entry, carried forward verbatim, with `[ROSTERED]` on its heading while a roster row shares its key | facets, origin, any byte of `trip-context.md` |
| 3 | model → `## person`, `## group`, `## group-expand` → `trip-context.md` (`bound`) | the outside-roster count, as a summand of `- **Total travelers:**` | a row, a name, a need, a heading, a mark |
| 4 | model → transport § *Input* item 7 | the same count | a name or a need |
| 5 | transport → `outputs/transport-brief.md` (`internal`) | the anchor stream sized with the count, and the `+ <n>` clause | a name or a need |
| 6 | brief → hub → `outputs/final-itinerary.md` (`bound`) | the plan the count sized and each booking by name; the party size only as the published total; the brief's lagging-total flag, with no number | the clause; a booking's quantity, the stream's bag and traveller counts, or a price on a stream carrying it; a count of part of the party that includes the member |
| 7 | model → hub and validator | needs as bounds on the plan | needs as rendered text (`ADR-006` § *Q3*) |
| 8 | roster and total → site | the travelers' names and the total | the member's name |
| 9 | publish guard | every value of the entry, its name keyed as a token wherever it can be | a render carrying a keyed value is refused |

## Consequences

- **The cost the operator accepted.** A published total above the named rows tells a reader of the
  site that the party holds someone the roster does not name. In a small party that person may be
  identifiable to people who know it. Their name and every need of theirs stay out.
- **A read across the publish boundary.** The verbs that write the published total read an
  `internal-hard` file for one count, and the bound on that read is a rule they follow rather than a
  property of the read — the kind transport's read under `ADR-011` already is. The shipped precedent
  is `## group-expand`, which reads `groups/<id>.md`, an `internal-hard` record, while writing the
  bound roster. The records that bar a model-derived value at the render are superseded in part for
  that one integer and no further, and each says so where its text stands (decision 5).
- **Where the total can still lag.** On a trip whose members were recorded before this decision,
  until its next admission or an operator's go-ahead at the table's asking row; where an asking row
  is left unsettled; and where a count is read after a row is added to the roster and before the
  reconcile that follows it, while `[ROSTERED]` is a reconcile stale, a count that then reads high.
  Transport's brief and the itinerary flag each one, naming nobody. **A removal is judged on a fresh
  count** (decision 4): `## group` runs the reconcile before every removal and removes nothing where
  that run cannot complete but a row one of that run's stops names, which is judged against no
  count, and runs it again once a stale row comes off or a member recorded through `## person`
  leaves, save where a stop on their row held the first. So a removal leaves out no member who still
  travels, except where a row comes off outside that verb, where the row of a member who still
  travels comes off on an answer that they were leaving, that the row was a duplicate, or that it
  was added in error — one recorded through `## person` and answered as leaving then loses their
  entry with it, save where a stop on their row held the reconcile before the removal — or where the
  reconcile after a stale row does not complete; where a row that reconcile stopped on comes off as
  a departure, as a duplicate or as added in error, the total stays as it stood until the operator
  states the party's; and where the reconcile after a recorded member's departure does not complete,
  or a stop on their row held the one before it, their entry stands until the withdrawal the act
  names, and a later removal or admission judged against a count that includes them again leaves the
  total one above the party, with nothing to flag it.
- **A withdrawn member leaves the count on the operator's statement.** `## person` carries it: it
  drops their entry and lowers a total that equalled the floor they were in; a total above that
  floor is left for the operator to restate, and a member the roster still names leaves the count
  with their row. Where the roster names such a member and they leave the party, and the reconcile
  before the removal completes, `## group` carries the same statement in the act that removes their
  row, so their entry drops with it and the removal rows lower the total once; that removal pays a
  second reconcile, and a departure answered by mistake drops the entry with the row, which
  `## person` restores only once the operator restates the member's needs. Where that second
  reconcile does not complete, `## group` says so and names the withdrawal, as it does where a stop
  on their row held the reconcile before the removal, and until it runs the entry stands.
- **A family recording a named child third-party** sees the child leave the published roster and
  stay in the published total; the plan honors every need.
- **The archived witness.** `examples/archived-trip-demo/` keeps the total it was archived with: the
  verbs that write a total serve only an active trip, and an archived trip receives no derivation.
  How its README says so is settled by the erasure card's design, which owns that fixture in this
  release.
- **Declared residuals,** routed to a next-release issue: the intake form's *"The trip's Group roster
  holds the full list"* (`templates/traveler-intake.template.md`); the cost estimate's omission of a
  per-person third-party fare; nothing asserting C2 or C3 on an entry the roster does not name; a
  `+ <n>` line's `group-total` left whole on the `unallocated` line rather than split; the hub's
  carry rule, exercised by no run in this release; a stated total whose unnamed remainder counts
  someone else in place of such a member, which the table reads as complete; a withdrawal whose
  name the roster spells differently from the entry — where the total equals the floor the
  reconcile leaves, the member is left in it, and where it exceeds that floor by one, the
  withdrawal rows decrement it and the later removal of the member's row as a departure decrements
  it again, so it ends one below the party's size, a path the withdrawal `## group` carries never
  takes, since it names the member as their row does; a removal's reconcile replacing an
  `## Update signals` block an earlier pass left for a replan that has not yet run and, within the
  act, a second run's block, or its absence, displaces the first run's, which then survives in the
  transcript only; and a roster row that itself stops every reconcile — rows reducing to one key, a
  name that reduces to nothing, or a name sharing a third-party entry's key under a different
  display name — which comes off through `## group` on the operator's answer, judged against no
  count, unless it is the only place in the count of someone who still travels; that row then stays,
  and the removal of any row no stop names waits until it is renamed, while no text states that any
  verb's edit reaches a roster row's `Person` cell.
- **Reversibility: CHEAP.** Markdown and one suite group. Reverting the release restores the text of
  `ADR-011`, `ADR-010`, `ADR-025` and `ADR-030` with it.

## References

- `skills/trip-record/SKILL.md` § *Roster standing of a third-party member* — the rule, its three
  states and their dispositions; § `group`'s reconciliation table — the counted floor.
- [ADR-006](ADR-006-third-party-data-capture.md) § *Q3* — the published-output bound, read by its
  decision text.
- [ADR-008](ADR-008-publish-content-guard.md) § *Coverage boundary* — the guard's declared limits.
- [ADR-010](ADR-010-per-traveler-approval-collection.md) § 4 — the anonymized-projection reading,
  superseded in part (decision 5).
- [ADR-011](ADR-011-per-traveler-cost-estimation.md) Decision 2 — superseded in part (decision 7).
- [ADR-018](ADR-018-cost-estimation-method.md) § 4 — the `unallocated` refusal path.
- [ADR-025](ADR-025-engagement-model-over-time.md) § 3 never-carry 2 — superseded in part
  (decision 5).
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the presence file's population, which
  stands.
- [ADR-029](ADR-029-group-approval-return-and-threshold.md) — approvers declared from `Person` cells,
  which stands.
- [ADR-030](ADR-030-what-the-private-site-may-show.md) § 2 and § 4 — superseded in part (decision 5).
- [ADR-035](ADR-035-site-transitions-and-refresh.md) — the refresh obligation's step R0, superseded in
  part for the reconcile `## group` runs once a row is off (decision 4).
- `agents/04-transport.md` § *Input* item 7 · `agents/00-enrichment.md` § *Traveler identity* ·
  `reference/data-model.md` § *Traveler identity — the satisfaction-layer projection* ·
  `reference/data-architecture.md` § 5.1 and § 5.3 · `scripts/test-corpus-hygiene.sh` group `E`.
