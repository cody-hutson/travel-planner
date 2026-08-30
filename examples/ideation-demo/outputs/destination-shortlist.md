---
artifact: outputs/destination-shortlist.md
schema-version: 1
trip: ideation-demo
writer: destination-ideation
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal
generated: 2026-08-29
---

# Group Destination Shortlist [DERIVED]
> A recommendation derived from every traveler's destination leanings.
> The group decides — nothing here picks a destination.

## Shortlist (ranked)
1. **Portuguese coast** — loved by 2 of 4: Ana, Cyra.
   Vibe: matches Ana's food + coastal and Cyra's nature + food; Ben's city +
   culture leaning is less served here.
   Rationale: highest coverage among surviving candidates and it anchors two
   travelers' top leanings, including Ana's slow-mornings/coastal vibe.
2. **Japan** — loved by 2 of 4: Ben, Cyra.
   Vibe: matches Ben's city + culture and Cyra's nature + food.
   Rationale: ties Portugal on love-count and is Ben's only surviving loved
   option (Italy was vetoed), so it also carries a coverage role for him.
3. **Iceland** — loved by 1 of 4: Dev.
   Vibe: matches Dev's nature + quiet, few-crowds leaning; less aligned with the
   food/city vibes of the others.
   Equity note: **retained for coverage** — Iceland is the *only* destination
   Dev loves that survived the vetoes. Ranking on popularity alone would drop it
   and leave Dev with nothing on the shortlist; equity-weighted coverage keeps
   it so every traveler is represented.
   Rationale: lower love-count than the top two, but sole representation for Dev.

## Vetoes applied (Rather skip)
- **Italy** removed — Dev would rather skip it (been twice recently).

## Conflicts & coverage
- **Italy** was loved by Ana and Ben but vetoed by Dev — so it is **not**
  shortlisted. The group may override the veto if Ana and Ben feel strongly and
  Dev is willing; that is a group conversation, not something this shortlist
  decides.
- Coverage: every traveler has at least one loved candidate on the shortlist —
  Ana → Portugal, Ben → Japan, Cyra → Portugal/Japan, Dev → Iceland. Dev is
  represented **only** by Iceland (their sole surviving leaning).
- Cyra's "very hot in summer" skip is a **timing** constraint, not a destination
  veto — whichever destination the group picks, avoid a peak-summer window for
  it (or confirm Cyra is comfortable). Carry this into DISCOVERY.

## Handoff to DISCOVERY
Once the group picks a destination, record it in `trip-context.md` (Destination)
and switch to **DISCOVERY** mode — the itinerary pipeline (enrichment → spokes →
hub → validator) then plans the chosen destination. This shortlist is not a
decision; it is the input to one.
