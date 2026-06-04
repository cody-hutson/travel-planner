# Worked Example — Tokyo July

A sanitized real-trip example showing what a finished planning cycle looks like across all engine artifacts. Use it as a reference for the shape and depth of agent outputs — not as a template to copy.

> Names, origin city, and GitHub URLs have been scrubbed. The destination, hotel, dates, venues, and itinerary structure are real. The group is a fictional 5-person party (Alex, Jordan, Sam, Pat, Riley) with Tokyo-relevant constraints (heat sensitivity, raw fish preferences, mandatory rest windows).

## What's here

| File | Produced by | Purpose |
|---|---|---|
| `trip-context.md` | User (with enrichment agent fill-ins) | Source of truth — destination, group, constraints, locked elements |
| `trip-log.md` | Hub / user (per-session) | Decision register across multiple planning chats |
| `outputs/activities-list.md` | Activities agent | Activity research, organized by neighborhood/theme |
| `outputs/food-list.md` | Food agent | Restaurant research with closure-day notes |
| `outputs/casual-dining-family.md` | Food agent (targeted re-run) | Subgroup-specific food research |
| `outputs/scheduling-framework.md` | Scheduling agent | Day-shape framework + heat-zone logic |
| `outputs/transport-brief.md` | Transport agent | Logistics — IC card, JR pass, ride-shares |
| `outputs/links-reference.md` | Hub | All venue URLs, rebuilt on each synthesis |
| `outputs/final-itinerary.md` | Hub | Synthesized day-by-day itinerary |

## What's NOT here

- **The published HTML site** — the original trip's site is hosted as a standalone GitHub Pages repo independent of this engine. The engine generates a single self-contained HTML file (`outputs/<destination>-travel-site.html` per the publish flow in `CLAUDE.md`) which then gets pushed to its own public repo per trip. Including the rendered HTML in the engine repo would double-host and clutter the example.
- **A `validation-report.md`** — not produced for this trip because it was reconstructed from pre-engine artifacts; new trips planned through the full pipeline will have one.
- **Bookings, confirmation codes, real personal details** — scrubbed.

## How to read this example

For someone new to the engine, the recommended reading order:

1. `trip-context.md` — what the trip actually is (group, dates, constraints, locked elements)
2. `outputs/scheduling-framework.md` — the day-shape framework the hub used
3. `outputs/final-itinerary.md` — the synthesized output the user actually carries on the trip
4. `outputs/activities-list.md` and `outputs/food-list.md` — the depth of research backing the itinerary
5. `trip-log.md` — how decisions evolved across sessions

The artifacts demonstrate the contract between agents: `trip-context.md` is sacred (only enrichment writes), spoke outputs accumulate (never overwrite), and the hub assembles `final-itinerary.md` from all spoke artifacts after the validator passes.

## Constraints showcased in this example

This trip exercises a useful spread of the engine's hard-constraint patterns:

- **Extreme heat / heat-sensitive traveler** → triggers mandatory indoor refuge 11 AM – 5 PM and bailout requirements for every outdoor block
- **Mandatory rest windows** (Days 1–3 jet lag recovery) → schedule shape constraint
- **Dietary preferences** (raw fish caution) → restaurant filter applied across all food research
- **Group splits** (5 travelers split into 2 + 3 on Days 6–7) → parallel itinerary tracks required
- **National holiday closure cascade** (Marine Day shifting Monday-closed venues to Tuesday) → venue-day validation
- **Hotel-proximity venue dedup cap** (max 2 appearances of Tsukiji / Ginza across the full itinerary) → venue-matrix enforcement

If you're planning a trip with different constraints, the patterns transfer: name the constraint in `trip-context.md` under "Hard Constraints," the spoke agents enforce it in their research, and the hub + validator audit compliance.
