# Changelog

All notable changes to the travel-planner engine are documented here. The format
follows Keep a Changelog; versions follow Semantic Versioning.

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
