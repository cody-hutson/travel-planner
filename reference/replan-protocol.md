# Replan Protocol — The Short Horizon

## What this document owns

This document owns the **behaviour a replan takes when the trip is near** — what
leads, what stops being advisory, and which levers are still open when there are
fewer days left than an item needs. It owns that and nothing else.

It **defines no data.** Every field, status value and predicate named below is
declared in `reference/data-model.md`, and this document cites them rather than
restating them. It **dispatches nothing.** Which agent runs on which verb belongs
to the control-flow contract — `.claude/commands/trip.md` § *replan* and
`CLAUDE.md` § *Dispatching agents* — and a second statement of a dispatch
decision is a second place for it to go stale.

It is the home two hooks in `reference/data-model.md` already declare and leave
unnamed: the closing sentence of § *Forward Connection — Profile Edits as a
Replanning Trigger*, which places the replanning behaviour with the replanning
capability rather than with that substrate, and the **No replanning policy**
bullet in § *What This Document Does Not Define*. Both now name this file.

## The signal — `days-to-trip-start`

**Definition, stated here and nowhere else.** `days-to-trip-start` is the count of
whole days between **today** and **the trip's first day**.

- **Today** is the date the reading agent stamps on its own output. For the
  validator that is the `generated:` field its artifact class requires
  (`reference/schemas/validation-report.md`). An agent that stamps no date reads
  no horizon.
- **The trip's first day** is the anchor origin's **arrival** — the Arrival day
  line of `trip-context.md` § `### Effective Planning Days [DERIVED]`, which
  `templates/trip-context.template.md` fixes as that origin's *last Outbound
  leg's* `Arrives:`.

**Derived at read time, never stored.** No artifact carries this value, no agent
writes it, and no schema declares it. A stored day-count is wrong the day after it
is written; any future proposal to persist it is a shadow source of truth, and is
refused here in advance.

**Why the name counts to the start.** The corpus already fixes *departure* as the
day the trip **ends** — each origin's departure is its *first Return leg's*
`Departs:`, stated in `templates/trip-context.template.md` and repeated verbatim
in `agents/04-transport.md`. This signal counts to the day the trip **begins**, so
it is named for the start rather than qualified wherever it is read. **No
consumption site carries a disambiguating clause**, and one that acquires a clause
has drifted back toward the name this protocol declined.

**Scope, inherited and not invented.** § *Effective Planning Days* declares itself
**not** a group-wide guarantee on a multi-origin trip, and this signal inherits
that limit unchanged: it is a trip-level posture, never a per-traveler one. What
any single traveler's window is remains that traveler's own derived block to
answer.

## The booking horizon — per item, never a fixed number

An item is **inside its horizon** when the whole days between today and **that
item's own event day** are at or below the **lead time its own row declares**.

The declared lead time is read from one of two places, in this order:

1. The `Lead Time` cell of the item's row in the **ADVANCE BOOKING CHECKLIST**
   the hub writes (`agents/05-hub-planner.md`), carried in
   `outputs/final-itinerary.md`.
2. Failing that, the category's `Lead Time Required` in `agents/03-scheduling.md`
   § *Advance Booking Priorities*. **That table ships a header and a separator and
   no rows**, so today it supplies nothing — it is a declared shape that is not
   yet populated, read by this same rule if it ever is.

**A replan is short-horizon when at least one checklist item is inside its
horizon.** That is the whole trigger, and it is the plan that decides it.

**No day count appears in this document, and none is to be added.** A fixed
threshold is right for one category and wrong for every other; the horizon is read
from the plan, never declared here.

**Where no horizon can be read.** A row whose `Lead Time` is absent or is not
expressed as a countable span, **and** whose `Deadline` resolves to no date,
carries no horizon at all, and no reading is taken over it. That gap is in the
**record**, not in the plan: it is reported as such — naming the item and the cell
— rather than being counted as either inside the horizon or outside it. A row that
carries either operand is read from the one it carries.

## What shifts, and what does not

**Bookability and closure lead, and the order does not change.** The validator's
priority list already opens with closure first and reservation availability second
(`agents/06-validator.md` § *Priorities (in order)*). Inside the horizon those two
**stop being advisory**: an item whose declared deadline has passed is a defect in
the **plan**, not a note about it, because the itinerary now depends on an event
that can no longer be secured.

**The trade this protocol names.** A remedy that cannot land before the deadline is
not a remedy. An alternative whose own lead time exceeds the days remaining must
not be proposed as the fix for an item inside its horizon — proposing it turns one
unbookable item into two, and reports the plan as repaired.

**Date-moves are first-class levers.** Moving an event to a later day **buys lead
time**, and near the trip's start it is often the only remedy that fits inside the
horizon at all. What a day move makes stale, and which agent it admits, is already
settled in `.claude/commands/trip.md` § *replan*'s coupling table — **cite that
table; no row of it is restated here.** A second statement of it is a second thing
to keep in step with it.

**What does not shift.** The status model is unchanged near the trip's start:
`locked` and `firmed` events keep their protection, an `option` is still never
promoted into a primary slot, and the needs-booking predicate is the one
`reference/data-model.md` already declares. The horizon changes what leads and what
counts as a defect. It changes no status rule, and nothing here adds one.

## Who consumes it

| Consumer | Where it is read |
|----------|------------------|
| `agents/06-validator.md` | § *Output Format* → the **Booking feasibility at the horizon** check, with its depth stated on the `DISCOVERY` and `ITERATION` branches of § *Mode Behavior* |
| `agents/03-scheduling.md` | § *Advance Booking Priorities*, and § *Mode Behavior* → `ITERATION` for when that section is re-produced |

This table is the consumer index. A later consumer is added to it here.

## What this document does not define

To keep the boundary clear:

- **No dispatch rule.** Which verb dispatches which agent, and what a change makes
  stale, live in `.claude/commands/trip.md` and `CLAUDE.md`. Both are cited above
  and neither is restated.
- **No preservation floor.** What a replan must hold of the group's stated intent
  and its price posture belongs to the individual mechanics of a replan, which are
  the child work items' scope and not this protocol's.
- **No new severity.** Findings raised under this protocol use the severities the
  validator already ships. This document introduces no fourth severity word, and
  no state vocabulary of its own for the horizon.
- **No stored signal, no new artifact, no new writer.** `days-to-trip-start` is
  derived at read time; this protocol creates no file, adds no writer to one, and
  declares no field.

Behaviour contracts live with their agents. This document is the short-horizon
**behaviour** contract; its data contract is `reference/data-model.md`.
