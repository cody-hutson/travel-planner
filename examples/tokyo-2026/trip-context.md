# Trip Context — Tokyo (Illustrative Example)

> **Illustrative, sanitized example.** This is an end-to-end worked example for the
> travel-planner engine, not a real person's trip. The group are first-name fixtures,
> the origin city is a placeholder, the property name and booking details are
> representative (not a real reservation), and the dates are illustrative. It exists to
> demonstrate the planning method — agent outputs, constraints handling, and synthesis.

---

## Mode

**Current mode:** ENRICHMENT

**Mode notes:**
Flights and hotel confirmed. Full itinerary exists (outputs/final-itinerary.md).
Travel site published at https://<your-github-username>.github.io/tokyo-trip-example/.
Active trip — use ITERATION mode for any changes going forward.

---

## Destination

- **Primary destination:** Tokyo, Japan
- **Secondary destinations:** KEIKOKU Valley glamping (overnight Day 6-7), DisneySea
- **Neighborhood base:** Ginza / Shintomicho area, Chuo-ku

---

## Logistics

- **Primary traveler:** Alex, Chicago, IL
- **Confirmation code(s):** [To be added as bookings are confirmed]

### Outbound
- **Destination:** NRT (Narita International Airport)
  - Arrives: Wednesday, July 15 ~4:00 PM JST
- **Notes:** Flight details TBD. CDT origin.

### Return
- **Destination:** NRT (Narita International Airport)
  - Departs: Wednesday, July 22 ~12:30 PM JST
- **Notes:** Must depart hotel by ~9:00 AM for N'EX to Narita.

### Effective Planning Days [DERIVED]

- **Jul 15 (Wed):** Arrival day — available from ~7:00 PM local (after hotel check-in)
- **Jul 16 (Thu) – Jul 21 (Tue):** Full planning days (6 days)
- **Jul 22 (Wed):** Departure day — must depart hotel by ~9:00 AM
- **Total:** 6 full days + 2 partial days = 8 effective planning days
- **Timezone delta:** CDT (UTC-5) to JST (UTC+9) = +14 hours, eastbound

---

## Accommodation

- **Property name:** Ginza Riverside Residence (illustrative — representative property, not a real booking)
- **Booking status:** Confirmed (illustrative example)
- **Address:** Chuo-ku, Ginza Shintomicho area, Tokyo
- **Room type:** Apartment-style with kitchenette
- **Key amenities:** Kitchenette, laundry
- **Check-in time:** Standard (likely 3:00 PM)
- **Check-out time:** Standard (likely 11:00 AM)

### Transit Access
- Shintomicho Station — 1 min walk — Yurakucho Line — connects to Ikebukuro, Ginza-itchome
- Hatchobori Station — 6 min walk — JR Keiyo Line — connects to Maihama (DisneySea)
- Tsukiji Station — 8 min walk — Hibiya Line — connects to Roppongi, Ebisu
- Ginza Station — 10 min walk — Ginza/Marunouchi/Hibiya Lines — connects to everywhere

### Walkable Proximity
- Tsukiji Outer Market — 10 min walk — primary breakfast/morning destination
- Ginza shopping district — 5 min walk — midday AC refuge, department stores
- Yurakucho Under the Tracks — 6 min walk — arrival night dinner
- Turret Coffee — 5 min walk — morning coffee

---

## Group

| Person | Role / Relationship | Key Characteristics |
|--------|---------------------|---------------------|
| Alex | Primary Planner | invited with partners family to attend; helping plan events; enjoys outdoors, shopping, and food; goes with the flow |
| Jordan | Partner | Goes with the flow; likes to shop; wants to go to pokepark and ghibli museum |
| Sam | Jordan's sister | Does not go solo; stays with Pat + Riley group; wants to go to ghibli museum |
| Pat | Jordan's mother | Heat-sensitive; needs pacing and rest windows; wants to go to disney sea |
| Riley | Jordan's step brother | Easygoing; likes to shop |

- **Total travelers:** 5
- **Travel mode:** Group splits — Alex + Jordan vs. Sam + Pat + Riley
- **Subgroup notes:** Sam always stays with Pat + Riley. Group splits on Day 6 (PokePark vs. spa) and Day 7 (KEIKOKU return vs. city). Parallel tracks required for split days.

---

## Hard Constraints

### Extreme Heat / Heat-Sensitive Traveler
- **Description:** July Tokyo: 88-92F / 32-33C, 75-80% humidity, heat index 95-100F+
- **Applies to:** Pat (primary), entire group (general)
- **Practical impact:** No outdoor activity 11 AM - 5 PM. AC refuge required for all midday blocks.
- **Time blocks affected:** 11:00 AM - 5:00 PM every day
- **Mitigation approach:** Three thermal zones per day: Green (8-11 AM outdoor), Red (11 AM-5 PM indoor required), Amber/Evening (after 5 PM outdoor possible). Tokyo's AC infrastructure (department stores, underground malls, museums) used deliberately.
- **Bailout requirement:** Yes — every outdoor block >3 hrs needs a pre-planned indoor escape

### Mandatory Rest Windows (Days 1-3)
- **Description:** Jet lag recovery requires enforced rest 2:30-5:00 PM on Days 1-3
- **Applies to:** Entire group
- **Practical impact:** Return to hotel for rest. Non-negotiable. This is what keeps the group functional on peak Days 4-5.
- **Time blocks affected:** 2:30-5:00 PM, Days 1-3
- **Mitigation approach:** Schedule around it — morning activities, midday refuge, rest, evening activities

### Raw Fish Sensitivity
- **Description:** Several members of the group aren't huge fans of raw fish, will consume in small amounts but prefere it's not their full mea.
- **Applies to:** Pat, Alex
- **Practical impact:** Every restaurant must have cooked options. Noted in all food recommendations.
- **Time blocks affected:** All meals
- **Mitigation approach:** Restaurants selected for having both raw and cooked menus. Explicitly noted throughout itinerary.

---

## Soft Preferences

- One main event + one main meal per day (pace, not quantity)
- Landmark tourist experiences done well (timing and execution matter more than novelty)
- Local neighborhood exploration over tourist infrastructure
- Convenience store culture embraced (combini runs are part of the experience)
- Group splits handled with parallel itineraries, not "free time"

---

## Trip Style

- Landmark versions of the classics, executed with local timing knowledge
- Food-forward: market mornings, ramen deep dives, izakaya, one peak dining experience
- Theme park days (DisneySea, PokePark/Poke Centers/Pokemon Cafe, Studio Ghibli Museum) balanced with neighborhood wander days
- Shopping: Uniqlo, Soniandsmi, Don Quijote Ginza
- One night outside the city (KEIKOKU glamping) for Alex & Jordan
- Evening culture: yakitori alleys, rooftop bars, neon neighborhoods

---

## Budget Posture

- **Overall tier:** Mid-to-upscale
- **Meals:** Comfortable at 2,000-5,000 JPY/person for most meals; one splurge dinner (Quintessence or equivalent)
- **Experiences:** Willing to pay for premium — Ghibli, DisneySea Premier Access, Shibuya Sky, TeamLab
- **Low-stakes acceptable:** Yes — combini meals, standing ramen, market grazing all welcome
- **Spend priorities:** Experiences and food over shopping. Theme parks get budget priority.

---

## Dietary & Health

- **Allergies:** None known
- **Dietary restrictions:** None
- **Dietary preferences:** Adventurous overall; 1-2 members cautious on raw fish. All venues must have cooked options.
- **Mobility notes:** Pat may need slower pace and shorter walking distances. Rest windows critical.
- **Other health notes:** Heat sensitivity (Pat) — see hard constraints

---

## Weather Context

- **Season:** Peak summer (tsuyu rainy season typically ends early-mid July)
- **Average high / low:** 88-92F / 77-80F (31-33C / 25-27C)
- **Humidity:** 75-80%
- **Heat index / feels-like range:** 95-100F+ (35-38C+)
- **Best outdoor activity windows:** 8:00-11:00 AM and after 6:00 PM
- **Avoid outdoors:** 11:00 AM - 5:00 PM (Red Zone — indoor required)
- **Seasonal hazards:** Extreme heat/humidity; possible late tsuyu rain
- **Specific implication for this group:** Pat cannot be in direct sun during Red Zone. Every day requires AC refuge infrastructure.

---

## Destination Baseline

- **Language:** English excellent on transit signage; bilingual menus in tourist areas; Japanese-only in local neighborhoods, markets, and taxis
- **Currency:** JPY, ~150 JPY per USD
- **Payment norms:** Cash still important at markets, small restaurants, taxis. Cards accepted at department stores, chains, hotels.
- **Tipping culture:** No tipping. Anywhere. Ever.
- **Key etiquette:** Quiet on trains; shoes off where indicated; no eating while walking (markets exempt); onsen rules (wash before entering, tattoo restrictions)
- **Pre-arrival apps:** TDR App (DisneySea), GO (taxi), Google Maps (offline), LINE (queuing), Google Translate (offline Japanese)
- **Connectivity:** eSIM recommended; hotel wifi reliable

---

## Events & Calendar

- **Marine Day (Umi no Hi):** Monday July 20 — national holiday. Affects: some venues shift closure days; theme parks and tourist areas more crowded. This is why DisneySea is scheduled for Friday (Jul 17) instead.
- **Known weekly closure patterns:** Many museums closed Monday (but Marine Day shifts some to Tuesday closure)
- **Closure cascade rules:** Marine Day (Mon Jul 20) may cause some Monday-closed venues to close Tuesday Jul 21 instead
- **Tourism season context:** Peak season. Everything is crowded. Advance booking essential.

---

## Locked Elements

- Hotel confirmed: Ginza Riverside Residence (illustrative)
- Jul 17: DisneySea (full day)
- Jul 18: Ghibli Museum (10 AM) + Shibuya Sky + special dinner
- Jul 19: Asakusa + TeamLab Planets + Sushi Iwa
- Jul 20: PokePark KANTO + group split + KEIKOKU glamping
- Jul 22: Departure by 12:30 PM from NRT

---

## Current Itinerary Status

- **Itinerary file:** outputs/final-itinerary.md
- **Current version:** v1
- **Travel site:** outputs/tokyo-travel-site.html (published at https://<your-github-username>.github.io/tokyo-trip-example/)
- **GitHub repo:** https://github.com/<your-github-username>/tokyo-trip-example
- **Locked elements:** See Locked Elements above
- **Open for change:** Day 2 dinner choice, Day 5 evening options, Day 7 farewell activities, booking confirmations as they come in

---

## Notes for All Agents

- This trip was planned before the multi-agent system existed. All outputs in outputs/ are the original research — treat as initial agent runs.
- Tsukiji and Ginza are hotel-proximity venues — cap at 2 appearances each across the full itinerary.
- Marine Day (Jul 20) closure cascade: verify Tuesday Jul 21 hours for any venues normally closed Monday.
- The group split on Days 6-7 requires parallel itinerary tracks, not "free time."
- All food venues must have cooked options (raw fish sensitivity in group).
