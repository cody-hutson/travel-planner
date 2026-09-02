---
artifact: outputs/nightlife-list.md
schema-version: 1
trip: evening-boundary-demo
writer: nightlife
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-09-01
---

# Nightlife List — Naples

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**The desire gate.** This fixture ships no `outputs/traveler-model.md`, so the gate has
no signal to read and this file states its resolution rather than leaving it to be
inferred: it is authored as though the gate resolved **FULL**, because the fixture's
purpose is the ownership boundary and a gate-result stub would demonstrate nothing about
it. The entry count here is therefore **not** the FULL minimum — depth is out of frame,
and the two entries below are the two the 2 Activities / 2 Food / 2 Nightlife split
allots to this spoke.

**Every section this writer declares is present**, under the writer's own names, per
`agents/07-nightlife.md` § *Output Format*, with a stated *not exercised* where this
fixture has no fact. The bracketed destination category is replaced with a
destination-accurate one, as that section directs.

**Labels this fixture has no fact for carry a stated *not exercised***. It ships no
prices, no opening hours, no addresses, no external links and no real bookings.

**Entry marker.** Each entry opens with a fenced `artifact-entry` block carrying the
venue key — and, since `reference/data-architecture.md` § 4.5.1 amended the rule, one
optional `cost:` line — and nothing else. **No marker here carries that line**, because
no prompt emits it yet; each entry's own money line stays the master, and this fixture
declares that label without exercising it. Every marker
here reads `venue: unminted` — the hub mints the token at its first enumeration, which
runs after this writer, and this fixture runs no hub.

### Destination Nightlife Overview

The night here is geographic rather than scheduled: two zones, one in the historic core
and one at the harbour, running late and filling at different hours, with almost nothing
between them. There is no club economy to speak of at the scale a larger city has, so
the useful distinction on the ground is between a lane you walk and a room you sit in.
The operative point for this fixture is that both zones hold venues of all three evening
draws on the same block, which is why the ownership question is answered on the venue
rather than on the neighbourhood or the hour. Proximity venues to cap: the harbour
cellar and the arcade are within a few minutes of each other.

### Cocktail & Wine Bars

#### Cantina del Molo — harbour cellar, poured by the glass

```artifact-entry
venue: unminted
```

- **Name** — Cantina del Molo, harbour edge, a few minutes from the arcade
- **Nights & hours:** *not exercised* — this fixture ships no opening hours
- **Night type:** low-key drink
- **Next-morning cost:** an evening rather than a late night; it costs the next start
  nothing
- **Price range:** *not exercised* — no prices in this fixture
  [Source date: not applicable — placeholder venue]
- **Entry:** walk-in
- **Why it's worth it:** it is the one entry here that plates food, which is exactly why
  it is the entry that tests the boundary rather than the one that avoids it
- **Group fit:** suits a subgroup that wants to sit and talk; not the group's whole
  evening
- **Dry-friendly:** a non-drinking traveller has a real reason to be here — the food is
  a reason to come rather than permission to attend
- **Desires served:** *not exercised* — this fixture ships no traveller model, so no
  desire-overlap signal is available to draw from
- **Constraint note:** cellar room, so stairs down and no step-free route
- **Getting home:** *not exercised* — no transit research in this fixture
- **Proximity flag:** hotel-neighbourhood venue — appearance cap applies
- **Honest caveat:** wrong for a group that wants a meal; the plates here are
  accompaniment and a reader who read them as dinner would leave hungry

**This entry is a reassignment, and it is the first of this fixture's two cross-spoke
conditions.** A cellar that pours by the glass *and* plates food is research the food
spoke would ordinarily file — and `outputs/food-list.md` says so, in prose, with **no
`artifact-entry` block**. Its stated draw is **drinking**, so under the primary-draw
rule this spoke claims it and carries the only fenced entry for it. Carried once, named
twice, in the direction Food → Nightlife.

**Galleria dei Fornai is not an entry in this file, on purpose — the same rule running
the other way.** The arcade grill taverna has a drinks counter and stays open into the
drinking hours, so a nightlife reader is likely to reach for it. Its stated draw is **a
meal**: the food comes to the table. `outputs/food-list.md` carries the fenced entry;
this is a **cross-reference in prose and carries no `artifact-entry` block**, because a
fence here would make it a second entry for one venue, which is the duplication the rule
forbids. That is the whole difference between *cross-referenced* and *duplicated*, and
it is the difference a reader can see in this file rather than one asserted about it.

### Alley Micro-Bars

#### Vico delle Lanterne — stepped lane of two-table bars

```artifact-entry
venue: unminted
```

- **Name** — Vico delle Lanterne, historic core, a stepped lane off the main street
- **Nights & hours:** *not exercised* — no opening hours in this fixture
- **Night type:** big night out
- **Next-morning cost:** a late end; it costs the following morning
- **Price range:** *not exercised* — no prices in this fixture
  [Source date: not applicable — placeholder venue]
- **Entry:** walk-in, one room at a time; no door policy
- **Why it's worth it:** the draw is the lane rather than any one room — about forty
  two-table bars, almost no food, and the point is moving between them
- **Group fit:** a subgroup activity; a group of more than four cannot sit together
  anywhere on the lane
- **Dry-friendly:** thin — a non-drinking traveller can walk the lane but has no reason
  to stop, and `### Non-Drinking & Dry-Traveler Options` is where they would go instead
  if this fixture exercised it
- **Desires served:** *not exercised* — see above
- **Constraint note:** stepped and narrow throughout; no step-free route, and loud
- **Getting home:** *not exercised* — no transit research in this fixture
- **Proximity flag:** not a hotel-neighbourhood venue
- **Honest caveat:** wrong before dinner, and wrong for anyone who wants to sit down

**Why Nightlife and not Food.** Its stated draw is **drinking, and the exploration
itself** — almost no food, and the advice a local gives is to come after dinner. It is
the deliberate contrast with the food list's own stall lane: the same physical shape, a
dense stepped lane full of small places open late, and the opposite verdict, because the
verdict is read off the draw and not off the shape.

### Live Music & Performance

*Not exercised.* Note that a scheduled evening performance whose draw is the event
itself belongs to `outputs/activities-list.md` — this section is for rooms whose reason
to exist is the going out. `Teatro di Cortile` in the activities list is the worked case.

### Clubs & Late-Night

*Not exercised.*

### Pubs & Neighbourhood Locals

*Not exercised.*

### Low-Key & Early-Evening

*Not exercised.*

### Non-Drinking & Dry-Traveler Options

*Not exercised* — this fixture ships no traveller model, so it has no dry traveller to
research for. The section is present rather than dropped: it is the alcohol axis, where
a traveller who does not drink goes when the group splits, and it is distinct from
`### Low-Key & Early-Evening`, which is the intensity axis. Both are required sections
and this fixture leaves neither out.

## What this file does not claim

Neither entry names the other's key, and neither names an Event ID. This fixture ships
no `outputs/links-reference.md`, `outputs/venue-matrix.md` or itinerary, so nothing here
is placed on a day. Placement is the hub's act and runs downstream of every writer.
