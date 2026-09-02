---
artifact: outputs/event-status.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: persist-mutable
provenance: recorded
publish: bound
generated: 2026-08-29
---

# Event Status

> **Illustrative, sanitized example. Not a real trip.**

The structured per-event source of truth for the scheduler, hub and validator.
**`persist-mutable`** — updated in place, survives every re-synthesis, never rebuilt
from scratch and never versioned. A re-synthesis *reads* this file; it does not
overwrite it.

**Entry marker: a declared key column.** C13 is table-shaped, so `Event ID` is the
marker — the form the model cites this very file as the precedent for.

**The venue column is named `Venue`, and the name is not cosmetic.** That is the
spelling `reference/data-model.md` § *The Per-Event Status Model* gives the table and
the spelling `agents/05-hub-planner.md` uses when it instructs *the table's `Venue`
column holds the venue's `ven-<token>`* and when it calls an empty cell an error. A
witness that renamed the column would put a second name on one field, and the model,
the emitter and the instance would then disagree about what a reader is looking for.
The column is a **foreign** key beside `Event ID`, read from the venue registry; the
entity this file keys is the Event, not the venue.

**Event ID is opaque and day-independent.** The hub mints it on first placement and it
is the cross-run join key, so it must not encode the day — which is exactly what lets
the Saturday patch below move an event without minting a new identity.

**`Time` is a column here, and `evt-c052` is the row that shows why.** The Saturday patch
changed that event's time and nothing else — same day, same venue, same role, same status.
Held in `Notes` as prose the way this table once held it, that shift is invisible to
anything that compares fields, and `outputs/change-summary.md` compares fields by
construction: it is derived from keys and forbidden to diff the itinerary's prose. So the
one cell that moved would have moved unwitnessed, and a re-bake whose only change was that
move would have published in silence. As a column it is `16:30` beside `May 16 (Sat)`, and
the difference is one MOVED row. The value is a 24-hour local **start** time; a duration or
a window stays in `Notes`, and an event the plan leaves deliberately untimed reads `—`.
Model: `reference/data-model.md` → *`Time` is a column, not a note*.

**Every `Time` cell above is the time the day body of `outputs/final-itinerary.md` places
that event at** — 15:00 for the timed entry, 17:00 for the Thursday garden placed clear of
the `HC-2` window, 09:30 for the Sunday walk ahead of the ~13:00 departure. That agreement
is a coupling this fixture now carries and a reader can check: the itinerary is the prose
render, this table is the structured record, and a time that disagreed between them would
have the change summary describe a shift the published plan does not show. `evt-9e34` is
the one row reading `—`, and that is the declared-absence case rather than a gap: it is the
Saturday `option`, never placed in a primary slot, so the plan gives it no time to hold. An
untimed event's placement renders **without** a time in `outputs/change-summary.md` — a
`—` there would read as a missing value rather than as a deliberate one.

**"Needs booking" is derived, not stored:** `planned` **and** `requires booking? =
yes`. `firmed`, `locked` and `option` therefore never read as needing a booking, even
when an `option` carries `requires booking? = yes` as a bookable backup — that flag
takes effect only on promotion to `planned`.

| Event ID | Venue | Event | Day | Time | Status | Requires booking? | Needs booking (derived) | Notes |
|----------|-------|-------|-----|------|--------|-------------------|-------------------------|-------|
| `evt-3f9a` | `ven-7b2e` | Livraria Lello timed entry | May 14 (Thu) | 15:00 | `locked` | yes | no — booked | Timed entry held |
| `evt-8c21` | `ven-c41a` | Jardins do Palácio de Cristal | May 14 (Thu) | 17:00 | `planned` | no | no | Outdoor; `ven-b5e0` is its bailout |
| `evt-7a05` | `ven-3c17` | Tasca do Bairro — dinner | May 14 (Thu) | 20:00 | `planned` | no | no | Thursday's anchor meal; walk-in |
| `evt-1d60` | `ven-2f68` | Mercado do Bolhão — market-hall lunch | May 15 (Fri) | 12:30 | `firmed` | no | no | Friday's anchor meal; group-settled, nothing to book |
| `evt-b47e` | `ven-93d7` | Serralves — contemporary art | May 15 (Fri) | 15:00 | `planned` | yes | **yes** | The one open booking |
| `evt-6e2b` | `ven-a90d` | Casa de Pasto Central — lunch | May 16 (Sat) | 13:00 | `planned` | no | no | Saturday's anchor meal; walk-in |
| `evt-c052` | `ven-e05b` | Miradouro da Vitória | May 16 (Sat) | 16:30 | `planned` | no | no | Re-timed by the Saturday patch (14:00 → 16:30); same ID |
| `evt-5ab8` | `ven-8a34` | Base Porto — rooftop at sunset | May 16 (Sat) | 19:30 | `locked` | yes | no — booked | Table held; covers two desire rows |
| `evt-9e34` | `ven-1d9f` | Casa do Livro — bar | May 16 (Sat) | — | `option` | yes | no — an alternative, never a primary slot | Backup for `evt-5ab8`; alternative pool |
| `evt-d1c8` | `ven-5e6b` | Padaria São Bento — breakfast | May 17 (Sun) | 08:30 | `planned` | no | no | Sunday's anchor meal; walk-in |
| `evt-2f77` | `ven-6c72` | Riverside walk, Ribeira to the bridge | May 17 (Sun) | 09:30 | `planned` | no | no | Ahead of the ~13:00 departure |

**The derived column is a truth table, and every one of the eleven rows is checkable
against it.** Only `evt-b47e` is `planned` **and** `requires booking? = yes`, so only it
reads **yes**. `evt-9e34` is the row that makes the rule visible rather than merely
satisfied: it carries `requires booking? = yes` and still reads **no**, because an
`option` is not a primary slot.

**`evt-9e34`'s note references its primary by ID**, not by a day-coded name — so when a
resequence moves either event to another day, the join key and the cross-reference
both still hold. That is the same property the ID's day-independence buys, read from
the `Notes` column.

**All four status values are present**, which is the point of the table: `planned` is
the only one iteration and resequencing change freely, `locked` and `firmed` are
preserved unless the user names them, and `option` is never auto-promoted.

**One `planned` needs-booking event remains** (`evt-b47e`), so "all events locked" is
false for this trip. That is the reading the phrase is defined by, and a fixture in
which nothing remained to book could not demonstrate it. **The three anchor meals are
all walk-ins**, so adding them changed the booking surface not at all — which is the
hub's own standard that at least one food moment a day requires no planning, seen in
the one column that would have moved if it did not hold.

**Every `Venue` value above resolves to exactly one row in
`outputs/links-reference.md`**, the venue registry. `ven-b5e0` (Café Majestic) appears
in the registry and *not* here, which is correct: it is the standing bailout and is
never placed, so it has no event. An itinerary element that names no navigable venue
is not an event at all, so an empty `Venue` cell would be an error rather than a
declared absence.

## What the Saturday patch did

The change recorded in `trip-context.md` § *Mode notes* moved the Saturday afternoon
later to make it slower. `evt-c052` kept its ID **and its venue key** across that move —
the ID is day-independent, so a re-timing is not a re-identification. **Exactly one cell
changed**: `Time`, from `14:00` to `16:30`. The `Day` is the same, the `Venue` is the same,
the `Status` is still `planned`, and the venue matrix still places `ven-e05b` as Saturday's
`A`. That is what makes this row the fixture's proof rather than its decoration — every
other field a keyed difference could compare is unchanged, so if `Time` were not compared
the pass would read as a no-op and `outputs/change-summary.md` § *2026-08-29* would not
exist. No row was
deleted: row deletion is the single case `persist-mutable` permits, and it applies
only when an event leaves the itinerary altogether.

**Three rows were added on the same pass**, when the spoke re-ran for anchor meals and
the hub placed them: `evt-7a05`, `evt-6e2b` and `evt-d1c8`. Adding a row is an ordinary
`persist-mutable` write — the file is updated in place, and the rows that were already
here kept their IDs, their statuses and their held bookings untouched.
