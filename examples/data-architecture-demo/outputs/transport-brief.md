---
artifact: outputs/transport-brief.md
schema-version: 1
trip: data-architecture-demo
writer: transport
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-28
---

# Transport Brief — Porto

> **Illustrative, sanitized example. Not a real trip.** Transport details are
> illustrative.

**Depth: tier 2 — the migrated-shape minimum.** See `README.md` § *Depth*.
`examples/tokyo-2026/outputs/transport-brief.md` is the worked example for this class's
*content*. **Section shape is not content depth**, so the eleven sections
`agents/04-transport.md` § *Output Format* declares are all present below, in its order
and under its names.

**Entry marker.** C9 is prose-shaped and its entity is the **Leg**, so its marker key
is `leg: leg-<token>` — a third entity key across the entry-bearing set, alongside C5
/ C7 / C18's `venue:` and C8's `day:`. Both markers also carry a `cost:` line, because
`agents/04-transport.md` emits the field from this release.

**This class is the one that needs a basis selection rule, and both streams below show
why.** Its `**Cost:**` label writes **both** bases on one line, and the marker grammar
admits one `cost:` line — so `reference/adr/ADR-018-cost-estimation-method.md`
§ *Decision 4* fixes it: `per-person` where the line states a per-person figure,
`group-total` only where it does not. The arrival stream's label states both, so its
marker carries `per-person`; the departure stream's label declares only a group total,
so its marker carries `group-total`. **One class, two bases, and the difference is read
off the prose rather than chosen.**

## This file hosts no optimizer signal, and that is the correction

**The three optimizer engines are routing, experience and attention**, and
`CLAUDE.md` § *Key Rules* → R1 binds each to produce its objective **in its own host
agent's output file**. The transport agent hosts none of them. What it produces is the
*input* the routing signal is computed from — group-adjusted door-to-door times, in the
*Point-to-Point Transit Matrix* below — and `agents/03-scheduling.md` § *Transit Cost &
Routing Signal* is where the routing objective is emitted, from those numbers.

A transport brief carrying a "geographic routing signal" would put an engine's
objective on a file whose writer does not own it. It also breaks the read direction: a
signal is something the hub *consumes and reconciles once*, and the hub reconciles the
routing signal from the scheduler's file, not from this one.

## Legs and navigation (2026-08-28)

### Destination Transport Character

A compact centre with a walkable core. Everything this trip places is reached on foot or
by lift-served transit from one base, so no placement was excluded on mobility grounds
and no day requires a cross-city transfer.

### Arrival Transport

#### Outbound — Origin to OPO

```artifact-entry
leg: leg-04a1
cost: 25 EUR per-person
```

**Passengers:** Alex, Robin, Sam
**Cost:** €25 / ~$28 per person, €75 / ~$83 group total

May 14 (Thu). Arrival ~13:00; accommodation from 14:00, which is what makes the arrival
day a half day rather than a full one.

**Luggage handling.** That hour is the pre-check-in window, and it is planned rather
than left standing: three travelers on one booking, their own bags, and no room yet.
The bags are carried to the base and held there until check-in — an hour does not
justify a storage run, and the base is reached on foot on this walkable core. Where the
property could not hold them, the fallback here is left-luggage at the arrival station.
No forwarding service is priced on this fixture, and a single short transfer gives one
nothing to save.

### Payment & Transit Card Setup

**Recommended:** the rechargeable city transit card, bought and topped up at any station
machine. Single fares are loaded onto it rather than bought as paper tickets.

**This section names an instrument and not an amount, which is the split the estimate
depends on.** `outputs/cost-estimate.md` takes its preload *figure* from § *Pass
Assessment* above and the *card it goes on* from here, so a recommendation that names a
number would give one value a second home. The card is a synthetic product, like every
other value this fixture carries.

### Pre-Departure Transit Familiarization

Present and thin, which is the tier-2 shape rather than an omission. This is what a
traveler reads *before* leaving: § *Payment & Transit Card Setup* above holds the
purchase procedure and § *Daily Navigation* below holds the apps and the in-trip
mistakes, so nothing here restates either.

**Fare model:** Partly exercised. This fixture now records a synthetic per-journey fare
and a card price, because § *Pass Assessment* below cannot be assessed without them —
but it states **no zone, transfer window or reduced-fare rule**, and those are what a
fare model actually is. On a real trip this carries the mental model: how a fare is
computed, and what forfeits a transfer.

**Conventions & etiquette:** Not exercised as destination research. The one movement
constraint this plan does carry is stated where it binds — the `HC-1` walkability
requirement in *Daily Navigation* below — rather than duplicated here.

**Primer resources:** Not exercised. The shape a real brief carries is one line per item,
and **external links are not reproduced** — `README.md` § *Depth* excludes them from the
tier-2 minimum, so these carry the entry shape and no live URL.

- [Publisher's own "how to ride" page] — [Transit authority] · [web, ~5 min] — [ticket
  types and the validation rule]
- [Short system explainer] — [Named publisher] · [video, ~6 min] — [what the lines are
  and how they interchange]

### Pass Assessment

- Estimated journeys: 2 over 4 days — the one lift-served hop to the museum, out and
  back. Everything else this plan places is walked.
- Per-journey cost: €2 / ~$2.20
- Pass cost: €18 / ~$20 for the 4-day card
- Break-even: 9 journeys
- **Verdict: no pass.** Two journeys at €2 is €4 against an €18 card, so single fares
  win by a wide margin — this is not a close call the traveller has to weigh.

**This section is filled so `outputs/cost-estimate.md` has a preload source, and the
verdict it gives is the one that exercises the harder limb.** Where a verdict recommends
the pass, preload simply *is* the pass cost. Where it does not — as here — preload is
apportioned journeys times per-journey cost, which is the arithmetic above and is what
the estimate's *Preload* line carries. **A previous revision of this section declared
this trip's ride volume zero**, which the *Point-to-Point Transit Matrix* below has always
contradicted: it carries a lift-served hop as *the trip's one longer hop*. The count is
corrected here rather than left standing.

### Hotel-Area Transit Reference

One base, central. The nearest stops are within the walkable core; specific line names
and stop distances are content this fixture does not carry.

### Point-to-Point Transit Matrix

| From | To | Mode | Group door-to-door | Notes |
|------|----|------|--------------------|-------|
| Base | Baixa core | Walk | short | Level throughout — clears `HC-1` |
| Base | The museum, west | Lift-served transit | the trip's one longer hop | Lift at both ends |
| Base | Ribeira riverside | Walk, downhill out | short | Level or ramped return |

**This table deliberately carries no entry marker, and that is a decided case rather
than an omission.** `reference/data-architecture.md` § 4.5 rules on it by name: *a
secondary table inside a fence-form class carries no marker*. The marker form is
assigned per **class** and attaches to that class's entries — the prose-shaped leg
stream above and below — not to every table the artifact happens to hold. Giving one
class both marker forms would make the marker a property of a surface rather than of a
class, and nothing would then tell a reader which surface to check.

**What that costs, stated rather than deferred.** These door-to-door durations are the
highest-value join this class has — `agents/03-scheduling.md` § *Transit Cost & Routing
Signal* reads them numerically — and they carry no key, so a consumer matches on the
stop pair **as written**, with exactly the display-string fragility the venue key exists
to escape. Assigning a key there is an identity decision for a later ADR, not a
body-shape rule; until one is taken the matrix is written as its prompt writes it today.

### Daily Navigation

All eleven placements are reached on foot or by lift-served transit, which is the
`HC-1` requirement. **In-destination movement carries no leg keys** — the two keyed legs
are the booked flights. A walked approach between two placements is not a Leg entity in
this model, and minting tokens for walks would put entities in the file that the model
does not define.

### Taxi & Rideshare

Available and not needed by any placement on this plan. Recorded so a reader does not
read the absence as an oversight: a plan that walks everywhere still states what the
fallback is.

### Day Trip Logistics

None — this trip places nothing outside the city. A four-day window with two partial
days has no day trip in it.

### Departure Logistics

#### Return — OPO to Origin

```artifact-entry
leg: leg-9f3c
cost: 75 EUR group-total
```

**Passengers:** Alex, Robin, Sam
**Cost:** €75 / ~$83, group total

May 17 (Sun). Afternoon flight, depart accommodation ~13:00 — which is what leaves
Sunday a usable morning and lets the riverside walk and the anchor breakfast be placed
at all.

**This marker is the fixture's `group-total`, and the `**Passengers:**` line above is
what makes it allocable.** The departure label declares only a group total, so the
selection rule gives the marker `group-total`; the estimate then divides it across
**this stream's own participant set**, which that line names. Had the set not been
resolvable, the rule is that the figure is **not** divided by the roster — it lands on a
named `unallocated group-total` line instead. Single origin and one booking is why that
line is empty on this trip; `examples/two-origin-demo/` is the shape where it would not
be.

**Luggage options.** Check-out is 11:00 and the party leaves at ~13:00, so there are two
hours of Sunday morning in which the bags are out of the room and the group is not yet
travelling. They go into the property's hold at check-out and are collected on the way
out; that is what keeps the riverside walk placeable *after* check-out instead of
forcing it ahead of breakfast. The collection stop and the minutes it takes to get three
people and their bags moving sit inside the departure buffer, not beside it. No
forwarding service is priced on this fixture; the airport run is one transfer.

---

**Single origin, one group booking**, so there is exactly one outbound and one return
leg and no per-traveller variation to reconcile. This is the shape
`examples/two-origin-demo/` exists to contrast: there the party does not share one
booking, and the leg set is not derivable from the trip level alone.

**`accumulate-append`, and this instance carries one dated section.** See `README.md`
§ *The accumulate-append criterion* for why four of the six instances are left at one
rather than leaving `reference/data-architecture.md` § 10's criterion silently unmet.
