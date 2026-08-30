---
artifact: outputs/scheduling-framework.md
schema-version: 1
trip: data-architecture-demo
writer: scheduling
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-28
---

# Scheduling Framework — Porto

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 2 — the migrated-shape minimum.** See `README.md` § *Depth*.
`examples/tokyo-2026/outputs/scheduling-framework.md` is the worked example for this
class's *content*. **Section shape is not content depth**, so the ten sections
`agents/03-scheduling.md` § *Output Format* declares are all present below, in its
order and under its names — a fixture whose job is to show the migrated shape cannot
drop the writer's declared section set and still be showing it.

**Entry marker.** C8 is prose-shaped and its entity is the **Day**, so its marker key
is `day:` carrying an ISO date — not a venue token, and not the day's ordinal. Two
entry-bearing classes, two different entity keys: the marker carries whatever key
identifies *that class's* entity, which is why the model fixes the form and each
agent prompt fixes the key.

**The key is the ISO date, not `Day 3`.** An ordinal encodes position, and position is
exactly what a resequence changes — the same reason `outputs/event-status.md`'s Event
ID must not encode the day. A date survives a reorder; `Day 3` becomes a lie.

## Which optimizer signals this file hosts, and which it does not

**Two of the three, and they are the routing and the experience signals.**
`agents/03-scheduling.md` § *Output Format* declares both — *Transit Cost & Routing
Signal* and *Experience Balance Signal* — and `CLAUDE.md` § *Key Rules* → R1 binds each
engine to **produce its objective in its own host agent's output file**. So both of
those sections are below, and they are the whole of this file's signal surface.

**The attention signal is not hosted here.** Its host is the desire-overlap signal in
`outputs/traveler-model.md`, which the enrichment agent writes and the hub reads
through the attention lens. A scheduling framework emitting an attention signal would
put an engine's objective on a file whose writer does not own it — the exact
producer/consumer break R1 exists to prevent, and one no check in this repository would
catch.

**Neither is the routing signal hosted in `outputs/transport-brief.md`.** The transport
agent supplies the *inputs* the routing signal is computed from — group-adjusted
door-to-door times — and hosts no optimizer objective of its own. That file says so in
its own terms.

## Initial Framework (2026-08-28)

### Destination Scheduling Profile

A compact centre, four days, one base, no cross-city transfers. Everything on this trip
is reached on foot or by lift-served transit, which is what `HC-1` requires and what
lets a half day still hold two placements.

### Jet Lag & Travel Fatigue Model

Not exercised — the origin is a placeholder, so there is no time-zone delta to model.
The arrival day is short for a scheduling reason rather than a fatigue one: the room
opens at 14:00.

### Hard Constraint Schedule Impact

`HC-2` is the constraint that binds *placement time* rather than venue choice: no
unshaded outdoor block between 13:00 and 16:00. **No outdoor block is scheduled inside
that window on any day** — which is the constraint holding, not the constraint being
idle. It reaches the two days carrying an **afternoon** outdoor block, May 14 and
May 16, and no others: Friday carries no outdoor block, and Sunday's is a morning one.
That is why `outputs/satisfaction-metrics.md` grades Alex's heat need on two days
rather than four.
`HC-1` binds venue choice on every day and never the clock. Robin's rest need floors one
slow afternoon on a full day.

### Group Energy Arc

Low on arrival, medium through the two full days, low on departure. The trip has no
peak day by design: a four-day trip with two partial days has no room for a build.

### Structural Unit Template

A block is one placement plus its approach. A half day holds two; a full day holds two
plus one alternative. This fixture states the unit and does not elaborate it — see the
depth note above.

### Daily Time Block Template

Morning · midday · late afternoon · evening. The midday slot is where `HC-2` bites, so
it takes an indoor placement or none.

### Day-by-Day Framework

#### May 14 (Thu) — arrival, half day

```artifact-entry
day: 2026-05-14
```

Usable from ~14:00. Two blocks plus the anchor meal. The outdoor block is placed after
16:00, so `HC-2` binds the placement time here.

#### May 15 (Fri) — full day

```artifact-entry
day: 2026-05-15
```

Two blocks, both indoor or covered, one of which is the anchor meal. `HC-2` does not
reach this day at all.

#### May 16 (Sat) — full day, deliberately slowed

```artifact-entry
day: 2026-05-16
```

The anchor meal at midday, then one block plus one alternative and the evening. This is
the day the patch changed: the viewpoint moved 14:00 → 16:30 and the block after it was
dropped. `HC-2` binds the new time.

#### May 17 (Sun) — departure, half day

```artifact-entry
day: 2026-05-17
```

The anchor meal, then one morning block; depart accommodation ~13:00. No outdoor block
in the `HC-2` window.

### Transit Cost & Routing Signal

The routing signal the hub consumes. One day is written out here; the other three are
the same shape and are not reproduced at tier 2.

**Day 3 — 2026-05-16 — Saturday**

```artifact-entry
day: 2026-05-16
```

- Ordered stop sequence: lunch room -> viewpoint -> rooftop
- Per-leg transit cost: both legs on foot within the centre; no transfer
- Total transit cost: walking only
- Compared alternative ordering: viewpoint -> lunch -> rooftop, at the same walking
  cost. The recommended sequence is chosen over it because the alternative puts the
  outdoor block back inside the `HC-2` window, which is a needs floor rather than a
  transit saving.
- Needs guardrail: `HC-2` held the viewpoint out of the 13:00–16:00 peak; `HC-1` chose
  the lift-served terrace over a stepped approach.
- Slack allocation: the freed slot was deliberately left empty — that is what the patch
  bought.

**The day key repeats across sections on purpose.** The Day is one entity described
from three angles, and the marker names that entity wherever it is described. Nothing
caps how often an entity key appears; the two-appearance cap is a **venue** rule, and it
counts venue keys in `outputs/venue-matrix.md`.

### Experience Balance Signal

The experience-balance signal the hub consumes. Read qualitatively — Low / Med / High
per axis, never a score.

**Day 3 — 2026-05-16 — Saturday**

```artifact-entry
day: 2026-05-16
```

- Experiential profile: excitement Med · newness Med · fun Med · rest High
- Newness note: the viewpoint and the rooftop are both first-time, and they are the only
  two on this day, so newness is spread rather than clumping.
- Arc placement: recovery — follows a build on Day 2 and precedes a departure morning.
- Rest floor: Robin's required-rest afternoon falls here and is marked **inviolable**.
  The block dropped by the patch is what makes room for it, and it is not traded back.

**Stacked-peak flag:** none. No two consecutive days read as peaks on this trip, so
there is no run to call out.

### Advance Booking Priorities

One: the Serralves timed entry, before Fri May 15. `outputs/event-status.md` is the
source and `outputs/final-itinerary.md` carries the checklist derived from it; this
section names the priority and does not restate the row.

---

**`accumulate-append`, and this instance carries one dated section.** The criterion in
`reference/data-architecture.md` § 10 — a fixture instantiating this lifecycle should
carry at least two dated sections — is met in this fixture by
`outputs/activities-list.md` and `trip-log.md`, and `README.md` § *The
accumulate-append criterion* states why the other four instances are left at one rather
than leaving the criterion silently unmet.
