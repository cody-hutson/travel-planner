---
artifact: outputs/food-list.md
schema-version: 1
trip: evening-boundary-demo
writer: food
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-09-01
---

# Food List — Naples

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**This file is class C6's declared witness.** Before it, the only tracked
`outputs/food-list.md` in the repository sat inside `examples/tokyo-2026/`, which is a
byte-identical regression witness that is not edited in place — so the class could not
be versioned anywhere and declared `no-witness-because:` instead. This instance removes
that reason. `reference/schemas/food-list.md` records what the flip cost the guard
suite and how the four control arms were kept firing.

**Every section this writer declares is present**, under the writer's own names, per
`agents/02-food.md` § *Output Format*, with a stated *not exercised* where this fixture
has no fact. The three bracketed destination categories are replaced with
destination-accurate ones, as that section directs.

**Labels this fixture has no fact for carry a stated *not exercised***. It ships no
prices, no opening hours, no addresses, no external links and no real bookings.

**Entry marker.** Each entry opens with a fenced `artifact-entry` block carrying the
venue key — and, since `reference/data-architecture.md` § 4.5.1 amended the rule, one
optional `cost:` line — and nothing else. **No marker here carries that line**, because
no prompt emits it yet; each entry's own money line stays the master. Every marker here
reads `venue: unminted` — the hub mints the token at its first enumeration, which runs
after this writer, and this fixture runs no hub.

### Destination Food Overview

Eating here is stratified by format rather than by price: the same quality of ingredient
turns up standing at a counter, sitting on a stool in a lane, and seated under an arcade,
and the three are different meals rather than three tiers of one. Dinner runs late and
the evening service overlaps the drinking hours, which is exactly the overlap that makes
the ownership boundary live — a reader looking at an evening venue here cannot route it
by the hour. Reservation culture is light except for the seated arcade rooms. Proximity
venues to watch: the arcade and the stall lane sit within a few minutes of each other, so
placing both on one day double-counts the same block. For this group the priority is one
seated evening meal and one standing one, which is what the two entries below are.

### Breakfast Options

*Not exercised.* This fixture carries only the evening set.

### Pizzerie

*Not exercised.*

### Pasticcerie

*Not exercised.*

### Cucina di Mare

*Not exercised.*

### Local / Neighborhood Dining

*Not exercised.*

### Specialty & Market Experiences

*Not exercised.*

### Occasion Dinners

#### Galleria dei Fornai — grill taverna under the arcade

```artifact-entry
venue: unminted
```

- **Name** — Galleria dei Fornai, under the arcade at the edge of the historic core
- **Closed:** one weekday, stated in the venue's own posting — *not exercised* here;
  this fixture ships no opening days
- **Price range:** *not exercised* — no prices in this fixture
  [Source date: not applicable — placeholder venue]
- **What to order:** the grill plate that comes to the table rather than to a counter,
  which is the whole reason this is a seated room and not a stall
- **Reservation:** Recommended — the arcade rooms are the one format here that fills
- **Why it's worth it:** it is the evening's seated meal, and it is the entry a nightlife
  reader is most likely to reach for by mistake, because it has a drinks counter and
  stays open into the drinking hours
- **Desires served:** *not exercised* — this fixture ships no traveller model, so no
  desire-overlap signal is available to draw from
- **Indoor / outdoor:** covered arcade; effectively weather-independent
- **Timing note:** the seated service starts later than the stall lane's, so the two are
  sequential rather than interchangeable on one evening
- **Proximity flag:** hotel-neighbourhood venue — appearance cap applies; it and the
  stall lane are on the same block
- **Anchor-meal eligibility:** not convenience-format
- **Honest caveat:** wrong for a group that wants to keep moving; the draw here is
  sitting down

**Why Food and not Nightlife — and what the nightlife list does with it.** Its stated
draw is **a meal**: the food comes to the table, and the counter exists to serve the
room rather than to be the reason to come. So this spoke claims it, and
`outputs/nightlife-list.md` **cross-references it in prose without an entry marker** —
carried once, named twice. A fenced block there would make it a second *entry* for one
venue, which is the duplication `agents/07-nightlife.md` forbids.

**Cantina del Molo is not an entry in this file, on purpose.** The harbour cellar pours
by the glass and plates a little food alongside, so the research for it would ordinarily
land here. Its stated draw is **drinking**, so under the primary-draw rule it is
reassigned to nightlife and `outputs/nightlife-list.md` carries the entry. It is named
here in prose and carries **no `artifact-entry` block**, because a fence would re-create
the duplicate the reassignment exists to avoid. This is the same rule as the paragraph
above, running in the opposite direction.

### Casual / Convenience

#### Vicolo dei Cuoppi — fried-snack stall lane with stools

```artifact-entry
venue: unminted
```

- **Name** — Vicolo dei Cuoppi, a stepped lane one block from the arcade
- **Closed:** *not exercised* — no opening days in this fixture
- **Price range:** *not exercised* — no prices in this fixture
  [Source date: not applicable — placeholder venue]
- **What to order:** the fried cone eaten standing or on a stool, not the sit-down plate
  the same stalls will serve if asked
- **Reservation:** No
- **Why it's worth it:** it is a real meal in a convenience format, which is what makes
  it a Food entry rather than a snack stop — you sit and you eat, and the lane is busy
  because of the food rather than because of the drinking
- **Desires served:** *not exercised* — see above
- **Indoor / outdoor:** open lane; weather-sensitive
- **Timing note:** fills earlier than the seated arcade rooms and empties before the
  drinking hours peak
- **Proximity flag:** hotel-neighbourhood venue — appearance cap applies; shares a block
  with the arcade
- **Anchor-meal eligibility:** anchor-eligible (1 of 2, market-stall)
- **Honest caveat:** wrong for a group that wants to linger; the seating is a stool and
  the lane is loud

**Why Food and not Nightlife.** Its stated draw is **a meal**. The lane is dense and it
is open late, and neither of those is the reason to go — a reader routing on density and
hour would send it to nightlife and would be routing on the wrong signal. The nightlife
list's own alley entry is the contrast: same shape of lane, and the reason to go there is
the drinking.

## What this file does not claim

No entry names an Event ID or another entry's key, and this fixture ships no
`outputs/links-reference.md`, `outputs/venue-matrix.md` or itinerary. Placement is the
hub's act and happens downstream of every writer here.
