---
artifact: outputs/activities-list.md
schema-version: 1
trip: data-architecture-demo
writer: activities
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Activities List — Porto

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**Depth: tier 2 — the migrated-shape minimum.** `examples/tokyo-2026/outputs/activities-list.md`
is the worked example for this class's *content*: the full field-label surface per
entry lives in `agents/01-activities.md` § *Output Format* and is not reproduced here.
What **is** reproduced exactly is the migrated **shape** — the file-scoped frontmatter
above, the per-entry `artifact-entry` marker below, and the accumulation across two
dated sections. See `README.md` § *Depth*.

**Entry marker.** C5 is prose-shaped, so each entry carries a fenced `artifact-entry`
block holding the entity key **and — since § 4.5.1 amended the rule — one optional
`cost:` line, and nothing else**, directly under that entry's own heading. Display
name, access, shade and booking posture stay in the entry's prose, where the
frontmatter/body test already puts them: this class's frontmatter is file-scoped, so
an entry-level value has no field to become. The key does, and so does that one
optional line. **Every marker in this file now carries both**, because
`agents/01-activities.md` emits the cost field and this class declares
`**Entry cost:**` as its money label — the label
`reference/adr/ADR-018-cost-estimation-method.md` § *Decision 9* adds, and the one this
class went without while its prompt already mandated researching a price.

**Seven of the ten carry a value and three declare `undetermined`, which is what makes
this fixture's estimate a partial reading rather than a complete or an empty one.** The
three are the anchor-meal entries in § *Targeted Update* below, and their reason is
stated on each: an anchor meal has no admission, so a writer looking for an *entry cost*
finds nothing normalizable. `undetermined` is the honest answer there rather than `free`,
which would be literally true of the door and would hide the meal. **`free` is a value
and it is used here**, on the entries that genuinely have no admission — it contributes
`cost: 0 EUR per-person` and counts toward `priced-items`.

**The synthetic prices are the § *Depth* narrowing landing.** `README.md` § *Depth* reads
*no **sourced** prices — synthetic currency values only, where a class's own rule cannot
be exercised without one*, and this class's rule cannot be exercised without one.

## The marker transition — what the two sections below depict

**This file is the fixture's witness for the mint window, and it is why it carries
two dated sections rather than one.** `reference/data-architecture.md` § 3.3 fixes
the mint point at **the hub's first enumeration of the venue set, before it writes
either reference file** — and the research spokes run *before* the hub. So a spoke's
entry cannot carry a key on the pass that writes it. Every marker is born
`venue: unminted`, and **the spoke resolves its own marker, in place and one-way, on
its next pass**: `unminted → ven-<token>`.

Read the two sections against that rule and the whole mechanism is visible at once:

| Section | Written on | Marker state now | Why |
|---|---|---|---|
| *Initial Research (2026-08-28)* | pass 1 | `ven-<token>` | Born `unminted`. The spoke re-ran on pass 2 and resolved each of these markers in place. |
| *Targeted Update — anchor meals (2026-08-29)* | pass 2 | `venue: unminted` | Written before the hub's pass-2 enumeration. These resolve on the spoke's **next** pass, which has not run. |

**Only the marker's value moved.** Every heading, labelled line and word of the
pass-1 prose below stands exactly as pass 1 wrote it. `reference/data-architecture.md`
§ 7.6 is what makes that binding rather than stylistic: an `accumulate-append` class
upgrades its frontmatter block in place, and **body entries are never rewritten**,
because rewriting accumulated history to satisfy a schema would destroy the record
the lifecycle exists to keep. Resolving a marker is the same act performed at entry
scope, by the file's single writer — so one writer per file is preserved and the
append guarantee is untouched.

**`unminted` is a converging state, not an instantaneous one — and it is a recorded
disposition, not a defect.** Resolution is one pass late by construction. On a
single-pass trip that never re-runs a spoke it never converges at all, and the marker
stays `unminted` permanently; `outputs/rooftop-sunset-bars.md` carries that permanent
case for its own reason. The three entries in the second section below are the
*converging* case: the hub has already minted their keys and placed them — they carry
a row in `outputs/links-reference.md`, `outputs/venue-matrix.md` and
`outputs/event-status.md` — while their markers here still read `unminted`.

**The key is a convergence optimisation and never the join basis.** That the hub
could place three venues whose research markers carry no key is the demonstration:
the hub joined those mentions to those places by the **five-rung identity procedure**
it runs at every mint (`agents/05-hub-planner.md` § *Step 1 — links-reference.md*),
not by reading a token off this file. A fixture in which every marker were already
minted would show the endpoint and conceal the mechanism — and would teach a state
the engine cannot reach on a first pass.

## Initial Research (2026-08-28)

### Livraria Lello

```artifact-entry
venue: ven-7b2e
cost: 8 EUR per-person
```

- **Entry cost:** €8 / ~$9 per person
  [Source date: synthetic — this fixture carries no sourced price]

Booking: advance. Access: level — clears `HC-1`. Indoor, so `HC-2` does not reach it.
Serves Alex's *good bookshop* wish.

### Jardins do Palácio de Cristal

```artifact-entry
venue: ven-c41a
cost: 0 EUR per-person
```

- **Entry cost:** free
  [Source date: synthetic — this fixture carries no sourced price]

Booking: open. Access: level paths — clears `HC-1`. Outdoor, so its placement has to
clear the `HC-2` window; Café Majestic is the named indoor bailout within reach.

**`free` is a value, not an absence** — it emits `cost: 0 EUR per-person` and counts
toward `priced-items`. An entry the spoke could not price would carry
`cost: undetermined` instead, and the two are read differently.

### Serralves

```artifact-entry
venue: ven-93d7
cost: 20 EUR per-person
```

- **Entry cost:** €20–24 / ~$22–26 per person — general admission at the lower figure,
  the combined ticket at the higher
  [Source date: synthetic — this fixture carries no sourced price]

Booking: advance, **not yet held** — this is the one needs-booking event left open.
Access: lift. Indoor. Serves Robin's *contemporary art* anchor.

**This entry's floor and ceiling differ, and it is not the only one on this trip that
does** — `ven-8a34` in `outputs/nightlife-list.md` and `outputs/rooftop-sunset-bars.md`
carries a range as well, and `outputs/cost-estimate.md` splits the spread between the
pair. The marker carries the **low bound** — § 4.5.1 fixes `amount` that way,
which is what makes a sum over markers a true floor by construction — and the range's
upper value stays in the prose line above, where `outputs/cost-estimate.md` reads it for
the ceiling. Neither file asserts that the two agree, and nothing fails if they do not.

### Mercado do Bolhão

```artifact-entry
venue: ven-2f68
cost: 0 EUR per-person
```

- **Entry cost:** free — the hall is open to walk into. What a counter costs is a meal
  price, which is C6's `**Price:**` master and not this label
  [Source date: synthetic — this fixture carries no sourced price]

Booking: walk-up. Access: level. Covered. Serves Alex's *working food market*
nice-to-have, and the hall's own counters make it a usable anchor meal rather than a
sight alone.

### Miradouro da Vitória

```artifact-entry
venue: ven-e05b
cost: 0 EUR per-person
```

- **Entry cost:** free
  [Source date: synthetic — this fixture carries no sourced price]

Booking: open. Access: level approach. Outdoor, so its placement has to clear the
`HC-2` window.

### Ribeira riverside

```artifact-entry
venue: ven-6c72
cost: 0 EUR per-person
```

- **Entry cost:** free
  [Source date: synthetic — this fixture carries no sourced price]

Booking: open. Access: level. Outdoor, morning. Serves Robin's *walk along the river*
wish.

### Café Majestic

```artifact-entry
venue: ven-b5e0
cost: 0 EUR per-person
```

- **Entry cost:** free
  [Source date: synthetic — this fixture carries no sourced price]

Booking: walk-up. Access: level. Indoor. **Proposed as a standing bailout rather than
as an anchor** — the AC escape for both outdoor blocks, which is the
*Pre-Planned Bailout Options* role this class carries.

**This entry is priced and is charged to nobody**, which is the difference between the
two coverage readings the estimate carries. It counts toward `priced-items` because that
pair measures the **entry population** — what the corpus made machine-readable — and it
is outside every traveller's `P of Q` because that pair measures a **placement**, and
`outputs/event-status.md` records in terms that this venue is never placed and has no
event.

**No entry above names another venue's key, and that is deliberate.** A research
entry holds exactly one key — its own, in its marker — and speaks of every other
venue by display name, because a display name is what a spoke has. The keyed
relationships between venues live in `outputs/venue-matrix.md` and
`outputs/links-reference.md`, which the hub writes.

## Targeted Update — anchor meals for each day (2026-08-29)

Appended, not overwritten: nothing above is deleted or rewritten, because the hub
reads the whole accumulated file and earlier entries stay useful as alternatives and
as the record of what was already considered.

**Why this re-run happened, and why it landed here.** `agents/06-validator.md`
§ *What You Audit* → *Structural integrity* checks that **no day is missing an anchor
event or anchor meal**, and the first pass placed no meal on any day. The spoke was
re-run to research one anchor meal per day. **These are activities entries because
this fixture ships no `outputs/food-list.md`** — C6 is absent on purpose, for a reason
`README.md` § *What is absent, and why* states — so the food venues this trip needs
land in the research class the fixture does carry. That is a property of the fixture,
not of the engine: on a real trip these entries are the food agent's, in C6.

Every entry here is a walk-in, so none of them changes the needs-booking set.

### Tasca do Bairro

```artifact-entry
venue: unminted
cost: undetermined
```

- **Entry cost:** [Not exercised — a tavern has no admission, and what this meal costs
  is a `**Price:**` figure belonging to C6, which this fixture does not carry]

Booking: walk-up — no reservation to hold. Access: street level — clears `HC-1`.
Indoor. A neighbourhood tavern for Thursday's anchor meal, a short walk from the
gardens block. Shellfish-free plates are the house default rather than a request, so
`DH-1` is honoured without a substitution.

### Casa de Pasto Central

```artifact-entry
venue: unminted
cost: undetermined
```

- **Entry cost:** [Not exercised — as above, a dining room's money value is a
  `**Price:**` figure and not an entry cost]

Booking: walk-up. Access: level entrance — clears `HC-1`. Indoor, which is what lets
it sit inside the 13:00–16:00 window without touching `HC-2` — the constraint bounds
**outdoor** blocks. Saturday's anchor meal, before the slowed afternoon rather than
inside it. `DH-1` is honoured from the menu as written.

### Padaria São Bento

```artifact-entry
venue: unminted
cost: undetermined
```

- **Entry cost:** [Not exercised — as above, a bakery counter's money value is a
  `**Price:**` figure and not an entry cost]

Booking: walk-up. Access: level. Indoor. A bakery counter for Sunday's anchor meal,
early enough to leave the riverside walk and the ~13:00 departure intact. No shellfish
on the counter at all, so `DH-1` is trivially honoured.

**These three markers carry a `cost:` line and an `unminted` key at once, and both are
declared absences of different kinds.** `venue: unminted` says *this venue exists and its
token has not been minted into this marker yet*; `cost: undetermined` says *this writer
looked for a money value and found nothing normalizable*. Neither is a default and
neither is the other. What would be wrong is a marker with **no** `cost:` line at all —
from this release that shape means *this writer does not yet emit cost*, which is no
longer true of any entry in this file.

---

**Every minted key above resolves to a row in `outputs/links-reference.md`**, which is
the venue registry. A key here with no row there would be a referencing key with
nothing behind it. **An `unminted` marker is not such a key** — it names no token, so
it makes no claim the registry has to answer. The three venues it stands on *do* have
registry rows, minted by the hub at its pass-2 enumeration; the markers here catch up
on the next pass this spoke runs.
