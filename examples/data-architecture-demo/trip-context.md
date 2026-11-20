---
artifact: trip-context.md
schema-version: 1
trip: data-architecture-demo
writer: block-owned
lifecycle: persist-mutable
provenance: human
publish: bound
---

# Trip Context — Porto May 2026 (Illustrative Example)

> **Illustrative, sanitized example. Not a real trip.** Placeholder people, a
> placeholder destination, illustrative dates, and no real bookings.

This is the **single-origin** companion to `examples/two-origin-demo/`. The whole
party leaves from one place on one booking, so `### Additional origins` is absent
rather than empty — the block exists only where a second origin does.

## Mode

**Current mode:** ITERATION

**Mode notes:** A full synthesis has already run once and produced
`outputs/final-itinerary-v1.md`. The group then asked for one change — a slower
Saturday afternoon — so the hub patched rather than re-planned, and the current
pass is `outputs/final-itinerary.md`. Evidence for ITERATION: a prior frozen
version exists and `outputs/event-status.md` already carries `locked` rows that a
re-plan would have had to preserve.

## Destination

- **Primary destination:** Porto, Portugal
- **Secondary destinations:** None
- **Neighborhood base:** [Illustrative — Baixa]

## Logistics

- **Primary traveler:** Alex
- **Confirmation code(s):** [Illustrative example — no real bookings]

### Outbound
- **Leg 1:** Origin -> OPO
- **Date:** May 14, 2026 (Thu)
- **Notes:** Illustrative example. One group booking; all three travelers are on it.

### Return
- **Leg 1:** OPO -> Origin
- **Date:** May 17, 2026 (Sun)
- **Notes:** Illustrative example. Afternoon flight — depart accommodation by
  ~1:00 PM, which is what leaves Sunday a usable morning.

### Effective Planning Days [DERIVED]

> Derived block. Not manually edited — see `CLAUDE.md` § *Write ownership*.

- **May 14 (Thu):** Arrival day — available from ~2:00 PM local
- **May 15 (Fri) – May 16 (Sat):** Full planning days (2 days)
- **May 17 (Sun):** Departure day — morning available, depart accommodation by ~1:00 PM
- **Total:** 2 full days + 2 partial days = 4 effective planning days

## Accommodation

- **Property name:** [Illustrative — central guesthouse]
- **Booking status:** Confirmed
- **Address:** [Illustrative]
- **Check-in time:** 2:00 PM — sets the arrival-day window above
- **Check-out time:** 11:00 AM

### Transit Access [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

### Walkable Proximity [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Group

| Traveler | Profile |
|----------|---------|
| Alex | `travelers/alex.md` |
| Robin | `travelers/robin.md` |
| Sam | — no profile filed; needs are operator-provided |

- **Total travelers:** 3
- **Travel mode:** Group moves together
- **Subgroup notes:** None — single origin, one booking, one window.

**Sam is the operator-fallback case, and it is here on purpose.** A traveller with no
usable profile is handled by fallback, never as a hard failure and never as *no
constraints*: the enrichment agent reconciles everyone who filed one, takes
operator-provided needs for the gap, and marks them as such in
`outputs/traveler-model.md`. An absent profile means **unknown**. Two travellers with
files and one without is what makes both branches readable in one fixture.

## Hard Constraints

The **constraint source of truth**. A per-traveler need links here through its
`Applies to:` line; it never restates the constraint text.

- **HC-1 — No stair-heavy routing on any day.** Lifts, ramps or level approaches
  only where a venue is reached on foot. *Applies to:* Robin.
- **HC-2 — No outdoor block between 13:00 and 16:00 without shade.** Any block
  that would sit in direct sun in that window is moved, shaded, or given an indoor
  bailout. *Applies to:* Alex.

## Dietary & Health

- **DH-1 — No shellfish at any group meal.** *Applies to:* Alex.

## Soft Preferences

- Slow mornings over early starts.

## Trip Style

- Three travelers, walkable city, low-intensity.

## Budget Posture

- **Overall tier:** mid
- **Meals:** comfortable rather than cheap; no splurge appetite stated
- **Experiences:** one paid museum is expected; everything else free or low

**This block is filled so that `outputs/cost-estimate.md` can exercise the one rule
attached to it, which is a rule of refusal.** `reference/adr/ADR-018-cost-estimation-method.md`
§ *Decision 8* fixes it: Budget Posture is declared **willingness to spend**, not observed
price, so the estimate may render it as a labelled comparison and **never sums it into any
total**. Filling an unreadable item from it would hand the operator their own number back
as an estimate. A fixture that left this block unexercised could not show that refusal
happening.

## Locked Elements

> Operator-maintained trip-level summary. `outputs/event-status.md` is the
> structured source of truth for the scheduler, hub and validator.

- Livraria Lello timed entry is booked for Thu May 14.
- The Base Porto rooftop table is booked for Sat May 16.

## Current Itinerary Status

One patch applied since the first synthesis: Saturday afternoon was slowed, and the
activities spoke re-ran once to research an anchor meal for each day. Eleven events
are placed: two are `locked`, one is `firmed`, one is an `option`, and the rest are
`planned`. One `planned` event still needs a booking.

## Events & Calendar [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Weather Context [ENRICH]

[Not exercised by this example — the enrichment agent owns this block.]

## Destination Baseline [ENRICH]

- **Language:** [Not exercised by this example]
- **Currency:** Euro, EUR — approximately €1 ≈ $1.10. **A synthetic rate for this
  example**, not a researched one; it is the rate used for all agent cost estimates.
- **Payment norms:** card at restaurants, museums and the transit machines; cash usual
  at the market-hall stalls and for small counter orders
- **Tipping culture:** restaurants — rounding up, or about 5–10% for table service;
  taxis — round up; hotels and guides — small notes
- **Key etiquette:** [Not exercised by this example]
- **Visa / entry:** [Not exercised by this example]
- **Pre-arrival apps:** [Not exercised by this example]
- **Connectivity:** [Not exercised by this example]

**Three of these eight are filled and the rest are not, which is the fixture's Depth
rule rather than an uneven edit.** `README.md` § *Depth* narrows the no-prices clause to
*no sourced prices — synthetic currency values only, where a class's own rule cannot be
exercised without one*, and `outputs/cost-estimate.md` cannot exercise its currency rule
without a declared rate, its cash rule without a payment norm, or its tipping allowance
without a tipping line. The other five are read by nothing this fixture demonstrates, so
they stay declared and unexercised. The sibling `[ENRICH]` blocks below stay unexercised
for the same reason: nothing here reads them.
