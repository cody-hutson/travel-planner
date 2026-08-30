---
artifact: trip-log.md
schema-version: 1
trip: data-architecture-demo
writer: operator
lifecycle: accumulate-append
provenance: human
publish: internal
---

# Trip Log — Porto 2026

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 2 — the migrated-shape minimum.** `examples/tokyo-2026/trip-log.md` is
the worked example for this class's content. See `README.md` § *Depth*.

**`accumulate-append`, and `generated:` is absent by design.** C1, C2 and C3 are the
three classes whose schema declares `generated` **optional**, and this file is the
clearest case for why: a running register accreted across sessions has no single
generation moment to record. Each entry carries its own session date instead, in the
body, where it belongs.

## Session 2026-08-28 (Fri)

**Topics:** first full synthesis.
**Decisions:**
- Livraria Lello booked for Thu — timed entry, so it had to be held rather than left
  open. Recorded as `EV-3f9a`, `locked`.
- Base Porto held for Sat sunset — it is the one placement serving a desire both
  travellers hold, so it was worth booking rather than leaving to chance.
**Rejected:**
- A second rooftop on Fri — it would have put the same venue type twice against one
  anchor desire, and the desire is one-off rather than daily.
**Next steps:** live with v1 for a day and see how Saturday reads.

## Session 2026-08-29 (Sat)

**Topics:** Saturday felt over-packed, and nobody had written down where we were
eating.
**Decisions:**
- Slow the Saturday afternoon. `EV-c052` moved 14:00 → 16:30 and the block after it
  dropped. The move also took the viewpoint out of the `HC-2` window, which was not
  the reason for the change but is why the heat row now passes on that day.
- Place an anchor meal on every day. `agents/06-validator.md` audits that no day is
  missing an anchor event **or an anchor meal**, and v1 placed no meal anywhere — so
  the plan was failing a check whose result the report had never printed. The
  activities spoke re-ran for three walk-ins; Friday's market hall already covered
  that day. All three are walk-ins, so the booking checklist did not move and the one
  open booking is still the only one.
**Rejected:**
- Re-running the full pipeline. Two events were `locked` and a re-plan would have had
  to preserve them anyway; the lightest action that matched the intent was a patch.
- Standing up an `outputs/food-list.md` for the meals. C6 is absent from this fixture
  on purpose — the reason is a coupling to the schema suite rather than a gap, and
  `README.md` states it — so the meal research went into `outputs/activities-list.md`
  and the fixture says so rather than leaving a reader to work it out.
**Next steps:** book Serralves (`EV-b47e`) — the one needs-booking event left open.
**Open questions:** whether to chase live fado for Robin, or accept the uncovered
nice-to-have.
