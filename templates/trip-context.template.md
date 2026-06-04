# Trip Context — [DESTINATION] [MONTH] [YEAR]

> Single source of truth for all agents.
> Layer 1 (user-provided) and Layer 2 (derived) fields are completed before
> any agent runs. Fields marked [ENRICH] are completed by the enrichment agent.
> Activity lists, food selections, and itinerary content never appear in this file.

---

## Mode

**Current mode:** [IDEATION / DISCOVERY / ENRICHMENT / ITERATION / RESEQUENCING]

**Mode notes:**
[Context on why this mode is active and what specifically is in scope.
Example: "Flights and hotel confirmed. Planning activities and food only."
Example: "Day 3 afternoon needs to be replaced. Day 3 anchor meal is locked.
All other days are locked."]

---

## Destination

- **Primary destination:** [City, Country]
- **Secondary destinations:** [Day trips, multi-city legs, or "none"]
- **Neighborhood base:** [If known — e.g., "Ginza/Chuo area, Tokyo"]

---

## Logistics

- **Primary traveler:** [Name, home city/state/country]
- **Confirmation code(s):** [Airline / hotel / rail confirmation codes]

### Outbound
- **Leg 1:** [Origin airport code] -> [Connecting airport code]
  - Flight: [#] | Departs: [Day, Date, Time TZ] | Arrives: [Day, Date, Time TZ]
- **Leg 2:** [Connecting airport code] -> [Destination airport code]
  - Flight: [#] | Departs: [Day, Date, Time TZ] | Arrives: [Day, Date, Time TZ]
- **Notes:** [Layover duration, bags, seat class, anything relevant]

### Return
- **Leg 1:** [Destination airport code] -> [Connecting airport code]
  - Flight: [#] | Departs: [Day, Date, Time TZ] | Arrives: [Day, Date, Time TZ]
- **Leg 2:** [Connecting airport code] -> [Origin airport code]
  - Flight: [#] | Departs: [Day, Date, Time TZ] | Arrives: [Day, Date, Time TZ]
- **Notes:** [Anything relevant]

### Effective Planning Days [DERIVED]
> Computed from flight data. Do not manually edit.

- **[Date]:** Arrival day — available from ~[arrival time] local
- **[Date] – [Date]:** Full planning days ([N] days)
- **[Date]:** Departure day — must depart hotel by [time] for [departure time] flight
- **Total:** [N] full days + [N] partial days = [N] effective planning days
- **Timezone delta:** [Origin TZ] to [Destination TZ] = [+/- N hours], [eastbound/westbound]

---

## Accommodation

- **Property name:** [Hotel / aparthotel / rental / hostel]
- **Booking status:** [Confirmed / Under consideration / Not yet booked]
- **Address:** [Full address]
- **Room type:** [Description — sleeps N, bed configuration]
- **Key amenities:** [Kitchenette, laundry, pool — anything that affects planning]
- **Check-in time:** [Time — affects Day 1 window]
- **Check-out time:** [Time — affects final day window]

### Transit Access [ENRICH]
- [Station/stop name] — [X] min walk — [Line name(s)] — connects to [key areas]
- [Station/stop name] — [X] min walk — [Line name(s)] — connects to [key areas]

### Walkable Proximity [ENRICH]
- [Landmark / area — X min walk — relevance to this trip]
- [Landmark / area — X min walk — relevance to this trip]

---

## Group

| Person | Role / Relationship | Key Characteristics |
|--------|---------------------|---------------------|
| [Name] | Primary traveler / planner | |
| [Name] | [Relationship] | [Relevant to planning] |
| [Name] | [Relationship] | [Relevant to planning] |
| [Name] | [Relationship] | [Relevant to planning] |

- **Total travelers:** [N]
- **Travel mode:** [Group moves together / subgroups as noted below]
- **Subgroup notes:** [If any members have independent plans for any portion —
  note which days and which members. Subgroups require parallel itinerary tracks,
  not just "free time."]

---

## Hard Constraints

> Non-negotiable. Every agent treats these as primary design drivers.
> A constraint that is not honored on every applicable day is not being honored.
> The validator audits every day against every constraint.

### [Constraint Name]
- **Description:** [What the constraint is]
- **Applies to:** [Which group member(s)]
- **Practical impact:** [What this means for scheduling and activity selection]
- **Time blocks affected:** [All day / morning / midday / evening / specific days]
- **Mitigation approach:** [How to accommodate — be specific about windows and
  required indoor refuge strategy]
- **Bailout requirement:** [Yes / No — if Yes, every outdoor block >3 hrs needs
  a pre-planned indoor escape for this constraint]

### [Constraint Name]
- **Description:**
- **Applies to:**
- **Practical impact:**
- **Time blocks affected:**
- **Mitigation approach:**
- **Bailout requirement:**

> Add or remove blocks as needed.
> If no hard constraints exist, write "None identified" and confirm before proceeding.

---

## Soft Preferences

> Honor where possible. Can be traded off against hard constraints,
> sequencing logic, or group energy without escalation.

- [Preference — description and why it matters]
- [Preference]
- [Preference]

---

## Trip Style

> Shape the tone and selection of the full itinerary. Be specific.
> "Mix of tourist and local" is too vague. "Landmark versions of the classics
> but genuinely local execution on food and neighborhoods" is useful.

- [Style descriptor]
- [Style descriptor]
- [Style descriptor]

---

## Budget Posture

- **Overall tier:** [Budget / Mid-range / Mid-to-upscale / Luxury / Mixed]
- **Meals:** [Comfort range per person; splurge appetite]
- **Experiences:** [Willingness to pay for premium — be specific]
- **Low-stakes acceptable:** [Convenience stores / food courts / market stalls — yes/no/sometimes]
- **Spend priorities:** [What this group wants to spend on vs. where to stay lean]

---

## Dietary & Health

- **Allergies:** [All known — or "none known; confirm before finalizing food list"]
- **Dietary restrictions:** [Religious, ethical, medical — or "none"]
- **Dietary preferences:** [Adventurous / conservative / specific aversions /
  strong preferences]
- **Mobility notes:** [Any limitation affecting walking distance, stairs, terrain, standing time]
- **Other health notes:** [Anything affecting pacing, environment, or activity type]

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
| [Name] | [Time one way] | [One line] | [TBD / Interested / Confirmed / Ruled out] |

---

## Locked Elements

> Treat as fixed. Agents do not re-litigate these.
> Applies in ENRICHMENT, ITERATION, and RESEQUENCING modes.

- [e.g., "Hotel confirmed — no alternative suggestions needed"]
- [e.g., "Day 4 dinner: [Restaurant name], 7 PM confirmed reservation"]
- [e.g., "Day 2: [Day trip] — tickets purchased"]
- [None — all elements open]

---

## Current Itinerary Status

> Used in ITERATION and RESEQUENCING modes.
> Leave blank in IDEATION or DISCOVERY.

- **Itinerary file:** [outputs/final-itinerary.md / Not yet generated]
- **Current version:** [v1 / v2 / etc.]
- **Locked elements in current plan:** [What cannot be changed]
- **Open for change:** [What can be modified]
- **Specific change requested:** [Precise description — which day, which block,
  what to replace/add/remove, and any constraint that triggered the change]

---

## Validation Requirements

> Specific items the validator must check for this trip.
> Populated after the hub produces the first itinerary draft.
> May also contain known concerns from research phase.

### Known Closure Risks
- [Any venue or venue category known to have irregular hours or closure patterns]
- [Any venue where recent reports suggest hours may have changed]

### Reservation Status to Confirm
- [Any venue marked "reservation required" where availability needs verification]
- [Any venue where the booking window may already be partially or fully closed]

### Price Staleness Flags
- [Any price reference sourced from a guide or source older than 12 months]
- [Any venue category known for frequent price changes at this destination]

### Travel Restriction Checks
- [Any entry requirement that may have changed recently]
- [Any health advisory or safety notice to verify as of travel date]

### Venue Deduplication Watch
- [Any venue appearing in multiple days of the initial draft — flag for review]
- [Any hotel-adjacent venue that may be over-represented as a fallback]

---

## Notes for All Agents

> Behavioral guidance applying to every agent on this trip.
> Read this section last — it is the override and emphasis layer.

- [Any universal instruction]
- [Any assumption requiring validation before proceeding]
- [Any prior research or decisions already established]
- [Common failure mode for this destination or group type to proactively avoid]
- [Agent-specific notes: e.g., "food agent: confirm dietary restrictions before
  generating full list"]
- [Deduplication note: e.g., "Tsukiji and Ginza are hotel-proximity venues —
  cap at 2 appearances each across the full itinerary"]
