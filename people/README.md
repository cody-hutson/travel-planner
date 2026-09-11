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
operation that writes an archived trip at all. It does not reopen one: the trip stays
archived, and erasure is the single exception to the rule that nothing touches it.

**It cannot be undone.** Nothing under `people/` is in git, so there is no earlier
version to restore from. After a deletion, a trip that referenced that person reads
*unknown* — never *no constraints*, and never a person with nothing on file.

**The delete path is `/trip-record erase <person-id>`.** It takes the record's id — never
a name — shows you every location it is about to reach before it changes anything, and
asks you to type that id back. There is no flag that skips the prompt and no way to run
it unattended; that is deliberate, and it is the only operation here that works this way.
It then removes the record and walks the trips, and it prints one line per location so
you can see what it reached and what it could not.

**What it cannot reach, said plainly rather than left for you to discover.** Four things
survive it, and the fourth survives for a different reason than the other three. A trip
you had already **unlinked** this person from keeps their name in its own files —
unlinking leaves no trace behind, so nothing connects that trip to this record any more
and nothing can find it by id. The erase report lists such trips as *candidates*, by path
and count, and changes nothing in them; walking them is yours. Anything already
**published** is gone from your machine only — a repository, a Pages site and any copy
anyone took of it are outside every local operation. And a value **promoted** into this
record from a trip stays in whichever trip it came from.

**The fourth is a reusable group's name.** The other three are outside the operation — a
trip it cannot find, a copy that is not on your machine, an answer belonging to the trip
it came from. A group record erasure *does* reach: it removes this person's id from every
group they were in, and then stops at the title line on purpose. The name has to be free
text for a group to have a usable one, and a sweep that rewrote free text would take the
name with it — so a group called `# Priya's crew` goes on saying so after Priya has been
erased, and clearing that is a thing you do.
[`../groups/README.md`](../groups/README.md) § *What a record does not hold* states the
same reach from the group's side.

Deleting a record by hand still works and still does only what it used to: it removes the
record, and every reference inside every trip stays behind pointing at nothing.

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

**A reusable group is a separate store, and it does not put group composition back into a
record here.** [`../groups/README.md`](../groups/README.md) holds a named set of people —
a display name and a list of person ids — so that a party you travel with often can be
referenced as a unit. **The link runs one way, from the group to the person, and there is
no line here that names a group.** That is what keeps the exclusion above true rather than
merely observed: a group record can be edited or deleted and nothing in this store changes,
because nothing in this store points at it. Reading which groups someone is in means
looking through the group store, which is what `/trip-record group-list` does.

**Trip history is resolvable without being stored, and the exclusion above is unchanged
rather than merely still true.** A trip points at a person; a person points at no trip. So
where someone has already been can be worked out by looking through the trips for the ones
that reference them — which is what `/trip-record history` does — while this store gains no
field, no file and no index, and nothing about the result is written back here. The link
runs one way again, and it is the same direction: **there is no line here that names a
trip.** Two things follow that are worth saying plainly. What that lookup can see is the
trips that *currently* reference someone, which is not the same as everywhere they have
been — a trip they were unlinked from is invisible to it, and it never reads that
invisibility as *has not been there*. And an erasure needs no extra step for any of it:
deleting the references is deleting the history, because the references are all it was.
[`../reference/adr/ADR-017-derived-trip-history.md`](../reference/adr/ADR-017-derived-trip-history.md)
records the decision.

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

**`/trip-record link <name> <person-id>` writes that line, and it shows you the
consequence first.** Adding a reference changes which source a field is planned from,
so before it writes anything the command surveys the difference: every field whose
value or whose disposition the link would change, each with **both** values side by
side — what this trip says now, and what the record says. Where the survey finds
something it stops and asks; where it finds nothing it just writes and names who the
id resolved to. Declining costs nothing: the gate sits **before** the write, so both
files are left byte-identical.

**It reconciles nothing on its own, in either direction.** The survey reports; it does
not merge. It writes no value into the record — making a trip answer durable is
`/trip-record promote`, one named field at a time — and it does not delete the trip's
own line either, even where the record's answer is the one you mean to keep. Removing
that line is yours to do, and doing nothing is a valid choice — but what it costs
depends on something outside this trip. **While the record still says what the trip
says**, a redundant line costs one report line per pass and nothing else. **Once the
record changes, that same line is a live override**: a `DEFAULT` field takes the trip's
answer for this trip, so the edit you just made to the record does not reach here, and
the pass reports the line the way it reports an override somebody chose — which is what
makes the two indistinguishable afterwards. **So make it a decision rather than a
leftover.** Keep the line to pin this trip to today's answer; remove it — delete it,
blank it, or write `—` — to let the record's later answers reach this trip. With no
reason to pin it, remove it: the record is the copy you will keep editing. Nothing on
this surface merges two people's answers together silently, and that is the property the
whole design is built to hold.

**Repointing an existing link is the branch worth reading twice.** Where the file
already names a *different* record, the command echoes the outgoing id, says plainly
that this replaces rather than adds, and counts how many fields stop drawing on the
record being replaced. Linking from nothing is additive; replacing a link is not, and
the count is there because that loss is otherwise invisible.

## Creating a record from a profile someone already filled

Most people meet this store with a folder of trip profiles and no records. **`/trip-record
extract <name>`** is the way across: it reads one traveller's filled trip profile, builds
a record from the durable answers already in it, and points that file at the new record.

**It copies. It never moves.** Not a byte of the profile's body changes — the file keeps
planning exactly as it did, whether you take the offer, decline it, or it fails partway.
The only change on the trip side is the one `person:` line.

**One file per run.** There is no bulk pass, no `--all`, and no upgrade sweep, deliberately:
a durable cross-trip record about a person is not something to create in a batch nobody
reviewed.

**You confirm against a preview, and the preview names fields rather than showing values.**
It lists what would move, what stays behind as trip-local, what has no answer to move, and
what is refused — by field name, with the display name as the only value on screen. That is
not coyness: a value echoed into a transcript is a new copy of someone's personal data in a
new place, and one an erasure cannot reach. To see the answers themselves, open the profile
— it is yours and it is untouched.

**What it will not do.** It creates nothing where the profile has no durable answers to
move — the ordinary state of a profile filled after the split, and not an error. It refuses
where the file already points at a record, rather than repointing it or minting a second.
It refuses a name that is a leftover placeholder, and it refuses where the name matches a
record already in the store, offering you the choice rather than guessing. And it never
runs unattended.

**Afterwards, expect the profile to get noisier, and nothing to be wrong.** Both files now
hold the extracted answers, so the next enrichment pass reports each one as a divergence on
a file that reported none before. Nothing is unsafe and nothing is lost: the reports are
information, every value still composes correctly, and no line is removed from anything
automatically. If you want them gone, delete the now-redundant lines from the trip profile
yourself. Nothing on this surface will do it for you.

## Retention

**Nothing here expires on its own.** No command sweeps this folder, no timer runs, and
a record does not go stale because it is old. Clearing is a thing you do.

A validity horizon on a field — the month a passport is good through — marks **that
value** stale once the month no longer covers the trip it is being used for: the later
of today and that trip's own travel window. It does not mark the record stale and it
deletes nothing: the field simply stops being usable, is reported as unknown rather than
quietly used or quietly dropped, and stays that way until someone updates it.

The folder you have stopped opening is exactly the one you stop noticing, and this one
holds the bytes worth noticing.
