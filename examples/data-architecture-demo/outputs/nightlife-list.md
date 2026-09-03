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
block holding the venue key — and, since § 4.5.1 amended the rule, one optional
`cost:` line — and nothing else, directly under its own heading. **Both markers here
carry the key alone**: no prompt emits the cost field yet, and each entry's own money
line stays the master either way.

**Both markers below are resolved, and `generated:` is why the file's dates differ.**
The entries were written on the first pass (2026-08-28) and were born
`venue: unminted`, because a spoke runs before the hub enumerates. The nightlife spoke
re-ran on 2026-08-29 to re-check the rooftop against the patched Saturday, found nothing
to add, and **resolved its own two markers in place on that pass** — so `generated:`
moved to the later date while the dated section below did not, and no section was
appended. **Resolving a marker is not an append**: the frontmatter block is upgraded in
place, body entries are never rewritten, and a re-run that confirms rather than adds has
nothing to accumulate. `outputs/activities-list.md` carries the same mechanism with the
other outcome — a re-run that *did* append — and states it at length.

## Initial Research (2026-08-28)

The desire gate resolved **open**: Alex holds *Watch a sunset from a rooftop* as an
anchor and Robin holds it as a wish, so a present traveller holds an
evening/nightlife desire and this spoke produces rather than writing a gate-result
stub.

### Base Porto — rooftop bar

```artifact-entry
venue: ven-8a34
```

- **Location:** Rua do Miradouro 12, Centro — the same address the targeted-research
  entry carries, which is what joined the two mentions
- **Night type:** low-key drink, at sunset
- **Booking:** advance — a table can be held, and one has been
- **Why:** the only option on this list that serves the rooftop-sunset desire both
  travellers hold, which is why it is offered as the evening's anchor rather than as
  an alternative
- **Access:** lift to the terrace — clears `HC-1`
- **Price tier:** mid · **Effort:** low
- **Next-morning cost:** an early-evening sitting; nothing it costs the next start

### Casa do Livro — bar

```artifact-entry
venue: ven-1d9f
```

- **Location:** Rua do Miradouro 40, Centro — a different address on the same street,
  which is what keeps it a **second** venue rather than a second name for the first
- **Night type:** low-key drink, indoor
- **Booking:** advance available, not held
- **Why:** the fallback if the rooftop is rained off; indoor, five minutes away
- **Access:** street level — clears `HC-1`
- **Price tier:** low · **Effort:** low
- **Next-morning cost:** none

**Alternatives vary on two axes.** Base Porto and Casa do Livro differ on price
tier **and** on what they are for — a held table at a view venue against a walk-in
indoor fallback. Two rooftop bars at the same price with the same walk-in status
would have been two entries and one option.

**Neither entry names the other's key, and neither names an Event ID.** Which of these
the hub places, on which day, and at which status is the hub's act and lives in
`outputs/event-status.md` and `outputs/final-itinerary.md`. A research list that
narrated its own placements would be asserting a decision it does not make, on a pass
that has not happened yet when the entry is written.

### Live fado

**No entry marker, because there is no entity to key.** Robin holds *Hear live fado*
as a nice-to-have and nothing on this list serves it. This is a **want recorded as
uncovered**, not a venue — so it carries no `artifact-entry` block at all, which is
different from carrying one that declares `venue: unminted`. An unminted key says
*this venue exists and the hub has not yet minted its token*; no block says *there is
no venue here*. `outputs/satisfaction-metrics.md` carries the matching `not covered`
row and `outputs/validation-report.md` carries it as `[W2]`. An uncovered nice-to-have
is a coverage reading, not a failure.

**This fixture therefore shows all three marker states, one per file**, and they are
three different facts: a **resolved** key here, `venue: unminted` in
`outputs/rooftop-sunset-bars.md` and in the second dated section of
`outputs/activities-list.md`, and **no marker at all** on the entry above.
