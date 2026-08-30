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
*content*. **Section shape is not content depth**, so the ten sections
`agents/04-transport.md` § *Output Format* declares are all present below, in its order
and under its names.

**Entry marker.** C9 is prose-shaped and its entity is the **Leg**, so its marker key
is `leg: leg-<token>` — a third entity key across the entry-bearing set, alongside C5
/ C7 / C18's `venue:` and C8's `day:`.

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
```

May 14 (Thu). Arrival ~13:00; accommodation from 14:00, which is what makes the arrival
day a half day rather than a full one.

### Payment & Transit Card Setup

Not exercised — this fixture records no fares, so there is no payment product to
compare. On a real trip this section carries the card or app the group buys and where.

### Pass Assessment

Not exercised, and correctly so rather than by omission: a multi-day transit pass is
assessed against expected ride volume, and this trip's ride volume is zero. Everything
is walked.

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
```

May 17 (Sun). Afternoon flight, depart accommodation ~13:00 — which is what leaves
Sunday a usable morning and lets the riverside walk and the anchor breakfast be placed
at all.

---

**Single origin, one group booking**, so there is exactly one outbound and one return
leg and no per-traveller variation to reconcile. This is the shape
`examples/two-origin-demo/` exists to contrast: there the party does not share one
booking, and the leg set is not derivable from the trip level alone.

**`accumulate-append`, and this instance carries one dated section.** See `README.md`
§ *The accumulate-append criterion* for why four of the six instances are left at one
rather than leaving `reference/data-architecture.md` § 10's criterion silently unmet.
