# Changelog

All notable changes to the travel-planner engine are documented here. The format
follows Keep a Changelog; versions follow Semantic Versioning.

## [0.6.0] — 2026-07-01 — Destination ideation

The front of IDEATION: help a group decide *where* to go before any destination
is fixed. From each traveler's individual destination leanings, the planner now
derives one ranked group shortlist to choose from — so a trip can start at "we
don't know where to go yet" instead of assuming a destination is already picked.

### Added
- **Destination Ideation agent (`agents/destination-ideation.md`)** — reads every
  traveler's destination leanings (`Would love` / `Rather skip` / `Trip vibe`) and
  writes `outputs/destination-shortlist.md`, a ranked group shortlist. Ranking is
  **equity-weighted coverage**: love-count adjusted so every traveler is
  represented near the top, `Rather skip` as a hard veto, and `Trip vibe` as the
  rationale. It recommends only — the group decides, nothing auto-picks — and hands
  off to DISCOVERY once a destination is chosen.
- **Worked example (`examples/ideation-demo/`)** — a four-traveler run showing the
  ranked shortlist, an applied veto, and the equity case (a lone-lover destination
  kept that a popularity-only ranking would drop).

### Notes
- Realizes the data model's forward-hook (a): the per-traveler files still only
  *capture* leanings; the aggregation lives in the new agent, never in an
  individual file. Enrichment and the data model were updated to point at the
  now-realized hook.
- Ships the destination-ideation seed (group destination recommendation). A fuller
  ideation flow (group shortlist → group decision → DISCOVERY handoff) remains
  documented future growth.

## [0.5.0] — 2026-07-01 — Publish-flow privacy & lifecycle

Rounds out the private-publish flow (v0.1.0) with the privacy and lifecycle
controls a real "site manager" needs: hide the destination in the repo name, see
every published site at a glance, and take a site back down.

### Added
- **Opaque repo names (`publish --opaque`)** — name the per-trip repo with a random
  token (e.g. `trip-a1b2c3d4e5`) instead of the readable `[destination]-[year]-trip`,
  so the destination and year no longer show on your public profile. The name is
  saved to `.publish-slug`, so `update`/`rotate`/`unpublish` resolve the same repo.
  Readable names stay the default (opt in per publish).
- **`list` — published-site inventory (read-only)** — one command shows every trip
  under `trips/`: its repo, live URL (or "not published"), last-published vs
  last-edited, and a **stale** flag when your local build is newer than what's
  deployed. Never writes, encrypts, or pushes.
- **`unpublish` — takedown** — take a published site down: by default it deletes the
  per-trip repo (removing the site *and* the destination/year in its name), or
  `--disable-pages-only` keeps the repo and just takes the site offline. It confirms
  before an irreversible delete, is idempotent (a no-op if already gone), and is
  honest that content may linger in third-party caches after takedown.

### Notes
- Deleting a repo needs the `delete_repo` gh scope (`gh auth refresh -h github.com -s delete_repo`);
  `unpublish` says so and offers `--disable-pages-only` as the no-extra-scope path.
- The privacy model is unchanged: published bytes are world-fetchable ciphertext
  (secret-gated by passphrase + 600k-KDF, not access-controlled). `--opaque` closes
  the repo-name metadata leak; commit timestamps still reveal publish activity.
- Regression tests extended (`test-publish-guard.sh` groups H/I/J) covering opaque
  naming, the inventory helpers, and the takedown safety gates.

## [0.4.0] — 2026-07-01 — Orchestration: equity-aware planning & replanning

The group planner that runs all three optimization engines and reconciles them
into one itinerary — and, when plans fall through or someone's wishes change,
rebuilds it fairly instead of grabbing any replacement. Built on v0.3.0's engines;
this is the layer that makes them work together for the whole group.

### Added
- **Equity-aware planning** — the planner runs the routing, experience, and
  fair-coverage engines together and reconciles where they disagree (a tight route
  vs. protecting one person's must-see vs. a needed rest day) into a single plan —
  everyone's needs applied first as hard limits, plus a per-traveler view of who is
  served and where the trip is lopsided. When the objectives collide, the tradeoff
  is named and shown, never silently dropped.
- **Equity-aware replanning ("who lost what")** — when a booking falls through, or
  a traveler edits their profile (a new must-see, a dropped wish), the planner works
  out who lost the most, rebuilds toward them first, and regroups the scattered gaps
  into one coherent thread rather than unrelated swaps — keeping everyone's needs
  intact through the recovery.
- **Side-bars / group splits** — when someone wants their own time, or interests
  diverge enough, the planner proposes single / small-group / full-group side-bars
  instead of dragging everyone along or leaving anyone out. The default stays one
  shared plan, and any moment a traveler marks whole-group is never split off.

### Notes
- The *structure* ships here; the *scoring* is deliberately deferred — how the three
  objectives rank, how "hardest-hit" and "enough divergence" are measured, and how
  gaps cluster into a theme are left to a later design pass. Nothing scores yet; the
  planner reasons with the structure and shows its work.
- Every recovery and every side-bar still honors each traveler's needs as hard
  floors — a split or a rebuild never becomes a way to slip a need violation through.

## [0.3.0] — 2026-07-01 — Optimization engines

The first engines that actually *optimize* a trip against the satisfaction
substrate. Each one works a single objective and surfaces its read for the group
planner to weigh — built on v0.2.0; the planner that runs all three and reconciles
them across the whole group comes next.

### Added
- **Geographic routing** — treats travel between stops as a real, minimizable
  cost: it orders each day so the group spends less time in transit and more time
  at the places, surfaces that cost so one plan can be compared against another,
  and spends any freed time on a single deliberate use. It never routes a traveler
  through a must-avoid (a heat window, a mobility limit).
- **Experience balance** — shapes how the trip *feels* across the days, not just
  how tiring it is: it spreads new and exciting things out instead of front-loading
  them, and avoids stacking too many big days back-to-back with no breather.
  Required rest (a real need) is always protected.
- **Fair coverage** — makes sure the plan serves everyone, not just the majority:
  a want several travelers share is an easy win, while a want only one person holds
  is protected so no one is quietly left out. It works on wants only — must-haves
  are always met.

### Notes
- These engines *surface* their objective; the group planner that runs all three
  and reconciles them (efficient routing vs. everyone's coverage vs. the trip's
  arc) is the next release — equity-aware planning.
- Every engine optimizes *within* each traveler's hard needs. Needs are floors,
  never traded away for a better score.

## [0.2.0] — 2026-06-28 — Satisfaction substrate

A structured foundation for understanding what each traveler wants and tracking
what's settled — so trips can be planned for the whole group and picked up from
any stage. Foundation only: nothing optimizes yet.

### Added
- **Per-traveler profiles** — each traveler gets their own intake form (fill it
  yourself, or have an agent walk you through it): needs (must-haves), desires
  (anchor / wish / nice-to-have), plus destination leanings, dates, budget,
  travel style, interests, and people-dynamics. All optional — fill what fits
  your trip's stage.
- **Per-event status** (`planned` / `locked` / `firmed` / `option`) — re-running
  the planner refines only what's still open and leaves booked or settled
  choices alone.
- **Satisfaction metrics** — defined dimensions: needs-compliance (pass/fail),
  desire-coverage, and balance signals for equity, experience, and rest.
- **Data-model document** — the canonical architecture for the satisfaction
  layer (storage homes, reconciliation, lifecycle).

### Changed
- Iteration and resequencing touch only `planned` events; `locked` / `firmed`
  events are preserved unless you name them, and the validator flags any
  unintended change.

### Notes
- Per-traveler data stays in private, git-ignored working files and is never
  published.
- This release is substrate — nothing optimizes yet. The optimization engines,
  equity-aware (re)planning, group side-bars, and destination ideation build on
  it next.

## [0.1.0] — 2026-06-28 — Private-by-default trip sites

- Published trip sites are encrypted client-side and private by default — only
  ciphertext is pushed to the public per-trip repo, gated by a passphrase, so a
  trip's details are never world-readable.
- A fail-closed pre-push guard refuses to publish anything but verified
  ciphertext.
