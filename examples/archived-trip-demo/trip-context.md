---
artifact: trip-context.md
schema-version: 1
trip: archived-trip-demo
writer: block-owned
lifecycle: persist-mutable
provenance: human
publish: bound
---

# Trip Context — Bruges October 2025 (Illustrative Example)

**Lifecycle:** ARCHIVED

> **Illustrative, sanitized example. Not a real trip.** Placeholder people, a
> placeholder destination, illustrative dates, and no real bookings.

**This is the archived-trip fixture, and it is the only one in the repository.** No
other example carries a `**Lifecycle:**` marker at all, so before it there was no
archived trip for any assertion to run against. It exists to make two halves of one
rule observable at the same time: an ordinary person-record edit leaves this trip
untouched, and an erasure reaches it. `CLAUDE.md` § *Archived trips — what the freeze
binds* is the rule; `scripts/test-artifact-schema.sh` group `AF` is the assertion.

**The frontmatter `lifecycle:` field above is a different axis from the marker line,
and the two appear in this file on purpose.** `lifecycle: persist-mutable` is the
**artifact** lifecycle class — one of the five tokens
`reference/data-architecture.md` § *Lifecycle Classes* declares — and it says how this
file is rewritten across passes. `**Lifecycle:** ARCHIVED` is the **trip** lifecycle
marker, which `G4` reads and `G7` disposes of. They share a word and nothing else.
Writing `ARCHIVED` into the frontmatter field would fail that field's enum, and this
fixture is the first artifact in the repository where both axes are visible together.

## Mode

**Current mode:** ITERATION

**Mode notes:** The trip ran and is over. The mode records where planning stopped, not
where the trip is now — the marker line above is what says the trip is concluded.
Evidence for ITERATION: a full synthesis had run and the group had asked for one
change before the trip began.

## Destination

- **Primary destination:** Bruges, Belgium
- **Secondary destinations:** None
- **Neighborhood base:** [Illustrative — near the Markt]

## Logistics

- **Primary traveler:** Dana
- **Confirmation code(s):** [Illustrative example — no real bookings]

### Outbound
- **Leg 1:** Origin -> BRU
- **Date:** October 9, 2025 (Thu)
- **Notes:** Illustrative example. One group booking; all three travelers are on it.

### Return
- **Leg 1:** BRU -> Origin
- **Date:** October 12, 2025 (Sun)
- **Notes:** Illustrative example. Late-afternoon flight.

## Accommodation

- **Property name:** [Illustrative — canal-side guesthouse]
- **Booking status:** Concluded
- **Address:** [Illustrative]
- **Check-in time:** 3:00 PM
- **Check-out time:** 11:00 AM

### Transit Access [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

### Walkable Proximity [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Group

| Traveler | Profile |
|----------|---------|
| Dana | `travelers/dana.md` |
| per-4f1c | `travelers/per-4f1c.md` |
| per-9a3e | — no profile filed; needs are operator-provided |

- **Total travelers:** 3
- **Travel mode:** Group moves together
- **Subgroup notes:** None — single origin, one booking, one window.

**The roster is the name authority, which is why erasure has to reach this table.**
`agents/00-enrichment.md` § *Traveler identity* makes this `Traveler` cell the
authoritative display name and calls the model's `## <Name>` heading and the stem of
`travelers/<file>.md` **projections** of it. A name left standing here is therefore not
a leftover: on the first pass after `/trip-decommission reopen` the party is
re-enumerated from this table, and the name would return **by instruction**. That is
the whole reason an erasure that cleaned only the derived model would un-erase itself.

## Hard Constraints

The **constraint source of truth**. A per-traveler need links here through its
`Applies to:` line; it never restates the constraint text.

- **HC-1 — No stair-heavy routing on any day.** Lifts, ramps or level approaches only
  where a venue is reached on foot. *Applies to:* per-4f1c.
- **HC-2 — Any block over two hours carries a named seated rest stop.** *Applies to:* per-9a3e.

## Dietary & Health

- **DH-1 — No shellfish at any group meal.** *Applies to:* Dana.

## Soft Preferences

- Short days; the group was not trying to see everything.

## Trip Style

- Three travelers, one small city, low intensity.

## Budget Posture

- **Overall tier:** [Not exercised by this example]
- **Meals:** [Not exercised by this example]
- **Experiences:** [Not exercised by this example]

## Locked Elements

> Operator-maintained trip-level summary. `outputs/event-status.md` is the structured
> source of truth for the scheduler, hub and validator.

[Not exercised by this example.] **Deliberately empty, and the reason is a finding rather
than a convenience.** A trip that names locked elements, has reached synthesis, and
carries no `outputs/event-status.md` is selected by this suite's seed-trigger arm as a
trip with an outstanding **seed write** — an enrichment-agent write. On an **archived**
trip that obligation must not fire at all: a write is a derivation, and this trip
receives none. The trigger has no lifecycle condition today, so an archived trip with
bullets here would be reported as owing a write the freeze forbids. This fixture stays
out of that population rather than resolving the collision, which belongs to whoever owns
that arm; the observation is recorded here so it is not lost.

## Current Itinerary Status

The trip is over and the site has been taken down. Nothing here changes again unless
`/trip-decommission reopen` returns the marker above to `ACTIVE`.

## Events & Calendar [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Weather Context [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Destination Baseline [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]
