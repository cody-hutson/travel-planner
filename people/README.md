# people/

One durable record per person — **one file, held across trips, rather than a copy of
the same facts inside each one.** A passport's issuing country, a standing dietary
need, how someone travels: these do not change when the trip does, so they are
answered once here and referenced from each trip instead of re-asked.

Everything in here is git-ignored except this file.

## What a record is

`people/psn-<token>.md`, one file per person. The filename carries the person's id —
minted once and never reused, so two people who happen to share a name still have two
records. The title line carries their display name and nothing else.

A trip does not copy these facts. A traveller's file inside a trip **points at** the
record, and the planner reads the two together — the durable record for what is
standing, the trip file for what is true of this trip only. One source per fact.

**One writer, and it is never an agent.** A record is written by the person it
describes, or by you writing down what that person told you. No agent authors a value
in it, computes one into it, or edits one already there. Agents read it.

## Why this file is tracked and nothing beside it is

A clone has to show that `people/` is where person records live. This file is the only
tracked thing under it: `.gitignore` excludes the directory's *contents* (`/people/*`)
rather than the directory itself, so this signpost survives while every record beside
it stays on your machine.

Same arrangement as [`../trips/README.md`](../trips/README.md) and
[`../analysis/README.md`](../analysis/README.md), for the same reason. The invariant is
tested — see group `U` in
[`../scripts/test-publish-guard.sh`](../scripts/test-publish-guard.sh).

## Privacy

**These are the most sensitive bytes in the repository, and they are durable rather
than per-trip.** A record holds a passport's issuing country and the month it is valid
through, standing needs — including health-adjacent ones such as an allergy, a mobility
limit or a heat ceiling — and personal preferences. A trip folder holds that kind of
detail for the length of one trip; this store holds the part of it that outlives every
trip, which is why it concentrates the risk rather than merely repeating it.

Nothing here is ever published. The class is declared *never rendered, in any form,
including anonymized* — not in a built site, not in an anonymized summary, not in an
excerpt. Nothing here leaves your machine, and nothing here enters git history.

Ask for no more precision than the plan needs. The intake form asks for a passport's
issuing country and validity month and says **never the number**; a durable record does
not get to ask for more than the per-trip form it replaces.

## Deleting a person

**Deleting a person is its own operation, and it is not the same as taking someone off
one trip.** Removing a traveller from a trip leaves their record here untouched, and
says so. Deleting the person deletes the record **and reaches every trip that
referenced it**, archived trips included — that reach is the point, and it is the one
operation allowed to reopen an archived trip.

**It cannot be undone.** Nothing under `people/` is in git, so there is no earlier
version to restore from. After a deletion, a trip that referenced that person reads
*unknown* — never *no constraints*, and never a person with nothing on file.

**Until the erasure command ships, the delete path is your own hand:** remove the file.
That deletes the record and nothing else — the references inside each trip stay behind,
pointing at a record that is gone, which is precisely the sweep the command exists to
perform. So delete a record by hand only when you are ready to walk the trips that
pointed at it, and expect to do that walk yourself.

## What a record does not hold

A record is **strictly one person**. It has no slot for any of the following, and that
is structural rather than a rule someone has to remember — none of these fields exists
in the durable form at all:

- **group or party composition** — who is travelling together, who is rooming with
  whom, who peels off with whom;
- **any split** — a share of a cost, a share of a booking;
- **computed values** — anything the planner works out, such as who else shares a want;
- **trip history** — where this person has already been, or what they have already done
  there;
- **a second person's data.** A record describes the person it is named for. Someone
  travelling on another person's booking is recorded in that *trip*, bounded to their
  needs, and never given a record here.

And **no record for a person who did not ask for one.** A durable, cross-trip file
about someone who never spoke to you is a different thing from a note in one trip's
folder, and this store does not hold it.

## A relayed value is not an agreed one

When you write down what someone else told you, that value is marked as relayed, so a
later reader can tell it apart from what the person wrote themselves. **The mark records
where the value came from. It never records that the person agreed to it being kept.**

Carrying is not confirming. If you are unsure whether someone wants a durable record of
their needs, the answer is not to mark it more carefully — it is to not create the
record.

## Linking a trip to a record

A trip links to a record from the traveller's own file inside that trip: a single
`person:` field carrying the record's id. That one line is the whole link — the trip
file then carries only what is true of this trip, and everything durable is read from
the record.

**Its absence is normal.** A traveller with no `person:` line is a complete, valid
traveller; the trip simply answers everything itself, exactly as it did before this
store existed. Nothing requires a person to have a record, and a first trip never
needs one.

## Retention

**Nothing here expires on its own.** No command sweeps this folder, no timer runs, and
a record does not go stale because it is old. Clearing is a thing you do.

A validity horizon on a field — the month a passport is good through — marks **that
value** stale when the month passes. It does not mark the record stale and it deletes
nothing: the field simply stops being usable, is reported as unknown rather than
quietly used or quietly dropped, and stays that way until someone updates it.

The folder you have stopped opening is exactly the one you stop noticing, and this one
holds the bytes worth noticing.
