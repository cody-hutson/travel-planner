# Travel Planner — Multi-Agent Trip Planning System

## What This Is

A multi-agent trip planning system. Nine specialized agents research, plan, validate, and produce travel itineraries. The agent prompts in `agents/` define deep behavioral profiles — destination specialist, food writer, nightlife curator, itinerary architect, logistics expert, synthesis director, and pre-departure auditor. Each produces a structured artifact. The hub synthesizes all artifacts into a final itinerary. The validator audits it before it's acted on.

## Agent Model Requirement

**All agent dispatches use Opus 4.6 (1M context) with maximum thinking budget. No exceptions.** When spawning agents via the Agent tool, always use `model: "opus"`. The quality of the research and synthesis depends on the model — this is not a place to economize.

---

## Session Protocol

Trip planning spans multiple chats over days or weeks. Files are the memory. Every session follows this protocol.

### Starting a session (any chat that touches a trip)

1. Read this `CLAUDE.md` (auto-loaded)
2. Read `trips/[destination-year]/trip-context.md` — the source of truth for what's planned
3. Read `trips/[destination-year]/trip-log.md` — the decision history and session bridge
4. Scan `trips/[destination-year]/outputs/` — know what exists and what's been produced

This is 30 seconds of file reads that prevents 10 minutes of "where were we?"

### Ending a session

**Scale the log entry to the session.** A quick site edit doesn't need a full decision register. A planning session with 5 decisions does.

- **Quick edits / lookups:** One-line entry in trip-log.md noting what was changed. Or skip the log entirely if the change is trivially visible in the file diff.
- **Planning sessions (decisions made, options discussed):** Full entry:
  - Decisions made this session (and rationale)
  - Options discussed and rejected (and why — this prevents re-litigating)
  - Any new preferences or constraints surfaced
  - What the user wants to do next
  - Current state of the plan (what's solid, what's still open)

### trip-log.md

Created alongside trip-context.md when a trip starts. Running decision register that grows across sessions. Structure:

```markdown
# Trip Log — [Destination] [Year]

## Session [Date]
**Topics:** [what was discussed]
**Decisions:**
- [Decision — rationale]
**Rejected:**
- [Option — why it was rejected]
**Next steps:** [what the user wants to do next session]
**Open questions:** [unresolved items]
```

This file is the primary session bridge. It captures what trip-context.md cannot: the reasoning behind choices, the options that were considered, and the conversational context that informs future decisions.

---

## Output Versioning — Never Lose Agent Work

**Agent outputs accumulate. They do not overwrite.**

When an agent re-runs (e.g., food agent runs again after the user asks for more options):
- **Append** new content to the existing output file with a dated section header
- **Never delete** previous research — the hub reads the full accumulated file
- Previous entries remain as context, alternatives, and history

Example: `food-list.md` after three sessions:
```markdown
# Food List — Lisbon

## Initial Research (2026-04-10)
[35 entries from first run]

## Targeted Update — Dinner Options Near Bairro Alto (2026-04-15)
[8 new entries addressing user's request for more dinner variety]

## Replacement Options — Day 3 Lunch (2026-04-18)
[4 alternatives after user rejected the original Day 3 lunch pick]
```

**Exception:** The hub's `final-itinerary.md` IS replaced on each synthesis (it's the assembled output, not research). But it uses version numbering: v1, v2, etc. Previous versions are preserved as `final-itinerary-v1.md`, `final-itinerary-v2.md`.

**Exception:** `links-reference.md` and `venue-matrix.md` are rebuilt by the hub on each synthesis pass (they reflect the current state of the itinerary, not research history).

### Satisfaction-layer artifacts

The satisfaction layer adds three `outputs/*.md` artifacts with their own lifecycles. Full rationale: `reference/data-model.md`.

- **`event-status.md` — persist-mutable (a fourth pattern).** Updated **in place** as events change status, and it **survives every re-synthesis** — never appended-with-history, never rebuilt from scratch, never versioned. It is the iteration-protection source of truth: a re-synthesis *reads* existing status, it does not overwrite it. This is the one artifact that must outlive a planning pass. The **hub is the primary writer** and owns it; the file is **created by whichever agent first writes it** — the enrichment agent's setup seed (from `## Locked Elements`), or the hub on the first full synthesis if no seed exists (the validator only reads it). Persist-mutable is not append-only — a row is **deleted** in the one case where its event is removed from the itinerary, so no ghost row lingers.
- **`traveler-model.md` — rebuilt/refreshed.** A `[DERIVED]` projection. The enrichment agent refreshes it from the current per-traveler source files (`travelers/<traveler>.md`) whenever those change. It holds no independent state — the source files are authoritative — so regeneration is safe.
- **`satisfaction-metrics.md` — rebuilt/refreshed.** Recomputed from the current itinerary and traveler model. A coverage snapshot at synthesis time; safe to regenerate because its inputs are authoritative. Two writers, **section-owned** so they never clobber: the **hub** owns the desire-coverage + balance-signal sections, the **validator** owns the needs-compliance + agreement-check sections, each read-merge-writing only its own.

---

## How to Use This (Claude Code as Primary Interface)

The user interacts conversationally. **Classify the intent before acting.** Not every request needs an agent. Most requests in an active trip are direct edits or quick lookups.

### Step 1: Classify the request

Before doing anything, determine what kind of request this is:

| Type | Signal | Action | Example |
|------|--------|--------|---------|
| **Direct edit** | User wants a specific change to an existing file | Read the file, make the edit, done. No agents. | "Update the emojis on the site", "Fix the typo in Day 3", "Change the dinner time to 8 PM" |
| **Quick lookup** | User asks about existing plan content | Read the relevant file(s), answer. No agents. | "What's our Day 5 plan?", "What still needs booking?", "What hotel are we at?" |
| **Site tweak** | User wants visual/design changes to the HTML | Read the site HTML, edit directly. No agents. | "Make the colors warmer", "Add a section for packing list", "Fix the map on Day 2" |
| **Context update** | User shares new information (booking, date change, preference) | Update trip-context.md and/or trip-log.md. No agents unless the change cascades. | "We booked the hotel", "Mom can't do stairs", "Add a traveler's food allergy" |
| **Targeted research** | User wants new options or deeper research on a specific topic | Dispatch the relevant spoke agent with a targeted prompt. Append to existing output. | "Find more dinner options near Bairro Alto", "What indoor activities exist near the hotel?" |
| **Planning change** | User wants to change the itinerary structure (swap days, add a day trip, reschedule) | Update trip-context.md mode notes → dispatch relevant agent(s) → hub patches itinerary. Only `planned` events change freely; `locked`/`firmed` events are preserved unless the user names them (see Key Rules → per-event status). | "Swap Day 3 and Day 4", "Replace the afternoon on Day 5 with something indoor" |
| **Full pipeline** | User wants the initial plan built or a full re-plan | Run the full agent pipeline (enrichment → spokes → hub → validator) | "Build the itinerary", "Start fresh on the plan" |
| **Site generation** | User wants the travel site built or rebuilt | See Travel Site Generation section | "Build the site", "Create the travel page" |
| **Publish** | User wants to push to GitHub | See Publishing section | "Publish this", "Push to GitHub" |

**The default is the lightest-weight action that matches the intent.** Direct edits are direct edits. Don't dispatch agents to change an emoji. Don't re-run the food pipeline to fix a typo in a restaurant name. Don't re-synthesize the itinerary to update a booking confirmation code.

**When in doubt, ask.** "Do you want me to just edit that in the site, or should I re-run the food agent for new options?" is better than guessing wrong and re-running the whole pipeline.

### Step 2: Read context (scaled to the request)

| Request type | What to read |
|-------------|-------------|
| Direct edit / site tweak | Just the file being edited |
| Quick lookup | The relevant output file(s) |
| Context update | trip-context.md (to update it) |
| Targeted research | trip-context.md + the relevant output file + trip-log.md |
| Planning change / full pipeline | trip-context.md + trip-log.md + all relevant outputs |

Don't read the entire trip state for a CSS color change. Do read the full state when making planning decisions.

### Starting a new trip

When the user wants to plan a trip:
1. Create `trips/[destination-year]/`, `trips/[destination-year]/outputs/`
2. Copy `templates/trip-context.template.md` to `trips/[destination-year]/trip-context.md`
3. Create `trips/[destination-year]/trip-log.md` with initial session entry
4. Fill in trip-context through conversation — ask the user questions, don't make them edit markdown
5. Set the mode based on what's known (IDEATION if exploring, DISCOVERY if destination picked, ENRICHMENT if flights/hotel booked)
6. In IDEATION with no destination yet, dispatch **Destination Ideation** to turn the group's leanings into a ranked shortlist (`outputs/destination-shortlist.md`) for the group to decide from — then, once they pick, set the destination and switch to DISCOVERY

### Dispatching agents (only when classification calls for it)

Read the relevant agent prompt from `agents/<name>.md` (see the roster below) and use it as context when producing that agent's output. For research-heavy agents (enrichment, validator), use web search. Always dispatch with Opus 4.6 1M, max thinking budget.

**Agent roster:**

| Agent | Prompt File | Output File | When to dispatch |
|-------|------------|-------------|-----------------|
| Destination Ideation | `agents/destination-ideation.md` | `outputs/destination-shortlist.md` | IDEATION with no destination chosen yet — aggregate travelers' leanings into a ranked group shortlist |
| Enrichment | `agents/00-enrichment.md` | Updates `trip-context.md` [ENRICH] fields | New trip setup, destination/hotel change |
| Activities | `agents/01-activities.md` | `outputs/activities-list.md` | User wants activity research or replacements |
| Food | `agents/02-food.md` | `outputs/food-list.md` | User wants food research or replacements |
| Nightlife | `agents/07-nightlife.md` | `outputs/nightlife-list.md` | User wants going-out research, or a full pipeline where a present traveler holds a nightlife/evening desire — the spoke resolves its own desire gate and writes a gate-result stub when nobody does |
| Scheduling | `agents/03-scheduling.md` | `outputs/scheduling-framework.md` | Structural schedule changes, resequencing |
| Transport | `agents/04-transport.md` | `outputs/transport-brief.md` | Transport questions requiring research |
| Hub Planner | `agents/05-hub-planner.md` | `outputs/links-reference.md`, `outputs/venue-matrix.md`, `outputs/final-itinerary.md`, `outputs/event-status.md` (primary writer), `outputs/satisfaction-metrics.md` (desire-coverage + balance sections) | Full synthesis or itinerary restructuring — **runs and reconciles the three optimizer engines** (routing vs. desire-coverage vs. experiential arc) into one itinerary, needs applied as hard constraints first (R1–R4) |
| Validator | `agents/06-validator.md` | `outputs/validation-report.md`, `outputs/satisfaction-metrics.md` (needs-compliance + agreement-check sections; reads `event-status.md`, never writes it) | After hub produces/updates itinerary |

**Pipeline flow (full pipeline only):** Enrichment → Spokes (parallel if possible) → Hub → Validator → Remediation (if criticals found). The Hub step is where the three optimizer-engine signals are **reconciled** into one itinerary — needs first as hard constraints, then routing / desire-coverage / experiential arc resolved by a documented policy (R3); the spokes only emit signals, they do not synthesize.

**For Agent tool calls:** Pass the agent's prompt file content as the agent's instructions. Include the trip-context.md, trip-log.md (for decision context), and any required input files as context. Write the output to the correct file path, following the output versioning rules.

### Modes

Read `trip-context.md` → Mode section to determine what's in scope.

| Mode | What's happening | What runs |
|------|-----------------|-----------|
| IDEATION | Exploring options, nothing decided | **No destination yet:** Destination Ideation aggregates travelers' leanings into a ranked group shortlist (`outputs/destination-shortlist.md`) to decide from. **Destination in play:** Activities, Food, Nightlife, Scheduling, Transport produce overview-level output; Hub compares options. Validator skipped. |
| DISCOVERY | Destination picked, nothing booked | Full pipeline. All agents run. |
| ENRICHMENT | Flights/hotel confirmed | Full pipeline. Agents plan around fixed anchors. |
| ITERATION | Existing plan, user wants changes — including a **disruption recovery**, triggered two ways: an event regressing `locked → planned` in `event-status.md` (a missed booking / cancelled hold) **or** a changed-profile delta (the enrichment agent's update signal that a traveler edited their file). | Only affected agents re-run. Hub patches itinerary. Validator re-checks changed days. Status honored: only `planned` events change freely; `locked`/`firmed` are preserved unless the user names them; `option` events stay alternatives. On a disruption recovery the hub runs its **equity-aware recovery** (per-traveler loss distribution → prioritize hardest-hit → re-run affected engines, needs preserved → regroup gaps under a coherent theme), and the validator runs its **recovery-equity check** (losses not concentrated; needs still hold). |
| RESEQUENCING | Keep selections, reorder days | Scheduling re-runs. Hub resequences. Validator checks new day-of-week assignments. Only `planned` events move; `locked`/`firmed` are fixed anchors; `option` events are not promoted into primary slots. |

---

## Travel Site Generation

The travel site is a **bespoke creative artifact** — not a template fill. Each trip gets a unique site with destination-specific design, color theming, and visual identity. The site grows as the trip plan evolves.

### Design Principles

- **Destination-specific aesthetic.** Every site reflects its destination: color palette, landmark visuals, typography mood. Tokyo got Japanese red (`#BC002D`) with kana characters and torii-gate gradients. Lisbon would get Portuguese blue/azulejo tones. Paris would get something else entirely.
- **Editorial luxury quality.** High-end travel magazine feel. Not a data dump — a designed experience you'd want to browse on your phone at the airport.
- **Functional on the ground.** Sticky navigation, collapsible days, Google Maps links on every venue, booking checklist with progress tracking. It's a planning tool AND a reference tool during the trip.
- **Grows with the plan.** The site isn't generated once at the end. It's created when there's enough content and updated as the plan evolves. Early versions may be lighter. Final versions are comprehensive.

### What a good site includes

Based on the quality bar established by previous trips:
- Hero section with destination name, dates, group, key stats
- Trip overview dashboard with booking action tags per day
- Sticky day navigation with energy-level color coding and sub-text
- **Desktop: one day per viewport** — 4-column grid (schedule · highlights · food · map), auto-expand/collapse to fit any screen size
- **Mobile: progressive disclosure** — one day at a time, bottom nav, collapsible sections
- **Tablet: 3-column fallback** — map goes full-width at bottom
- Per-day sections: schedule timeline, featured stop cards (side-by-side, compact/expandable), food cards, transport notes
- **Booking status indicators** on every card (advance/ahead/walkup/open)
- **Transport field** on every card (mode + time from hotel)
- **Featured card enrichments**: insider tips, best timing, group-fit tags
- Heat/weather zone visualizations where relevant
- Leaflet maps in dedicated grid column (desktop) or tap-to-show (mobile)
- Interactive booking checklist sorted by action date with booking window rules
- Collapsible prep-boxes, transport-boxes, and warn-boxes on desktop
- Responsive across all screen sizes — viewport-fit JS adapts automatically
- CSS-art landmark visuals (not stock photos — pure CSS/SVG)
- Print styles (hide nav, maps, toggles; single-column)
- See `reference/site-layout-spec.md` for full implementation specification

### How to build it

When the user says "build the site" or "create the travel site":

1. **Read the content sources:**
   - `outputs/final-itinerary.md` (primary content)
   - `outputs/links-reference.md` (all venue URLs for maps/links)
   - `outputs/venue-matrix.md` (day assignments)
   - `trip-context.md` (group info, dates, constraints for the hero)

2. **Read reference sites for quality standard:**
   - Check the Site References section below for previous trip sites
   - Use them as design inspiration — not as templates to copy
   - Match or exceed the quality bar; adapt the aesthetic to the new destination

3. **Design the destination aesthetic:**
   - Choose a color palette that evokes the destination
   - Design CSS-art landmark visuals specific to the location
   - Select typography that fits the mood (editorial, elegant, destination-appropriate)

4. **Build the full HTML site** as a single self-contained file:
   - All CSS inline (no external stylesheets except Google Fonts)
   - Leaflet.js for maps (CDN link is fine)
   - No build step, no framework — one HTML file that works offline
   - Write to `outputs/[destination]-travel-site.html`
   - **Follow `reference/site-layout-spec.md`** for responsive architecture, viewport-fit logic, card system, booking indicators, and mobile/desktop interaction patterns

5. **Iterate with the user.** The first version won't be final. Expect:
   - Color tweaks ("more muted", "warmer tones")
   - Content additions as the plan evolves
   - Section reordering
   - New features for this specific trip

### Updating the site

When the itinerary changes (iteration mode, new bookings, swapped venues):
- Read the current site HTML
- Patch the affected sections — don't regenerate from scratch
- Preserve any design tweaks the user already approved
- After patching, run the round-trip completeness check (see `reference/site-layout-spec.md` §9 Plan/Site Single-Sourcing & Round-Trip Fidelity): every element in `final-itinerary.md` — every day and **every track of a split day** — still resolves to a rendered component or a named exclusion, so a patch never silently drops plan detail.

### Publishing to GitHub Pages

**Published trip sites are private-by-default.** A trip itinerary — dates, lodging, who you're travelling with — must not be world-readable. The publish flow encrypts the site before anything reaches the public per-trip repo, so only ciphertext is ever pushed. Free public Pages hosting still works because decryption happens client-side, in the viewer's browser, after they enter the passphrase.

When the user says "publish this" or "put this on GitHub", run:

```bash
scripts/publish-trip-site.sh publish trips/[destination-year]
```

That one command:
1. Encrypts `outputs/[destination]-travel-site.html` with StatiCrypt (AES-256-CBC + HMAC-SHA256, 600k PBKDF2-SHA256) into a passphrase-gated `index.html`.
2. Runs a fail-closed **pre-push guard** that refuses to push unless the output is verified ciphertext with no plaintext itinerary tokens.
3. Creates the per-trip **public** repo and pushes **only the ciphertext**, using a no-reply commit identity (never the user's email).
4. Enables Pages and prints the live URL plus the passphrase.

If the pre-push guard aborts, **nothing was published** — the error names what failed; rebuild the site and re-run.

**Passphrase.** If `$STATICRYPT_PASSWORD` is set it is used; otherwise a strong one is generated and saved to `trips/[destination-year]/.passphrase` (git-ignored, never published). Share it over a private channel — anyone with the passphrase can view the site; without it, the page is just a prompt.

**Repo name.** By default the per-trip repo is `[destination]-[year]-trip`. Pass `--opaque` to `publish` to name it with a random token instead (`trip-<hex>`, no destination/year); the name is saved to `.publish-slug` so every later command resolves the same repo. To publish to a custom or pre-existing repo — a shorter shared name or an existing site — put the bare repo name in `trips/[destination-year]/.publish-slug` (git-ignored). `publish`/`update`/`rotate`/`list`/`unpublish` all resolve it the same way.

**Site is live at:** `https://<github-username>.github.io/[destination]-[year]-trip/` — the URL shows a passphrase prompt, not the itinerary.

**Updating after edits** (re-encrypt and re-publish only ciphertext):
```bash
scripts/publish-trip-site.sh update trips/[destination-year]
```

**Rotating the passphrase** (e.g. after sharing with someone who should no longer keep access):
```bash
scripts/publish-trip-site.sh rotate trips/[destination-year]
```
Rotation re-encrypts under a new passphrase and re-publishes; previously-shared viewers must re-receive the new one.

**Listing published sites** (read-only — never writes, encrypts, or pushes):
```bash
scripts/publish-trip-site.sh list
```
Prints every trip under `trips/` with its repo, live URL (or "not published"), last-published vs last-edited, and a **stale** flag when your local build is newer than what's deployed.

**Taking a site down:**
```bash
scripts/publish-trip-site.sh unpublish trips/[destination-year]                      # delete the repo (default)
scripts/publish-trip-site.sh unpublish trips/[destination-year] --disable-pages-only # keep repo, site offline
```
The default **deletes** the per-trip repo — removing the site *and* the destination/year in its name. Deletion is irreversible, needs the `delete_repo` gh scope (grant once with `gh auth refresh -h github.com -s delete_repo`), and prompts you to type the repo name to confirm. `--disable-pages-only` instead disables Pages and keeps the repo (reversible). Either way `unpublish` is idempotent (a no-op if the site is already gone), and content may persist in third-party caches or clones after takedown.

**Opting out** — publish the itinerary fully public and unencrypted — is explicit and requires confirmation. Interactively the script prompts you to type `PUBLISH`; non-interactively (e.g. when Claude runs it) set `ALLOW_PLAINTEXT=1`:
```bash
ALLOW_PLAINTEXT=1 scripts/publish-trip-site.sh publish trips/[destination-year] --plaintext
```

> **What "private" means here.** The published bytes are world-fetchable ciphertext; security rests on passphrase strength plus the 600k-iteration KDF, not on access control — anyone can download the file and attempt an offline guess. Use a strong passphrase. This is privacy-by-construction (a fresh repo, only ciphertext ever committed), not an identity-gated ACL.
>
> **What still leaks (metadata).** By default the per-trip repo is named `[destination]-[year]-trip` and is public, so the destination and year show on your GitHub profile even though the itinerary itself is encrypted; commit timestamps reveal when you publish. Only the itinerary *content* is protected — not the fact that the trip exists. Pass `--opaque` at publish (or set a custom name in `trips/[destination-year]/.publish-slug`) to keep destination/year out of the repo name; commit timestamps still reveal publish activity.
>
> **Trust boundary.** Encryption runs via `npx staticrypt` (pinned to an exact version); your passphrase is passed to that package at publish time, so you are trusting the pinned StatiCrypt release and the npm supply chain.
>
> The trip repo is independent from this engine repo — a standalone public repo containing only the encrypted `index.html`. The plaintext itinerary, agent outputs, and `.passphrase` stay in the git-ignored `trips/` working dir and are never published.

### Site References

Previous trip sites that set the quality bar. Read these when building a new site. Each establishes a different destination aesthetic while maintaining the same editorial quality standard.

| Trip | Itinerary Source | Design Notes |
|------|------------------|-------------|
| Tokyo 2026 (worked example) | [`examples/tokyo-2026/outputs/final-itinerary.md`](examples/tokyo-2026/outputs/final-itinerary.md) | Japanese red (#BC002D), Bebas Neue + DM Serif Display + Karla fonts, CSS-art landmark visuals, Leaflet maps, interactive booking checklist, energy-level nav, 3-column day layout, scroll animations, heat zone strips |

> The published HTML for each trip lives in its own standalone public repo (per the publishing section above), not in the engine repo. The example above is the markdown source set; the rendered HTML is produced fresh from those sources per trip.
>
> As more trip examples are added, append them here. Each becomes a reference for future sites — an expanding library of design patterns and destination aesthetics.

---

## Key Rules (From Agent Design)

These are encoded in the agent prompts but worth knowing as the orchestrator:

- **trip-context.md is sacred.** Only the enrichment agent modifies it. No activity lists, food picks, or itinerary content goes in this file. No per-traveler desire detail, no per-event status, and no satisfaction metrics go in it either — those have their own homes (see below).
- **Per-traveler data lives in separate files.** Each traveler's needs and desires live in `trips/[destination-year]/travelers/<traveler>.md` — human-authored, independently editable, one file per traveler, **filled from the blank intake form at `templates/traveler-intake.template.md`** (copied once per traveler). The enrichment agent reads and reconciles them into `outputs/traveler-model.md` (`[DERIVED]`); it does not author the source files. Keeps heavy per-traveler detail out of sacred trip-context.md and makes each file a change surface. Each file separates **needs** (constraints that bound the solution — e.g. heat, mobility, dietary-health, rest, budget, timing, sensory) from **desires** (wants optimized within those bounds, each carrying a structural priority tier of anchor/wish/nice-to-have, an optional recurrence of one-off or daily, optional theme tags, and a desire-overlap signal); the tier is a priority label, not a numeric weight, and recurrence is orthogonal to it — a daily want may be an anchor, a wish, or a nice-to-have — nothing optimizes yet. A daily recurrence is a cadence on the want, never an exemption from the venue-deduplication cap below. The template spans the trip lifecycle (IDEATION → ENRICHMENT), capturing the individual's party, destination leanings, dates, journey & origin, accommodation, budget appetite, travel style, interests, and people dynamics through to needs and desires — all the individual's own view; group destination shortlists and any side-bar splits are pipeline-derived, never authored in the individual file (see `reference/data-model.md`). The flow is **intake template → filled per-traveler profile (human, in the git-ignored `trips/`) → enrichment reconciles → `outputs/traveler-model.md`**; filled profiles carry real personal detail and so live only in the git-ignored working dir — they never go in trip-context.md and are never published. A **missing or blank profile is handled by operator fallback, not a hard failure**: the enrichment agent reconciles everyone who has a usable profile, falls back to operator-provided needs/desires for the gap (marked as operator-provided), and otherwise records a flagged `PROFILE MISSING` gap and continues — an absent profile means *unknown*, never *no constraints*. A **third fallback branch covers a party member who will never file a profile at all**: where the operator supplies that person's needs, they are admitted to `outputs/traveler-model.md` as exactly one `## <Name>` entry marked `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` — needs only, no file created for them anywhere, and no entry at all without operator input. A `[THIRD-PARTY]` value is **never published**: it never escalates into trip-context.md (it triggers no new constraint and its subject is never added to a constraint's `Applies to:` line) and must not appear in any publish-bound artifact in attributed *or* anonymized form — it shapes the plan solely through `outputs/traveler-model.md`, which the site build excludes and the hub applies as a hard bound before any objective; provenance-marking records only that a value is second-hand and never establishes the described person's consent (`reference/adr/ADR-006-third-party-data-capture.md`). Full model: `reference/data-model.md`.
- **Satisfaction-layer homes.** Per-event status → `outputs/event-status.md` (persists across re-runs). Coverage metrics → `outputs/satisfaction-metrics.md`. Derived per-traveler model + desire-overlap → `outputs/traveler-model.md`. None of these belong in trip-context.md or in the rebuilt venue-matrix.md. Full data architecture: `reference/data-model.md`.
- **Satisfaction metrics — define the dimensions, not the scoring.** `outputs/satisfaction-metrics.md` tracks six named coverage dimensions, each of a fixed type — emitted by the hub (per-traveler coverage read) and the validator (audit report), never scored at this layer. **Needs-compliance** is **pass/fail** per need per applicable day (each need category honored every day it applies — the applicable days being the days its governing constraint governs **intersected with that traveler's at-destination day set**, so no need is graded on a day its traveler was not at the destination; the structured, recorded form of the every-applicable-day hard-constraint audit, *not* a balance score). Its agreement with constraint-compliance is **forward-only**: every needs-compliance `fail` is a constraint Critical, but a trip-level/group constraint with no linked per-traveler need yields a constraint Critical with no needs-compliance row by design. **Desire-coverage** is **covered / not** per traveler per desire (each anchor/wish met by the plan or not — a boolean, not a degree). **Group-equity**, the four **experience axes** (creativity, fun, excitement, newness), **rest-recovery balance**, and **meal-variety concentration** (per day) are named **balance signals** to track — their scoring (formulas, weights, thresholds) is **left to design**, since nothing in the satisfaction layer optimizes yet. Full dimension set, types, and artifact shape: `reference/data-model.md` → Satisfaction Metrics.
- **Per-event status — only `planned` changes freely.** Every placed event carries exactly one status in `outputs/event-status.md`: `planned` (working state, open to iteration, may still need a booking), `locked` (booked/confirmed, preserved), `firmed` (settled with nothing to book, preserved), or `option` (an alternative/bailout — never a primary slot). Iteration and resequencing change only `planned` events; `locked`/`firmed` are preserved unless the user names them; an `option` is never auto-promoted into a primary slot (that is a deliberate user act). A booking that falls through regresses `locked → planned` (the event re-opens and its booking question reopens), and an event removed from the itinerary has its row **deleted** (the one deletion persist-mutable permits — no ghost row). The **Event ID is opaque and day-independent** (the hub mints it on first placement; it is the cross-run join key and must not encode the day). "Needs booking" derives from status — `planned` **and** `requires booking? = yes` — so `firmed`/`locked`/`option` never read as "needs booking" (an `option` may still carry `requires booking? = yes` as a bookable backup; its flag takes effect only on promotion to `planned`), and "all events locked" means no `planned`-needs-booking event remains. This structured per-event layer supersedes the coarse free-text `## Locked Elements` notes in trip-context.md (which stay as the **operator-maintained** trip-level human summary, not an agent-written field) as the source of truth for the scheduler, hub, and validator. Field-shape decision and full model: `reference/data-model.md`.
- **Engine producer/consumer convention (R1–R4).** The three optimizer engines (geographic routing, experience, attention) each **produce** their objective as a signal in their own host agent's output file — no engine writes synthesis logic into `agents/05-hub-planner.md` (R1); each output file keeps **one writer**, so engines sharing a file serialize on it (R2); the **hub consumes and reconciles all three exactly once**, in the "Spoke conflict protocol" objective-reconciliation clause — engines only append their signal to the hub's Required inputs, never editing the synthesis flow (R3); and the **validator consumes too**, adding audit checks to `agents/06-validator.md` under the same read-only pattern, never hub edits (R4). Full convention: `reference/data-model.md` and the hub's objective-reconciliation clause.
- **Link, don't copy — one source per fact.** Trip-level constraints stay in trip-context.md `## Hard Constraints` / `## Dietary & Health` (the constraint SSOT). Per-traveler files own per-traveler desires and need-specifics. The enrichment agent *links* a traveler's need to the governing constraint via "Applies to" — it never duplicates the constraint text. A fact has exactly one owner.
- **Venue deduplication.** No venue appears as an anchor on one day and an alternative on another. Max 2 appearances total across the full itinerary. The hub builds venue-matrix.md to enforce this BEFORE writing the itinerary.
- **Hub builds reference files first.** links-reference.md and venue-matrix.md are built before the day-by-day itinerary — not after.
- **Every 3+ hour outdoor block needs a bailout.** A named indoor venue with address, walking distance, and hours. Not a suggestion to "find somewhere nearby."
- **Alternatives must vary on two axes.** Price tier AND effort level. Three options at the same price and walk-in status provide no real choice.
- **Hard constraints are audited every day.** The hub checks. The validator double-checks. A constraint violation in the final output is a system failure.
- **Closure days matter.** Every venue needs a day-of-week closure check against the day it's scheduled. The validator catches these but the spoke agents should note them.

## File Structure

```
travel-planner/
├── CLAUDE.md               ← you are here
├── agents/                 ← agent behavioral definitions (the knowledge base)
│   ├── 00-enrichment.md
│   ├── 01-activities.md
│   ├── 02-food.md
│   ├── 03-scheduling.md
│   ├── 04-transport.md
│   ├── 05-hub-planner.md
│   ├── 06-validator.md
│   ├── 07-nightlife.md
│   └── destination-ideation.md
├── reference/              ← engine reference specs
│   ├── data-model.md              ← satisfaction-layer data architecture (storage homes, reconciliation, lifecycle)
│   └── site-layout-spec.md        ← travel-site responsive/layout specification
├── scripts/                ← publish-trip-site.sh (private publish) + test-publish-guard.sh
├── templates/
│   ├── trip-context.template.md
│   └── traveler-intake.template.md   ← per-traveler profile form (blank; copied per traveler into the git-ignored trips/.../travelers/)
└── trips/
    └── [destination-year]/ ← one folder per trip
        ├── trip-context.md            ← source of truth for the trip
        ├── trip-log.md                ← decision history, session bridge
        ├── travelers/                 ← per-traveler source files (gitignored), one .md per traveler — human-authored
        └── outputs/
            ├── destination-shortlist.md ← ranked group shortlist (IDEATION, pre-destination)
            ├── activities-list.md     ← accumulates across sessions
            ├── food-list.md           ← accumulates across sessions
            ├── nightlife-list.md      ← accumulates across sessions
            ├── scheduling-framework.md
            ├── transport-brief.md
            ├── links-reference.md     ← rebuilt by hub each synthesis
            ├── venue-matrix.md        ← rebuilt by hub each synthesis
            ├── traveler-model.md      ← [DERIVED] reconciled per-traveler model + desire-overlap (rebuilt from source files)
            ├── event-status.md        ← per-event status — persist-mutable, survives re-runs
            ├── satisfaction-metrics.md ← coverage metrics (validator + hub)
            ├── final-itinerary.md     ← current version (previous versions preserved as v1, v2...)
            ├── validation-report.md
            └── [destination]-travel-site.html   ← bespoke, Claude-generated
```
