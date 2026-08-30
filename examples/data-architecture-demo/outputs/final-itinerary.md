---
artifact: outputs/final-itinerary.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: versioned
provenance: derived
publish: bound
generated: 2026-08-29
---

# Final Itinerary — Porto, May 14–17 2026 (v2)

> **Illustrative, sanitized example. Not a real trip.**

**`versioned`:** this file is *replaced* on each synthesis rather than appended, and
the version it replaced is preserved beside it as
`outputs/final-itinerary-v1.md` — an instance of the separate frozen-sibling class
C16. This is v2; v1 is the pass before the Saturday patch.

**`schema-version` is not the itinerary version.** The `1` in the fence is the
*artifact schema's* version; the `v2` in the title and in the version log below is the
*plan's* version. Both are bare integers, which is exactly why they are named apart.

## Why this file carries no Event IDs and no venue keys

**C15 holds no entries of its own.** `reference/data-architecture.md` § 4.5 gives the
entry-bearing set nine classes and the itinerary is not one of them: an event and a
venue named on a day here are **references** to entities another class masters — the
Event by `outputs/event-status.md`, the Venue by `outputs/venue-matrix.md` — and a
reference resolves against the mastering class's key without making the referring
artifact entry-bearing.

**The cost of that is stated by the model rather than repaired by this fixture.** § 4.5
records it in terms: *the join runs one way. From `outputs/event-status.md` or
`outputs/venue-matrix.md` a reader reaches an itinerary day by key; from the itinerary
back, only by display title.* Closing it would mean structuring the most narrative
artifact in the engine, which `reference/adr/ADR-009-data-architecture.md` Decision 3
and the Day-Header Content Contract in `reference/site-layout-spec.md` both rule out —
Decision 3 exists to prevent exactly *the slow migration of prose into fields*, and
holds that every class keeps its H1 and its existing body structure with frontmatter
prepended and nothing existing moved.

**So the day shape below is `agents/05-hub-planner.md` § *File:
outputs/final-itinerary.md*, unaltered.** Anchor, supporting experiences, AC bailout,
alternatives, food anchors, transit notes, nightlife, constraint compliance — prose
and named blocks, no ID column and no key column. A witness that added them would
demonstrate a reverse join the model rules out, and would teach a reader to flatten
the day's editorial content into fields on the artifact where the model most
explicitly forbids it.

---

**ADVANCE BOOKING CHECKLIST**
> Act on this section first. Items have real lead times.

| Item | Venue | Category | Lead Time | How to Book | Deadline | Status |
|------|-------|----------|-----------|-------------|---------|--------|
| Contemporary-art admission | Serralves | Museum entry | days | Timed-entry, in advance | before Fri May 15 | Not yet held |

**One row, and that is the whole list.** It is derived from `outputs/event-status.md`
and never authored here: an event needs booking when it is `planned` **and** requires
one, and exactly one event satisfies that pair. The two held bookings are `locked`, the
market lunch is `firmed`, the Saturday bar is an `option`, and the three anchor meals
are walk-ins — so none of them belongs on a checklist.

---

**TRIP OVERVIEW**

Three travellers, one origin, one booking, four days in Porto from Thursday 14 to
Sunday 17 May 2026. The party is on foot the whole trip and every approach is level or
lift-served, because `HC-1` bounds it. `HC-2` keeps unshaded outdoor blocks out of the
13:00–16:00 window — **no day places one inside it** — and Café Majestic stands as the
named indoor escape on the two days carrying an afternoon outdoor block. `DH-1` puts no shellfish on any group meal, and every day now carries
an anchor meal for it to bind on. One synthesis has run and one patch has been applied;
one booking remains open.

---

**Day 1 — May 14 (Thu) — Thursday — Arrival**
*Energy:* Low | *Zone:* Baixa | *Type:* Arrival, half day
*Theme:* You land at one and the room opens at two, so the afternoon is the whole of
this day. Two places within a short walk, then an early dinner while you are still
awake to enjoy it.

**Anchor**
Livraria Lello — Baixa — 15:00 — ~1 hour — timed entry, already held. Level approach.
Indoor, so the heat window does not reach it. Serves Alex's *good bookshop* wish.

**Supporting Experiences**
Jardins do Palácio de Cristal — 17:00 — ~1h15 — level paths. Outdoor, and placed after
16:00 so it sits clear of the `HC-2` window rather than needing shade inside it.

**AC Bailout** *(activate if needed)*
Café Majestic — indoor, level access — the standing escape if the gardens block is
rained or heated off.

**Alternatives**
*Not exercised on this day.* Ten of the twelve venues in `outputs/venue-matrix.md` are
anchors, and the deduplication rule forbids a venue anchored on one day standing as an
alternative on another; Café Majestic is the bailout and already at the two-appearance
cap. The one venue that could stand here without breaching either rule is Casa do Livro —
already Saturday's alternative — and placing it again would put a **second** venue at the
cap, which `outputs/venue-matrix.md` and `README.md` F8 both state in the singular. So the
section is carried and left unfilled rather than filled by inventing a venue: `README.md`
§ *Depth* licenses a thin section and never a missing one. **Named by display title and
not by key**, because this file carries none — see the note above.

**Food Anchors**
- Breakfast: — *(in transit — the party is travelling)*
- Lunch: — *(in transit)*
- Dinner: Tasca do Bairro — 20:00 — walk-in, no reservation to hold — shellfish-free
  plates are the house default, so `DH-1` is honoured without a substitution.

**Transit Notes**
Arrival around 13:00, accommodation from 14:00. Everything on this day is on foot from
the base, which is what makes a 15:00 start realistic on an arrival day.

**Nightlife**
No nightlife tonight — arrival day, and the evening desire both travellers hold is
served on Saturday rather than split across two nights.

**Constraint Compliance**
`HC-1` — both approaches level. `HC-2` — the one outdoor block is at 17:00, outside the
window, and carries a named indoor bailout regardless. `DH-1` — the day's anchor meal
is shellfish-free as served.

---

**Day 2 — May 15 (Fri) — Friday — Bolhão and Serralves**
*Energy:* Medium | *Zone:* Baixa, then west | *Type:* Full day
*Theme:* The market hall is a late-morning thing and the counters are the point — eat
there. The afternoon is indoors and air-conditioned, which is not an accident on the
one day nothing outside is scheduled.

**Anchor**
Serralves — 15:00 — ~2 hours — lift access, indoor. Serves Robin's *contemporary art*
anchor. **This is the one placement still needing a booking.**

**Supporting Experiences**
The market hall is this day's other placement; it is carried under **Food Anchors**
below, where its lunch counters put it. Listing it twice would give one fact two homes.

**AC Bailout** *(activate if needed)*
Not activated — no outdoor block today. Café Majestic remains the standing escape for
the days that have one.

**Alternatives**
*Not exercised on this day* — the same bound as Day 1. Nothing about this day narrows it
further; it is the venue set that runs out, not the day.

**Food Anchors**
- Breakfast: — *(not placed — see the depth note below)*
- Lunch: Mercado do Bolhão — 12:30 — market-hall counters, walk-up, covered, level.
  Group-settled with nothing to book. Also serves Alex's *working food market*
  nice-to-have — one placement, two purposes.
- Dinner: — *(not placed)*

**Transit Notes**
On foot within Baixa in the morning; the museum sits west of the centre and is the only
cross-town move of the trip. No day requires a transfer between blocks.

**Nightlife**
No nightlife tonight — no present desire for this night, and Saturday carries the
evening the group asked for.

**Constraint Compliance**
`HC-1` — covered hall, lift at the museum. `HC-2` — does not reach this day at all;
both placements are indoor or covered, which is why the heat need is graded on two days
rather than four. `DH-1` — the market counters serve the group's lunch shellfish-free.

---

**Day 3 — May 16 (Sat) — Saturday — The Viewpoint, Late**
*Energy:* Medium | *Zone:* Centre | *Type:* Full day, slowed afternoon
*Theme:* This is the day that got its afternoon back. Lunch sits down properly, then
nothing until the light starts to go — and the viewpoint is better at half four than it
was at two anyway.

**Anchor**
Miradouro da Vitória — 16:30 — ~45 minutes — level approach, outdoor. **Re-timed from
14:00 by the patch this version records.**

**Supporting Experiences**
None. Removing the block that followed the viewpoint is what the patch did, and putting
another one back would undo it.

**AC Bailout** *(activate if needed)*
Café Majestic — indoor, level access — the escape for the viewpoint block.

**Alternatives**
*(Pre-researched. Hours and walk times confirmed.)*

| Option | Type | Price | Effort | Walk/Transit | Hours |
|--------|------|-------|--------|-------------|-------|
| Casa do Livro | Indoor bar | Low | Walk-in | — | — |

**Two of the six cells read `—`, and that is a fixture property rather than a plan
property.** The only per-venue operational detail this example ships is the street
address the venue-identity procedure consumes as its rung-2 evidence, on the four
research entries in `outputs/nightlife-list.md` and `outputs/rooftop-sunset-bars.md`;
it carries no opening hours, no walk times and no external links, which `README.md`
§ *Depth* declares and `outputs/links-reference.md` repeats for external URLs. On a
real trip those cells are filled, and `agents/06-validator.md`'s structural-integrity
check flags an alternative listed without them. The `—` is what keeps that visible
instead of inventing hours nobody researched. The **two-axis** requirement is met on
the axes the fixture does carry: Casa do Livro differs from the rooftop on price tier
**and** on effort — a walk-in indoor room against a held table at a view venue.

**Food Anchors**
- Breakfast: — *(not placed)*
- Lunch: Casa de Pasto Central — 13:00 — walk-in, level entrance, indoor. Indoors is
  what lets it sit inside the 13:00–16:00 window without touching `HC-2`, which bounds
  outdoor blocks. Shellfish-free from the menu as written.
- Dinner: — *(not placed — the rooftop below is a drinks placement, not the day's meal)*

**Transit Notes**
Everything is within the centre and on foot. The lift to the rooftop terrace is what
makes that venue reachable under `HC-1`.

**Nightlife**
Base Porto — centre — rooftop drinks at sunset — from 19:30 — lift to the terrace, table
held. The one option that serves the rooftop-sunset desire **both** travellers hold,
which is why it is the anchor of the evening rather than an alternative.
*Next morning:* an early-evening sitting rather than a late one; Sunday's 08:30
breakfast and ~13:00 departure are unaffected.

**A nightlife entry never satisfies the day's anchor-event requirement.** That is
`agents/06-validator.md` § *Structural integrity* in terms, and it is why the viewpoint
above is this day's anchor and the rooftop is not. A day whose only anchor-class
placement is a going-out venue is still missing its anchor.

**Constraint Compliance**
`HC-1` — level approach at the viewpoint, lift at the terrace, level entrance at lunch.
`HC-2` — the viewpoint's move to 16:30 is what takes the day's outdoor block out of the
window; a bailout is named regardless. `DH-1` — the anchor meal is shellfish-free.
Robin's rest need — this is the slow afternoon it asks for.

**Spoke Deviations**
The activities spoke researched the anchor meals on a second pass; the hub placed all
three as offered and changed none of them.

---

**Day 4 — May 17 (Sun) — Sunday — Departure**
*Energy:* Low | *Zone:* Ribeira | *Type:* Departure, half day
*Theme:* A bakery counter, then the river while it is still quiet. Be back at the room
by one — the afternoon belongs to the airport.

**Anchor**
Riverside walk, Ribeira to the bridge — 09:30 — ~1h30 — level, outdoor, morning. Serves
Robin's *walk along the river* wish.

**Supporting Experiences**
None. The window is a morning, and one unhurried thing is what fits in it.

**AC Bailout** *(activate if needed)*
Not activated — the outdoor block is a morning one, hours clear of the `HC-2` window.

**Alternatives**
*Not exercised on this day* — the same bound as Day 1, and a departure morning carrying
one placement has little for an alternative to stand against in any case.

**Food Anchors**
- Breakfast: Padaria São Bento — 08:30 — walk-in, level, indoor. Early enough to leave
  the river walk and the departure intact. No shellfish on the counter at all.
- Lunch: — *(not placed — departure)*
- Dinner: — *(in transit)*

**Transit Notes**
Depart the accommodation by ~13:00 for an afternoon flight. That deadline is what makes
this a usable morning rather than a lost day.

**Nightlife**
No nightlife tonight — the party is travelling.

**Constraint Compliance**
`HC-1` — level throughout. `HC-2` — no outdoor block in the window. `DH-1` — the
counter carries no shellfish.

---

**A note on food depth, stated rather than left to be inferred.** Each day above
carries **one** anchor meal, which is the floor `agents/06-validator.md`
§ *Structural integrity* audits — *no day is missing an anchor event or anchor meal*.
`agents/05-hub-planner.md` § *Output Quality Standards* sets a higher bar for a real
trip — **three food moments a day, at least one requiring no planning** — and this
fixture does not meet it. The difference between a **check** and a **standard** is the
distinction being drawn: the check is what
`outputs/validation-report.md` grades, and the standard is what a full worked example
shows. `examples/tokyo-2026/` is that worked example. This fixture places the floor and
says so, which is what lets its validation report call the plan clean without the check
being decorative.

---

**OPEN DECISIONS**

| Decision | Option A | Option B | Recommended Default | Decide By |
|----------|----------|----------|---------------------|-----------|
| Robin's *hear live fado* nice-to-have is uncovered | Chase a fado room for Saturday, ahead of the rooftop | Accept the uncovered nice-to-have | Option B — every anchor and every wish is covered, and Saturday is the day the group asked to slow | before Sat May 16 |

---

**ITINERARY VERSION LOG**

| Version | Date | Changes |
|---------|------|---------|
| v1 | 2026-08-28 | Initial generation |
| v2 | 2026-08-29 | Saturday afternoon slowed — the viewpoint moved 14:00 → 16:30 and the block after it dropped. One anchor meal added to each day from the activities spoke's second pass. |

---

**Depth note.** The per-venue detail a real itinerary carries — addresses, transit
legs, opening hours, booking windows, insider notes — is **not reproduced here**.
`examples/tokyo-2026/outputs/final-itinerary.md` is the worked example for that, and
this fixture exists for the migrated artifact *shape*. See `README.md` § *Depth*.
