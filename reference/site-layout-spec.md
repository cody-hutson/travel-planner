# Travel Site Design System

> Complete specification extracted from the Tokyo 2026 site. Apply to all future trip sites. Destination-specific elements (colors, landmarks, typography mood) change per trip — structural patterns, component architecture, and responsive behavior are universal.

---

## 1. Typography

### Font Stack
Three Google Fonts, each with a distinct role:

| Font | Role | Usage |
|---|---|---|
| **Display sans** (Tokyo: Bebas Neue) | Headlines, hero title, day names, section numbers | All-caps, tight tracking, large scale. Sets the editorial tone. |
| **Display serif** (Tokyo: DM Serif Display) | Venue names, dates, taglines, meal pick previews | Elegant, readable at medium sizes. The "magazine" voice. |
| **Body sans** (Tokyo: Karla) | Everything else — descriptions, notes, metadata, UI | Clean, neutral, highly readable at small sizes. |

### Type Scale (base 16px)

| Element | Size | Weight | Notes |
|---|---|---|---|
| Hero title | `clamp(7rem, 22vw, 18rem)` | 400 | Display sans. Responsive clamp. |
| Day headline (mobile) | `clamp(2rem, 5vw, 3.2rem)` | 400 | Display sans. |
| Day headline (desktop) | `1.6rem` | 400 | Display sans. Compact hero bar. |
| Venue name (act-card) | `0.95rem` | 400 | Display serif. |
| Venue name (mini-card) | `0.72rem` | 400 | Display serif. |
| Food card name | `0.78rem` | 400 | Display serif. |
| Timeline title | `0.84rem` | 700 | Body sans bold. |
| Timeline note | `0.76rem` | 400 | Body sans. |
| Card description | `0.74rem` | 400 | Body sans. |
| Section header | `0.58rem` | 800 | Body sans. Uppercase, letter-spacing 3px. |
| Tags/pills | `0.52-0.55rem` | 800 | Body sans. Uppercase. |
| Metadata/muted | `0.6-0.66rem` | 400-700 | Body sans. Muted color. |

**Rule:** Never override base font sizes in desktop compact CSS. Space savings come from collapsing containers, not shrinking text.

---

## 2. Color Architecture

### Variable System
Define all colors as CSS custom properties in `:root`. Every trip changes these values:

```css
:root {
  /* ── Destination accent (changes per trip) ── */
  --accent: #BC002D;        /* Primary brand color */
  --accent-deep: #7A001B;   /* Dark variant */

  /* ── Structural (consistent across trips) ── */
  --navy: #0F1117;          /* Dark backgrounds, nav, overlays */
  --navy2: #1a1a2e;         /* Booking section, night cards */
  --gold: #C5973A;          /* Highlights, tips, rules */
  --gold-light: #F2D98B;
  --cream: #FAF8F5;         /* Page background */
  --white: #FFFFFF;         /* Card backgrounds */
  --border: #E4DDD5;        /* Subtle dividers */
  --muted: #8A8078;         /* Secondary text */

  /* ── Semantic (consistent across trips) ── */
  --safe: #2A7D4F;          /* Green — outdoor safe, walk-up, open */
  --caution: #D0692A;       /* Orange — heat caution, book ahead */
  --danger: #BC002D;        /* Red — heat danger, advance booking */

  /* ── Spacing tokens ── */
  --r: 14px;                /* Card border radius */
  --r-sm: 8px;              /* Small element radius */
  --shadow: 0 6px 30px rgba(15,17,23,0.1);
  --shadow-lg: 0 12px 50px rgba(15,17,23,0.15);
}
```

### Opacity Scale for Dark Backgrounds
Used consistently on nav, hero, overview, booking sections:

| Opacity | Usage |
|---|---|
| `0.9` | Active/hover text |
| `0.7` | Primary text on dark |
| `0.45` | Secondary text on dark |
| `0.35` | Tertiary/muted on dark |
| `0.25` | Decorative text, kana |
| `0.15` | Watermark numbers |
| `0.08` | Subtle borders |
| `0.06` | Card borders, dividers |

### Booking Status Colors
Same across all trips:

| Status | Background | Text |
|---|---|---|
| Advance required | `#fdecea` | `var(--danger)` |
| Book ahead | `#fff3e0` | `#C07000` |
| Walk-up | `#f3f9f0` | `var(--safe)` |
| Free/open | `#f0f0f0` | `var(--muted)` |

### Tag Colors
| Tag | Background | Text |
|---|---|---|
| Hot/danger | `#fdecea` | `#BC002D` |
| AC/safe | `#e8f5e9` | `#2A7D4F` |
| Walk | `#e3f2fd` | `#1565C0` |
| Book | `#fff3e0` | `#C07000` |
| Star | `#fffde7` | `#A07800` |
| Free | `#f3e5f5` | `#6A1B9A` |

### Energy Level Colors
Per-day nav pills and overview dots:

| Level | Color | Hex |
|---|---|---|
| Survival | Red | `#BC002D` |
| Fragile | Orange | `#C0652B` |
| Building | Yellow | `#C09000` |
| Peak | Green | `#2A7D4F` |
| Selective | Yellow | `#C09000` |
| Comfort | Orange | `#C0652B` |

---

## 3. Component Catalog

### Hero Section
- Full viewport height (`100svh`) on initial load
- Gradient background: `linear-gradient(160deg, navy 0%, accent-deep 45%, accent 100%)`
- Radial overlay for subtle lighting effect
- Staggered `fadeup` animation on children (0.1s intervals)
- Stats grid: 4 columns, display sans numbers in gold
- "Scroll ↓" bounce animation at bottom

### Overview Dashboard
- Navy background, 4×2 card grid (responsive: 2-col on mobile, 1-col at 480px)
- Each card: date pip (colored dot) + day name (display sans) + highlights + booking action tag
- Watermark day number (display sans, 3.2rem, 5% opacity, z-index:0 behind text)
- Alert strip above grid for next booking deadline
- Cards clickable — navigate to that day

### Sticky Navigation
- Glassmorphism: `backdrop-filter:blur(20px) saturate(180%)` on dark bg at 96% opacity
- Pills with energy-level-colored underline on hover/active
- Desktop: full-width, pills spread evenly, sub-text showing day highlights (1200px+)
- Mobile: horizontal scroll, no scrollbar

### Day Hero Banner
- Unique gradient per day (`.bg-d1` through `.bg-dN`)
- Energy pill + date label + headline + tagline + summary stats
- Large watermark day number (mobile only, desktop hidden)
- Desktop: compact bar (~114px), click to expand tagline
- Mobile: full banner with tagline visible

### Day-Header Content Contract

The Day Hero Banner (above) renders two content elements — a **headline** and a
**tagline**. This contract governs what those two elements *say*. A day header is
the first thing a reader sees on each day's page; it must read as if a travel
editor wrote it, not as if a planning tool generated it. The failure this
prevents: headers that read as AI meta-commentary — narrating the plan, or the
tool that built it, instead of the day itself.

**The two parts**

| Element | What it is | Form | Example |
|---|---|---|---|
| **Headline** | The day's *theme* **or** its *anchor place* — the name of what the day is | A noun phrase, never a sentence. A neighborhood or pairing, a landmark, or a thematic name for the day. No verb-promise, no logistics list, no day-number prefix in the content itself. | `Tsukiji + Ginza` · `DisneySea` · `Arrival` · `A Slow Day, On Purpose` |
| **Tagline** | One editorial line about the day | One sentence, or two short ones. Speaks about the place and the day — its rhythm, its reason, the one thing worth knowing before you start. Concrete and useful; it earns its place. | `Jet lag will wake you at five — use it. The market is a morning thing, and after that the day loosens on purpose.` |

**What "editorial travel voice" means here**

- **Addresses the reader about the destination** — a magazine standfirst, or a
  friend who has been there. Second person or plain declarative.
- **Concrete.** It names a real thing: a time window, a neighborhood, a sensory
  detail, a constraint made human ("your body thinks it's 2 AM").
- **Has a point of view.** It knows *why* the day is shaped this way and says so
  plainly, without hedging.
- **Earns its place.** Delete it and the reader loses orientation — not just a
  flourish. If the line would fit any day of any trip, it is filler; cut it.
- **Present, active energy** where it's natural ("Land, eat, sleep." "Use it.").

**Banned — meta / AI phrasing.** A header must never break the fourth wall
(reveal itself as generated) or narrate the plan instead of the trip. The
following patterns are prohibited in both the headline and the tagline:

| # | Banned pattern | Why it fails | Do not write |
|---|---|---|---|
| B1 | Design / optimization meta-talk | Describes the plan's construction, not the day | "This day is designed to…", "an optimized itinerary", "carefully balanced", "we've structured this day so that…", "strategically scheduled" |
| B2 | Assistant / concierge framing | The voice of a chatbot, not an editor | "Here's your…", "we've curated…", "we've hand-picked…", "get ready to…", "enjoy your…" |
| B3 | Generator self-reference | Reveals the header was machine-made | "AI-generated", "based on your preferences", "tailored to your group", "as requested" |
| B4 | Empty hype with no referent | Travel-brochure filler that states nothing true | "unforgettable", "the perfect day", "a magical experience", "immerse yourself", "hidden gems", "a feast for the senses" |
| B5 | Logistics-as-headline | The schedule already lists the day's mechanics | a headline that em-dash-lists the plan: "Breakfast, then the museum, then dinner — with a rest in between" |
| B6 | Scaffold labels leaking into prose | Emits the template instead of the content | the words "Theme:", "Day type:", or placeholder text like "One honest line about…" appearing in the rendered tagline |

**Voice exemplars.** Each pair is the same day written two ways. The ✗ column is
the failure the contract exists to stop; the tag names the ban rule it trips.

| Day shape | ✗ AI-notes (banned) | ✓ Editorial voice |
|---|---|---|
| Arrival, after a long flight | **Your Optimized Arrival Experience** <br> *This day is thoughtfully designed to ease you into your trip and help you recover from your long flight.* <br> — trips B1 | **Arrival** <br> *You land at four, but your body says it's the middle of the night. Adrenaline carries about ninety minutes — eat something close and sleep before it makes the choice for you.* |
| Market morning, slow afternoon | **A Curated Day of Local Culture & Cuisine** <br> *Get ready to immerse yourself in an unforgettable culinary adventure through the city's most iconic market!* <br> — trips B2, B4 | **Tsukiji + Ginza** <br> *Jet lag will wake you at five — use it. The market is a morning thing; after that the day loosens on purpose, and a cool department-store floor is minutes away when the heat lands.* |
| Full theme-park day | **Maximizing Your Theme-Park Value** <br> *We've strategically structured this high-energy day to optimize your time and make the most of your park experience.* <br> — trips B1, B2 | **DisneySea** <br> *One park, one day, no second act. Be at the gate for rope-drop, ride the headliner first, then let the afternoon heat set the pace.* |
| Peak day with a special dinner | **The Perfect Peak Day** <br> *Immerse yourself in a magical, unforgettable experience showcasing the very best the city has to offer!* <br> — trips B4 | **Ghibli + Shibuya** <br> *The tickets you booked months ago. The morning is slow and green; the night is the dinner you'll still be describing when you're home.* |
| Departure / travel-out day | **Efficient Departure Logistics** <br> *This carefully planned day ensures a smooth, stress-free transition to the airport based on your preferences.* <br> — trips B1, B3 | **Departure** <br> *One last breakfast at the market, then the airport train while the city is still yawning. Pack the night before — morning-you will be grateful.* |
| A deliberate rest day | **A Balanced Recovery Day for Optimal Rest** <br> *Recharge and rejuvenate with this thoughtfully curated day of relaxation and self-care.* <br> — trips B2, B4 | **A Slow Day, On Purpose** <br> *Nothing here is required. A late lunch, the pool, a nap — this is the day that makes the last three possible.* |

**Worked before / after.** A real market-and-neighborhood day (jet-lagged early
wake, market breakfast, no trains, a mandatory afternoon rest, department-store
AC when midday turns hot):

*Before — AI-notes:*

> **Day 2 — Thu, Jul 16 — An Optimized Day of Market Exploration and Neighborhood Immersion**
> *Theme: This day is carefully designed to balance a high-energy morning at the market with a relaxed, curated afternoon, optimized to accommodate the group's rest needs while maximizing cultural exposure.*

The headline is a sentence-shaped mission statement (B1, B5); the tagline
narrates the plan's *design* ("designed to balance", "optimized to", "curated")
rather than the day (B1, B2). Nothing in it could only be true of *this* day.

*After — editorial voice:*

> **Day 2 — Thu, Jul 16 — Tsukiji + Ginza**
> *Theme: Jet lag wakes everyone at five — use it. The market is best before the heat, and the rest of the day slows on purpose: no trains, no far neighborhoods, just a cool floor to duck into when midday turns red.*

The headline names the day (anchor places). The tagline is concrete (five AM,
the heat, no trains), has a point of view (the slow afternoon is deliberate), and
would fit no other day of the trip.

### Day Grid
- **Desktop 1200px+:** `grid-template-columns: 1fr 1.3fr 1fr 0.8fr` (schedule · highlights · food · map)
- **Tablet 769-1200px:** `1fr 1.2fr 1fr` (map goes full-width at bottom)
- **Mobile ≤768px:** single column

### Featured Stop Cards (`.act-card`)
Structure:
```
.act-vis      — Emoji gradient banner (80px mobile, 32px desktop compact, 60px expanded)
.act-body
  .act-links  — Website/Tickets pills (absolute top-right, via JS wrapping); the map link is the standard .map-link, a sibling of this cluster (see Map-Link Component) and exempt from the compact-hide
  .act-kicker — Category · Location (uppercase, muted)
  .card-transit — Mode + time from hotel
  .act-name   — Venue name (display serif)
  .act-desc   — Description (hidden when compact)
  .act-meta   — Duration + cost (hidden when compact)
  .book-status — Booking tier pill
  .act-tip    — Insider tip (gold-bordered box, hidden when compact)
  .act-timing — Best time (muted, hidden when compact)
  .act-group  — Group fit tags (colored pills, hidden when compact)
```
- Desktop: compact by default, click to expand (`card-open` class)
- Mobile: always fully expanded
- Side-by-side: JS wraps in `.act-card-row` (flex-wrap, min-width:180px per card)

### Mini Cards (`.act-mini`)
Compact always. Two-column grid in `.alt-grid`. Structure:
```
.mini-em    — Emoji icon
.mini-body
  .mini-name    — Venue name (plain text; the map link is the sibling .map-link, see Map-Link Component)
  .mini-sub     — Category · Area
  .card-transit — Mode + time
  .mini-note    — Short description
  .book-status  — Booking tier pill
  .mini-links   — Optional extra links (website / booking); the standard .map-link is separate and always present
```

### Food Cards (`.food-card`)
Two-column grid in `.meal-cards`. Structure:
```
.fc-tag     — Option letter (A/B/C, absolute top-right)
.fc-em      — Emoji
.fc-name    — Restaurant name (display serif)
.fc-type    — Cuisine · qualifier (hidden desktop compact)
.fc-desc    — Description (hidden desktop compact)
.fc-foot    — Price + transit
.book-status — Booking tier pill
.fc-links   — Site links (absolute top-right on desktop); the map link is the standard .map-link, adjacent (see Map-Link Component)
```

### Night Cards (`.night-card`)
Dark background (navy). Structure:
```
.nc-em    — Emoji
.nc-name  — Venue name (display serif)
.nc-meta  — Location · details
.nc-desc  — Description (hidden desktop compact)
.nc-links — Standard .map-link (see Map-Link Component)
.nc-who   — Whose night: the subgroup members verbatim, or "whole group"
```

**Placement — the nightlife band (`.night-zone`).** Night Cards render in a nightlife band: a
region of the day body, rendered after the day's primary content region — after the day grid on
an unsplit or partially-split day, and after `.split-day` on a fully-split one, where the day
grid is omitted. The band renders on **every** day whose `final-itinerary.md` carries a
`**Nightlife**` block with content, and it is the unit the viewport-fit collapse priority
already names as "nightlife". On a split night each card's `.nc-who` carries the same verbatim
members string `.track-label` carries above it, so a reader matches a night card to its track
column by identical text.

### Section Toggles
Used for alternative venue sections (coffee, nearby stops, outdoor/indoor):
```html
<div class="sec-toggle" onclick="this.classList.toggle('open')">
  <span class="st-icon">☕</span>
  <span class="st-label">Nearby Coffee</span>
  <span class="st-meta">2 cards</span>
  <span class="st-chev">▾</span>
</div>
<div class="sec-body"><!-- mini-cards here --></div>
```
- CSS: `.sec-body{display:none}` / `.sec-toggle.open+.sec-body{display:block}`
- Desktop: managed by `fitDayToViewport` JS (expand/collapse to fit screen)
- Mobile: always collapsed, click to expand

### Meal Toggles
```html
<div class="meal-toggle" onclick="this.classList.toggle('open')">
  <span class="mt-icon">🌅</span>
  <span class="mt-label">Breakfast</span>
  <span class="mt-pick">Full Market Wander</span>
  <span class="mt-chev">▾</span>
</div>
<div class="meal-cards-wrap"><!-- meal-label + food-cards --></div>
```

### Collapsible Boxes (Desktop)
| Element | Collapsed | Expand | Click handler |
|---|---|---|---|
| `.prep-box` | 28px (header only) | `max-height:500px` | `.prep-open` class |
| `.transport-box` | 40px (header only) | `max-height:200px` | `.prep-open` class |
| `.split-panel .warn-box` | 22px | `max-height:300px` | `.prep-open` class |

### Heat/Weather Strip
Gradient bar showing thermal zones across the day:
- Green (safe outdoor) → Red (indoor required) → Amber (evening possible)
- Desktop: legend hidden for space. Mobile: legend visible.

### Maps
- Leaflet.js with CartoDB light tiles
- Circle markers with icon-specific colors (star: red, food: gold, hotel: navy, etc.)
- Dashed polyline connecting route points
- Alternative venues in blue (`#0EA5E9`)
- Desktop: in grid column 4, flex-stretches to fill height
- Mobile: hidden by default, "View Day Map" trigger button
- Lazy-loaded via IntersectionObserver

### Booking Checklist
- Dark background (navy2)
- Groups sorted by action date with emoji headers
- Each item: checkbox + venue + booking date/time + website link + booking rule
- localStorage persistence per trip (rename key per destination)
- Progress bar with gradient fill
- Desktop: inline section at page bottom (or slide-up overlay on mobile)

**Derives from tracked event status.** The checklist, book-by dates,
"needs booking" flags, and the per-item links are not authored independently —
they derive from per-event status in `outputs/event-status.md` (the
persist-mutable status layer; see `reference/data-architecture.md`
§ *Lifecycle Classes*). The rules:

- **An item appears on the checklist only if it "needs booking"** —
  `status = planned` **and** `requires booking? = yes`. Those are the open
  bookings the user still has to act on.
- **`firmed`, `locked`, and `option` events never show as "needs booking."**
  A `locked` event is already booked (show it as booked / done, or omit it from
  the open list); a `firmed` event has nothing to book; an `option` is an
  alternative, not a primary slot, so it carries no booking obligation. None of
  these belong in the "still to book" set.
- **"All booked" / empty checklist** is the rendering of *all events locked* —
  no `planned`-needs-booking event remains. The progress bar reaches 100% when
  that set is empty, even if the itinerary still contains `firmed` and `option`
  events (those are not outstanding bookings).
- **Booking-status pills elsewhere on the site** (the advance / book-ahead /
  walk-up / open tiers on each card — see Booking Status Colors) read from the
  same status: a `planned`-needs-booking card shows its booking tier; a `locked`
  card shows as booked; `firmed`/`option` cards do not show a "needs booking"
  state.

The site is a read surface for status — it never writes `event-status.md`. The
hub is the **primary writer** of that file (the validator only reads it; the
enrichment agent may seed initial `locked` rows on setup); the site renders what
the hub has recorded.

### Map-Link Component

Every event on the site carries the **same** map-link treatment: a single standard `.map-link`
element. This replaces the former per-tier ad-hoc links — the map pill inside the featured-stop
link cluster, the map link embedded in the mini-card name, the food-card link cluster, and the
night-card links — which rendered maps four different ways and let some cards ship with no map
link at all.

**What is an event.** An *event* is any itinerary element that names a venue with a physical
location and renders as a card — a **featured stop**, a **mini / alternative / bailout** card, a
**food** card, or a **night** card — including **each per-track venue on a split day**. Every event
is a place a traveler navigates *to*, so every event card carries **exactly one** `.map-link`.
Transit connectors — the mode-and-time transit field, and route/direction links — are **not**
events (they describe movement *between* events, not a destination) and carry no `.map-link`.

**The location invariant.** Every event card resolves to a map link. A card whose venue has
neither a map URL nor an official-site URL is a broken card. This is an audited invariant — the
validator treats a missing or unresolvable link as a hard failure.

**What it renders.** One anchor:

    <a class="map-link" href="{maps_url}" target="_blank" rel="noopener">📍 Map</a>

- A pin glyph + the label **Map** — concise and legible at every card scale (featured, mini, food,
  night).
- `href` = the venue's map URL, **sourced from `outputs/links-reference.md`** (the canonical venue
  list): the venue's Google Maps URL, or — when that venue has no map pin (an in-park venue, or a
  service reachable only via an official page) — its official-site URL as the fallback. The href is
  **never hand-authored per card**: the site reads it from `links-reference.md`, so one venue has
  one URL everywhere it appears.
- **Resolved by venue key, never by display name.** The event carries the venue's `ven-<token>` in
  `outputs/event-status.md`, and `links-reference.md` declares the same key as its own key column;
  the site joins the two on that token. It does **not** match the venue's rendered name against the
  link list — one venue can carry more than one display string across artifacts, so a name match
  both misses links that exist and invents matches that do not. This is what makes "one venue, one
  URL" hold by construction rather than by care, and what makes the validator's unresolvable set
  decidable.

**Placement and visibility.**
- On tiers that also carry website / tickets / booking links (featured stops, food cards), those
  extra links stay in the tier's existing link cluster (`.act-links`, `.fc-links`); the `.map-link`
  sits **adjacent to** that cluster as a **sibling element, not inside it**. On tiers without a standing
  website / tickets cluster (mini, night), the `.map-link` is the primary link affordance; a
  mini card may still carry optional extra links (`.mini-links`) beside it.
- **Always reachable, even when a card is compact.** The desktop compact/collapse rules hide a
  featured stop's description, meta, tips, and its extra-links cluster (`.act-links`). Because the
  `.map-link` is a **sibling** of that cluster — not a child — the existing `display:none` on
  `.act-links` leaves it visible with no extra CSS. **Do not add `.map-link` to any compact-hide
  selector**: a reader must be able to navigate to any venue without expanding the card.
- **Mini cards:** the venue name (`.mini-name`) is **plain text**; the map link is the sibling
  `.map-link`, not a link embedded in the name.
- **Print:** the `.map-link` prints (a usable URL on paper). It is a per-card affordance, distinct
  from the Leaflet day map (`.map-zone`) that print styles hide — hiding the day map does not hide
  the per-card map links.

**Not the Leaflet map.** The `.map-link` is the per-event navigation link. It is separate from the
Leaflet day-map visual (see **Maps** above), which plots the day's route. The two are independent:
the Leaflet map may be collapsed or hidden without removing any event's `.map-link`.

### Split-Day Component

Some days divide the group into parallel tracks — a subgroup does one thing while another does
something else, then they rejoin. The site renders this as a **single day** with a first-class
**split-day region**: N ≥ 2 labeled track columns side by side, each self-contained with its own
stops, its own map, and its named endpoints. This replaces the former treatment of duplicating the
whole day into one full page per subgroup ("take the version for your group"), which forced the
reader to work out which page was theirs and made who-is-on-which-track invisible at a glance.

**Where the data comes from.** The split-day region renders **from the hub's Parallel Track
blocks** — on a split day the itinerary already carries one Parallel Track block per track (subgroup
members, grain, trigger, named venues with timing, and rejoin logistics). The component renders those
blocks: **one Parallel Track block → one track column.** It introduces no new data and never
duplicates the day.

**Structure.** A `.split-day` region — full-width, within the one-day viewport — containing:

- `.split-point` — a shared lead-in naming the place and time the group divides (e.g.
  "Hotel · ~1:30 PM"). The whole-group portion of the day that precedes the split renders normally in
  the day grid above; when the entire day is split, the day grid is omitted and `.split-day` is the
  day body.
- N `.track-col` columns, one per Parallel Track block, laid side by side. Each column holds:
  - `.track-label` — the subgroup members, verbatim (e.g. "Sam · Pat · Riley"). This is what makes
    who-is-on-which-track legible at a glance.
  - `.track-grain` — a small badge: single / small-group / full-group.
  - `.track-why` — a one-line muted kicker from the block's trigger (why this track exists).
    Optional; omit when absent.
  - `.track-stops` — the block's named venues, in order, each rendered as an event card using the
    existing card tiers (mini card by default for column fit; a featured card for the track's anchor
    stop — no new card type). **Every stop carries the standard `.map-link`** (see Map-Link
    Component), sourced from `outputs/links-reference.md` — one venue, one URL, everywhere it appears.
  - `.track-map` — the track's **own** Leaflet map (a `.map-zone` instance; see Maps), plotting only
    this track's stops plus its rejoin point. Each track has its own map.
  - `.track-rejoin` — the named rejoin endpoint and timing, from the block's rejoin logistics (e.g.
    "Rejoin: Hotel · ~noon next day"). Same-day or next-day.

**Named endpoints.** Every track states two named endpoints: the shared **split point** (where it
starts) and its **rejoin point** (where and when it reconverges). Neither is a vague "meet up
later" — both are named places with times, taken straight from the Parallel Track block.

**One day, one header.** A split day keeps a single day section and a single day header; the header
names the split (e.g. "PokePark AM · Split PM"). The day is never duplicated into per-subgroup
pages — the split lives in the body, expressed as parallel columns.

**Not rendered.** The Parallel Track block's *Whole-group bound* and *Needs honored* fields are audit
confirmations (for the validator), not reader content; the component does not render them.

**Distinct from `.split-panel`.** The `.split-day` region (parallel tracks) is unrelated to the
`.split-panel .warn-box` collapsible caution box above — different components; they share no
selectors.

---

## 4. Responsive Architecture

### Desktop (min-width:769px) — One Day Per Viewport

**Viewport-fit hierarchy:**
1. Start with all sections expanded
2. Measure natural height vs viewport (`window.innerHeight - nav.offsetHeight`)
3. Collapse in priority order until content fits: nightlife → sec-toggles → meal-toggles

**Key CSS:**
```css
.day-section { min-height: calc(100svh - var(--nav-h)); display:flex; flex-direction:column }
.day-body { flex:1; display:flex; flex-direction:column }
.day-grid { flex:1 }
.reveal { opacity:1 !important; transform:none !important } /* no scroll animation */
```

**Cards compact by default:**
```css
.act-card .act-desc, .act-card .act-meta, .act-card .act-tip,
.act-card .act-timing, .act-card .act-group, .act-card .act-links { display:none }
.act-card.card-open [above selectors] { display:block }
```

**JS triggers:** `window.load` (with readyState check) + `window.resize` (debounced 300ms)

### Tablet (769-1200px)
- 3-column grid, map full-width at bottom
- Featured stops stack vertically (no side-by-side)
- Must go AFTER desktop block in CSS (cascade override)

### Mobile (≤768px)
- Single column, all desktop rules overridden with `!important`:
  ```css
  .day-section { height:auto !important; min-height:auto; overflow:visible !important }
  .day-body { display:block !important; flex:none !important }
  ```
- Progressive disclosure: sec-toggle, meal-toggle, show-more-tl, map-trigger all visible and functional
- Bottom nav: Map / Eat / Schedule / Bookings
- One day at a time: `.day-section{display:none}` / `.mob-active{display:block}`

### Print
```css
@media print {
  .day-nav, .bottom-nav, .map-zone, .booking-overlay { display:none !important }
  .day-section { display:block !important; page-break-inside:avoid }
  .day-grid { grid-template-columns:1fr !important }
  .reveal { opacity:1 !important; transform:none !important }
}
```

### Split-Day Region

The `.split-day` region extends the one-day-per-viewport model — the whole day (shared portion +
split band) still targets a single viewport.

- **Desktop (≥769px):** track columns lay out side by side (`grid-template-columns: repeat(N, 1fr)`
  for N tracks) within the day viewport, below the shared-portion day grid. Each column carries its
  own `.map-zone` inline. Extend the viewport-fit collapse priority
  (nightlife → sec-toggles → meal-toggles) with **track maps last**: if the day still overflows,
  per-track maps collapse to a per-track "Show track map" trigger — maps are the core affordance of a
  split day, so they are the last thing collapsed. On a split day the day grid's own map column shows
  only the shared/whole-group route, or is omitted; the per-track maps are the day's maps.
- **Tablet (769–1200px):** track columns **stack** (one per row), each a full-width labeled block
  with its stops, then its `.map-zone` full-width below — matching the tablet convention that the map
  drops to full width at the bottom. Labels keep each track legible when stacked.
- **Mobile (≤768px):** tracks stack, one labeled block each, inside the single active `.day-section`
  (one day at a time is preserved). Each track's map sits behind a per-track "View map" trigger
  (tap-to-show), matching the mobile map-trigger pattern; each stop's `.map-link` stays visible.
- **Print:** tracks print stacked and labeled; per-track `.map-zone` maps are hidden (as all Leaflet
  maps are in print), and each stop's `.map-link` prints as a usable URL.

---

## 5. Scroll & Navigation

| Scenario | Behavior |
|---|---|
| Fresh visit | Hero at top, no auto-jump |
| Refresh within 5 min | Restore scroll position (sessionStorage) |
| Stale session (>5 min) | Start from top |
| Nav pill click (desktop) | Smooth scroll to day hero |
| Nav pill click (mobile) | Show that day, hide others |
| Hash link (#day3) | Scroll to that day |
| Window resize | Re-run fitDayToViewport (debounced) |

---

## 6. Animations

| Animation | Trigger | CSS |
|---|---|---|
| `fadeup` | Hero children on load | `opacity:0 → 1`, `translateY(24px) → 0`, staggered 0.1s |
| `bounce` | "Scroll ↓" text | `translateY(0 → 8px)`, infinite 2.5s |
| `reveal` | Scroll into viewport | `opacity:0 → 1`, `translateY(30px) → 0`, 0.6s ease. Disabled on desktop (forced visible). |
| Card hover | Mouse enter | `translateY(-3px)`, shadow elevation |
| Toggle chevron | `.open` class | `rotate(180deg)`, 0.25s |

---

## 7. Destination-Specific Elements

These change per trip — everything else stays the same:

| Element | Tokyo Example | What Changes |
|---|---|---|
| `--accent` | `#BC002D` (Japanese red) | Color palette per destination |
| Hero background | Navy → deep red → red gradient | Gradient that evokes destination |
| Hero decorative | `.hero-kana` (東京), `.hero-sun` (radial glow) | Destination-specific CSS art |
| Font choice (display) | Bebas Neue | Typography that matches mood |
| `.act-vis` gradients | `.av-temple`, `.av-disney`, etc. | Activity-specific card header colors |
| Day hero gradients | `.bg-d1` through `.bg-d8` | Unique gradient per day |
| Energy level names | Survival, Fragile, Building, Peak... | Jet lag / climate specific labels |
| Heat strip colors | Green/Red/Amber thermal zones | Climate-specific zone visualization |
| Booking checklist dates | Tokyo venue-specific dates | Destination booking windows |

---

## 8. File Structure for Site Generation

```
trips/<destination>-<year>/
├── outputs/<destination>-travel-site.html   ← Source file (plaintext, stays local, git-ignored)
└── .publish/                                ← per-trip public repo working copy (git-ignored)
    ├── .git/
    └── index.html                           ← ENCRYPTED artifact — ciphertext only, never plaintext
```

The published `index.html` is the **encrypted** output of the source file, not a raw copy: the publish flow passphrase-gates the site (StatiCrypt) and pushes only ciphertext, so the design system above is what the viewer sees *after* decrypting in-browser. See the publish flow in `CLAUDE.md`.

Site is a single self-contained HTML file. External dependencies:
- Google Fonts (3 families via CDN)
- Leaflet.js + CartoDB tiles (via CDN)
- No build step, no framework, works offline (except maps/fonts)

---

## 9. Plan/Site Single-Sourcing & Round-Trip Fidelity

The site is a **rendering of the plan, single-sourced from `outputs/`.** It reads the plan
artifacts and renders them; it never authors plan content of its own and never writes back to any
`outputs/` file. §3's Booking Checklist already establishes this read-surface principle for one
slice — booking status derives from `event-status.md`, and the site never writes it. This section
generalizes that principle to the **entire** plan: every element the site shows traces to an
authoritative `outputs/` artifact, and nothing in `final-itinerary.md` is silently dropped on the
way to the page.

### 9.1 Single-source authority — which artifact owns which element

Each site element has exactly one authoritative source. Where two artifacts could carry the same
fact, the authority column decides and the others are read-only consumers of it (one source per
fact).

| Site element | Authoritative artifact | The site reads it for |
|---|---|---|
| Itinerary structure — days, day headers, anchors, supporting stops, bailouts, alternatives, food, transit, nightlife, and **every track of a split day** | `final-itinerary.md` | The plan content and its per-day shape |
| Every venue link — each `.map-link` href, plus website / tickets / booking links | `links-reference.md` | One URL per venue, everywhere it appears — resolved by venue key (§3) |
| Day assignment + deduplication — which venue sits on which day, the appears-at-most-twice rule, anchor vs. alternative/bailout placement | `venue-matrix.md` | Placing a venue on the right day, not double-showing it |
| Booking status, "needs booking" flags, checklist membership, per-card booking-tier pills | `event-status.md` | Whether an event is booked / to-book / settled (per §3's read-surface rule) |
| Group, dates, home base, trip-level hard constraints — hero + overview facts | `trip-context.md` | Trip-level header and constraint framing |

Two artifacts are **authoritative internally but not reader-facing site content:**
`traveler-model.md` and `satisfaction-metrics.md` hold per-traveler needs, desires, and coverage.
They are the planner's internal view and carry personal detail that lives only in the working dir
and is never published — the site does **not** render them by default (see the Intentional-
Exclusion list in 9.3).

The rule, stated once: **the site renders `outputs/`; it writes none of it.** A build or update
reads these artifacts and produces the HTML — it never edits an `outputs/` file as a side effect.

**The machine-readable projection of this section.** The table above remains the authority for
which artifacts are publish-bound; the fence below is its projection, and the two are required to
agree. It exists so that the publish-bound artifact set has **one declared home**, and so a source
added to the build lands there rather than in whichever consumer needed it. **It is now an asserted
home.** `scripts/test-artifact-schema.sh` group `PB` resolves this fence and checks it against § 1.1
in both directions: every fence row has a class row carrying the same publishability, and every such
class row has a fence row. "The publish-bound artifact set is sourced from § 9.1" is a checked claim
rather than a stated one.

```publish-contract-artifacts
# artifact                          class
trip-context.md                     bound
outputs/final-itinerary.md          bound
outputs/links-reference.md          bound
outputs/venue-matrix.md             bound
outputs/event-status.md             bound
outputs/traveler-model.md           internal-hard
outputs/satisfaction-metrics.md     internal-hard
```

The `class` values are the closed four-value enum in `reference/data-architecture.md` § 5.1
(`bound` | `internal` | `internal-hard` | `output`). `internal-hard` marks the two artifacts § 9.3
lists as intentional exclusions — never rendered, **and** carrying values that must not reach a
rendered page in any form, including anonymized.

**The publish guard does not read this fence.** It reads the field/entry declaration in
`reference/data-architecture.md` § 5.6, which is what decides *which values* are in class. This
fence declares *which artifacts* the site build may read. **One of its two intended consumers now
reads it:** the artifact-schema gate, in group `PB`. The other does not — `agents/06-validator.md`
still restates the five `bound` artifact names inline, in the same file that cites § 5.6's sibling
fence as the single home of the class it does read. The fence predated the gate, so it shipped as a
forward reference; the gate has since arrived, and the validator's inline restatement is the one
second enumeration that remains.

### 9.2 Round-trip completeness — every plan element has a rendered home

Round-trip fidelity is **surjective from plan onto site**: every element in `final-itinerary.md`
maps to something the site renders. It is **not** bijective — the site may add reference and
navigation scaffolding (a hero, an overview dashboard, an essentials card, a trip-at-a-glance,
appendices) that has no single plan-element source. Additive site scaffolding is legitimate;
**dropped plan detail is not.** The invariant runs one way: plan → site is total; site → plan need
not be.

**The mapping table (the anti-silent-loss mechanism).** Every element type the itinerary format
defines resolves to a named site component or to a named exclusion. A day-by-day plan element that
is neither is a **silent drop** — the defect this contract forbids.

| Itinerary element type | Renders as (site component, §3) |
|---|---|
| Advance Booking Checklist | Booking Checklist — status ← `event-status.md`, links ← `links-reference.md` |
| Trip Overview | Hero + Overview Dashboard |
| Day header — energy / zone / type / theme | Day Hero Banner + energy-coded day nav |
| Anchor | Featured Stop Card (`.act-card`) with its `.map-link` |
| Supporting Experiences | Featured Stop Cards (side-by-side) or Mini Cards |
| AC Bailout | Mini Card in a Section Toggle, bailout-flagged, with its `.map-link` |
| Alternatives | Mini Cards in `.alt-grid` under a Section Toggle — Alt/B placement ← `venue-matrix.md` |
| Food Anchors — breakfast / lunch / dinner + options | Food Cards under Meal Toggles |
| Transit Notes | `.card-transit` field + collapsible transport-box |
| Nightlife / later-tonight options | Night Cards (`.night-card`) in the nightlife band (`.night-zone`); on a split night each card carries its `.nc-who` members string |
| Nightlife decline — the `No nightlife tonight` line | A stated line in the nightlife band (`.night-zone`), carrying its member slot verbatim in the same `.nc-who` form the cards use — `whole group` on an unsplit night, the subgroup's members string on a split one. A decline produces no `.night-card`, so this introduces **no new card type**; the band already renders whenever the block has content, and a decline is content. It is rendered rather than excluded because a *stated* decline and a *dropped* subgroup must not look alike on the page — which is the silent drop this contract forbids. |
| Constraint Compliance | Heat/Weather Strip + constraint note |
| Parallel Track — a split day | **Split-Day Component** — one labeled track column per subgroup (N≥2), each with its own day map and named endpoints; every per-track event carries its `.map-link` |

**Split days are the sharpest test of this rule.** A split day carries two or more parallel tracks,
and the failure this contract exists to prevent is a track — or a track's detail — silently
collapsing into one. Every track of every split day renders as its **own labeled column** through
the Split-Day Component; no track is merged away, and each track's events each get the
location invariant's `.map-link`. (The Split-Day Component and its exact class names are
defined by the split-day component section; this contract requires only that all per-track plan
content route through it, with no track dropped.)

Trip-level reference matter — an essentials card, a trip-at-a-glance table, a key-closures list,
appendices — is **site-additive** reference content: render it when the plan provides it, sourced
from `final-itinerary.md`'s front/back matter and `trip-context.md`. It is static reference, not
the per-day plan detail the completeness rule gates — not a drift risk, and not part of the round-
trip core.

### 9.3 Intentional exclusions — named, so nothing is silent

Some itinerary elements are **deliberately not reader-facing.** They are named here so that "not
rendered" is an explicit decision with a reason — not a silent drop. Excluding a listed element is
correct; dropping an *unlisted* plan element is the defect.

| Excluded element | Why it is not on the site |
|---|---|
| Spoke Deviations | The planner's trace of why the plan diverged from a specialist's recommendation. Audit-trail, not reader content. |
| Open Decisions | Pre-decision options for the planner, not finalized plan. Not a reader-facing commitment. |
| Itinerary Version Log | Document metadata. |
| Per-traveler model + satisfaction metrics | Internal coverage view carrying personal detail; kept out of the published surface by design (see 9.1). |
| Artifact frontmatter — the YAML block a plan artifact opens with | Machine-readable identity, lifecycle, provenance and publishability, read by the schema gate and by the agents. It is metadata *about* the artifact rather than plan content in it, and has no reader-facing form. Named here because 9.2's completeness rule is total over every element of `final-itinerary.md`, so once a migrated itinerary carries a block, an unlisted block would read as a silent drop on every build. |

### 9.4 The completeness check — run at build and at update

At **site build** and again at every **site update**, walk 9.2's mapping against the current
`final-itinerary.md`:

- Every day resolves to a Day Hero Banner and a day body — a day grid, a `.split-day` region,
  or both; every card-bearing element (anchor, supporting, bailout, alternative, food,
  nightlife) resolves to its component, and the nightlife band renders regardless of which
  day-body shape is present. The band's contents are walked in full — night cards **and** any
  `No nightlife tonight` line, which is block content rather than absence, and which on a split
  night is the only thing that distinguishes a stated decline from a dropped subgroup.
- Every track of every split day resolves to its own labeled Split-Day Track column.
- Every rendered event carries its `.map-link` (the location invariant).
- Every element type present in the plan is either rendered (mapping table) or on the
  Intentional-Exclusion list.

An **update** is the higher-risk moment: patching only the changed sections is correct (do not
regenerate from scratch), but the walk must still confirm the patch dropped nothing — most often a
**second track of a split day** changing while only the first was patched. A patch that leaves any
plan element unrendered and unexcluded fails the check.

### 9.5 Structural-gap boundary — what is a later slice, not this one

The completeness check separates two failures that look alike but scope differently:

- **A build/update that forgot to place an element whose component exists** is an ordinary build
  defect. The check catches it; fixing it is **in scope** — re-place the element.
- **A reader-facing plan element type for which no site component can represent it** — a
  structurally unrepresentable element — is a **component gap.** Designing the missing component is
  a **fast-follow**, tracked as its own work item and shipped in a later patch release. It is
  **not** an in-scope expansion of this single-sourcing contract.

This contract's job is to make the mapping **total over the elements today's components can
render**, and to **surface** any structural gap as a named finding — not to build new components
under the banner of round-trip fidelity. If the completeness walk turns up an element type with no
possible rendered home, record it and route it to a fast-follow; do not grow this contract to
absorb it.
