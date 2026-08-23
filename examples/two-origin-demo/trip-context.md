# Trip Context — Lisbon April 2026 (Illustrative Example)

> **Illustrative, sanitized example. Not a real trip.** Placeholder people, a
> placeholder destination, illustrative dates, and no real bookings.
> This example demonstrates **one thing**: the `### Per-Traveler Planning Days
> [DERIVED]` derivation on a party with two origins and three different timing
> bases. Only `## Destination`, `## Logistics` and `## Group` are filled —
> every `[ENRICH]` section is left at its template placeholders on purpose,
> because no enrichment agent has run on this example.
> See [`README.md`](README.md) for the raw traveler inputs this is derived from.

---

## Mode

**Current mode:** ENRICHMENT

**Mode notes:**
Flights confirmed for the group booking. This example exists to demonstrate the
per-traveler planning-days derivation only — no activity, food, or itinerary
content is generated here.

---

## Destination

- **Primary destination:** Lisbon, Portugal
- **Secondary destinations:** None
- **Neighborhood base:** [Illustrative — Baixa/Chiado]

---

## Logistics

- **Primary traveler:** Jordan, Austin, TX
- **Confirmation code(s):** [Illustrative example — no real bookings]

### Outbound
- **Leg 1:** AUS -> LIS
  - Flight: [illustrative] | Departs: Wed, Apr 8, 5:40 PM CDT | Arrives: Thu, Apr 9, 10:15 AM WEST
- **Notes:** Illustrative example. The group booking; Jordan is on it.

### Return
- **Leg 1:** LIS -> AUS
  - Flight: [illustrative] | Departs: Wed, Apr 15, 11:20 AM WEST | Arrives: Wed, Apr 15, 4:05 PM CDT
- **Notes:** Must depart hotel by ~8:30 AM.

### Additional origins

> One block per **origin**, never one per traveler. Name travelers by their
> `## Group` roster entry — the name only. Their `Leaving from:`, journey comfort
> and passport stay in `travelers/<traveler>.md` and are never copied here.

#### Origin B — Manchester, United Kingdom (MAN)
- **Departing travelers:** Pat
- **Outbound**
  - **Leg 1:** MAN -> LIS
    - Flight: Not yet booked | Departs: Not yet booked | Arrives: Not yet booked
  - **Notes:** Illustrative example. Pat named this origin, so the trip level
    records it; Pat has not confirmed timing, so it carries no legs yet. That is
    why Pat's Origin basis below is `ASSERTED-DIFFERENT` while their Window basis
    is `UNKNOWN` — the two are independent.
- **Return**
  - **Leg 1:** LIS -> MAN
    - Flight: Not yet booked | Departs: Not yet booked | Arrives: Not yet booked
  - **Notes:** Not yet booked.

> The anchor origin is the unlabelled Outbound/Return pair above and is always
> `Origin A`. Every traveler not named in a block here resolves to it; the
> per-traveler table below says on what basis.

### Effective Planning Days [DERIVED]
> Computed from flight data. Do not manually edit.
> **Scope: the anchor origin (`Origin A`).** On a multi-origin trip this is **not**
> a group-wide guarantee — a traveler on another origin may arrive later or leave
> earlier. Anything that needs to know who is present on a given day must read each
> traveler's own derived window in `### Per-Traveler Planning Days [DERIVED]` below,
> not this block.
> On this trip Pat departs from `Origin B`, so the days listed here describe the
> anchor origin only — they are not Pat's.

- **Apr 9 (Thu):** Arrival day — available from ~1:00 PM local (after hotel check-in)
- **Apr 10 (Fri) – Apr 14 (Tue):** Full planning days (5 days)
- **Apr 15 (Wed):** Departure day — must depart hotel by ~8:30 AM for 11:20 AM flight
- **Total:** 5 full days + 2 partial days = 7 effective planning days
- **Timezone delta:** CDT (UTC-5) to WEST (UTC+1) = +6 hours, eastbound

### Per-Traveler Planning Days [DERIVED]
> Computed per traveler. Do not manually edit.
> Reads each traveler's own profile by link — the `## Group` roster carries the path.
> **Last derived:** Apr 2 — from the traveler profiles as of that date

| Traveler | Window basis | Origin basis | Effective window (local) | Full + partial | Timezone delta |
|----------|--------------|--------------|--------------------------|----------------|----------------|
| Jordan | `ASSERTED-SAME` | `ASSERTED-DIFFERENT` | Apr 9, ~1:00 PM – Apr 15, ~8:30 AM | 5 full + 2 partial | CDT (UTC-5) to WEST (UTC+1) = +6 hrs, eastbound |
| Riley | `UNKNOWN` | `ASSERTED-SAME` | Apr 9, ~1:00 PM – Apr 15, ~8:30 AM *(assumed)* | 5 full + 2 partial *(assumed)* | CDT (UTC-5) to WEST (UTC+1) = +6 hrs, eastbound |
| Pat | `UNKNOWN` | `ASSERTED-DIFFERENT` | Apr 9, ~1:00 PM – Apr 15, ~8:30 AM *(assumed)* | 5 full + 2 partial *(assumed)* | BST (UTC+1) to WEST (UTC+1) = 0 hours, no shift |
| Sam | `ASSERTED-DIFFERENT` | `UNKNOWN` | Apr 8, ~4:00 PM – Apr 12, ~7:00 PM | 3 full + 2 partial | CDT (UTC-5) to WEST (UTC+1) = +6 hrs, eastbound *(assumed)* |

> **Reading this.** Jordan and Pat hold the same window for different reasons: Jordan
> said so, Pat said nothing. Pat's window is marked `(assumed)` and stays open to
> correction — but Pat's **timezone delta is their own**, derived from their trip-level
> origin (`Origin B`) rather than the group's, and across these dates it is **zero**:
> Pat crosses no time zones while the group crosses six. A jet-lag model that gave Pat
> the group's +6 would be wrong on day one, and the old field shape had no way to
> notice. Sam's window is pinned to their own dates and does not move if the group's
> flights change; Sam's timezone delta is `(assumed)` because they never said where
> they set out from.
>
> **Jordan and Riley leave from the same city on different bases.** Jordan *named*
> Austin, so Jordan's Origin basis is `ASSERTED-DIFFERENT` — **pinned**, and it does
> not move if the group rebooks out of somewhere else. Riley said only "whatever the
> group flies out of", so Riley's is `ASSERTED-SAME` — **tracks**, and it would follow
> that rebooking. Same departure city today, opposite behaviour tomorrow: what
> classifies a traveler is what they bound their answer to, never whether two values
> happen to agree. Riley's timezone delta carries no `(assumed)` marker — an
> `ASSERTED-SAME` origin is asserted, not assumed — while Riley's window cells do,
> because Riley's Window basis is `UNKNOWN`.
>
> Whole-group anchors on Apr 8 and Apr 13–15 fall outside at least one traveler's
> window. Naming who is absent is the scheduler's job, not this block's.

---

## Accommodation

- **Property name:** [Illustrative — central aparthotel]
- **Booking status:** Confirmed
- **Address:** [Illustrative]
- **Room type:** [Illustrative — sleeps 4]
- **Key amenities:** [Illustrative]
- **Check-in time:** 1:00 PM — sets the arrival-day window above
- **Check-out time:** 11:00 AM — hotel departure by ~8:30 AM on the return flight day

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
| Jordan | Primary traveler / planner | `travelers/jordan.md` |
| Riley | Friend — on the group booking | `travelers/riley.md` |
| Pat | Friend — joining from a second origin | `travelers/pat.md` |
| Sam | Friend — own dates | `travelers/sam.md` |

- **Total travelers:** 4
- **Travel mode:** Group moves together, with noted exceptions
- **Subgroup notes:** Sam arrives Apr 8 and departs Apr 12 — Apr 8 and Apr 13–15 are
  not whole-group days. Pat's and Riley's timing is unconfirmed; treat their presence
  on any day as an assumption until their profiles are answered.

---

## Hard Constraints

> Non-negotiable. Every agent treats these as primary design drivers.
> A constraint that is not honored on every applicable day is not being honored.
> The validator audits every day against every constraint.
> This section is the trip-level constraint source of truth: per-traveler needs
> in `travelers/<traveler>.md` *link* here via "Applies to" — they never copy
> the constraint text. One source per fact (see `reference/data-model.md`).

None identified — this example demonstrates the planning-days derivation only.

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

- Group booking (AUS -> LIS, Apr 8 / LIS -> AUS, Apr 15) confirmed
- Sam's own dates (Apr 8 arrival, Apr 12 departure) confirmed
- Pat's departure origin (`Origin B` — MAN) confirmed; Pat's legs not yet booked

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

- This is an illustrative example for the per-traveler planning-days derivation.
  No agent output is generated from it.
- Pat's and Riley's timing basis is `UNKNOWN`. Any finding that either of them is
  present or absent on a given day is an **assumption**, and must be named as one —
  not a fact.
- Sam is not present on Apr 8 morning, or on Apr 13, 14, or 15. A whole-group anchor
  on those days is a scheduling error, not a preference.
