---
artifact: trip-context.md
schema-version: 1
trip: single-origin-demo
writer: block-owned
lifecycle: persist-mutable
provenance: human
publish: bound
---

# Trip Context — Seville June 2026 (Illustrative Example)

> **Illustrative, sanitized example. Not a real trip.** Placeholder people, a
> placeholder destination, illustrative dates, and no real bookings.
> This example demonstrates **one thing**: the **single-origin collapse** in
> `### Per-Traveler Planning Days [DERIVED]` — the per-traveler table deleted and
> replaced by the `- **All travelers:**` line carrying its warrant census, which is
> what `templates/trip-context.template.md` requires when every traveler's Window
> basis *and* Origin basis is `ASSERTED-SAME` or `UNKNOWN`. Only `## Mode`,
> `## Destination`, `## Logistics` and `## Group` are filled — every `[ENRICH]`
> section is left at its template placeholders on purpose, because no enrichment
> agent has run on this example.
> See [`README.md`](README.md) for the raw traveler inputs this is derived from.

---

## Mode

**Current mode:** ENRICHMENT

**Mode notes:**
Group booking confirmed. This example exists to demonstrate the collapsed form of
the per-traveler planning-days derivation only — no activity, food, or itinerary
content is generated here.

---

## Destination

- **Primary destination:** Seville, Spain
- **Secondary destinations:** None
- **Neighborhood base:** [Illustrative — Santa Cruz]

---

## Logistics

- **Primary traveler:** Mira
- **Confirmation code(s):** [Illustrative example — no real bookings]

> `### Additional origins` is absent rather than empty. One origin is the default
> shape, and the Outbound/Return legs below are it — the block exists only where a
> second origin does.

### Outbound
- **Leg 1:** DEN -> SVQ
  - Flight: [illustrative] | Departs: Wed, Jun 10, 4:35 PM MDT | Arrives: Thu, Jun 11, 1:50 PM CEST
- **Notes:** Illustrative example. One group booking; all three travelers are on it.

### Return
- **Leg 1:** SVQ -> DEN
  - Flight: [illustrative] | Departs: Mon, Jun 15, 10:05 AM CEST | Arrives: Mon, Jun 15, 4:40 PM MDT
- **Notes:** Must depart hotel by ~7:30 AM.

### Effective Planning Days [DERIVED]

> Derived block. Not manually edited — see `CLAUDE.md` § *Write ownership*.
> **Scope: the whole group.** The anchor origin is the only origin and no traveler
> holds a window of their own, so this block is a group-wide guarantee on this trip.
> That is a property of *this* trip, not of the block: on a multi-origin trip the
> same block describes the anchor origin alone.

- **Jun 11 (Thu):** Arrival day — available from ~3:00 PM local (after hotel check-in)
- **Jun 12 (Fri) – Jun 14 (Sun):** Full planning days (3 days)
- **Jun 15 (Mon):** Departure day — must depart hotel by ~7:30 AM for 10:05 AM flight
- **Total:** 3 full days + 2 partial days = 5 effective planning days
- **Timezone delta:** MDT (UTC-6) to CEST (UTC+2) = +8 hours, eastbound

### Per-Traveler Planning Days [DERIVED]

> Derived block. Not manually edited — see `CLAUDE.md` § *Write ownership*.
> **Last derived:** Jun 1, 2026 — from the traveler profiles as of that date

- **All travelers:** trip-level window applies — no traveler states a different arrival, departure, or origin. 2 asserted, 1 assumed.

> **Reading this.** The per-traveler table is **absent, not omitted.** Every
> traveler's Window basis and Origin basis is `ASSERTED-SAME` or `UNKNOWN`, which is
> the collapse precondition in `templates/trip-context.template.md`: under it the
> group has one window and one origin, the table is deleted, and the trip-level
> `### Effective Planning Days [DERIVED]` block above becomes everyone's window.
> A table here would carry three rows that repeat that block three times.
>
> **The census is the warrant, and it is the reason the line is not just "everyone".**
> `2 asserted` — Mira and Ravi each said they are on whatever the group books.
> `1 assumed` — Tess answered neither field, so Tess *inherits* the trip-level window
> rather than having agreed to it, and anything derived from it is an assumption. The
> two are not interchangeable, and collapsing the table is not allowed to lose the
> difference: the counts survive the deletion so a reader still knows how much of this
> window was asserted and how much was inferred.
>
> **What would break the collapse.** A traveler who *named* an origin — even this
> trip's own DEN — would classify `ASSERTED-DIFFERENT` and **pin** it, the
> precondition would fail, and the full table would return. Nobody here named one, so
> every basis **tracks**: rebook this group out of another city and all three move
> with it. See `examples/two-origin-demo/` for the uncollapsed form, and
> `examples/data-architecture-demo/` for a party that meets this precondition and
> renders the table anyway, on purpose, to show the basis values the collapse hides.

---

## Accommodation

- **Property name:** [Illustrative — central guesthouse]
- **Booking status:** Confirmed
- **Address:** [Illustrative]
- **Room type:** [Illustrative — sleeps 3]
- **Key amenities:** [Illustrative]
- **Check-in time:** 3:00 PM — sets the arrival-day window above
- **Check-out time:** 11:00 AM — hotel departure by ~7:30 AM on the return flight day

### Transit Access [ENRICH]
- [Station/stop name] — [X] min walk — [Line name(s)] — connects to [key areas]
- [Station/stop name] — [X] min walk — [Line name(s)] — connects to [key areas]

### Walkable Proximity [ENRICH]
- [Landmark / area — X min walk — relevance to this trip]
- [Landmark / area — X min walk — relevance to this trip]

---

## Group

> Roster only. Each traveler's needs and desires live in their own file at
> `trips/<destination>-<year>/travelers/<traveler>.md` (human-authored, one per
> traveler) — not in this table. The enrichment agent reconciles those files
> into `outputs/traveler-model.md`. See `reference/data-model.md` for the model.

| Person | Role / Relationship | Traveler file |
|--------|---------------------|---------------|
| Mira | Primary traveler / planner | `travelers/mira.md` |
| Ravi | Friend — on the group booking | `travelers/ravi.md` |
| Tess | Friend — profile not yet answered | `travelers/tess.md` |

- **Total travelers:** 3
- **Travel mode:** Group moves together
- **Subgroup notes:** None — one origin, one booking, one window. Tess's timing is
  unconfirmed; treat Tess's presence on any day as an assumption until that profile
  is answered.

---

## Hard Constraints

> Non-negotiable. Every agent treats these as primary design drivers.
> A constraint that is not honored on every applicable day is not being honored.
> The validator audits every day against every constraint.
> This section is the trip-level constraint source of truth: per-traveler needs
> in `travelers/<traveler>.md` *link* here via "Applies to" — they never copy
> the constraint text. One source per fact (see `reference/data-model.md`).

None identified — this example demonstrates the single-origin collapse rendering only.

---

## Soft Preferences

> Honor where possible. Can be traded off against hard constraints,
> sequencing logic, or group energy without escalation.

- [Not exercised by this example]

---

## Trip Style

> Shape the tone and selection of the full itinerary. Be specific.

- [Not exercised by this example]

---

## Budget Posture

- **Overall tier:** [Not exercised by this example]
- **Meals:** [Not exercised by this example]
- **Experiences:** [Not exercised by this example]
- **Low-stakes acceptable:** [Not exercised by this example]
- **Spend priorities:** [Not exercised by this example]

---

## Dietary & Health

> Trip-level dietary/health constraint source of truth. Per-traveler dietary and
> health *needs* in `travelers/<traveler>.md` link here via "Applies to" rather
> than duplicating these entries. One source per fact (see `reference/data-model.md`).

- **Allergies:** [Not exercised by this example]
- **Dietary restrictions:** [Not exercised by this example]
- **Dietary preferences:** [Not exercised by this example]
- **Mobility notes:** [Not exercised by this example]
- **Other health notes:** [Not exercised by this example]

---

## Weather Context [ENRICH]

- **Season at destination during travel dates:**
- **Average high / low:** [F and C]
- **Humidity:** [%]
- **Precipitation pattern:** [Frequency, type, typical timing in day]
- **Heat index / feels-like range:** [If relevant]
- **Best outdoor activity windows:** [Specific time ranges]
- **Avoid outdoors:** [Time ranges and reason]
- **Seasonal hazards:** [Typhoon season, monsoon, extreme cold, wildfire smoke, etc.]
- **Specific implication for this group:** [Given hard constraints and composition]

---

## Destination Baseline [ENRICH]

- **Language:** [English prevalence by context: transit / restaurants / markets / taxis / hotels]
- **Currency:** [Name, code, approximate USD rate — rate used for all agent cost estimates]
- **Payment norms:** [Cash vs. card by context — restaurants / markets / transit / taxis]
- **Tipping culture:** [By context — restaurants / taxis / hotels / guides]
- **Key etiquette:** [3-5 specific, actionable notes relevant to this group's activity profile]
- **Visa / entry:** [Requirements for traveler's passport nationality; any current restrictions]
- **Pre-arrival apps:** [5 max — each with one-line rationale specific to this destination]
- **Connectivity:** [SIM / eSIM recommendation; local wifi norms]

---

## Events & Calendar [ENRICH]

- **Public holidays during travel dates:**
  - [Holiday name — date — practical effect: what's closed / crowded / shifted]
  - [Holiday name — date — practical effect]
- **Closure cascade rules:** [Any holidays that shift regular closure days at specific
  venue types — e.g., "If Monday is a holiday, some museums close Tuesday instead"]
- **Festivals or major events:** [Name — dates — opportunity or obstacle or both]
- **Tourism season context:** [Peak / shoulder / off-season — crowd and pricing implications]
- **Known weekly closure patterns:** [By venue category — e.g., "many museums closed Monday"]
- **Seasonal availability:** [What is open, closed, or at peak quality in this month]

---

## Possible Day Trips

| Destination | Approx. transit time | Appeal | Status |
|-------------|---------------------|--------|--------|
| [Not exercised by this example] | | | |

---

## Locked Elements

> Treat as fixed. Agents do not re-litigate these.
> Applies in ENRICHMENT, ITERATION, and RESEQUENCING modes.

- Group booking (DEN -> SVQ, Jun 10 / SVQ -> DEN, Jun 15) confirmed
- No traveler holds independent legs — there is nothing else to lock

---

## Current Itinerary Status

> Used in ITERATION and RESEQUENCING modes.
> Leave blank in IDEATION or DISCOVERY.

- **Itinerary file:** Not yet generated
- **Current version:** —
- **Locked elements in current plan:** —
- **Open for change:** —
- **Specific change requested:** —

---

## Validation Requirements

> Specific items the validator must check for this trip.
> Populated after the hub produces the first itinerary draft.
> May also contain known concerns from research phase.

### Known Closure Risks
- [Not exercised by this example]

### Reservation Status to Confirm
- [Not exercised by this example]

### Price Staleness Flags
- [Not exercised by this example]

### Travel Restriction Checks
- [Not exercised by this example]

### Venue Deduplication Watch
- [Not exercised by this example]

---

## Notes for All Agents

> Behavioral guidance applying to every agent on this trip.
> Read this section last — it is the override and emphasis layer.

- This is an illustrative example for the single-origin collapse rendering.
  No agent output is generated from it.
- Tess's window and origin basis are both `UNKNOWN`. Any finding that Tess is
  present or absent on a given day is an **assumption**, and must be named as one —
  not a fact. The collapsed line says so with its `1 assumed`.
- The collapse is a rendering rule, not a data rule. Nothing here asserts that Tess
  agreed to these dates; it asserts that the trip level is the only window on record.
