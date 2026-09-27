# ADR-037: The group snapshot — what travellers share with the group before a plan, whose it is, who writes it, and where it shows

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries the group snapshot; *References* lists the card's other records. The milestone's other
  cards are [the private-site record](ADR-030-what-the-private-site-may-show.md) (#1242) and [the
  contact and emergency record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after
  [the private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because every value it carries is one that record admits
  (G-4). The flip is the maintainer's, taken at
  this milestone's close, and it moves both halves of a two-artifact state: the `Status:` line
  above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **the group snapshot**, the section that carries the group's
  shared details to the private page before a plan exists: what it carries, whose data it carries,
  who writes it and when, its class, where it shows, and what never happens.
- **What this record is not.** It does not decide what the private site may show, which is the
  private-site record's, or where the snapshot's section sits in each state, which [the site
  phase-model record](ADR-031-site-phase-model.md)'s map places. It builds nothing, and in this
  release it changes no `publish:` value, no fence line and no per-verb requirement row: every
  change it decides lands in a later slice.
- **How it was decided.** In a scoped design step for the group snapshot on the card's design
  sub-task #1388, after the operator's D-3 added it to the milestone; the milestone's fit review and
  scope lock, CR-2, are recorded on #1369, and decision Q, recorded on #1385, binds the snapshot's
  writer through the private-site record's safeguard 7. The card's one record was split by topic
  under the operator's R2, recorded on #1369, with no decision changed.

## Context

**Before a plan, nothing rendered carries the group's shared details.** [The site phase-model
record](ADR-031-site-phase-model.md) carries a value the group may see to the page only through a
`bound` artifact that carries it, and before a plan no rendered document carries a traveller's own
window, where they set out from, or how they like to stay and pace their days. Of the carriers that
record weighed, a derived, `bound` projection of the shared details was taken as the group snapshot,
by the operator's D-3.

**Terms.** R0 to R3 are the refresh steps [the site-transitions
record](ADR-035-site-transitions-and-refresh.md) declares, and D0 to D4 the dispositions of [the
section-ceiling record](ADR-033-site-section-ceiling.md)'s ladder.

**Precedents this record reuses rather than mints.**

| Precedent | Where | What it already decided |
|---|---|---|
| The presence class | `ADR-028` § 2 | an `internal` class takes no fence row and no § 9.3 row: the class alone excludes it |
| Production-gating | `ADR-026` § 4 | mode conditions production, never reach, and is never an artifact-availability axis |

**The inputs this record is bound by.** The private-site record's verdict — what the group may see,
the share mark, the concealed occasion and the seven safeguards — and the contact and emergency
record's carrier are inputs here, cited rather than restated. The milestone's surface map, recorded
on #1369, fixed the closed list of what this record still had to decide.

## Decision drivers

1. **`ADR-026` § 4 binds.** Mode conditions production and never reach, and it is never inferred from
   which files exist.
2. **A value's bound is the same in every mode**, as the joint source-binding step of this milestone
   (#1383) fixed it.
3. **One declared home per fact, graded by an existing suite** — the corpus pattern of groups `PB`,
   `W` and `MG`. A rule nobody grades is the defect group `W` was built to close.
4. **Fail closed.** An empty read is not an empty class (`ADR-009` § *Decision* 4.4).
5. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
6. **The private-site record's verdict** — its lists, its share mark, its concealed occasion and its
   safeguards — binds every cell of the map.
7. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### The group snapshot's writer and home

| | Option | Disposition |
|---|---|---|
| **W1** | **The enrichment agent, in its reconciler role** | **chosen.** It already reads every input and already computes who filed, so it adds no agent |
| W2 | The destination-ideation agent | **rejected.** It is skipped once a destination is set, so it cannot serve *Destination in play*; its declared read is the leaning fields only, and the shortlist's no-reader design stands |
| W3 | The site build, deriving it at render from the traveller model | **rejected.** The build reads no traveller file or model, and the model is `internal-hard` — never rendered in any form |
| W4 | A `/trip-record` verb, writing it itself | **rejected.** That verb's own writes are human source; where a derived file must be rebuilt it dispatches the reconciler or names that step, because ownership follows the writer, not the caller |
| W5 | The hub | **rejected.** It runs only in synthesis — never in *No destination yet* — and the snapshot is not plan content |
| W6 | A new agent | **rejected.** A new roster row and dispatch for a projection the reconciler already holds every input of |
| **S1** | **A new `bound` class, `outputs/group-snapshot.md`** | **chosen** — net-new, because in-place is infeasible |
| S2 | Fold it into the shortlist | **infeasible.** The shortlist renders only in *No destination yet*, its producer is skipped once a destination is set, and its schema declines per-entry fields |
| S3 | Fold it into the trip context | **infeasible.** No per-traveller desire detail goes in that file, which is block-owned, and it would give traveller answers a second, hand-edited home |
| S4 | Relax the traveller model to `bound` behind a field fence | **rejected.** The model carries values that are out, and the field-keyed mechanism is not carried forward |
| S5 | The traveller file made `bound`, with a field fence | **rejected.** It covers only the per-trip half, and the build would parse raw hand-edited files |
| S6 | Widen `ADR-028`'s presence file | **infeasible.** It is `internal` and bounded to its window lines, and its own tripwire moves it to `internal-hard` the moment it carries content derived from desires |

### The group snapshot's production and currency

| | Option | Disposition |
|---|---|---|
| **P1** | **Written only on IDEATION passes; on the `site` verb's Reads line in every state** | **chosen** — the shortlist's pattern, with no false `BEHIND`. Its costs: a mode branch in an agent, graded only once registered; and on a return to IDEATION the file on disk is as of its last IDEATION pass until reconciled, which the `mode` verb names |
| P2 | Written on every pass; the Reads line qualified by state | **rejected.** A state-qualified Reads line is a new idiom [the site-admission record](ADR-034-site-build-admission.md) declined for the shortlist — two patterns for one problem. Its real merit, a file kept current across a return, is named |
| P3 | Written on every pass; the Reads line unqualified | **rejected.** A false `BEHIND` on every plan-mode reconcile — `ADR-028` § 2's own reason |
| P4 | The site verb dispatches the reconciler before building | **rejected.** The site dispatches no agent and never edits an `outputs/` file as a side effect; it would widen the verb's grants and read class |
| **R-a** | **No new freshness relation** | **chosen** — ride the named reconcile step, R1 to R3, and the declared hand-edit residual |
| R-b | A `profiles-to-snapshot` relation | **rejected under P1.** It would read `BEHIND` in every plan mode, with a remedy that cannot clear it |

### The group snapshot's smaller forks

| Fork | Chosen | Rejected, and why |
|---|---|---|
| Plan modes | excluded | rendered as a section: it re-opens the plan-mode carriers, and D-3 scopes the document to before a plan |
| A marked desire | its `Desire` text only | the whole desire block: its overlap signal would disclose unmarked desires, and its tiers invite ranking people's wants |
| Content that is out, inside a carried value | withhold the line whole | trim it: that publishes words the traveller did not write |
| The population floor | `SELF-STATED` | `ADR-025`'s default floor, `OPERATOR-STATED`: the private-site record's safeguard 3 |
| The name | `outputs/group-snapshot.md` — the operator's own term | a neutral stem such as `group-details`: it loses traceability to D-3 |

## Decision

**Before there is a plan, the private page gets a section about the people going.** It shows while the
group is choosing where to go, and while a place is being explored but not yet planned; once planning
starts, the plan takes over the page. For each person who filled in their own trip form it shows what
they said, in their own words — when they can travel, where they would set out from, how they like to
stay, eat and pace their days, the wants they chose to share, and the occasion the trip marks if they
said it is not private. A line appears only if the person answered it; nothing is guessed. It is the
operator's D-3, designed on #1388, and it holds G-1 to G-6 whole.

### G-1 — What it carries

**A closed field list, every row of the private-site record's IN list disposed of by name.** Labels are
spelled exactly as the intake forms spell them; the scope is the one `reference/data-model.md`
§ *Field Scope* assigns.

| IN item | Field | Asked on | Scope | In the snapshot? | Why |
|---|---|---|---|---|---|
| who is coming — name | the roster's `Person` cell | the trip context's `## Group` | — | **no — the entry key only** | the hero renders every name from the trip context (D-1); each entry is headed by the roster display name, a projection of the roster cell, not a second statement of who is coming |
| who is coming — relationship | `Relationship` | the trip form | TRIP | **no** | for a filer the hero renders the roster's *Role / Relationship* cell (D-1); a second relationship text on the same page would give one fact a second home |
| destination leanings and the shortlist | `Would love`, `Rather skip` · `Trip vibe` | the person form · the trip form | DEFAULT · TRIP | **no** | the shortlist section carries them in *No destination yet*; D-4 takes them off the page once a destination is in play |
| dates | `Can travel`, `Blackout`, `Trip length` | the trip form | TRIP | **yes** | no rendered document carries a traveller's own window before a plan; the trip's own dates stay with the hero |
| dates — arrive and leave | `Arrive / leave` | the trip form | TRIP | **yes** | the booked legs reach the page only through the itinerary, in plan modes |
| getting there | `Leaving from`, `Journey comfort` | the person form | DEFAULT | **yes** | — |
| where you stay | `Lodging style` · `Rooming` | the person form · the trip form | DEFAULT · TRIP | **yes** | the booked property reaches the page only through the trip context and the itinerary |
| interests and tastes | `Interests`, `Cuisine appetite` | the person form | DEFAULT | **yes** | — |
| interests and tastes for this destination | `Been here before?`, `Already done` | the trip form | DEST | **yes, only while a destination is recorded** | a DEST value is scoped to one destination; with none recorded it has no referent, so the writer omits both lines — the reason `ADR-025` never-carry 4 gives across trips, applied inside one |
| pace and day rhythm | `Pace`, `Day rhythm` | the person form | DEFAULT | **yes** | — |
| desires the traveller marks group-facing | `Desire` | the trip form's desire block | TRIP | **yes — the `Desire` text of a marked desire, and nothing else of the block** | its priority tier, recurrence and theme tags are planner annotations, and its overlap signal is computed over every desire, marked or not, so carrying it would disclose unmarked desires |
| the special occasion, marked not private | `Special occasion?` | the trip form | TRIP | **yes — only when marked** | unmarked means private, and a private occasion leaves no trace: no line, no placeholder, nothing saying something is withheld |

**What a line carries.** The value the traveller model carries for that label, verbatim — carried
through, not computed. A DEFAULT field is the composed value: the person record's, unless the trip form
answers it. **A line is carried only when its value is answered** — absent, blank, an em dash, a
surviving bracketed placeholder and a lapsed horizon are not answers — and **no line carries a
bracketed mark of any kind**, provenance or horizon.

**Never carried**, named so the list is closed in both directions: `Party`, `Passport`, `Documents`,
`Comfort range`, `Splurge appetite`, the needs block (`Category`, `Specific`, `Applies to`), `Novelty vs
comfort`, `Planning style`, `Group time`, `Split off with`, `Whole-group moments`, `Solo, I'd`, the
free-text tail, update signals, divergence reports, and the engagement value itself (`ADR-025`
never-carry 5).

**The list changes only by a record decision.** A value outside it is never admitted by the writer's
judgment. That is this class's tripwire in `ADR-011` decision 6's form, inverted: the class never moves;
the list does, and only in terms.

### G-2 — Whose data it carries

**The population.** An entry exists only for a roster member whose engagement value (`ADR-025`
§ *Decision* 1) is **`SELF-STATED` or `PERSON-LINKED`** — a traveller-model entry projected from the
person's own `travelers/<traveler>.md`, composed with their own `people/<person>.md` where it is linked.
In `ADR-025` § 5's terms the snapshot declares its floor at **`SELF-STATED`**, the stricter first-party
reading that section names for a consumer needing one.

| Engagement value | In the snapshot? | Why |
|---|---|---|
| `PERSON-LINKED` · `SELF-STATED` | yes | they filed their own form |
| `OPERATOR-STATED` | **no** | the operator relayed the values; the person did not fill in their own form (the private-site record's safeguard 3) |
| `THIRD-PARTY-STATED` | **no** | `ADR-006`; the entry carries needs only |
| `UNSOURCED` — no entry, a missing profile, or a blank form | **no** | nothing first-party is held |
| `ENGAGEMENT-UNDETERMINED` | **no**, and the pass says so | fail closed: a read that did not complete admits no one |

**Also excluded:** an erased member, on every later pass, and a traveller who has recorded a refusal
(the private-site record's safeguard 4, whose capture is Wave 1's). **An entry is written only when at
least one line survives the list, the mark rule and the withhold rule.** A non-filer, a refuser and a
filer with nothing to show all look the same — no entry — and **the page never says which**, so a
refusal is never itself disclosed. The engagement value decides the population and is never written or
rendered.

**Keying.** `## <Name>`, the `## Group` roster's display name — the Traveler natural key, as `ADR-028`
§ 2 keys the presence file. The roster is the display-name authority; a person token is never used.

**People who did not fill in their own form** (D-1). Their roster name shows through the hero, and
nothing else about them does: no entry, and — by the withhold rule — no line in anyone else's entry
that names or describes them.

**Desires and the occasion.** A desire is carried only when the traveller has marked it group-facing,
and the occasion only when it is marked not private — the private-site record's share mark, whose
representation is Wave 1's. **An absent or malformed mark reads as unmarked.**

**The withhold rule — OUT binds by kind, not by carrier.** This is D-2's "out everywhere", applied at
the one producer this record adds. **A carried line is withheld whole — never trimmed, never
paraphrased — when its value states or implies any OUT kind:**

| OUT kind | A line that would be withheld | Where the example comes from |
|---|---|---|
| a need or must-have | `Lodging style:` "hotel; need a lift rather than stairs" | the person form's own `Lodging style` example |
| money | `Rooming:` "own room if it's affordable" | the trip form's own `Rooming` example |
| a person who did not fill in their own form | `Special occasion?:` "Mum's 70th, on the Thursday", where that person is a non-filer | the trip form's own `Special occasion?` example |
| togetherness, or a split | `Rooming:` "my own room, away from Sam" | — |
| identification, or contact details | an address written into `Leaving from` | — |

**Why withhold rather than trim.** Trimming publishes words the traveller did not write, against the
reconciler's own rule that it never authors or rewrites a traveller's own words. Withholding costs
coverage and never misstates anyone; a traveller who wants the line shown can reword it, and the
notice (the private-site record's safeguard 1) is where they learn that.

### G-3 — Who writes it, and when

**The writer: the enrichment agent, in its reconciler role only**, never its research role — one
writer, as § 1.1 requires. It already reads every input — each `travelers/<traveler>.md`, the linked
person record, `trip-context.md` and the model it replaces; it already carries every IN field into the
model by its label; and it is the one component that computes who filed, since its missing-profile
branch is `ADR-025`'s evaluator. **So the snapshot adds no read and no agent.** `ADR-028` § 4 widened
the same role's write set by the presence file, and this is the same kind of extension.

**Its source.** As designed, the snapshot is a projection of the traveller model the same pass writes,
read and never re-derived, and the reconciler's composed source stays "a value, not a file", never
materialised. **The private-site record's safeguard 7 (decision Q) re-points that input:** no agent step
that writes a file the site build reads receives a value of the non-publishable field class, so the
step that writes the snapshot reads the script-made projection of the traveller data that omits the
class, and the writing of internal files from full inputs is split from the writing of group-visible
files from the projection. **Carried to Wave 1, as conditions by citation to
[the private-site record](ADR-030-what-the-private-site-may-show.md):** the projection script; that
split; and the snapshot's writer input re-pointed to the projection. G-1's list carries no member of
that class, so what the snapshot carries is unchanged by it.

**When: production is gated on the declared mode.** The reconciler writes the snapshot **on a pass
whose resolved mode is IDEATION, in either destination state, and on no other pass.** Outside IDEATION it
leaves the file untouched on disk: not rewritten, not deleted. The mode comes from the dispatching verb's
resolved record and is never inferred. This is `ADR-026` § *Decision* 4 exactly: mode conditions
production, never reach.

**Why the gate.** The site declares the snapshot on its **Reads:** line, which is the source side of
`itinerary-to-build`. A file rewritten on plan-mode passes would raise a `BEHIND` that a rebuild clears
without changing the page — the false `BEHIND` `ADR-028` § 2 kept the presence file off that line to
avoid. Producing the snapshot only in the states that render it is the shortlist's argument, reused: it
joins the Reads line in every state, and it can lead `itinerary-to-build` only where `BEHIND` is true.
The gate is an agent-side branch on the mode, so **the Wave-1 slice registers it** in the mode-gated
behaviour register; **until that row lands, the branch is ungraded**, and this record says so.

**Lifecycle: `rebuilt-each-synthesis`.** Rebuilt whole on every IDEATION pass; never appended, never
versioned. There is no carry-forward exception: `ADR-025` never-carry 1 applies without the traveller
model's third-party carve-out, because no third-party entry can enter this file. On an `ARCHIVED`
trip no pass runs.

**The rebuild announce.** `ADR-007` § 2 bound 5's announce is **not** taken for this file. The
class-wide question `ADR-028` § 2 routed covers every `rebuilt-each-synthesis` file a dispatched agent
replaces, this one included, and this record does not pre-decide it. The change a group would see is
confirmed by the organizer at R2 before it reaches them.

**Erasure.** `/trip-record erase` reaches the snapshot directly, by a reach row the landing slice appends
at its own base in `ADR-028` § 9's shape. It **deletes the subject's entry whole**, with **no
tombstone and no token**: the roster row already carries the trip's tombstone, the file holds no
independent state, and a tokenized entry would publish an erased person's values under a pseudonym.
It **never skips silently**. The row's text is Wave 1's.

**Currency — how it stays current when a traveller edits their form.** Report-only throughout: no gate
blocks on any of it (`CLAUDE.md` G8; `/trip-publish` rule 7). The chain is R0 to R3 in
[the site-transitions record](ADR-035-site-transitions-and-refresh.md): the named
reconcile step rewrites the snapshot, `itinerary-to-build` reads `BEHIND`, the organizer confirms, and
`build-to-published` reads `BEHIND` until the republish. **A form edited by hand** is observed by nothing
until the next reconciler pass, whose profile-change detection catches it — a declared residual, the
one the shortlist already carries and the model carries today. **No new relation is added**.

**Safeguard 4 for this document.** A refusal, a removal from the roster or an erasure is honoured **at
the snapshot's next rebuild, by construction**: nothing is carried forward, and a refuser or a departed
member gets no entry. Erasure reaches the file at once. Reaching the published page takes R1 to R3
([the site-transitions record](ADR-035-site-transitions-and-refresh.md)), which are report-only.

### G-4 — Its class

**`outputs/group-snapshot.md`** — writer `enrichment`, lifecycle `rebuilt-each-synthesis`, provenance
`derived`, **`publish: bound`**, primary entities Traveler and Desire. It is named by path, never by
ordinal, because the enumeration's numbering moves (`ADR-028` § 2's rule, reused). It takes a § 1.1
row; a § 9.1 authority row and a `publish-contract-artifacts` fence row, which land with the
§ 1.1 row in one commit so that group `PB` stays green; and the element fence below. Wave 1 lands
each of them and writes its text, and none is edited in this release.

**§ 5.6: no row.** The file carries no `Passport` or `Documents` field and no `[THIRD-PARTY]` entry, by
its own population rule. A row naming a pair outside those the evaluator queries would parse and then
abort every publish as `UNDETERMINED`.

**Why `bound`, and not `internal` or `internal-hard`.** It exists to be rendered, and every value in it
is IN on the private site by the private-site record's verdict. `internal-hard` is reserved for a class
whose values must not reach a rendered page in any form (`reference/data-architecture.md` § 5.1), and
the one class that holds these values that way, the traveller model, keeps that class unchanged.

**The element fence** `round-trip-contract-elements-group-snapshot`, at the label grain the class's
schema declares, graded against the writer's grammar block; its rows follow G-1's list, and their
text is Wave 1's.

### G-5 — Where it shows

**The ladder** returns **D4, a section**, `group-snapshot`
([the section-ceiling record](ADR-033-site-section-ceiling.md)): no § 3 component carries a
per-traveller record — the Hero is a trip-level banner with a line of names, the shortlist section is
keyed by candidate, and the Overview Dashboard is keyed by day and not admitted in IDEATION — and no
section iterates people. Mode earns nothing here: the ground is a new source artifact whose element type
no component represents, not a mode wanting content shown differently.

**Per state** ([the site phase-model record](ADR-031-site-phase-model.md)'s map): rendered in *No
destination yet* and in *Destination in play*; excluded, and named in § 9.3, in every plan mode,
which keep today's shape plus the group contacts section.

**Its three states**, none inferred from existence: present with entries → rendered; present with none
→ **the declared empty state**, a neutral line that gives no reason; absent → **a degraded read, never a
smaller site** — the walk exits degraded, the verb does not present the site as current, and the remedy
is `/trip-record travelers`. Where the section sits, its title and its frame line are Wave 1's layout
and words; the frame says it is what travellers chose to share, in their own words, and that it is not
a plan.

### G-6 — What never happens

| Never | How it holds |
|---|---|
| **anything from the OUT list** | three layers. **The field list:** no OUT field is on it (G-1). **The population:** no non-filer, operator-relayed, third-party, erased or refusing member gets an entry (G-2). **The withhold rule:** content that is out, inside a carried value, withholds the line (G-2). Money: no `Comfort range` or `Splurge appetite`, and money in a value withholds it. Identification: no `Passport` or `Documents`. Needs: no needs block, and a need in a value withholds it. Non-filers and a traveller's `Party` entry: never carried, never named or described. Contact and emergency details: none carried, and an address or a number withholds the line; what of them the group sees is [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md)'s carrier. Planner internals and cross-trip group records: never read or carried. Unmarked desires, novelty against comfort, planning style, togetherness, *split off with*, satisfaction metrics: not on the list, and the overlap signal is excluded because it would disclose unmarked desires |
| **a public page** | the render is limb-blind, and every value in the section is group-only by construction. The private-site record's public-path refusal covers this section **by its presence alone** — a structural key, with no matching on values, which paraphrase would defeat — and no redaction step is added |
| **going live before the rotation fix** | the private-site record's fifth safeguard binds every Wave-1 slice of this document — the class, the writer and the section: none goes live before the fix for the rotation defect tracked privately ships |

**The notice couples with the snapshot.** The private-site record's safeguard 1 is how a traveller learns
what the snapshot shows, what the share mark does and why a mixed answer is left out, so it states G-1's
list, the mark rule and the withhold rule. The forms' own example answers that put content that is out
in an IN line — the person form's `Lodging style`, the trip form's `Rooming` and `Special occasion?` —
are replaced in the same edit.

### Conformance to the records the snapshot touches

| Accepted decision | How this record conforms |
|---|---|
| `ADR-026` § 4, production-gating | The group snapshot, produced only in IDEATION, is one more instance |
| `ADR-025` § 1 and § 5 | The group snapshot reads the engagement value to decide its population, at the floor `SELF-STATED`, and never stores or renders it |
| `ADR-025` § 3, the carry rule and never-carries | The group snapshot is rebuilt each synthesis with no carry-forward, and the axis value is never written |
| `ADR-028` §§ 2, 4 and 9 | The group snapshot reuses its keying, its write-set widening and its erase-row shape |
| `ADR-006` | No third-party value enters the group snapshot, by its population rule |
| `ADR-004` | The group snapshot carries no contact or emergency value; [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md)'s carrier holds what of them the group sees |
| `ADR-007` § 2, bound 5 | The rebuild announce is not taken for the group snapshot: the class-wide question `ADR-028` § 2 routed covers every `rebuilt-each-synthesis` file a dispatched agent replaces, and this record does not pre-decide it |

## Consequences

**Positive**

- **No new agent, no new read and no new writer role for the group snapshot**, and refusal, removal and
  erasure reach it by construction at its next rebuild, because nothing in it is carried forward.

**Costs and residuals, stated rather than smoothed**

- **New rules sit on the reconciler** — the snapshot rules — and are graded only where Wave 1 adds
  arms. The snapshot's withhold rule is conduct; only its labels are graded.
- **A mode branch in an agent**, graded only once the register row lands.
- **A form edited by hand is not observed until the next reconciler pass**, and a publish in between
  shows the old entry.
- **On a return from a plan mode to IDEATION**, the snapshot on disk is as of its last IDEATION pass until
  reconciled; the `mode` verb names the step.
- **An absent snapshot makes an IDEATION build degraded** — one more step, `/trip-record travelers`,
  before a first pre-plan site.
- **Filer status is inferable on the private page**, as the private-site record states.
- **Pre-plan details leave the page when planning starts**, rooming preferences before rooms are booked
  among them; a later record can admit a field into a plan mode through the ceiling.
- **An answer given for an earlier destination cannot be detected** after the destination changes; the
  traveller's form owns it, as it does for the plan.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| the group snapshot joins the `bound` set | group `PB`: "the publish-bound artifact set matches the spec fence that declares it." | a § 1.1 cell landed without its fence row, or the reverse, fails a required check, so both land in one commit — by design |
| content that is out, inside a carried snapshot value | located nowhere | **unverified by design, and declared rather than asserted as fine**: no rule reads value content on the private limb; the withhold rule is conduct, and only the labels are graded |

**The non-blocking claims hold.** The snapshot's staleness never gates a build or a publish.

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `skills/trip/SKILL.md` | `plan`'s naming of the snapshot write, with its condition |
| `reference/data-model.md` · `reference/schemas/group-snapshot.md` (new) · `reference/schemas/README.md` | the snapshot's appended rules section; its schema and coverage declaration |
| `agents/00-enrichment.md` | the group snapshot's writer contract and grammar block, gated on IDEATION, with its output-contract table; the projection split of the private-site record's safeguard 7 |
| `scripts/test-artifact-schema.sh`, beyond group `W` | the snapshot's label arm; group `MG`'s declared heading; the erase tally |
| `skills/trip-record/SKILL.md` | the reconcile-step namings, including on a move into IDEATION; `erase`'s reach over the group snapshot |
| `CLAUDE.md` · `reference/command-reference.md` · `README.md` | the file-structure tree, the register row and the derived row |
| both intake templates | the notice states the snapshot's list, the mark rule and the withhold rule; the example answers that put content that is out in an IN line are replaced |
| `examples/` | a sanitized witness of the group snapshot's class |

**Three axes.** *Best practice:* one declared home per fact; reads that fail closed; withhold rather
than rewrite a person's words. *Scalability:* a new IN field costs one list row, one fence row and
one notice line. *Maintainability:* it reuses the reconciler, the engagement tokens and `ADR-028`'s
keying and erase-row shape, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| G-1 to G-6, the group snapshot | **EXPENSIVE** once built; CHEAP while `Proposed` | HIGH on the class and placement; MEDIUM-HIGH on the production gate and its residual |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What the private site may show, the share mark and the safeguards | [the private-site record](ADR-030-what-the-private-site-may-show.md) |
| What of a traveller's contact and emergency details the group sees, and their carrier | [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) |
| The engagement axis and its boundaries | `ADR-025` |
| The rebuild announce for `rebuilt-each-synthesis` files | the class-wide question `ADR-028` § 2 routed |
| Where the snapshot's section sits in each state, and the page's shape | [the site phase-model record](ADR-031-site-phase-model.md) |
| The refresh steps R0 to R3 the snapshot rides | [the site-transitions record](ADR-035-site-transitions-and-refresh.md) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **The group snapshot slice**: its class, schema and rules, its writer contract, its gated production
  and register row, the dispatchers' naming, the reconcile-step namings, its section, its erase row, a
  sanitized fixture, and its writer input re-pointed to the private-site record's projection. It also
  carries the private-site record's § *Decision* 7 condition, the Decision-4 supersession entry inside
  `ADR-009`, as do the shortlist's render slice and the phase-aware build of [the site-admission
  record](ADR-034-site-build-admission.md): whichever of the three completes the replacement — the
  first change after which an IDEATION build renders the shortlist or the group snapshot — records the
  entry.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The private-site record](ADR-030-what-the-private-site-may-show.md) — the IN list the snapshot's
  fields are drawn from, the share mark, and the safeguards it binds: 1, 3, 4, 5 and 7.
- [The site phase-model record](ADR-031-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The contact and emergency record](ADR-038-contact-emergency-group-visibility.md) — the carrier
  that holds what of a traveller's contact and emergency details the group sees.
- [ADR-025](ADR-025-engagement-model-over-time.md) — the engagement axis and its floors, the carry rule
  and never-carries.
- [ADR-026](ADR-026-channel-architecture.md) — § 4's production-gating.
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the presence class whose keying, write-set
  widening and erase-row shape this record reuses.
- [ADR-007](ADR-007-command-entry-point.md) — § 2 bound 5's rebuild announce.
- [ADR-011](ADR-011-per-traveler-cost-estimation.md) — decision 6's tripwire form, which the snapshot's
  closed list inverts.
- [ADR-006](ADR-006-third-party-data-capture.md) and [ADR-004](ADR-004-contact-emergency-privacy.md) —
  the third-party and contact boundaries the snapshot's population and field list respect.
- `reference/data-architecture.md` — § 1.1's classes, § 5.1 and § 5.6.
- `reference/data-model.md` — § *Field Scope*, the scopes of the labels the snapshot carries.
- `CLAUDE.md` — the mode-gated behaviour register.
- `skills/trip-record/SKILL.md` — the reconcile-step namings and the erase reach table.
- `agents/00-enrichment.md` — the writer this record names.
- `templates/person-intake.template.md` and `templates/traveler-intake.template.md` — the field labels
  the snapshot carries.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the operator's D-3 and the
  group-snapshot step; decision Q on #1385; the plan, its surface map, the fit review, CR-2 and R2 on
  #1369; and the Wave-1 working notes this record's build detail moved to, on #1392.
