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

### Day Grid
- **Desktop 1200px+:** `grid-template-columns: 1fr 1.3fr 1fr 0.8fr` (schedule · highlights · food · map)
- **Tablet 769-1200px:** `1fr 1.2fr 1fr` (map goes full-width at bottom)
- **Mobile ≤768px:** single column

### Featured Stop Cards (`.act-card`)
Structure:
```
.act-vis      — Emoji gradient banner (80px mobile, 32px desktop compact, 60px expanded)
.act-body
  .act-links  — Map/Website/Tickets pills (absolute top-right, via JS wrapping)
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
  .mini-name    — Venue name with map link
  .mini-sub     — Category · Area
  .card-transit — Mode + time
  .mini-note    — Short description
  .book-status  — Booking tier pill
  .mini-links   — Optional extra links
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
.fc-links   — Map/site links (absolute top-right on desktop)
```

### Night Cards (`.night-card`)
Dark background (navy). Structure:
```
.nc-em    — Emoji
.nc-name  — Venue name (display serif)
.nc-meta  — Location · details
.nc-desc  — Description (hidden desktop compact)
.nc-links — Map links
```

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
outputs/
├── [destination]-travel-site.html   ← Source file (plaintext, stays local)
└── [destination]-trip/              ← GitHub Pages repo (per-trip, public)
    ├── .git/
    └── index.html                   ← ENCRYPTED artifact — ciphertext only, never plaintext
```

The published `index.html` is the **encrypted** output of the source file, not a raw copy: the publish flow passphrase-gates the site (StatiCrypt) and pushes only ciphertext, so the design system above is what the viewer sees *after* decrypting in-browser. See the publish flow in `CLAUDE.md`.

Site is a single self-contained HTML file. External dependencies:
- Google Fonts (3 families via CDN)
- Leaflet.js + CartoDB tiles (via CDN)
- No build step, no framework, works offline (except maps/fonts)
