---
artifact: outputs/nightlife-list.md
schema-version: 1
trip: data-architecture-demo
writer: nightlife
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Nightlife List — Porto

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**`accumulate-append`:** each run adds a dated section. Nothing above is deleted or
rewritten, because the hub reads the whole accumulated file and earlier entries stay
useful as alternatives and as the record of what was already considered.

**Entry marker.** C7 is prose-shaped: each entry carries a fenced `artifact-entry`
block holding the venue key and nothing else, directly under its own heading.

## Initial Research (2026-08-29)

The desire gate resolved **open**: Alex holds *Watch a sunset from a rooftop* as an
anchor and Robin holds it as a wish, so a present traveller holds an
evening/nightlife desire and this spoke produces rather than writing a gate-result
stub.

### Base Porto — rooftop bar

```artifact-entry
venue: ven-8a34
```

- **Placed as:** `EV-5ab8`, May 16 (Sat), `locked`
- **Booking:** advance — a table is held
- **Why:** the only option on this list that serves the rooftop-sunset desire both
  travellers hold, which is why it is the anchor rather than an alternative
- **Access:** lift to the terrace — clears `HC-1`
- **Price tier:** mid · **Effort:** low

### Casa do Livro — bar

```artifact-entry
venue: ven-1d9f
```

- **Placed as:** `EV-9e34`, May 16 (Sat), `option`
- **Booking:** advance available, not held — the flag takes effect only on promotion
- **Why:** the bailout if the rooftop is rained off; indoor, five minutes away
- **Access:** street level — clears `HC-1`
- **Price tier:** low · **Effort:** low

**Alternatives vary on two axes.** Base Porto and Casa do Livro differ on price
tier **and** on what they are for — a held table at a view venue against a walk-in
indoor fallback. Two rooftop bars at the same price with the same walk-in status
would have been two entries and one option.

### Live fado

**No entry marker, because there is no entity to key.** Robin holds *Hear live fado*
as a nice-to-have and nothing on this list serves it. This is a **want recorded as
uncovered**, not a venue — so it carries no `artifact-entry` block at all, which is
different from carrying one that declares `venue: unminted`. An unminted key says
*this venue exists and the hub has not yet minted its token*; no block says *there is
no venue here*. `outputs/satisfaction-metrics.md` carries the matching `not covered`
row. An uncovered nice-to-have is a coverage reading, not a failure.
