---
artifact: outputs/activities-list.md
schema-version: 1
trip: evening-boundary-demo
writer: activities
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-09-01
---

# Activities List — Naples

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**Every section this writer declares is present**, under the writer's own names, per
`agents/01-activities.md` § *Output Format*. This fixture demonstrates the evening
ownership boundary and nothing else, so every section but the two below carries a
stated *not exercised* rather than being left out — depth governs content, never the
section set.

**Labels this fixture has no fact for carry a stated *not exercised*** rather than an
invented value. It ships no prices, no opening hours, no addresses, no external links
and no real bookings.

**Entry marker.** Each entry opens with a fenced `artifact-entry` block carrying the
venue key — and, since `reference/data-architecture.md` § 4.5.1 amended the rule, one
optional `cost:` line — and nothing else. **No marker here carries that line**, because
no prompt emits it yet. Every marker here reads `venue: unminted`: the token is
minted by the hub at its first enumeration of the venue set, which runs after this
writer, and this fixture runs no hub. `unminted` is a **declared absence, never a
default value**.

### Destination Activity Overview

A dense historic core on a bay, walkable end to end, with the evening life concentrated
in two zones rather than spread across the city. The interesting after-dark hours run
late by northern-European standards and the two zones fill at different times, which is
what makes an evening plan here a sequencing problem rather than a selection one. For
this fixture the operative point is narrower: the evening zones hold venues of all three
draws side by side, so the ownership question is live on the same block rather than only
across neighbourhoods. Proximity venues to cap: the waterfront belvedere and the arcade,
which sit within ten minutes of each other and of the group's assumed base.

### Landmark / Tourist Must-Dos

*Not exercised.* This fixture carries only the evening set; daytime research is out of
frame.

### Local Neighborhood Experiences

*Not exercised.*

### Unusual / Off-Tourist-Track

*Not exercised.*

### Indoor / Climate-Appropriate Options

*Not exercised.*

### Evening & Mixed-Group Options

> Non-nightlife evening experiences only — sunset viewpoints, evening tours, night
> markets as sights, family-friendly shows and performances. Going-out venues (bars,
> clubs, live-music rooms, pubs, late-night lounges) belong to the nightlife agent.
> **Cross-reference, never duplicate.**

**Two entries, and they are two because rule 3 has two limbs.** `agents/07-nightlife.md`
hands this spoke *a sight, a view, **or** a scheduled event that happens to occur after
dark*. Belvedere del Faro is the first; Teatro di Cortile is the second. A fixture
carrying only one of them would still read as 2 Activities while leaving half the rule
undemonstrated.

#### Belvedere del Faro — waterfront belvedere, seen after dark

```artifact-entry
venue: unminted
```

- **Name** — Belvedere del Faro, harbour edge, a short walk from the arcade
- **Best time:** after full dark, when the harbour lighting is on
- **Duration:** under an hour, standing; longer if the group sits
- **Why it's worth it:** the reason to come is the view itself — nothing is served here
  and nothing is scheduled, so the draw survives the venue being empty
- **Group fit:** works across the whole energy range; it is the one evening stop a
  traveller with no interest in going out can join without joining a night out
- **Desires served:** *not exercised* — this fixture ships no traveller model, so no
  desire-overlap signal is available to draw from
- **Constraint note:** open air and unlit underfoot at the approach; step-free along the
  seaward path
- **Bailout option:** *not exercised* — no indoor-escape research in this fixture
- **Reservation / timing:** No
- **Proximity cap note:** hotel-neighbourhood venue — flagged; it and the arcade are the
  two capped in the overview
- **Honest caveat:** wrong for a group that wants the evening to *do* something; this is
  a stop, not an event

**Why Activities and not Nightlife.** Its stated draw is **a sight**. Nothing is poured
and nothing is staged; a reader who moved it to `outputs/nightlife-list.md` would be
routing on the hour rather than on the draw, which is the error the boundary exists to
prevent.

#### Teatro di Cortile — open-courtyard evening performance

```artifact-entry
venue: unminted
```

- **Name** — Teatro di Cortile, historic core, inside a courtyard off the main lane
- **Best time:** the scheduled sitting; one per evening
- **Duration:** the length of the performance plus the walk in and out
- **Why it's worth it:** it is the only entry on this list with a fixed start time, which
  is what makes it an anchor the hub can build an evening around rather than a stop it
  can slot anywhere
- **Group fit:** seated and low-effort; suits the whole group including anyone who does
  not drink, which is what distinguishes it from the two nightlife entries
- **Desires served:** *not exercised* — see above
- **Constraint note:** open courtyard, so weather-sensitive; seating is fixed and the
  approach is cobbled
- **Bailout option:** *not exercised*
- **Reservation / timing:** Recommended — a scheduled sitting, so the timing is the
  constraint rather than the booking
- **Proximity cap note:** not a hotel-neighbourhood venue
- **Honest caveat:** wrong on a night the group wants to keep loose; a fixed start time
  spends the evening's flexibility

**Why Activities and not Nightlife.** Its stated draw is **a scheduled event that
happens to occur after dark**. There is a bar in the courtyard and it is not the reason
to go — a venue is claimed by its primary draw, not by the facilities it happens to
carry.

### Day Trip Options

*Not exercised.*

### Pre-Planned Bailout Options

*Not exercised.*

## What this file does not claim

Neither entry names the other's key, and neither names an Event ID. Which of these the
hub places, on which day and at which status is the hub's act, and this fixture ships no
hub artifacts at all. A research list that narrated its own placements would be asserting
a decision it does not make.
