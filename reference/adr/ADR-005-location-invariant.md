# ADR-005: Location invariant — every itinerary event carries a standard, validator-gated map link

- **Status:** Accepted (2026-07-26)
- **Deciders:** repo maintainer
- **Driving work:** the Faithful site rendering epic (#67); foundational invariant consumed by the split-day component and the plan/site unification slices.

## Context

A trip site is a navigation tool: on the ground, a traveler taps a venue to route to it. Today the
map treatment is not standardized. The site design system renders map links four different ways —
a map pill bundled with website/tickets in the featured-stop link cluster, a link embedded in the
mini-card's venue name, a food-card link cluster, and a night-card link line — each with a
different name and position. Nothing enforces that a card *has* a map link, so some events ship
with none; worse, the featured-stop map pill is hidden by the desktop compact-hide rule that
collapses the whole link cluster.

The itinerary already has a precise notion of an "event" — the roster of placed venues keyed in
`outputs/event-status.md` (an anchor activity, an anchor meal, a day trip, a fixed reservation) —
and a single source of truth for venue links, `outputs/links-reference.md`, which the hub builds
and the validator already treats as its primary audit target. What is missing is a contract tying
the two together: one map-link treatment, sourced from that SSOT, present on every event, and
audited so a gap fails the trip rather than surfacing on the ground.

This invariant is foundational rather than cosmetic because two sibling slices in the same epic
build on it: the split-day component (each per-track venue must be an event that carries a map
link) and the plan/site unification work (which round-trips the event roster and the link SSOT).
Fixing "what counts as an event, and what link it must carry" once — here — stops those slices
re-deriving it inconsistently.

## Decision drivers

- One treatment, not four — a single standard component removes the per-tier drift and the
  "some cards have no map link" gap.
- Reuse the existing event population and the existing link SSOT; do not invent a second roster
  or a second source of venue URLs.
- The map link must survive the desktop compact-hide — a reader must reach any venue without
  expanding the card.
- The invariant must be *enforced*, not merely documented: a missing link is a completeness
  failure of the same class as a missing bailout.

## Options considered

1. **Leave the per-tier treatments; add a "should have a map link" note.** Rejected: documents an
   aspiration without enforcing it — the exact gap this slice exists to close. Nothing catches a
   missing link before departure.
2. **Standardize the component but keep it inside each tier's existing link cluster.** Rejected:
   the featured-stop cluster (`.act-links`) is hidden by the desktop compact-hide, so a child map
   link disappears in the default desktop view — the invariant would silently not hold when it
   matters most.
3. **A single standard `.map-link`, a DOM sibling of each tier's link cluster, sourced from the
   link SSOT and gated by the validator.** Chosen — see below.

## Decision

### 1. What counts as an event

An *event* is any itinerary element that names a venue with a physical location and renders as a
card — a featured stop, a mini / alternative / bailout card, a food card, or a night card,
including each per-track venue on a split day. Every event is a place a traveler navigates *to*, so
every event card carries exactly one map link. Transit connectors (the mode-and-time transit
field, route/direction links) describe movement *between* events, not a destination, and carry no
map link. This is the event population already keyed in `event-status.md` — not a new one.

### 2. The standard `.map-link` component

All tiers render the same element — a single `.map-link` anchor (a pin glyph + the label "Map").
Its `href` is read from `outputs/links-reference.md`, never hand-authored per card: the venue's
Google Maps URL, or its official-site URL as the fallback when the venue has no map pin (an in-park
venue, or a service reachable only via an official page). One venue therefore resolves to one URL
everywhere it appears. The `.map-link` sits **adjacent to** each tier's existing website/tickets
cluster as a **sibling, not a child**, which keeps it visible when the desktop compact-hide
collapses that cluster — with no change to the collapse CSS. Website/tickets/booking affordances
are unchanged; only the map link is standardized.

### 3. The validator gate

The validator builds the event roster and, for every event, confirms it resolves to a link in
`links-reference.md` and that its card renders that link. An event with no resolvable entry, or a
card with no rendered map link, is a **Critical** finding. Because the validator's contract already
holds that a Critical must be resolved before an itinerary is finalized, a trip with a missing link
**fails validation** — no new gating machinery is introduced; the invariant rides the existing
Critical semantics.

## Consequences

**Positive**

- One map treatment across all card tiers, sourced from a single SSOT — the four scattered
  treatments and the "no map link" gap are retired.
- The link is reachable even on a compact desktop card, by construction (sibling, not child).
- The invariant is enforced, not just described: a missing link is caught before departure.
- The split-day component and the plan/site unification slices consume this invariant — "each
  per-track venue is an event carrying a map link" and "the event roster resolves against the link
  SSOT" are settled once, upstream of both.

**Trade-offs**

- The mini-card DOM changes: the venue name becomes plain text and the map link moves to the
  sibling `.map-link`. A one-time, contained change.
- The map link's quality is only as good as `links-reference.md`; keeping that file complete and
  correct remains the hub's job. Fuller plan↔site round-tripping is deferred to the unification
  slice.
- Inserting the validator priority renumbers the tail of the priority list (cosmetic).

## References

- Site render contract: `reference/site-layout-spec.md` → Map-Link Component (§3) and the
  compact-hide rules (§4).
- Validator gate: `agents/06-validator.md` → Priorities, "Location-link completeness", Validation
  Summary, and the Location-Link Report.
- Link SSOT: `outputs/links-reference.md` (built by `agents/05-hub-planner.md`); event roster:
  `outputs/event-status.md` (see `reference/data-model.md`).
