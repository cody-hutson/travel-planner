# Channel and Engagement Model — the registered memberships

**This document registers. It decides nothing and admits nothing.** Two decision records decide
how a traveller is reached and how the engine holds a person over time:
`reference/adr/ADR-026-channel-architecture.md` and
`reference/adr/ADR-025-engagement-model-over-time.md`. Each section below restates one membership
those records decide, names the surface that owns it, and says what holds this copy to that
owner. Every member set here is repeated from an owner: each registration names that owner where
it repeats the members and cites the rule that asks it to, and a row its owner does not carry is
a defect of this document, never an admission.

**A block quotation in this document is a decision record's own words**, and so is each value in
the fence of § 1. Where a record changes them, this document follows in the same change.

## 1. The channel-set

**Owner:** `reference/adr/ADR-026-channel-architecture.md` — § *Decision* 1 for the test,
§ *Decision* 2 for the set, and the amendment in that section that resolves `V-2`. Naming it
here, where its members are repeated, is the admission duty of
`CLAUDE.md` § *Rules over an enumeration*.

**What a channel is.** Each limb is its own item, and is evaluated on its own:

> A surface is a **channel** when all three hold:
>
> - **L1** — a person is on the far side.
> - **L2** — the engine governs the crossing, via a named engine-side act declared in a tracked
>   file.
> - **L3** — the crossing point is **guardable**: a single place where a predicate can be
>   evaluated **before** content crosses.

**A limb that cannot be evaluated is not a limb that holds.** That is an outcome of its own,
beside holding and being determinately false: it refuses a surface as a false limb does, and on a
different ground, which is what a vacancy row records.

> The admission test requires all three limbs to **hold**, and a limb that cannot be evaluated
> does not hold.

**What admits a member, and where.** A surface no row below names is not a member. It becomes
one only as the record says:

> **What admits a fourth member.** All four must hold: **(1)** L1–L3 of § *Decision* 1; **(2)**
> its `audience` and `observers` values declared in the same change; **(3)** its `W-test` and
> `R-test` declared in the same change; **(4)** admission by **amendment to this record or by a
> superseding record** — never by a slice, and never as a side effect of building something.

So the record is the one place a member is added, and its row joins the fence below in the change
that amends or supersedes it. Each member's own limbs, its `audience` and `observers` values and
its tests stand in the record's tables and are not copied here.

```channel-set-register
# id   | field   | value
CH-1   | channel | The published site
CH-2   | channel | The intake surface
CH-3   | channel | The command surface
V-1    | vacancy | approval notice, outbound
V-1    | verdict | DISCHARGED — it crosses on CH-1.
V-1    | ground  | ADR-003 § 3 ships it: "The published site shows a 'change pending / recently updated' state on next open"
V-2    | vacancy | approval return, inbound
V-2    | verdict | resolved: an operator-mediated crossing on CH-3, and no fourth member
V-2    | ground  | L2 fails on the traveller leg
```

Each row is `id | field | value`. A `channel` row names a member. A `vacancy` row names a row of
the set that is typed and is not a member, and it carries a `verdict` and the `ground` that
verdict stands on. A row naming any other field is a broken reading, never a row read past. A
line whose first non-blank character is `#` is a comment.

## 2. The `G8` class

**Owner of the class:** `CLAUDE.md` § *Resolving a trip*, gate `G8`. It fixes what a reading of
this class is and never which readings exist, so it holds no list for this section to repeat.
What is registered here is each reading, with the file that declares it: that file is the
reading's owner, and naming it beside the reading is the admission duty of
`CLAUDE.md` § *Rules over an enumeration*.

```g8-class-register
# reading             | declared in
itinerary-to-build    | skills/trip/SKILL.md
research-to-placement | skills/trip/SKILL.md
plan-to-coverage      | skills/trip-record/SKILL.md
engagement(t)         | reference/adr/ADR-025-engagement-model-over-time.md
```

**A relation** is a freshness relation a command file declares in its own relation table — the
table whose first column is headed *relation*. That table is its owner: a relation is added
there, and its row here follows in the same change. The relations registered above are evaluated
inside `trip.freshness` unless the file that declares one evaluates it outside, as
`skills/trip-record/SKILL.md` does with `plan-to-coverage`. A consumer that evaluates a relation
outside `trip.freshness` says so in its own report, and declares it the same way.

**`engagement(t)`** is a reading a decision record types into the class, and that record is its
owner:

> `engagement(t)` is **`G8`-class**: evaluated **after** resolution, **report-only**, with
> **consumer-declared membership**. It **never changes `trip.resolution`**, **no gate may be
> added that blocks on it**, it is **not graded by `G7`**, and it **may not enter the resolution
> contract's return as a new field without arguing for one** — which this record does not do.

Its evaluator is the enrichment agent and its carrier is the derived traveller model. No command
file declares a reading of it, and registering it here asks none to. **No gate is bound to it:**
no requirement table and no relation table names it. A further reading enters the class only
where a decision record types it, and its row here follows in the same change.

## 3. The freshness verdicts, and the staleness that reuses them

**Owner:** `skills/trip/SKILL.md` § *The freshness report*. A verdict is added there, and that
section says so. Naming it here, where its list is repeated, is the admission duty of
`CLAUDE.md` § *Rules over an enumeration*.

`reference/adr/ADR-025-engagement-model-over-time.md` § *Decision* 6 decides that staleness in
the engagement layer mints no verdicts of its own.
Staleness takes its verdicts from that family (`CURRENT`, `BEHIND`, `UNDETERMINED`) and from
nowhere else, compared as the owner compares them and with every declared relation rendered.
That group is a registered repeat: `reference/data-architecture.md` § *The enumeration register*
holds it to the owner in both directions, and says what that check cannot see.
When the owner gains or loses a verdict, that check fails on this group, and the failure asks a
question the group cannot answer by following: the record decided this reuse verbatim, so a
record decides whether staleness takes the changed family before a token is written into the
group or taken out of it.

The boundary staleness respects is the owner's too, and the record adopts it in these words:

> **And the shipped family's declared boundary is adopted rather than worked around.**
> `trip.freshness` is a property of *the resolved trip's own artifacts*: it *"carries no
> publication state and asserts nothing about whether anything is published."* So **a relation
> whose derived side is *what a traveller was shown* is OUTSIDE that boundary** — what a traveller
> was shown is what **crossed a channel**.

## 4. The names

Each name below was introduced or adopted by one of the two records, which measured it against
the corpus before adopting it. The figures, their instrument and their baseline stand in
`reference/adr/ADR-026-channel-architecture.md` § *Decision* 6 and
`reference/adr/ADR-025-engagement-model-over-time.md` § *Decision* 7 and are cited, never copied;
what is carried here is the collision each name was measured against. Each record also lists the
candidates it withdrew, which are not to be minted again. The freshness verdicts of § 3 are
reused by those records and minted by neither.

| Name | What it names | Decided in | The collision it was measured against |
|---|---|---|---|
| `channel` | a surface on which every limb of § 1 holds | `ADR-026` § 1 | the word's other shipped senses — an internal record stream, an egress surface, a human-carried path — kept apart by the limbs and not by a rename |
| `channel-set` | the members and vacancy rows of § 1 | `ADR-026` § 2 | the verb in *the channel sets*, in `ADR-010` |
| `vacancy` | a row of the set that is typed and is not a member | `ADR-026` § 2 | none found |
| `audience` · `observers` | the axes of a channel's envelope: who can read the content, and who can see the bytes | `ADR-026` § 3 | *the three audiences it has* in `CHANGELOG.md`, a different subject; *different observers* in `ADR-010`, the same sense |
| `may-carry` | the relation that says whether a value may cross a channel | `ADR-026` § 3 | the ordinary phrase *may carry*; the hyphenated token is the identifier |
| `carry-envelope` | a channel's declared pair of `audience` and `observers` | `ADR-026` § 3 | none found |
| `W-rule` · `R-rule` · `W-test` · `R-test` | the authorship rule, the emission rule, and a channel's observable test for each | `ADR-026` § 5 | none found |
| `direct-crossing` | adopted and measured; no sentence of the record defines it | `ADR-026` § 6 | none found |
| `phase-axis-declaration` | the fence in which each record declares the axis tokens | `ADR-026` § 4, `ADR-025` § 1 | none found |
| `engagement` | the axis: on what basis the engine holds a person, and who authored it | `ADR-025` § 1, `ADR-026` § 6 | the milestone name *Group approval engagement layer* in `ADR-010`, the same domain, and the verb *engage*; `ADR-026` also writes *the engagement record* for `ADR-025` itself, and `ADR-046` writes *engagement record* for the identifiers and counts that come back beside a profile, a record it says is neither `engagement(t)` nor `ADR-025` itself |
| `engagement(t)` | the axis read for one member of its domain | `ADR-025` § 1 | the bare name above |
| `PERSON-LINKED` · `SELF-STATED` · `OPERATOR-STATED` · `THIRD-PARTY-STATED` · `UNSOURCED` · `ENGAGEMENT-UNDETERMINED` | the values of the axis | `ADR-025` § 1 | *what the operator stated*, quoted by two records for the same state; the shipped `UNDETERMINED`, the same sense; the rest none found |
| `NO-SUBJECT-KIND` | the fence literal beside the value that has no subject kind | `ADR-025` § 1 | none found |
| `EB-0` · `EB-1` · `EB-2` · `EB-3` | the phase boundaries | `ADR-025` § 3 | none found; the bare codes they replaced collided with other subjects and were withdrawn |
| `depth-floor` | a consumer-declared floor on how many fields a person has answered | `ADR-025` § 5 | none found |
| *the profile-gap denominator* | the domain of the axis | `ADR-025` § 2 | adopted as a citation of the phrase `agents/00-enrichment.md` already uses, not minted |

## 5. What holds this document, and what does not

**The two fences are read on every push.** `scripts/test-artifact-schema.sh` reads them and holds
no copy of a row. For § 1 it reads the owning record where it stands — the limb list, the set
table, the paragraph that says what admits a member, and the tables that declare what that
paragraph requires — and fails when the record's set and the fence differ in either direction;
when a limb is on one side only, the limbs here being read from this document's first block
quotation as the record's are from its own; when the paragraph that says what admits a member
does not stand whole in a block quotation here; when a `channel` here lacks a declaration that
paragraph names, or an id the record declares a test for is not a `channel` here; when a `vacancy`
lacks its `verdict` or its `ground`; when a value of the fence is not in the words of the owning
record; and when a block quotation in this document is not in the words of a decision
record, or does not end where a sentence ends. A decision record, for that comparison, is a file
under `reference/adr/` whose name opens `ADR-`. For § 2 it reads every relation table, and every
record's sentence typing a reading into the class — a paragraph at a time, however the sentence
is wrapped — and fails when a relation or a typed reading has no row, when a row has no subject,
and when a cell of a requirement table or of a relation table carries a typed reading's own
token. § 3's group is held by the enumeration register.

**When a reading cannot be made.** That is a failure of the instrument: it is reported as one,
once for the section it belongs to, it withholds every comparison of that section, and it never
passes. A fence that is absent or holds no row, an id that is not exactly one of `channel` and
`vacancy`, a record in which the limb list, the set table or the paragraph that says what admits
a member cannot be found, a tree in which no relation table is read, and a tree in which no
record types a reading into the class are examples; the test is whether the reading could be made.

**What none of that can see.** A green suite is not evidence about any of these.

- **Everything this document says in its own words** — the names table, and each sentence around
  a quotation or a fence. Nothing compares them with their owners.
- **A surface that is never proposed.** A slice that builds something a person is on the far side
  of, and edits neither the record nor this document, is read by nothing here.
- **Words a record keeps and no longer decides.** `reference/adr/README.md` § *Convention* keeps
  superseded text as decided, has an amendment's account quote the wording it replaced, and
  keeps every rejected option with its reason. All of that is in a record's words, so all of it
  passes: a vacancy row put back to the cell its own amendment superseded reads green, and so
  does a superseded sentence added here as a quotation.
- **Where in the record a value stands, and whether a row is true.** A value of the fence passes
  wherever in the owning record its words occur — under another id, or in an option the record
  rejected — so the suite does not hold that a ground is the ground of its own row, and never
  what it means.
- **A quotation that is absent, or shorter than what the record says.** The limb list and the
  paragraph that says what admits a member must be here, and that paragraph whole. Any other
  quotation can be removed, or cut at the end of any sentence, with the suite green. A quotation is
  read where its lines open at the left margin: one that is indented or stands inside a list item,
  and a line that continues one without a marker, are not read. The end of a sentence is read as its
  last character, so a cut after a full stop inside a token passes.
- **A relation declared outside a relation table,** and a reading typed into the class in other
  words than the record's own.
- **A gate the suite does not read.** The gate comparison looks for a typed reading's own token
  in the cells of requirement tables and relation tables. It does not read the gate ladder of
  `CLAUDE.md` § *Resolving a trip*, a table of any other shape, or the axis's bare name. A value
  of the axis spelled on a stored-value surface is read by the never-carry group of the same
  suite, and the approval gate's independence of the axis by `scripts/test-publish-guard.sh`; a
  gate that names neither is unread.
