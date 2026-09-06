# ADR-001: Dedicated nightlife agent — roster placement, producer/consumer boundary, per-night coverage

- **Status:** Accepted (2026-07-12)
- **Deciders:** repo maintainer
- **Driving work:** the nightlife-agent epic (#59); this ADR is its milestone-head decision gate (#65).

## Context

The planner dispatches a roster of specialist research and assembly agents. Evening
and going-out coverage is currently split and partly gapped:

- Activities (`agents/01-activities.md`) owns an "Evening & Mixed-Group Options" section.
- Food (`agents/02-food.md`) owns dining, including food-forward drinking venues
  (izakaya, mezcalerías, dining wine bars) that legitimately appear as destination food categories.
- No agent consistently owns **pure nightlife** — cocktail/wine bars *as bars*, clubs,
  live-music venues, pubs, late-night lounges. This falls into the gap between the two
  spokes or is inconsistently picked up by the Activities evening section.

Adding a dedicated nightlife research spoke (`agents/07-nightlife.md`) is a cross-cutting
change to the roster and the dispatch pipeline, so three questions must be decided once,
before feature slices are cut under the nightlife epic. This is also travel-planner's
first ADR, so it establishes the `reference/adr/` convention documented in
`reference/adr/README.md`.

## Decision drivers

- **Coverage gap** — pure nightlife has no consistent owner today.
- **Group-fit** — the same engine serves families, early risers, and dry travelers as
  well as nightlife-seeking groups; nightlife must never be force-scheduled.
- **Non-duplication** — the hub already dedupes venues (`venue-matrix.md`); a new spoke
  must not double-schedule or double-list a venue.
- **Minimal blast radius** — prefer additive change over renumbering the existing roster.

## Options considered

1. **No new spoke — extend Activities' evening section.** Rejected: leaves the food/nightlife
   boundary ambiguous and overloads a spoke already responsible for daytime curation.
2. **New spoke, inserted as `agents/03-nightlife.md` (renumber 03–06 → 04–07).** Rejected:
   cleaner numeric ordering but cascades renames across every agent file and cross-reference
   for no functional gain — the hub dispatches by role, not filename.
3. **New spoke appended as `agents/07-nightlife.md`, dispatched in the research phase.**
   Chosen — see below.

## Decision

### 1. Roster placement & dispatch order

Add `agents/07-nightlife.md` as a **research/curation spoke** that produces
`outputs/nightlife-list.md` and does **not** schedule. It dispatches in the **research
phase**, alongside Activities (01) and Food (02), and before Scheduling (03) and Hub
synthesis (05). The numeric prefix `07` is a registry identifier, **not** a strict
dispatch rank — the roster already carries an unnumbered `agents/destination-ideation.md`, and
the hub dispatches spokes by role.

### 2. Producer/consumer boundary with Food & Activities

Ownership is decided by a venue's **primary draw**:

- **Nightlife owns** going-out venues: cocktail/wine bars *as bars*, clubs, live-music
  venues, pubs, late-night lounges.
- **Food keeps** eating venues, including food-forward drinking where the point is a meal
  or tasting (izakaya, mezcalerías, dining wine bars).
- **Activities narrows** its "Evening & Mixed-Group Options" to non-nightlife evening
  experiences (sunset viewpoints, evening tours, family-friendly shows).

A venue that plausibly fits two spokes is claimed by the one matching its primary draw and
**cross-referenced, never duplicated**, by the other. The hub's existing `venue-matrix.md`
dedup rules (no venue as anchor on one day and alternative on another; no venue appearing
more than twice) arbitrate scheduling.

### 3. Per-night rule & validator coverage

Nightlife is **desire-gated and optional by default**. On a given night, nightlife options
are surfaced when a **present** traveler holds a nightlife/evening desire, or a natural
occasion applies (weekend, special occasion). Nightlife is offered as an optional per-night
entry, **never a forced anchor**, unless a traveler's desire tier elevates it to an anchor
for that traveler.

The validator (`agents/06-validator.md`) gains a **per-night nightlife coverage check** that
slots into the existing per-applicable-day needs/desire-coverage model: for each night where
nightlife is desired or expected, confirm a nightlife option is present, or an explicit
"no nightlife tonight — [reason]" note (rest day, early start, no present desire). The site
already renders a `.night-card` type (`reference/site-layout-spec.md`), so no new render
primitive is required.

## Consequences

**Positive**

- Pure nightlife gets a consistent owner; the coverage gap closes.
- Group-fit preserved: desire-gating lets the traveler's own intake set nightlife
  aggressiveness — no group is pushed into nightlife it did not ask for.
- Additive: no roster renumbering; existing cross-references are untouched.
- Validator and site render **extend** existing structures rather than adding new primitives.

**Trade-offs**

- The Food/Activities boundary is a heuristic ("primary draw"), not a hard rule; it may need
  tuning after the first few real trips.
- A new spoke adds a research pass (more time/tokens per plan); mitigated by nightlife being
  skippable when no present traveler desires it.
- Desire-gating depends on intake capturing a nightlife/evening desire; if intake
  under-captures it, nightlife may under-fire — revisit alongside the traveler-intake epic.

## Follow-on build slices (out of scope for this ADR; tracked under the nightlife epic)

- Author `agents/07-nightlife.md` (the research-spoke prompt).
- Narrow Activities' "Evening & Mixed-Group Options"; add the nightlife cross-reference note
  to Food and Activities.
- Extend `agents/06-validator.md` with the per-night nightlife coverage check.
